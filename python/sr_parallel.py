"""Offline Apollo conversion on the GPU (MPS) and the CPU at the same time.

No real-time requirement: the song is cut into chunks, and a GPU worker and a
CPU worker each take the next chunk when they are free, so the faster one
simply does more and both finish together. Every chunk is computed once, with
real audio on both sides (`pad`) that is thrown away afterwards, and the
results are joined in order.

The slow device is not allowed to take a chunk that would still be running
after the fast one has finished everything else, which would only make the
whole job wait for it.

    uv run python sr_parallel.py 缭花绚烂.mp3
    uv run python sr_parallel.py song.mp3 --seconds 40 --devices mps     # GPU only
    uv run python sr_parallel.py song.mp3 --seconds 40 --devices mps cpu
"""
import argparse
import os
import sys
import threading
import time
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from tqdm import tqdm

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))

import look2hear.models  # noqa: E402

from apollo_split import MixedPrecisionApollo  # noqa: E402
from sr_mp3 import SR, load  # noqa: E402


class ParallelConverter:
    def __init__(self, checkpoint: Path, devices: list[str], chunk_s=5.0, pad_s=1.0, fp16=False):
        self.devices = devices
        self.chunk = int(chunk_s * SR)
        self.pad = int(pad_s * SR)
        def build(device: str):
            model = look2hear.models.BaseModel.from_pretrain(
                str(checkpoint), sr=SR, win=20, feature_dim=256, layer=6
            ).eval()
            if fp16:
                model = MixedPrecisionApollo(model, torch.float16).eval()
            return model.to(device)

        self.models = {d: build(d) for d in devices}

    def _run(self, device: str, audio: torch.Tensor, start: int) -> np.ndarray:
        total = audio.shape[-1]
        window = min(self.chunk + 2 * self.pad, total)
        ws = min(max(0, start - self.pad), total - window)
        x = audio[..., ws : ws + window].to(device)
        with torch.inference_mode():
            y = self.models[device](x)
        if device == "mps":
            torch.mps.synchronize()
        y = y.detach().to("cpu").squeeze(0).numpy()
        lo = start - ws
        return y[:, lo : lo + min(self.chunk, total - start)]

    def convert(self, audio: torch.Tensor, bar=None):
        total = audio.shape[-1]
        starts = list(range(0, total, self.chunk))
        results: dict[int, np.ndarray] = {}
        per_chunk = {d: 0.0 for d in self.devices}  # smoothed seconds per chunk
        taken = {d: 0 for d in self.devices}
        next_index = [0]
        lock = threading.Lock()
        errors: list[BaseException] = []

        def claim(device: str) -> int | None:
            """Next chunk for `device`, or None when it should stop."""
            with lock:
                i = next_index[0]
                if i >= len(starts):
                    return None
                # A device with a known speed only takes work that does not
                # outlast what the fastest device needs for everything left.
                known = [t for d, t in per_chunk.items() if t > 0]
                mine = per_chunk[device]
                if mine > 0 and known and mine > min(known):
                    left = len(starts) - i
                    # `left` chunks split among the devices by their speed.
                    rate = sum(1 / t for t in known)
                    if mine > left / rate:
                        return None
                next_index[0] += 1
                return i

        def worker(device: str) -> None:
            try:
                while (i := claim(device)) is not None:
                    t = time.perf_counter()
                    out = self._run(device, audio, starts[i])
                    took = time.perf_counter() - t
                    with lock:
                        results[i] = out
                        taken[device] += 1
                        old = per_chunk[device]
                        per_chunk[device] = took if old == 0 else 0.6 * old + 0.4 * took
                        if bar:
                            bar.update(out.shape[-1] / SR)
                            bar.set_postfix_str(
                                ", ".join(f"{d} {taken[d]} chunks" for d in self.devices)
                            )
            except BaseException as e:  # noqa: BLE001
                errors.append(e)

        threads = [threading.Thread(target=worker, args=(d,), name=d) for d in self.devices]
        for t in threads:
            t.start()
        for t in threads:
            t.join()
        if errors:
            raise errors[0]
        # Chunks the slow device declined are all taken by the fast one, so
        # everything is covered; check anyway.
        missing = [i for i in range(len(starts)) if i not in results]
        if missing:
            raise RuntimeError(f"chunks never computed: {missing}")
        return np.concatenate([results[i] for i in range(len(starts))], axis=-1), taken, per_chunk


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("--out", type=Path, default=HERE / "out" / "parallel")
    p.add_argument("--devices", nargs="+", default=["mps", "cpu"], choices=["mps", "cpu"])
    p.add_argument("--fp16", action="store_true", help="run the network in FP16 (STFT stays FP32)")
    p.add_argument("--chunk-seconds", type=float, default=5.0)
    p.add_argument("--cpu-threads", type=int, default=os.cpu_count(), help="threads for the CPU worker (default: every core)")
    p.add_argument("--seconds", type=float, default=None, help="only the first N seconds")
    p.add_argument("--checkpoint", type=Path, default=HERE / "models" / "pytorch_model.bin")
    args = p.parse_args()

    torch.set_num_threads(args.cpu_threads)
    audio = load(args.input)
    if args.seconds:
        audio = audio[..., : int(args.seconds * SR)]
    total_s = audio.shape[-1] / SR
    print(f"{args.input.name}: {total_s:.1f} s, devices {args.devices}, CPU threads {args.cpu_threads}")

    conv = ParallelConverter(args.checkpoint, args.devices, chunk_s=args.chunk_seconds, fp16=args.fp16)
    bar = tqdm(total=round(total_s, 1), unit="s", bar_format="{l_bar}{bar}| {n:.0f}/{total:.0f} s [{elapsed}<{remaining}] {postfix}")
    t0 = time.perf_counter()
    out, taken, per_chunk = conv.convert(audio, bar)
    bar.close()
    wall = time.perf_counter() - t0
    print(f"converted {total_s:.1f} s in {wall:.1f} s (x{total_s / wall:.2f} realtime)")
    for d in args.devices:
        print(f"  {d}: {taken[d]} chunks, {per_chunk[d]:.1f} s per {args.chunk_seconds:.0f} s chunk")

    peak = float(np.abs(out).max())
    if peak > 1.0:
        print(f"peak {peak:.3f} > 1.0: scaled by {20 * np.log10(1 / peak):.1f} dB for the FLAC")
        out = out / peak
    args.out.mkdir(parents=True, exist_ok=True)
    tag = "+".join(args.devices) + (".fp16" if args.fp16 else "")
    flac = args.out / f"{args.input.stem}.{tag}.flac"
    sf.write(flac, out.T, SR, subtype="PCM_16", format="FLAC")
    print(f"wrote {flac} ({flac.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
