"""Soft-real-time Apollo conversion with a progress bar (stage 0 prototype).

One pass over the song, in order: the first 5 s chunk doubles as the speed
calibration, every chunk's result is cached once, and the cache is simply
concatenated into the FLAC at the end. So playback could start from the cache
long before the file is finished, and nothing is ever computed twice.

    uv run python sr_stream.py 缭花绚烂.mp3
    uv run python sr_stream.py song.mp3 --seconds 60 --device cpu

How a chunk is cut: the model is run on the chunk plus real audio on both
sides (`pad`), and only the middle is kept, because Apollo is wrong within
about 0.5 s of the edge of what it is given. When playback is starving, the
pad is cut from 1.0 s to 0.5 s to run faster (a small quality trade).
"""
import argparse
import sys
import time
from dataclasses import dataclass, field
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
from tqdm import tqdm

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))

import inference as apollo  # noqa: E402
import look2hear.models  # noqa: E402

from sr_mp3 import SR, load  # noqa: E402


@dataclass
class Progress:
    """Live state of one conversion, also what a UI would show."""

    total_s: float
    done_s: float = 0.0
    rtf: float = 0.0  # audio seconds produced per wall second, smoothed
    pad_s: float = 1.0
    started_play_at: float | None = None  # wall seconds since the start
    underruns: list[float] = field(default_factory=list)


class SoftRealtimeConverter:
    def __init__(self, model, device, chunk_s=5.0, pad_s=1.0, low_pad_s=0.5, margin=1.15):
        self.model, self.device = model, device
        self.chunk_s, self.pad_s, self.low_pad_s, self.margin = chunk_s, pad_s, low_pad_s, margin

    def _run(self, audio: torch.Tensor, start: int, chunk: int, pad: int) -> np.ndarray:
        """Model output for audio[start:start+chunk], from a window with context."""
        total = audio.shape[-1]
        window = min(chunk + 2 * pad, total)
        ws = min(max(0, start - pad), total - window)
        x = audio[..., ws : ws + window].to(self.device)
        with torch.inference_mode():
            y = self.model(x)
        if self.device.type == "mps":
            torch.mps.synchronize()
        y = y.detach().to("cpu").squeeze(0).numpy()
        lo = start - ws
        return y[:, lo : lo + min(chunk, total - start)]

    def convert(self, audio: torch.Tensor, on_update=None):
        """Returns (cache [ch, samples], Progress, per-chunk completion log)."""
        total = audio.shape[-1]
        chunk = int(self.chunk_s * SR)
        prog = Progress(total_s=total / SR, pad_s=self.pad_s)
        cache: list[np.ndarray] = []
        log: list[tuple[float, float]] = []  # (wall time done, audio seconds ready)
        t0 = time.perf_counter()
        start = 0
        while start < total:
            pad = int(prog.pad_s * SR)
            t = time.perf_counter()
            cache.append(self._run(audio, start, chunk, pad))
            took = time.perf_counter() - t
            n = cache[-1].shape[-1]
            speed = (n / SR) / took
            # The first chunk includes the model warm-up, so it only seeds.
            prog.rtf = speed if prog.rtf == 0 else 0.6 * prog.rtf + 0.4 * speed
            start += n
            prog.done_s = start / SR
            now = time.perf_counter() - t0
            log.append((now, prog.done_s))

            # Soft real time. Playback may start once what is cached plus what
            # the remaining speed can still deliver never runs dry.
            remaining = prog.total_s - prog.done_s
            if prog.started_play_at is None:
                wait_needed = 0.0 if prog.rtf >= 1 else remaining / prog.rtf - remaining
                wait_needed *= self.margin
                if prog.done_s >= self.chunk_s and (prog.rtf >= 1 or now >= wait_needed):
                    prog.started_play_at = now
            else:
                played = now - prog.started_play_at
                if played > prog.done_s:  # the playhead caught up with the cache
                    prog.underruns.append(now)
                # Starving: spend a little quality for speed. Only when the
                # cache is nearly dry, or we cannot keep up at all.
                ahead = prog.done_s - played
                starving = ahead < 0.5 * self.chunk_s or (prog.rtf < 1.0 and ahead < 2 * self.chunk_s)
                prog.pad_s = self.low_pad_s if starving else self.pad_s
            if on_update:
                on_update(prog)
        return np.concatenate(cache, axis=-1), prog, log


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("--out", type=Path, default=HERE / "out" / "stream")
    p.add_argument("--device", default="auto", choices=apollo.DEVICE_CHOICES)
    p.add_argument("--chunk-seconds", type=float, default=5.0)
    p.add_argument("--seconds", type=float, default=None, help="only the first N seconds")
    p.add_argument("--checkpoint", type=Path, default=HERE / "models" / "pytorch_model.bin")
    args = p.parse_args()

    device = apollo.select_device(args.device)
    audio = load(args.input)
    if args.seconds:
        audio = audio[..., : int(args.seconds * SR)]
    total_s = audio.shape[-1] / SR
    model = look2hear.models.BaseModel.from_pretrain(
        str(args.checkpoint), sr=SR, win=20, feature_dim=256, layer=6
    ).to(device).eval()
    print(f"{args.input.name}: {total_s:.1f} s, {audio.shape[1]} ch, device={device}")

    conv = SoftRealtimeConverter(model, device, chunk_s=args.chunk_seconds)
    bar = tqdm(total=round(total_s, 1), unit="s", bar_format="{l_bar}{bar}| {n:.0f}/{total:.0f} s [{elapsed}<{remaining}] {postfix}")
    last = [0.0]

    def update(prog: Progress) -> None:
        bar.update(prog.done_s - last[0])
        last[0] = prog.done_s
        playing = "▶ playable" if prog.started_play_at is not None else "buffering"
        bar.set_postfix_str(f"x{prog.rtf:.2f} realtime, pad {prog.pad_s:.1f}s, {playing}")

    t0 = time.perf_counter()
    out, prog, log = conv.convert(audio, update)
    bar.close()
    wall = time.perf_counter() - t0

    # What the user would have experienced, judged after the fact: the smallest
    # head start with which playback never stalls.
    min_start = max(t_done - (ready - n) for (t_done, ready), n in zip(log, [log[0][1]] + [b[1] - a[1] for a, b in zip(log, log[1:])]))
    print(f"converted {total_s:.1f} s in {wall:.1f} s (x{total_s / wall:.2f} realtime)")
    print(f"first chunk ready after {log[0][0]:.1f} s; smallest stall-free head start {max(0.0, min_start):.1f} s")
    if prog.started_play_at is not None:
        print(f"online policy started playback at {prog.started_play_at:.1f} s, stalls: {len(prog.underruns)}")

    peak = float(np.abs(out).max())
    if peak > 1.0:
        print(f"peak {peak:.3f} > 1.0: scaled by {20 * np.log10(1 / peak):.1f} dB for the FLAC")
        out = out / peak
    args.out.mkdir(parents=True, exist_ok=True)
    flac = args.out / f"{args.input.stem}.sr.flac"
    sf.write(flac, out.T, SR, subtype="PCM_16", format="FLAC")
    print(f"wrote {flac} ({flac.stat().st_size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
