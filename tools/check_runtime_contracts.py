#!/usr/bin/env python3
"""Check stable runtime contracts that should not need heavier abstractions."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "mkit"
GAME = ROOT / "game"

ENTITY_ROOT_SCRIPT = "res://addons/mkit/kernel/entity/entity_root.gd"
ENTITY_IDENTITY_SCRIPT = "res://addons/mkit/kernel/entity/entity_identity.gd"
COMMAND_RECEIVER_SCRIPT = "res://addons/mkit/kernel/commands/command_receiver.gd"
STATE_MACHINE_SCRIPT = "res://addons/mkit/kernel/state_machine/hfsm.gd"
ENTITY_SAVE_AGENT_SCRIPT = "res://addons/mkit/kernel/save/entity_save_agent.gd"

REQUIRED_ENTITY_NODES = (
    "EntityIdentity",
    "StateMachine",
    "CommandReceiver",
    "Components",
    "Controllers",
    "Presentation",
)
EXPECTED_ENTITY_NODE_SCRIPTS = {
    "EntityIdentity": ENTITY_IDENTITY_SCRIPT,
    "StateMachine": STATE_MACHINE_SCRIPT,
    "CommandReceiver": COMMAND_RECEIVER_SCRIPT,
}

EXT_RESOURCE_RE = re.compile(
    r'^\[ext_resource\s+type="Script"\s+path="([^"]+)"\s+id="([^"]+)"\]'
)
NODE_RE = re.compile(r'^\[node\s+name="([^"]+)"\s+type="([^"]+)"(?:\s+parent="([^"]+)")?')
PROPERTY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_/]*)\s*=\s*(.+)$")
EXT_RESOURCE_REF_RE = re.compile(r'ExtResource\("([^"]+)"\)')
QUOTED_STRING_RE = re.compile(r'^"([^"]*)"$')
SERVICE_ID_RE = re.compile(r'^const\s+SERVICE_ID(?::\s*String)?\s*=\s*"([^"]+)"', re.MULTILINE)
SAVE_ID_RE = re.compile(r'\bsave_id\s*=\s*"([^"]+)"')
GET_SAVE_SCOPES_RE = re.compile(
    r"func\s+get_save_scopes\s*\([^)]*\)\s*->\s*Array\[String\]:"
    r"(?P<body>(?:\n(?:\t|    ).*)+)"
)
RETURN_ARRAY_RE = re.compile(r"return\s+\[([^\]]*)\]")
STRING_RE = re.compile(r'"([^"]+)"')


@dataclass
class TscnNode:
    name: str
    type_name: str
    path: str
    source_line: int
    properties: dict[str, str] = field(default_factory=dict)


@dataclass
class TscnScene:
    path: Path
    ext_resources: dict[str, str]
    nodes: dict[str, TscnNode]
    root_node: TscnNode | None


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def add_issue(issues: list[str], category: str, path: Path | None, message: str) -> None:
    prefix = f"[{category}]"
    if path is None:
        issues.append(f"{prefix} {message}")
    else:
        issues.append(f"{prefix} {rel(path)}: {message}")


def gd_files() -> list[Path]:
    return sorted((ADDON / "kernel").rglob("*.gd")) + sorted((ADDON / "modules").rglob("*.gd"))


def parse_tscn(path: Path) -> TscnScene:
    ext_resources: dict[str, str] = {}
    nodes: dict[str, TscnNode] = {}
    root_node: TscnNode | None = None
    current: TscnNode | None = None

    for line_no, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), start=1):
        line = raw.strip()
        if match := EXT_RESOURCE_RE.match(line):
            ext_resources[match.group(2)] = match.group(1)
            current = None
            continue
        if match := NODE_RE.match(line):
            name = match.group(1)
            type_name = match.group(2)
            parent = match.group(3)
            if parent is None:
                node_path = "."
            elif parent == ".":
                node_path = name
            else:
                node_path = f"{parent}/{name}"
            current = TscnNode(name, type_name, node_path, line_no)
            nodes[node_path] = current
            if parent is None:
                root_node = current
            continue
        if current is not None and (match := PROPERTY_RE.match(line)):
            current.properties[match.group(1)] = match.group(2).strip()

    return TscnScene(path, ext_resources, nodes, root_node)


def script_path(scene: TscnScene, node: TscnNode | None) -> str:
    if node is None:
        return ""
    raw = node.properties.get("script", "")
    match = EXT_RESOURCE_REF_RE.search(raw)
    if match is None:
        return ""
    return scene.ext_resources.get(match.group(1), "")


def string_property(node: TscnNode | None, name: str) -> str:
    if node is None:
        return ""
    raw = node.properties.get(name, "")
    match = QUOTED_STRING_RE.match(raw)
    return match.group(1) if match else ""


def check_service_ids(issues: list[str]) -> None:
    owners: dict[str, list[Path]] = {}
    for path in gd_files():
        text = path.read_text(encoding="utf-8")
        for match in SERVICE_ID_RE.finditer(text):
            service_id = match.group(1).strip()
            if service_id:
                owners.setdefault(service_id, []).append(path)

    for service_id, paths in sorted(owners.items()):
        if len(paths) > 1:
            locations = ", ".join(rel(path) for path in paths)
            add_issue(issues, "service-id", None, f'duplicate SERVICE_ID "{service_id}": {locations}')


def check_entity_scenes(issues: list[str]) -> None:
    for path in sorted(GAME.rglob("*.tscn")):
        scene = parse_tscn(path)
        if script_path(scene, scene.root_node) != ENTITY_ROOT_SCRIPT:
            continue

        for required in REQUIRED_ENTITY_NODES:
            if required not in scene.nodes:
                add_issue(issues, "entity-scene", path, f"missing EntityRoot child {required}")

        for node_path, expected_script in EXPECTED_ENTITY_NODE_SCRIPTS.items():
            actual = script_path(scene, scene.nodes.get(node_path))
            if actual and actual != expected_script:
                add_issue(
                    issues,
                    "entity-scene",
                    path,
                    f"{node_path} uses {actual}, expected {expected_script}",
                )

        identity = scene.nodes.get("EntityIdentity")
        entity_id = string_property(identity, "entity_id")
        receiver = scene.nodes.get("CommandReceiver")
        receiver_id = string_property(receiver, "receiver_id")
        if entity_id and receiver_id and entity_id != receiver_id:
            add_issue(
                issues,
                "entity-scene",
                path,
                f"CommandReceiver.receiver_id {receiver_id} does not match entity_id {entity_id}",
            )

        for node in scene.nodes.values():
            if script_path(scene, node) != ENTITY_SAVE_AGENT_SCRIPT:
                continue
            agent_id = string_property(node, "entity_id")
            if entity_id and agent_id and entity_id != agent_id:
                add_issue(
                    issues,
                    "entity-scene",
                    path,
                    f"{node.path}.entity_id {agent_id} does not match EntityIdentity {entity_id}",
                )
            scene_path = string_property(node, "scene_path")
            expected_scene_path = f"res://{rel(path)}"
            if scene_path and scene_path != expected_scene_path:
                add_issue(
                    issues,
                    "entity-scene",
                    path,
                    f"{node.path}.scene_path {scene_path} does not match {expected_scene_path}",
                )


def check_addon_save_contracts(issues: list[str]) -> None:
    save_ids: dict[str, list[Path]] = {}
    save_scopes: dict[str, list[Path]] = {}

    for path in gd_files():
        text = path.read_text(encoding="utf-8")
        for match in SAVE_ID_RE.finditer(text):
            save_id = match.group(1).strip()
            if save_id:
                save_ids.setdefault(save_id, []).append(path)

        for function_match in GET_SAVE_SCOPES_RE.finditer(text):
            body = function_match.group("body")
            return_match = RETURN_ARRAY_RE.search(body)
            if return_match is None:
                continue
            local_seen: set[str] = set()
            for scope in STRING_RE.findall(return_match.group(1)):
                normalized = scope.strip()
                if not normalized:
                    continue
                if normalized in local_seen:
                    add_issue(
                        issues,
                        "save-scope",
                        path,
                        f'duplicate scope "{normalized}" in get_save_scopes()',
                    )
                local_seen.add(normalized)
                save_scopes.setdefault(normalized, []).append(path)

    for save_id, paths in sorted(save_ids.items()):
        unique_paths = sorted(set(paths))
        if len(unique_paths) > 1:
            locations = ", ".join(rel(path) for path in unique_paths)
            add_issue(issues, "save-id", None, f'duplicate addon default save_id "{save_id}": {locations}')

    for scope, paths in sorted(save_scopes.items()):
        unique_paths = sorted(set(paths))
        if len(unique_paths) > 1:
            locations = ", ".join(rel(path) for path in unique_paths)
            add_issue(issues, "save-scope", None, f'duplicate addon save scope "{scope}": {locations}')


def check_game_scene_save_ids(issues: list[str]) -> None:
    owners: dict[str, list[str]] = {}
    for path in sorted(GAME.rglob("*.tscn")):
        scene = parse_tscn(path)
        for node in scene.nodes.values():
            save_id = string_property(node, "save_id")
            if save_id:
                owners.setdefault(save_id, []).append(f"{rel(path)}:{node.source_line}")

    for save_id, locations in sorted(owners.items()):
        if len(locations) > 1:
            add_issue(
                issues,
                "save-id",
                None,
                f'duplicate explicit game scene save_id "{save_id}": {", ".join(locations)}',
            )


def main() -> int:
    issues: list[str] = []

    check_service_ids(issues)
    check_entity_scenes(issues)
    check_addon_save_contracts(issues)
    check_game_scene_save_ids(issues)

    if issues:
        print("runtime-contracts failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print("runtime-contracts passed: service ids, entity scenes, and save ids/scopes are stable.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
