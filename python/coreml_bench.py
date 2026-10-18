"""Check the converted Core ML Apollo against PyTorch and time it per device.

    uv run python coreml_bench.py --units gpu
    uv run python coreml_bench.py --units gpu ane all
"""
import argparse
import sys
import time
from pathlib import Path

import coremltools as ct
import numpy as np
import soundfile as sf
import torch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))
import look2hear.models  # noqa: E402

from apollo_split import ApolloCore  # noqa: E402
from sr_mp3 import SR, load  # noqa: E402

UNITS = {
    "cpu": ct.ComputeUnit.CPU_ONLY,
    "gpu": ct.ComputeUnit.CPU_AND_GPU,
    "ane": ct.ComputeUnit.CPU_AND_NE,
    "all": ct.ComputeUnit.ALL,
}


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--model", type=Path, default=HERE / "out" / "coreml" / "apollo_core_fp16_7s.mlpackage")
    p.add_argument("--units", nargs="+", default=["gpu"], choices=list(UNITS))
    p.add_argument("--input", type=Path, default=HERE / "缭花绚烂.mp3")
    p.add_argument("--start", type=float, default=60.0)
    p.add_argument("--runs", type=int, default=3)
    args = p.parse_args()

    net = look2hear.models.BaseModel.from_pretrain(
        str(HERE / "models" / "pytorch_model.bin"), sr=SR, win=20, feature_dim=256, layer=6
    ).eval().to("mps")
    core = ApolloCore(net).eval()
    spec = ct.models.MLModel(str(args.model), compute_units=ct.ComputeUnit.CPU_ONLY).get_spec()
    frames = spec.description.input[0].type.multiArrayType.shape[2]
    seconds = (frames - 1) * 441 / SR  # the window the model was converted for
    n = (frames - 1) * 441
    audio = load(args.input).squeeze(0)[:, int(args.start * SR) : int(args.start * SR) + n]
    window = torch.hann_window(net.win)
    spec = torch.stft(audio, n_fft=net.win, hop_length=net.stride, window=window, return_complex=True)
    re, im = spec.real.contiguous(), spec.imag.contiguous()
    with torch.inference_mode():
        ref_re, ref_im = (t.cpu().numpy() for t in core.to("mps")(re.to("mps"), im.to("mps")))
    ref = np.stack([ref_re, ref_im])
    feed = {"re": re.numpy(), "im": im.numpy()}

    for name in args.units:
        t = time.perf_counter()
        model = ct.models.MLModel(str(args.model), compute_units=UNITS[name])
        out = model.predict(feed)  # first call also compiles
        first = time.perf_counter() - t
        times = []
        for _ in range(args.runs):
            t = time.perf_counter()
            out = model.predict(feed)
            times.append(time.perf_counter() - t)
        est = np.stack([out["est_re"], out["est_im"]])
        err = est - ref
        snr = 10 * np.log10((ref**2).sum() / ((err**2).sum() + 1e-20))
        best = min(times)
        print(f"{name:4s}: load+first {first:5.1f} s, then {best * 1000:7.0f} ms per {seconds:.0f} s window "
              f"(x{seconds / best:.2f} realtime, network only), vs PyTorch FP32: {snr:.1f} dB, outputs {list(out)}")


if __name__ == "__main__":
    main()
