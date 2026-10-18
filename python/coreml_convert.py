"""Convert the Apollo network (without STFT/iSTFT) to a Core ML ML Program.

Uses torch.export, which traces with fake tensors, so it does not have to run
the slow CPU forward pass that torch.jit.trace needed.

    uv run python coreml_convert.py --seconds 7 --precision fp16
"""
import argparse
import sys
import time
from pathlib import Path

import coremltools as ct
import numpy as np
import torch

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE / "vendor" / "Apollo"))
import look2hear.models  # noqa: E402

from apollo_split import ApolloCore  # noqa: E402

SR = 44100


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--seconds", type=float, default=7.0)
    p.add_argument("--precision", choices=["fp16", "fp32"], default="fp16")
    args = p.parse_args()

    model = look2hear.models.BaseModel.from_pretrain(
        str(HERE / "models" / "pytorch_model.bin"), sr=SR, win=20, feature_dim=256, layer=6
    ).eval()
    core = ApolloCore(model).eval()
    frames = int(args.seconds * SR) // model.stride + 1
    shape = (2, model.enc_dim, frames)
    print(f"input shape {shape}")
    re, im = torch.zeros(shape), torch.zeros(shape)

    t = time.perf_counter()
    with torch.inference_mode():
        ep = torch.export.export(core, (re, im), strict=False)
    ep = ep.run_decompositions({})
    print(f"torch.export: {time.perf_counter() - t:.1f} s, {len(ep.graph.nodes)} graph nodes")

    t = time.perf_counter()
    prec = ct.precision.FLOAT16 if args.precision == "fp16" else ct.precision.FLOAT32
    mlmodel = ct.convert(
        ep,
        inputs=[
            ct.TensorType("re", shape=shape, dtype=np.float32),
            ct.TensorType("im", shape=shape, dtype=np.float32),
        ],
        outputs=[ct.TensorType("est_re"), ct.TensorType("est_im")],
        convert_to="mlprogram",
        minimum_deployment_target=ct.target.macOS15,
        compute_precision=prec,
        compute_units=ct.ComputeUnit.CPU_AND_GPU,
    )
    print(f"ct.convert: {time.perf_counter() - t:.1f} s")
    out = HERE / "out" / "coreml"
    out.mkdir(parents=True, exist_ok=True)
    path = out / f"apollo_core_{args.precision}_{int(args.seconds)}s.mlpackage"
    mlmodel.save(str(path))
    size = sum(f.stat().st_size for f in path.rglob("*") if f.is_file())
    print(f"saved {path} ({size / 1e6:.1f} MB)")


if __name__ == "__main__":
    main()
