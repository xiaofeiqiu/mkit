#!/usr/bin/env python3
"""Enforce mkit layering: kernel must never reference module classes or paths.

Rules (dependencies point downward only: game -> modules -> kernel):
  1. addons/mkit/kernel/**.gd must not reference any class_name declared under
     addons/mkit/modules/, nor any res://addons/mkit/modules/ path.
  2. addons/mkit/**.gd (kernel + modules) must not reference res://game/ paths.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
KERNEL = ROOT / "addons" / "mkit" / "kernel"
MODULES = ROOT / "addons" / "mkit" / "modules"

CLASS_NAME_RE = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b", re.MULTILINE)


def strip_comments_and_strings(line: str) -> str:
    """Drop string literals and trailing comments so matches hit real code."""
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    line = re.sub(r"'(?:[^'\\]|\\.)*'", "''", line)
    return line.split("#", 1)[0]


def module_class_names() -> set[str]:
    names: set[str] = set()
    for gd in MODULES.rglob("*.gd"):
        match = CLASS_NAME_RE.search(gd.read_text(encoding="utf-8"))
        if match:
            names.add(match.group(1))
    return names


def main() -> int:
    violations: list[str] = []
    module_classes = module_class_names()
    if not module_classes:
        print("check_layering: no module classes found; aborting", file=sys.stderr)
        return 2
    class_re = re.compile(r"\b(" + "|".join(sorted(module_classes)) + r")\b")

    for gd in sorted(KERNEL.rglob("*.gd")):
        rel = gd.relative_to(ROOT).as_posix()
        for line_no, raw in enumerate(gd.read_text(encoding="utf-8").splitlines(), 1):
            if "res://addons/mkit/modules/" in raw:
                violations.append(f"{rel}:{line_no}: kernel references modules path")
            code = strip_comments_and_strings(raw)
            match = class_re.search(code)
            if match:
                violations.append(
                    f"{rel}:{line_no}: kernel references module class {match.group(1)}"
                )

    for layer in (KERNEL, MODULES):
        for gd in sorted(layer.rglob("*.gd")):
            rel = gd.relative_to(ROOT).as_posix()
            for line_no, raw in enumerate(gd.read_text(encoding="utf-8").splitlines(), 1):
                if "res://game/" in raw:
                    violations.append(f"{rel}:{line_no}: addon references game path")

    if violations:
        print("Layering violations (kernel must not depend on modules, addon must not depend on game):")
        for v in violations:
            print(f"  {v}")
        return 1
    print("check_layering: OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
