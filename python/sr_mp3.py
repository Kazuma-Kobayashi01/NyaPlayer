"""Stage 0 of the AI super-resolution experiment: run Apollo on an MP3 (or any
file libsndfile can read) and write a 16-bit/44.1 kHz FLAC plus a before/after
spectrogram. Not part of the app; see docs for the plan.

    uv run python sr_mp3.py ~/Music/song.mp3
    uv run python sr_mp3.py song.mp3 --device cpu     # compare with the CPU
"""
import argparse
import sys
import time
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np
import soundfile as sf
import torch
import torchaudio

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))

import inference as apollo  # noqa: E402
import look2hear.models  # noqa: E402

SR = apollo.SAMPLE_RATE  # 44100


def load(path: Path) -> torch.Tensor:
    """[1, channels, samples] float32 at 44.1 kHz."""
    audio, rate = sf.read(path, dtype="float32", always_2d=True)
    x = torch.from_numpy(np.ascontiguousarray(audio.T))
    if rate != SR:
        x = torchaudio.functional.resample(x, rate, SR)
    return x.unsqueeze(0)


def cutoff_khz(x: np.ndarray) -> float:
    """Highest frequency whose average level is within 60 dB of the peak bin."""
    mono = x.mean(axis=0)
    spec = np.abs(np.fft.rfft(mono[: SR * 60].reshape(-1)[: len(mono)])) ** 2
    freqs = np.fft.rfftfreq(len(mono[: SR * 60]), 1 / SR)
    db = 10 * np.log10(spec + 1e-20)
    # Smooth over 200 Hz so single bins do not decide.
    k = max(1, int(200 / (freqs[1] - freqs[0])))
    db = np.convolve(db, np.ones(k) / k, mode="same")
    above = np.where(db > db.max() - 90)[0]
    return float(freqs[above[-1]] / 1000) if len(above) else 0.0


def spectrogram(ax, x: np.ndarray, title: str) -> None:
    ax.specgram(x.mean(axis=0), NFFT=2048, Fs=SR, noverlap=1024, vmin=-130, vmax=-20, cmap="magma")
    ax.set_ylim(0, 22050)
    ax.set_title(title)
    ax.set_ylabel("Hz")


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("--out", type=Path, default=HERE / "out")
    p.add_argument("--device", default="auto", choices=apollo.DEVICE_CHOICES)
    p.add_argument("--chunk-seconds", type=float, default=6.0)
    p.add_argument("--overlap-seconds", type=float, default=1.0)
    p.add_argument("--chunk-pad-seconds", type=float, default=1.0)
    p.add_argument("--seconds", type=float, default=None, help="only the first N seconds (quick test)")
    p.add_argument("--reference", type=Path, default=None, help="the true lossless original, drawn as a third spectrogram")
    p.add_argument("--checkpoint", type=Path, default=HERE / "models" / "pytorch_model.bin")
    args = p.parse_args()

    args.out.mkdir(parents=True, exist_ok=True)
    device = apollo.select_device(args.device)
    audio = load(args.input)
    if args.seconds:
        audio = audio[..., : int(args.seconds * SR)]
    duration = audio.shape[-1] / SR
    print(f"input: {args.input.name}, {duration:.1f} s, {audio.shape[1]} ch, device={device}")

    model = look2hear.models.BaseModel.from_pretrain(
        str(args.checkpoint), sr=SR, win=20, feature_dim=256, layer=6
    ).to(device).eval()
    params = sum(p.numel() for p in model.parameters())
    print(f"model: {params / 1e6:.1f} M parameters")

    chunk, overlap, pad = apollo.resolve_chunking(
        args.chunk_seconds, args.overlap_seconds, args.chunk_pad_seconds
    )
    start = time.perf_counter()
    with torch.inference_mode():
        out = apollo.run_model(model, audio, device, chunk, overlap, 1, pad)
    if device.type == "mps":
        torch.mps.synchronize()
    took = time.perf_counter() - start
    print(f"inference: {took:.1f} s for {duration:.1f} s of audio (x{duration / took:.2f} realtime)")

    stem = args.input.stem
    before = audio.squeeze(0).numpy()
    after = out.squeeze(0).numpy()
    peak = float(np.abs(after).max())
    if peak > 1.0:
        print(f"peak {peak:.3f} > 1.0: scaled down to avoid clipping in FLAC")
        after = after / peak
    flac = args.out / f"{stem}.sr.flac"
    sf.write(flac, after.T, SR, subtype="PCM_16", format="FLAC")
    print(f"wrote {flac} ({flac.stat().st_size / 1e6:.1f} MB)")
    if args.reference:
        ref_audio = load(args.reference).squeeze(0).numpy()[:, : before.shape[-1]]
        n = min(ref_audio.shape[-1], after.shape[-1])
        def snr(a):
            noise = a[:, :n] - ref_audio[:, :n]
            return 10 * np.log10((ref_audio[:, :n] ** 2).sum() / ((noise ** 2).sum() + 1e-20))
        print(f"SNR vs the original: input {snr(before):.2f} dB, Apollo {snr(after):.2f} dB")

    rows = [(before, "input (lossy)"), (after, f"Apollo ({device.type})")]
    if args.reference:
        ref = load(args.reference).squeeze(0).numpy()[:, : before.shape[-1]]
        rows.append((ref, "reference (lossless original)"))
    fig, axes = plt.subplots(len(rows), 1, figsize=(12, 3.5 * len(rows)), sharex=True)
    for ax, (x, title) in zip(axes, rows):
        spectrogram(ax, x, title)
    axes[-1].set_xlabel("s")
    png = args.out / f"{stem}.spec.png"
    fig.tight_layout()
    fig.savefig(png, dpi=110)
    print(f"wrote {png}")


if __name__ == "__main__":
    main()
