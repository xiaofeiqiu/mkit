#!/usr/bin/env python3
"""Check generated API HTML output against Godot doctool XML files."""

from __future__ import annotations

import argparse
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_XML_DIR = ROOT / "docs" / "generated" / "xml"
DEFAULT_HTML_DIR = ROOT / "docs" / "generated" / "html"


def clean_name(name: str) -> str:
    return name.strip().strip('"')


def is_renderable_class(name: str) -> bool:
    cleaned = clean_name(name)
    return bool(cleaned) and "/" not in cleaned and not cleaned.endswith(".gd")


def expected_classes(xml_dir: Path) -> set[str]:
    classes: set[str] = set()
    for path in sorted(xml_dir.glob("*.xml")):
        root = ET.parse(path).getroot()
        raw_name = root.attrib.get("name", "")
        if is_renderable_class(raw_name):
            classes.add(clean_name(raw_name))
    return classes


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
