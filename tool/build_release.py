#!/usr/bin/env python3
"""Build current Release apps into output/<system>-<architecture>/.

Usage: python3 tool/build_release.py [darwin-arm64 darwin-x86_64 android-armv8a]
With no arguments, build all three targets. macOS targets require a macOS host.
"""

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parent.parent
OUTPUT = ROOT / "output"
MAC_APP = ROOT / "build/macos/Build/Products/Release/NyaPlayer.app"
TARGETS = ("darwin-arm64", "darwin-x86_64", "android-armv8a")
MACH_MAGICS = {
    b"\xfe\xed\xfa\xce", b"\xce\xfa\xed\xfe",
    b"\xfe\xed\xfa\xcf", b"\xcf\xfa\xed\xfe",
    b"\xca\xfe\xba\xbe", b"\xbe\xba\xfe\xca",
    b"\xca\xfe\xba\xbf", b"\xbf\xba\xfe\xca",
}


def run(*args, env=None):
    subprocess.run(args, cwd=ROOT, env=env, check=True)


def architectures(path):
    return subprocess.check_output(
        ["lipo", "-archs", str(path)], text=True
    ).split()


def single_arch_app(app, arch):
    """Remove unused slices in bundled prebuilt frameworks as well as the app."""
    binaries = []
    for path in app.rglob("*"):
        if path.is_symlink() or not path.is_file():
            continue
        with path.open("rb") as stream:
            if stream.read(4) in MACH_MAGICS:
                binaries.append(path)
    if not binaries:
        raise RuntimeError(f"No Mach-O binaries found in {app}")
    for binary in binaries:
        archs = architectures(binary)
        if arch not in archs:
            raise RuntimeError(f"{binary} has {archs}, missing required {arch}")
        if archs != [arch]:
            mode = binary.stat().st_mode
            thin = binary.with_name(binary.name + ".thin")
            run("lipo", str(binary), "-thin", arch, "-output", str(thin))
            thin.chmod(mode)
            thin.replace(binary)
    # Thinning invalidates signatures. Retain each existing code object's
    # identity, entitlements and signing flags, then rebuild bundle seals.
    for binary in sorted(binaries, key=lambda p: len(p.parts), reverse=True):
        run("codesign", "--force", "--sign", "-",
            "--preserve-metadata=identifier,entitlements,flags,runtime",
            "--generate-entitlement-der", str(binary))
    bundles = [p for p in app.rglob("*") if p.is_dir() and not p.is_symlink()
               and p.suffix in (".framework", ".appex", ".app", ".xpc")]
    for bundle in sorted(bundles, key=lambda p: len(p.parts), reverse=True) + [app]:
        run("codesign", "--force", "--sign", "-",
            "--preserve-metadata=identifier,entitlements,flags,runtime",
            "--generate-entitlement-der", str(bundle))
    run("codesign", "--verify", "--deep", "--strict", str(app))
    for binary in binaries:
        if architectures(binary) != [arch]:
            raise RuntimeError(f"Unexpected architectures left in {binary}")
    print(f"{arch}: {len(binaries)} Mach-O files contain only this architecture", flush=True)


def build(target):
    print(f"\nBuilding {target}", flush=True)
    if target.startswith("darwin-"):
        arch = target.removeprefix("darwin-")
        # Remove the previous architecture's assembled bundle before building.
        if MAC_APP.exists():
            shutil.rmtree(MAC_APP)
        env = os.environ.copy()
        env.update(FLUTTER_XCODE_ARCHS=arch, FLUTTER_XCODE_ONLY_ACTIVE_ARCH="NO")
        run("flutter", "build", "macos", "--release", env=env)
    else:
        run("flutter", "build", "apk", "--release", "--target-platform", "android-arm64")

    OUTPUT.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=f".{target}-", dir=OUTPUT) as temporary:
        staged = Path(temporary)
        if target.startswith("darwin-"):
            app = staged / "NyaPlayer.app"
            run("ditto", str(MAC_APP), str(app))
            single_arch_app(app, arch)
        else:
            apk = ROOT / "build/app/outputs/flutter-apk/app-release.apk"
            with zipfile.ZipFile(apk) as archive:
                abis = {name.split("/")[1] for name in archive.namelist()
                        if name.startswith("lib/") and name.endswith(".so")}
            if abis != {"arm64-v8a"}:
                raise RuntimeError(f"Unexpected Android ABIs: {abis}")
            shutil.copy2(apk, staged / "NyaPlayer.apk")
        version = next(line.split(":", 1)[1].strip()
                       for line in (ROOT / "pubspec.yaml").read_text().splitlines()
                       if line.startswith("version:"))
        revision = subprocess.check_output(
            ["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip()
        (staged / "build-info.json").write_text(json.dumps({
            "target": target, "mode": "release", "version": version,
            "git_commit": revision,
        }, indent=2) + "\n")
        destination = OUTPUT / target
        if destination.exists():
            shutil.rmtree(destination)
        staged.rename(destination)
    print(f"Ready: {destination}", flush=True)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("targets", nargs="*", metavar="TARGET",
                        help="one or more of: " + ", ".join(TARGETS))
    arguments = parser.parse_args()
    for target in arguments.targets:
        if target not in TARGETS:
            parser.error(f"unknown target: {target}")
    for target in dict.fromkeys(arguments.targets or TARGETS):
        build(target)
