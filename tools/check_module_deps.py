#!/usr/bin/env python3
"""Validate module dependency manifests under addons/mkit/modules/.

Each module directory must contain a module.cfg (Godot ConfigFile syntax):

    [module]
    id="shop"
    deps=["inventory", "progression"]
    services=["shop"]
    events="ShopEvents"

Rules:
  1. Every module directory has a module.cfg whose id matches the directory name.
  2. Declared deps reference existing modules and contain no self-dependency.
  3. Actual cross-module references (class_name usage and res:// module paths in
     .gd / .tscn / .tres files) exactly match declared deps - no undeclared
     references, no unused declarations.
  4. The declared dependency graph is acyclic; the topological order is printed.
  5. Declared services exist as SERVICE_* ids in ServiceRegistry; the declared
     events catalog class is defined inside the module.

Root-level files in modules/ (the Mkit facade and ModuleBootstrap composition
root) intentionally reference all modules and are exempt from rule 3.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULES = ROOT / "addons" / "mkit" / "modules"
SERVICE_REGISTRY = ROOT / "addons" / "mkit" / "kernel" / "services" / "service_registry.gd"

CLASS_NAME_RE = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b", re.MULTILINE)
CFG_ENTRY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.+)$")
SERVICE_ID_RE = re.compile(r'^const SERVICE_\w+:\s*String\s*=\s*"([a-z_]+)"', re.MULTILINE)


def strip_comments_and_strings(line: str) -> str:
    line = re.sub(r'"(?:[^"\\]|\\.)*"', '""', line)
    line = re.sub(r"'(?:[^'\\]|\\.)*'", "''", line)
    return line.split("#", 1)[0]


def parse_manifest(path: Path) -> dict | None:
    data: dict = {}
    section = ""
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.strip()
        if not line or line.startswith(";") or line.startswith("#"):
            continue
        if line.startswith("[") and line.endswith("]"):
            section = line[1:-1].strip()
            continue
        match = CFG_ENTRY_RE.match(line)
        if match is None or section != "module":
            continue
        try:
            data[match.group(1)] = json.loads(match.group(2))
        except json.JSONDecodeError:
            return None
    return data


def module_dirs() -> list[Path]:
    return sorted(p for p in MODULES.iterdir() if p.is_dir())


def class_owners() -> dict[str, str]:
    owners: dict[str, str] = {}
    for mod_dir in module_dirs():
        for gd in mod_dir.rglob("*.gd"):
            match = CLASS_NAME_RE.search(gd.read_text(encoding="utf-8"))
            if match:
                owners[match.group(1)] = mod_dir.name
    return owners


def actual_deps(mod_dir: Path, owners: dict[str, str], class_re: re.Pattern) -> dict[str, set[str]]:
    refs: dict[str, set[str]] = {}
    path_re = re.compile(r"res://addons/mkit/modules/([a-z_]+)/")
    for ext in ("*.gd", "*.tscn", "*.tres"):
        for source in mod_dir.rglob(ext):
            for raw in source.read_text(encoding="utf-8").splitlines():
                for path_match in path_re.finditer(raw):
                    target = path_match.group(1)
                    if target != mod_dir.name and (MODULES / target).is_dir():
                        refs.setdefault(target, set()).add(path_match.group(0))
                if source.suffix != ".gd":
                    continue
                code = strip_comments_and_strings(raw)
                for class_match in class_re.finditer(code):
                    target = owners[class_match.group(1)]
                    if target != mod_dir.name:
                        refs.setdefault(target, set()).add(class_match.group(1))
    return refs


def topological_order(deps: dict[str, list[str]]) -> list[str] | None:
    remaining = {mod: set(d for d in dep_list if d in deps) for mod, dep_list in deps.items()}
    order: list[str] = []
    while remaining:
        ready = sorted(mod for mod, dep_set in remaining.items() if not dep_set)
        if not ready:
            return None
        for mod in ready:
            order.append(mod)
            del remaining[mod]
        for dep_set in remaining.values():
            dep_set.difference_update(ready)
    return order


def main() -> int:
    violations: list[str] = []
    owners = class_owners()
    if not owners:
        print("check_module_deps: no module classes found; aborting", file=sys.stderr)
        return 2
    class_re = re.compile(r"\b(" + "|".join(sorted(owners)) + r")\b")
    service_ids = set(SERVICE_ID_RE.findall(SERVICE_REGISTRY.read_text(encoding="utf-8")))

    declared: dict[str, list[str]] = {}
    for mod_dir in module_dirs():
        mod = mod_dir.name
        rel = mod_dir.relative_to(ROOT).as_posix()
        manifest_path = mod_dir / "module.cfg"
        if not manifest_path.is_file():
            violations.append(f"{rel}: missing module.cfg")
            continue
        manifest = parse_manifest(manifest_path)
        if manifest is None or "id" not in manifest or "deps" not in manifest:
            violations.append(f"{rel}/module.cfg: unparsable or missing id/deps")
            continue
        if manifest["id"] != mod:
            violations.append(f"{rel}/module.cfg: id {manifest['id']!r} != directory name {mod!r}")
        deps = manifest["deps"]
        declared[mod] = deps
        for dep in deps:
            if dep == mod:
                violations.append(f"{rel}/module.cfg: self-dependency")
            elif not (MODULES / dep).is_dir():
                violations.append(f"{rel}/module.cfg: unknown dep {dep!r}")
        for service_id in manifest.get("services", []):
            if service_id not in service_ids:
                violations.append(f"{rel}/module.cfg: service {service_id!r} has no ServiceRegistry SERVICE_* id")
        events = manifest.get("events", "")
        if events and owners.get(events) != mod:
            violations.append(f"{rel}/module.cfg: events class {events!r} is not defined in this module")

        refs = actual_deps(mod_dir, owners, class_re)
        for target in sorted(set(refs) - set(deps)):
            symbols = ", ".join(sorted(refs[target]))
            violations.append(f"{rel}: references module {target!r} ({symbols}) but module.cfg does not declare it")
        for target in sorted(set(deps) - set(refs)):
            violations.append(f"{rel}/module.cfg: declares dep {target!r} but no reference found")

    order = topological_order(declared) if declared else []
    if order is None:
        violations.append("dependency cycle in declared module deps")
        order = []

    if violations:
        print("Module dependency violations (declared deps in module.cfg must match actual references):")
        for v in violations:
            print(f"  {v}")
        return 1
    print("check_module_deps: OK")
    print("module load order: " + " -> ".join(order))
    return 0


if __name__ == "__main__":
    sys.exit(main())
