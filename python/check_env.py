"""Sanity check of the Python environment: PyTorch build, MPS (Apple GPU) and a
small matrix multiply on each device."""
import time

import torch
import torchaudio

print(f"torch {torch.__version__}, torchaudio {torchaudio.__version__}")
print("MPS built:", torch.backends.mps.is_built())
print("MPS available:", torch.backends.mps.is_available())

for name in ["cpu", "mps"]:
    if name == "mps" and not torch.backends.mps.is_available():
        continue
    x = torch.randn(2048, 2048, device=name)
    torch.matmul(x, x)  # warm-up
    if name == "mps":
        torch.mps.synchronize()
    start = time.perf_counter()
    for _ in range(10):
        y = torch.matmul(x, x)
    if name == "mps":
        torch.mps.synchronize()
    ms = (time.perf_counter() - start) * 100
    print(f"{name}: 2048x2048 matmul {ms:.1f} ms, device={y.device}")
