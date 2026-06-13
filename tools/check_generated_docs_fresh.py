#!/usr/bin/env python3
"""Check generated API HTML output against Godot doctool XML files."""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_XML_DIR = ROOT / "docs" / "generated" / "xml"
DEFAULT_HTML_DIR = ROOT / "docs" / "generated" / "html"

LIFECYCLE_METHODS = {
    "_ready",
    "_enter_tree",
    "_exit_tree",
    "_process",
    "_physics_process",
    "_input",
    "_unhandled_input",
    "_notification",
}
PUBLIC_HOOKS = {
    "_apply_impl",
    "_evaluate_impl",
    "_on_start",
    "_on_update",
    "_on_cancel",
    "_on_complete",
}
BANNED_DESCRIPTION_PATTERNS = (
    re.compile(r"领域契约一致"),
    re.compile(r"对应的公开操作"),
    re.compile(r"对应的数据或对象"),
    re.compile(r"当前是否成立"),
    re.compile(r"公开常量 `[^`]+`，作为"),
)


def clean_name(name: str) -> str:
    return name.strip().strip('"')


def is_renderable_class(name: str) -> bool:
    cleaned = clean_name(name)
    return bool(cleaned) and "/" not in cleaned and not cleaned.endswith(".gd")


def text_of(element: ET.Element | None) -> str:
    if element is None:
        return ""
    text = "".join(element.itertext())
    return re.sub(r"[ \t\r\n]+", " ", text).strip()


def is_visible_method(name: str, description: str) -> bool:
    if name in PUBLIC_HOOKS:
        return True
    if name in LIFECYCLE_METHODS:
        return bool(description)
    return not name.startswith("_")


def expected_classes(xml_dir: Path) -> set[str]:
    classes: set[str] = set()
    for path in sorted(xml_dir.glob("*.xml")):
        root = ET.parse(path).getroot()
        raw_name = root.attrib.get("name", "")
        if is_renderable_class(raw_name):
            classes.add(clean_name(raw_name))
    return classes


def description_issue(description: str) -> str:
    if not description:
        return "missing description"
    for pattern in BANNED_DESCRIPTION_PATTERNS:
        if pattern.search(description):
            return "generated template description"
    return ""


def constant_description_issue(description: str) -> str:
    if not description:
        return ""
    for pattern in BANNED_DESCRIPTION_PATTERNS:
        if pattern.search(description):
            return "generated template description"
    return ""


def check_visible_descriptions(xml_dir: Path) -> list[str]:
    issues: list[str] = []
    for path in sorted(xml_dir.glob("*.xml")):
        root = ET.parse(path).getroot()
        raw_name = root.attrib.get("name", "")
        if not is_renderable_class(raw_name):
            continue
        class_name = clean_name(raw_name)
        for method in root.findall("./methods/method"):
            method_name = method.attrib.get("name", "")
            description = text_of(method.find("description"))
            if not is_visible_method(method_name, description):
                continue
            if issue := description_issue(description):
                issues.append(f"{class_name}.{method_name}: {issue}")
        for constant in root.findall("./constants/constant"):
            constant_name = constant.attrib.get("name", "")
            description = text_of(constant)
            if issue := constant_description_issue(description):
                issues.append(f"{class_name}.{constant_name}: {issue}")
    return issues


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xml-dir", type=Path, default=DEFAULT_XML_DIR)
    parser.add_argument("--html-dir", type=Path, default=DEFAULT_HTML_DIR)
    args = parser.parse_args()

    issues: list[str] = []
    xml_dir = args.xml_dir
    html_dir = args.html_dir
    classes_dir = html_dir / "classes"

    if not xml_dir.exists():
        issues.append(f"missing XML directory: {xml_dir.relative_to(ROOT)}")
    if not html_dir.exists():
        issues.append(f"missing HTML directory: {html_dir.relative_to(ROOT)}")
    if issues:
        print("generated docs freshness failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    try:
        expected = expected_classes(xml_dir)
    except ET.ParseError as exc:
        print(f"generated docs freshness failed:\n  invalid XML: {exc}")
        return 1

    actual = {path.stem for path in classes_dir.glob("*.html")} if classes_dir.exists() else set()
    for class_name in sorted(expected - actual):
        issues.append(f"missing HTML class page: classes/{class_name}.html")
    for class_name in sorted(actual - expected):
        issues.append(f"stale HTML class page: classes/{class_name}.html")
    issues.extend(check_visible_descriptions(xml_dir))

    index = html_dir / "index.html"
    if not index.exists():
        issues.append("missing HTML index: index.html")

    newest_xml = max((path.stat().st_mtime for path in xml_dir.glob("*.xml")), default=0)
    oldest_html = min((path.stat().st_mtime for path in html_dir.rglob("*.html")), default=0)
    if newest_xml and oldest_html and oldest_html + 0.001 < newest_xml:
        issues.append("HTML output is older than XML input; run make docs-html")

    if issues:
        print("generated docs freshness failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print(f"generated docs freshness passed: {len(expected)} class pages.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
