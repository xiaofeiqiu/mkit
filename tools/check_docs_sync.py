#!/usr/bin/env python3
"""Check docs links, navigation, cookbook ownership, and stale demo paths."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "docs"
INDEX = DOCS / "index.html"
DIRECT_HREF_RE = re.compile(r"href:\s*['\"]([^'\"]+\.md)['\"]")
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
    check_nav_sync(issues)
    check_recipe_ownership_sections(issues)
    check_no_demo_paths(issues)

    if issues:
        print("docs-check failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print(
        "docs-check passed: links, NAV sync, and recipe ownership sections are "
        "in sync; no game/demo paths are exposed."
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
