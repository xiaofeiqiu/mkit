#!/usr/bin/env python3
"""Check docs drift against source files and docs/index.html navigation."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
INDEX = DOCS / "index.html"
ADDON = ROOT / "addons" / "mkit"

CLASS_NAME_RE = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b", re.MULTILINE)
DIRECT_HREF_RE = re.compile(r"href:\s*['\"]([^'\"]+\.md)['\"]")
QUOTED_STRING_RE = re.compile(r"['\"]([^'\"]+)['\"]")
MARKDOWN_LINK_RE = re.compile(r"!?\[[^\]\n]*\]\(([^)\n]+)\)")
HTML_HREF_RE = re.compile(r"<a\b[^>]*\bhref=['\"]([^'\"]+)['\"]", re.IGNORECASE)
RECIPE_OWNERSHIP_RE = re.compile(r"^##\s+你负责 / mkit 负责\s*$", re.MULTILINE)
DEMO_PATH_RE = re.compile(r"(?:res://)?game/demo/")


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

    direct_hrefs = DIRECT_HREF_RE.findall(text)
    hrefs: list[str] = list(direct_hrefs)

    for layer in ("kernel", "modules"):
        prefix = f"ref/{layer}"
        marker = f"href: `{prefix}/${{c}}.md`"
        marker_index = text.find(marker)
        if marker_index == -1:
            add_issue(issues, "nav", INDEX, f"missing computed NAV map for {prefix}")
            continue

        items_index = text.rfind("items: [", 0, marker_index)
        if items_index == -1:
            add_issue(issues, "nav", INDEX, f"cannot locate item array for {prefix}")
            continue

        body_start = text.find("[", items_index, marker_index)
        body_end = text.find("]", body_start, marker_index)
        if body_start == -1 or body_end == -1:
            add_issue(issues, "nav", INDEX, f"cannot parse item array for {prefix}")
            continue

        class_names = QUOTED_STRING_RE.findall(text[body_start + 1 : body_end])
        hrefs.extend(f"{prefix}/{class_name}.md" for class_name in class_names)

    seen: set[str] = set()
    duplicates: set[str] = set()
    for href in hrefs:
        if href in seen:
            duplicates.add(href)
        seen.add(href)

    for href in sorted(duplicates):
        add_issue(issues, "nav", INDEX, f"duplicate NAV href {href}")

    return set(hrefs)


def check_nav_sync(issues: list[str]) -> None:
    nav_hrefs = extract_nav_hrefs(issues)
    if not nav_hrefs:
        return

    docs_files = {path.relative_to(DOCS).as_posix() for path in markdown_files()}

    for href in sorted(nav_hrefs):
        if not (DOCS / href).exists():
            add_issue(issues, "nav", INDEX, f"NAV href points to missing file: {href}")

    for path in sorted(docs_files - nav_hrefs):
        add_issue(issues, "nav", DOCS / path, "markdown file is not listed in NAV")


def class_names_for_layer(layer: str, issues: list[str]) -> dict[str, Path]:
    layer_root = ADDON / layer
    classes: dict[str, Path] = {}

    for gd_file in sorted(layer_root.rglob("*.gd")):
        text = read_text(gd_file, issues, "ref")
        if not text:
            continue
        match = CLASS_NAME_RE.search(text)
        if match is None:
            continue
        class_name = match.group(1)
        if class_name in classes:
            add_issue(
                issues,
                "ref",
                gd_file,
                f"duplicate class_name {class_name}; already declared in {rel(classes[class_name])}",
            )
        classes[class_name] = gd_file

    return classes


def expected_ref_classes(issues: list[str]) -> dict[str, dict[str, Path]]:
    expected = {
        "kernel": class_names_for_layer("kernel", issues),
        "modules": class_names_for_layer("modules", issues),
    }

    service_registry = ADDON / "kernel" / "services" / "service_registry.gd"
    if service_registry.exists():
        expected["kernel"].setdefault("ServiceRegistry", service_registry)

    return expected


def check_ref_coverage(issues: list[str]) -> None:
    expected = expected_ref_classes(issues)

    for layer, classes in expected.items():
        ref_dir = DOCS / "ref" / layer
        for class_name, source in sorted(classes.items()):
            ref_path = ref_dir / f"{class_name}.md"
            if not ref_path.exists():
                add_issue(
                    issues,
                    "ref",
                    source,
                    f"missing ref page {rel(ref_path)} for class_name {class_name}",
                )

        for ref_path in sorted(ref_dir.glob("*.md")):
            class_name = ref_path.stem
            if class_name not in classes:
                add_issue(
                    issues,
                    "ref",
                    ref_path,
                    f"no matching source class under addons/mkit/{layer}",
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

    check_links(issues)
    check_ref_coverage(issues)
    check_nav_sync(issues)
    check_recipe_ownership_sections(issues)
    check_no_demo_paths(issues)

    if issues:
        print("docs-check failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print(
        "docs-check passed: links, ref coverage, NAV sync, and recipe ownership "
        "sections are in sync; no game/demo paths are exposed."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
