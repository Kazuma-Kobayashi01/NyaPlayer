"""Does Apollo survive INT8? Fake-quantised inference on a short clip (stage 0).

"Fake" means values are rounded to the INT8 grid and converted back to float,
so this measures the quality cost of INT8 only, not any speed gain (that needs
a real INT8 runtime: Core ML on the ANE, MNN on Android).

W8A8 here: every Conv1d weight per output channel, every Conv1d input and the
attention Q/K/V per tensor, all symmetric int8 with a dynamic range (scale =
max |x| / 127). `--aggressive`: one scale per weight tensor, and Conv1d / attention outputs
rounded to int8 as well. (RMSNorm outputs need no extra rounding here: each one
feeds a Conv1d, whose input is already rounded.)

    uv run python sr_int8_sim.py 缭花绚烂.mp3 --start 60 --seconds 5
"""
import argparse
import copy
import sys
from pathlib import Path

import numpy as np
import soundfile as sf
import torch
import torch.nn as nn
import torch.nn.functional as F

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))
import look2hear.models  # noqa: E402
import look2hear.models.apollo as apollo_mod  # noqa: E402

from sr_mp3 import SR, load  # noqa: E402


def fq(x: torch.Tensor, dim=None) -> torch.Tensor:
    """Symmetric int8 round trip; per tensor, or per slice along `dim`."""
    if dim is None:
        scale = x.abs().max().clamp_min(1e-12) / 127
    else:
        scale = x.abs().amax(dim=[d for d in range(x.ndim) if d != dim], keepdim=True).clamp_min(1e-12) / 127
    return (x / scale).round().clamp(-127, 127) * scale


def quantise(model: nn.Module, aggressive: bool) -> nn.Module:
    """W8A8. Aggressive: one scale per weight tensor instead of per output
    channel, and every Conv1d output is rounded to int8 too."""
    q = copy.deepcopy(model)
    for m in q.modules():
        if isinstance(m, nn.Conv1d):
            with torch.no_grad():
                m.weight.copy_(fq(m.weight, dim=None if aggressive else 0))
            m.register_forward_pre_hook(lambda mod, args: (fq(args[0]),))
            if aggressive:
                m.register_forward_hook(lambda mod, args, out: fq(out))
    return q


_real_sdpa = F.scaled_dot_product_attention


AGGRESSIVE = False


def _int8_sdpa(q, k, v, *a, **kw):
    out = _real_sdpa(fq(q), fq(k), fq(v), *a, **kw)
    return fq(out) if AGGRESSIVE else out


def run(model, audio, device):
    with torch.inference_mode():
        y = model(audio.to(device))
    if device == "mps":
        torch.mps.synchronize()
    return y.detach().cpu().squeeze(0).numpy()


def snr(ref: np.ndarray, est: np.ndarray) -> float:
    return 10 * np.log10((ref**2).sum() / (((est - ref) ** 2).sum() + 1e-20))


def band_energy_db(x: np.ndarray, lo: float, hi: float) -> float:
    spec = np.abs(np.fft.rfft(x.mean(0))) ** 2
    f = np.fft.rfftfreq(x.shape[-1], 1 / SR)
    return 10 * np.log10(spec[(f >= lo) & (f < hi)].sum() + 1e-20)


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("input", type=Path)
    p.add_argument("--start", type=float, default=60.0)
    p.add_argument("--seconds", type=float, default=5.0)
    p.add_argument("--device", default="mps", choices=["mps", "cpu"])
    p.add_argument("--aggressive", action="store_true")
    p.add_argument("--out", type=Path, default=HERE / "out" / "int8")
    args = p.parse_args()

    audio = load(args.input)
    s = int(args.start * SR)
    audio = audio[..., s : s + int(args.seconds * SR)]
    print(f"{args.input.name}: {args.start:.0f}-{args.start + args.seconds:.0f} s on {args.device}")

    fp32 = look2hear.models.BaseModel.from_pretrain(
        str(HERE / "models" / "pytorch_model.bin"), sr=SR, win=20, feature_dim=256, layer=6
    ).eval()
    int8 = quantise(fp32, args.aggressive).eval()
    fp32, int8 = fp32.to(args.device), int8.to(args.device)

    global AGGRESSIVE
    AGGRESSIVE = args.aggressive
    ref = run(fp32, audio, args.device)
    F.scaled_dot_product_attention = _int8_sdpa
    apollo_mod.F.scaled_dot_product_attention = _int8_sdpa
    try:
        est = run(int8, audio, args.device)
    finally:
        F.scaled_dot_product_attention = _real_sdpa

    inp = audio.squeeze(0).numpy()
    print(f"INT8 output vs FP32 output : SNR {snr(ref, est):.1f} dB")
    print(f"FP32 output vs MP3 input   : SNR {snr(inp, ref):.1f} dB (for scale)")
    for lo, hi in [(0, 16000), (16000, 22050)]:
        print(f"  {lo // 1000}-{hi // 1000 if hi < 22050 else 22} kHz energy: FP32 {band_energy_db(ref, lo, hi):.1f} dB, INT8 {band_energy_db(est, lo, hi):.1f} dB")
    print(f"peak: FP32 {np.abs(ref).max():.3f}, INT8 {np.abs(est).max():.3f}")

    args.out.mkdir(parents=True, exist_ok=True)
    tag = "int8-aggr" if args.aggressive else "int8"
    for name, x in [("fp32", ref), (tag, est), ("input", inp)]:
        x = x / max(1.0, float(np.abs(x).max()))
        sf.write(args.out / f"{args.input.stem}.{args.start:.0f}s.{name}.flac", x.T, SR, subtype="PCM_16", format="FLAC")
    print(f"wrote FLACs to {args.out}")


if __name__ == "__main__":
    main()
