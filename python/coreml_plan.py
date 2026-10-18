"""Where would Core ML run each operator of the converted Apollo? (MLComputePlan)

    uv run python coreml_plan.py                 # CPU + Neural Engine
    uv run python coreml_plan.py --units gpu
"""
import argparse
import collections
import subprocess
import tempfile
from pathlib import Path

import coremltools as ct
from coremltools.models.compute_plan import MLComputePlan

HERE = Path(__file__).resolve().parent
UNITS = {"cpu": ct.ComputeUnit.CPU_ONLY, "gpu": ct.ComputeUnit.CPU_AND_GPU,
         "ane": ct.ComputeUnit.CPU_AND_NE, "all": ct.ComputeUnit.ALL}

p = argparse.ArgumentParser()
p.add_argument("--model", type=Path, default=HERE / "out/coreml/apollo_core_fp16_7s.mlpackage")
p.add_argument("--units", default="ane", choices=list(UNITS))
args = p.parse_args()

# MLComputePlan wants a compiled model (.mlmodelc), not the .mlpackage.
tmp = tempfile.mkdtemp(prefix="plan-")
model = args.model
if model.suffix == ".mlpackage":
    subprocess.run(["xcrun", "coremlcompiler", "compile", str(model), tmp], check=True,
                   capture_output=True)
    model = Path(tmp) / (model.stem + ".mlmodelc")
plan = MLComputePlan.load_from_path(path=str(model), compute_units=UNITS[args.units])
ops = plan.model_structure.program.functions["main"].block.operations
name = lambda d: type(d).__name__.replace("ML", "").replace("ComputeDevice", "")

preferred = collections.Counter()
by_type = collections.defaultdict(collections.Counter)
no_ane = collections.Counter()
cost = collections.Counter()
for op in ops:
    if op.operator_name.startswith("const"):
        continue
    usage = plan.get_compute_device_usage_for_mlprogram_operation(op)
    if usage is None:
        continue
    pref = name(usage.preferred_compute_device)
    preferred[pref] += 1
    by_type[op.operator_name][pref] += 1
    c = plan.get_estimated_cost_for_mlprogram_operation(op)
    cost[pref] += c.weight if c else 0
    if "NeuralEngine" not in {name(d) for d in usage.supported_compute_devices}:
        no_ane[op.operator_name] += 1

total = sum(preferred.values())
print(f"{total} operators, compute units = {args.units}")
print("preferred device:", dict(preferred))
w = sum(cost.values()) or 1
print("estimated cost share:", {k: f"{100 * v / w:.1f}%" for k, v in cost.items()})
print("\nper operator type:")
for t, c in sorted(by_type.items(), key=lambda kv: -sum(kv[1].values()))[:25]:
    print(f"  {t:30s} {dict(c)}")
print("\nnot supported on the Neural Engine at all:", dict(no_ane) or "(none)")
