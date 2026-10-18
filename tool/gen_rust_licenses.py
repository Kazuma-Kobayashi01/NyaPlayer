#!/usr/bin/env python3
"""Collects the licence texts of the Rust crates linked into libnya_core.

Reads the dependency tree of rust/ for every shipped target (Android, macOS
arm64 and x86_64), finds each crate's LICENSE/COPYING/NOTICE files in the
local cargo registry (run `cargo fetch` first) and writes
assets/licenses/rust_crates.txt. Crates with identical texts share one entry.

Crates that ship no licence file get the standard text for their SPDX
expression from tool/license_templates (MIT for any "... OR MIT", MPL-2.0
for the symphonia family), with the authors from their Cargo.toml.

Format: entries separated by a line `=====`; the first line of an entry is the
comma-separated crate list, then a blank line, then the licence text.

Usage: python3 tool/gen_rust_licenses.py
"""
import glob
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGETS = ["aarch64-linux-android", "aarch64-apple-darwin", "x86_64-apple-darwin"]
LICENSE_FILE = re.compile(r"^(LICEN[CS]E|COPYING|UNLICENSE|NOTICE)", re.I)


def crates():
    found = {}
    for target in TARGETS:
        out = subprocess.run(
            ["cargo", "tree", "-e", "normal", "--target", target,
             "--prefix", "none", "--format", "{p}|{l}"],
            cwd=os.path.join(ROOT, "rust"), check=True,
            capture_output=True, text=True,
        ).stdout
        for line in out.splitlines():
            pkg, _, spdx = line.partition("|")
            match = re.match(r"(\S+) v(\S+)", pkg)
            # Skip this crate and compile-time-only proc macros.
            if not match or "nya_core" in pkg or "(proc-macro)" in pkg:
                continue
            found[(match.group(1), match.group(2))] = spdx.strip()
    return found


def sources(name, version):
    pattern = os.path.expanduser(f"~/.cargo/registry/src/*/{name}-{version}")
    hits = glob.glob(pattern)
    return hits[0] if hits else None


def authors(src):
    """The `authors = [...]` of a crate's Cargo.toml, as one string."""
    try:
        toml = open(os.path.join(src, "Cargo.toml"), encoding="utf-8").read()
    except OSError:
        return "the authors"
    match = re.search(r"^authors\s*=\s*\[(.*?)\]", toml, re.S | re.M)
    names = re.findall(r'"([^"]+)"', match.group(1)) if match else []
    return ", ".join(names) or "the authors"


def template(name):
    with open(os.path.join(ROOT, "tool", "license_templates", name),
              encoding="utf-8") as f:
        return f.read().strip()


def fallback_text(spdx, src):
    """Standard text for a crate without its own licence file, or None."""
    if "MIT" in spdx:
        return template("MIT.txt").replace("{authors}", authors(src))
    if "MPL-2.0" in spdx:
        return template("MPL-2.0.txt")
    return None


def main():
    groups = {}  # text -> [crate names]
    missing = []
    for (name, version), spdx in sorted(crates().items()):
        src = sources(name, version)
        files = sorted(
            f for f in (os.listdir(src) if src else [])
            if LICENSE_FILE.match(f) and os.path.isfile(os.path.join(src, f))
        )
        # Dual-licensed crates: the MIT text is enough, skip the long Apache one.
        if any("MIT" in f.upper() for f in files):
            files = [f for f in files if "APACHE" not in f.upper()]
        if not files:
            text = fallback_text(spdx, src) if src else None
            if text is None:
                missing.append(f"{name} {version} ({spdx})")
                text = f"License: {spdx or 'see the crate'}"
            groups.setdefault(text, []).append(f"{name} {version}")
            continue
        text = "\n\n".join(
            open(os.path.join(src, f), encoding="utf-8", errors="replace").read().strip()
            for f in files
        )
        groups.setdefault(text, []).append(f"{name} {version}")

    out = os.path.join(ROOT, "assets", "licenses", "rust_crates.txt")
    with open(out, "w", encoding="utf-8") as f:
        entries = [f"{', '.join(names)}\n\n{text}" for text, names in sorted(
            groups.items(), key=lambda kv: kv[1][0])]
        f.write("\n=====\n".join(entries) + "\n")
    print(f"{sum(len(v) for v in groups.values())} crates, "
          f"{len(groups)} entries -> {out}")
    if missing:
        print("no licence file found (SPDX id only):", *missing, sep="\n  ")


if __name__ == "__main__":
    sys.exit(main())
