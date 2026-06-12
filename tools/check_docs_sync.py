#!/usr/bin/env python3
"""Check docs links, navigation, cookbook ownership, and stale demo paths."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "mkit"
DOCS = ROOT / "docs"
INDEX = DOCS / "index.html"
EVENT_PAYLOADS = DOCS / "event_payloads.md"
DIRECT_HREF_RE = re.compile(r"href:\s*['\"]([^'\"]+\.md)['\"]")
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
HTML_HREF_RE = re.compile(r"<a\b[^>]*\bhref=['\"]([^'\"]+)['\"]", re.IGNORECASE)
RECIPE_OWNERSHIP_RE = re.compile(r"^##\s+你负责 / mkit 负责\s*$", re.MULTILINE)
DEMO_PATH_RE = re.compile(r"(?:res://)?game/demo/")
EVENT_CONST_RE = re.compile(r'^const\s+[A-Z][A-Z0-9_]*\s*(?::\s*String)?\s*:?=\s*"([^"]+)"', re.MULTILINE)

SYNTHETIC_PUBLIC_EVENTS = {
    "item_acquired",
    "zone_entered",
}
EVENT_PAYLOAD_KEYS = {
    "damage_applied": (
        "base_amount",
        "final_amount",
        "damage_type",
        "element_type",
        "critical",
        "evaded",
        "blocked",
        "lethal",
        "applied_status_effects",
        "trace",
        "result",
    ),
    "entity_died": (
        "entity_id",
        "entity_ref",
        "killer_id",
        "killer_ref",
        "tags",
        "faction",
        "definition_id",
        "killer_tags",
        "killer_faction",
        "killer_definition_id",
    ),
    "dialogue_started": ("dialogue_id",),
    "dialogue_ended": ("dialogue_id",),
    "npc_talked": ("npc_id",),
    "inventory_changed": ("owner_id", "item_id", "quantity", "change_type"),
    "reward_selected": ("reward_id",),
    "loot_dropped": ("drop",),
    "quest_accepted": ("quest_id",),
    "quest_objective_advanced": ("quest_id", "objective_id", "current", "required"),
    "quest_completed": ("quest_id",),
    "quest_turned_in": ("quest_id",),
    "enemy_killed": ("entity_id", "tags", "faction", "definition_id"),
    "item_acquired": ("owner_id", "item_id", "quantity", "change_type", "amount"),
    "item_purchased": ("shop_id", "item_id", "quantity"),
    "item_sold": ("shop_id", "item_id", "quantity"),
    "room_cleared": (),
    "zone_changed": ("from_zone_id", "to_zone_id"),
    "zone_entered": ("zone_id",),
    "run_started": ("seed",),
    "run_finished": ("result",),
}
SHORT_PATH_NAV_HREFS = {
    "readme.md",
    "concepts.md",
    "pipeline.md",
    "cookbook/index.md",
}
SHORT_PATH_MARKERS = {
    DOCS / "concepts.md": ("Minimal path", "Standard path", "Advanced path"),
    DOCS / "cookbook" / "index.md": ("Minimal path", "Standard path", "Advanced path"),
    DOCS / "pipeline.md": ("Minimal path", "Standard path", "Advanced path"),
    DOCS / "readme.md": ("标准管线与短路径", "CommandService.dispatch()", "GameAction"),
}


def rel(path: Path) -> str:
    try:
        return path.relative_to(ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def add_issue(issues: list[str], category: str, path: Path | None, message: str) -> None:
    prefix = f"[{category}]"
    if path is not None:
        issues.append(f"{prefix} {rel(path)}: {message}")
    else:
        issues.append(f"{prefix} {message}")


def read_text(path: Path, issues: list[str], category: str) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        add_issue(issues, category, path, f"cannot read file: {exc}")
        return ""


def markdown_files() -> list[Path]:
    return sorted(DOCS.rglob("*.md"))


def strip_fenced_code(text: str) -> list[str]:
    lines: list[str] = []
    in_fence = False
    fence = ""

    for line in text.splitlines():
        stripped = line.lstrip()
        marker = stripped[:3]
        if marker in ("```", "~~~"):
            if not in_fence:
                in_fence = True
                fence = marker
            elif marker == fence:
                in_fence = False
                fence = ""
            lines.append("")
        elif in_fence:
            lines.append("")
        else:
            lines.append(line)

    return lines


def clean_markdown_target(raw: str) -> str:
    target = raw.strip()
    if target.startswith("<"):
        end = target.find(">")
        if end != -1:
            return target[1:end].strip()
    match = re.match(r"\S+", target)
    return match.group(0).strip() if match else ""


def is_external_target(target: str) -> bool:
    parsed = urlparse(target)
    if parsed.scheme in {"http", "https", "mailto", "tel", "res", "user", "app"}:
        return True
    return bool(parsed.netloc)


def check_links(issues: list[str]) -> None:
    if not DOCS.exists():
        add_issue(issues, "link", DOCS, "docs directory is missing")
        return

    docs_root = DOCS.resolve()
    for source in markdown_files():
        text = read_text(source, issues, "link")
        if not text:
            continue
        for line_no, line in enumerate(strip_fenced_code(text), start=1):
            targets = [m.group(1) for m in MARKDOWN_LINK_RE.finditer(line)]
            targets.extend(m.group(1) for m in HTML_HREF_RE.finditer(line))

            for raw in targets:
                target = clean_markdown_target(raw)
                if not target or target.startswith("#") or is_external_target(target):
                    continue

                parsed = urlparse(target)
                path_part = unquote(parsed.path)
                if not path_part:
                    continue

                target_path = (source.parent / path_part).resolve()
                try:
                    target_path.relative_to(docs_root)
                except ValueError:
                    add_issue(
                        issues,
                        "link",
                        source,
                        f"line {line_no}: link leaves docs directory: {target}",
                    )
                    continue

                if not target_path.exists():
                    add_issue(
                        issues,
                        "link",
                        source,
                        f"line {line_no}: missing target {target}",
                    )


def extract_nav_hrefs(issues: list[str]) -> set[str]:
    text = read_text(INDEX, issues, "nav")
    if not text:
        return set()

    hrefs: list[str] = DIRECT_HREF_RE.findall(text)

    seen: set[str] = set()
    duplicates: set[str] = set()
    for href in hrefs:
        if href in seen:
            duplicates.add(href)
        seen.add(href)

    for href in sorted(duplicates):
        add_issue(issues, "nav", INDEX, f"duplicate NAV href {href}")

    return set(hrefs)


def check_nav_sync(issues: list[str], nav_hrefs: set[str]) -> None:
    if not nav_hrefs:
        return

    docs_files = {path.relative_to(DOCS).as_posix() for path in markdown_files()}

    for href in sorted(nav_hrefs):
        if not (DOCS / href).exists():
            add_issue(issues, "nav", INDEX, f"NAV href points to missing file: {href}")

    for path in sorted(docs_files - nav_hrefs):
        add_issue(issues, "nav", DOCS / path, "markdown file is not listed in NAV")


def collect_public_event_types(issues: list[str]) -> set[str]:
    event_types: set[str] = set(SYNTHETIC_PUBLIC_EVENTS)
    event_root = ADDON / "modules"
    for path in sorted(event_root.rglob("*_events.gd")):
        text = read_text(path, issues, "event")
        if not text:
            continue
        event_types.update(match.group(1) for match in EVENT_CONST_RE.finditer(text))
    return event_types


def find_event_payload_row(text: str, event_type: str) -> str:
    needle = f"`{event_type}`"
    for line in text.splitlines():
        if line.startswith("|") and needle in line:
            return line
    return ""


def check_event_payload_reference(issues: list[str]) -> None:
    text = read_text(EVENT_PAYLOADS, issues, "event")
    if not text:
        return

    public_events = collect_public_event_types(issues)
    for event_type in sorted(public_events):
        if event_type not in EVENT_PAYLOAD_KEYS:
            add_issue(
                issues,
                "event",
                EVENT_PAYLOADS,
                f"missing checker payload key spec for public event {event_type}",
            )
            continue

        row = find_event_payload_row(text, event_type)
        if not row:
            add_issue(
                issues,
                "event",
                EVENT_PAYLOADS,
                f"missing public event payload row for {event_type}",
            )
            continue

        keys = EVENT_PAYLOAD_KEYS[event_type]
        if not keys:
            if "none" not in row:
                add_issue(
                    issues,
                    "event",
                    EVENT_PAYLOADS,
                    f"{event_type} row must mark payload keys as none",
                )
            continue

        for key in keys:
            if f"`{key}`" not in row:
                add_issue(
                    issues,
                    "event",
                    EVENT_PAYLOADS,
                    f"{event_type} row is missing payload key {key}",
                )


def check_short_path_navigation(issues: list[str], nav_hrefs: set[str]) -> None:
    for href in sorted(SHORT_PATH_NAV_HREFS - nav_hrefs):
        add_issue(issues, "path-nav", INDEX, f"NAV must expose short/advanced path doc: {href}")

    for path, markers in SHORT_PATH_MARKERS.items():
        text = read_text(path, issues, "path-nav")
        if not text:
            continue
        for marker in markers:
            if marker not in text:
                add_issue(
                    issues,
                    "path-nav",
                    path,
                    f"missing short/advanced path marker: {marker}",
                )


def check_recipe_ownership_sections(issues: list[str]) -> None:
    cookbook = DOCS / "cookbook"
    for recipe in sorted(cookbook.glob("[0-9][0-9]_*.md")):
        text = read_text(recipe, issues, "recipe")
        if text and RECIPE_OWNERSHIP_RE.search(text) is None:
            add_issue(
                issues,
                "recipe",
                recipe,
                'missing required heading "## 你负责 / mkit 负责"',
            )


def check_no_demo_paths(issues: list[str]) -> None:
    for path in markdown_files():
        text = read_text(path, issues, "scope")
        if DEMO_PATH_RE.search(text):
            add_issue(issues, "scope", path, "user-facing docs must not expose game/demo paths")


def main() -> int:
    issues: list[str] = []
    nav_hrefs = extract_nav_hrefs(issues)

    check_links(issues)
    check_nav_sync(issues, nav_hrefs)
    check_short_path_navigation(issues, nav_hrefs)
    check_event_payload_reference(issues)
    check_recipe_ownership_sections(issues)
    check_no_demo_paths(issues)

    if issues:
        print("docs-check failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print(
        "docs-check passed: links, NAV sync, and recipe ownership sections are "
        "in sync; event payload docs and path navigation are covered; no game/demo "
        "paths are exposed."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
