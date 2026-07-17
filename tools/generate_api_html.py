#!/usr/bin/env python3
"""Render Godot doctool XML into static HTML class reference pages."""

from __future__ import annotations

import argparse
import html
import re
import shutil
import sys
import xml.etree.ElementTree as ET
from dataclasses import dataclass, field
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_XML_DIR = ROOT / "docs" / "generated" / "xml"
DEFAULT_OUT_DIR = ROOT / "docs" / "generated" / "html"

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


@dataclass(frozen=True)
class ParamDoc:
    name: str
    type_name: str
    default: str = ""


@dataclass(frozen=True)
class MethodDoc:
    name: str
    return_type: str
    params: tuple[ParamDoc, ...]
    qualifiers: str
    description: str


@dataclass(frozen=True)
class MemberDoc:
    name: str
    type_name: str
    default: str
    description: str
    enum: str = ""


@dataclass(frozen=True)
class SignalDoc:
    name: str
    params: tuple[ParamDoc, ...]
    description: str


@dataclass(frozen=True)
class ConstantDoc:
    name: str
    value: str
    enum: str
    description: str


@dataclass
class ClassDoc:
    name: str
    inherits: str
    brief: str
    description: str
    methods: list[MethodDoc] = field(default_factory=list)
    members: list[MemberDoc] = field(default_factory=list)
    signals: list[SignalDoc] = field(default_factory=list)
    constants: list[ConstantDoc] = field(default_factory=list)


def text_of(element: ET.Element | None) -> str:
    if element is None:
        return ""
    text = "".join(element.itertext())
    return re.sub(r"[ \t\r\n]+", " ", text).strip()


def clean_name(name: str) -> str:
    return name.strip().strip('"')


def is_renderable_class(name: str) -> bool:
    cleaned = clean_name(name)
    return bool(cleaned) and "/" not in cleaned and not cleaned.endswith(".gd")


def class_page_name(class_name: str) -> str:
    return f"{class_name}.html"


def parse_params(parent: ET.Element) -> tuple[ParamDoc, ...]:
    params: list[ParamDoc] = []
    for param in parent.findall("param"):
        params.append(
            ParamDoc(
                name=param.attrib.get("name", ""),
                type_name=param.attrib.get("type", ""),
                default=param.attrib.get("default", ""),
            )
        )
    return tuple(params)


def parse_class(path: Path) -> ClassDoc | None:
    root = ET.parse(path).getroot()
    raw_name = root.attrib.get("name", "")
    if not is_renderable_class(raw_name):
        return None

    class_doc = ClassDoc(
        name=clean_name(raw_name),
        inherits=root.attrib.get("inherits", ""),
        brief=text_of(root.find("brief_description")),
        description=text_of(root.find("description")),
    )

    for method in root.findall("./methods/method"):
        return_node = method.find("return")
        class_doc.methods.append(
            MethodDoc(
                name=method.attrib.get("name", ""),
                return_type=return_node.attrib.get("type", "void") if return_node is not None else "void",
                params=parse_params(method),
                qualifiers=method.attrib.get("qualifiers", ""),
                description=text_of(method.find("description")),
            )
        )

    for member in root.findall("./members/member"):
        class_doc.members.append(
            MemberDoc(
                name=member.attrib.get("name", ""),
                type_name=member.attrib.get("type", ""),
                default=member.attrib.get("default", ""),
                enum=member.attrib.get("enum", ""),
                description=text_of(member),
            )
        )

    for signal in root.findall("./signals/signal"):
        class_doc.signals.append(
            SignalDoc(
                name=signal.attrib.get("name", ""),
                params=parse_params(signal),
                description=text_of(signal.find("description")),
            )
        )

    for constant in root.findall("./constants/constant"):
        class_doc.constants.append(
            ConstantDoc(
                name=constant.attrib.get("name", ""),
                value=constant.attrib.get("value", ""),
                enum=constant.attrib.get("enum", ""),
                description=text_of(constant),
            )
        )

    return class_doc


def html_text(value: str) -> str:
    return html.escape(value, quote=True)


def code(value: str) -> str:
    return f"<code>{html_text(value)}</code>"


def paragraph(value: str) -> str:
    if not value:
        return '<p class="muted">No description.</p>'
    linked = html_text(value)
    linked = re.sub(r"`([^`]+)`", lambda m: f"<code>{html_text(m.group(1))}</code>", linked)
    return f"<p>{linked}</p>"


def params_signature(params: tuple[ParamDoc, ...]) -> str:
    parts: list[str] = []
    for param in params:
        part = param.name
        if param.type_name:
            part += f": {param.type_name}"
        if param.default:
            part += f" = {param.default}"
        parts.append(part)
    return ", ".join(parts)


def method_signature(method: MethodDoc) -> str:
    prefix = f"{method.qualifiers} " if method.qualifiers else ""
    return f"{prefix}func {method.name}({params_signature(method.params)}) -> {method.return_type}"


def method_section(method: MethodDoc) -> str:
    if method.name in PUBLIC_HOOKS:
        return "Hooks"
    if method.name in LIFECYCLE_METHODS:
        return "Lifecycle Hooks" if method.description else ""
    if method.name.startswith("_"):
        return ""
    return "Methods"


def signal_signature(signal: SignalDoc) -> str:
    return f"signal {signal.name}({params_signature(signal.params)})"


def section(title: str, body: str) -> str:
    if not body:
        return ""
    return f"<section><h2>{html_text(title)}</h2>{body}</section>"


def render_table(headers: list[str], rows: list[list[str]]) -> str:
    if not rows:
        return ""
    head = "".join(f"<th>{html_text(header)}</th>" for header in headers)
    body_rows = []
    for row in rows:
        body_rows.append("<tr>" + "".join(f"<td>{cell}</td>" for cell in row) + "</tr>")
    return f"<table><thead><tr>{head}</tr></thead><tbody>{''.join(body_rows)}</tbody></table>"


def stylesheet() -> str:
    return """
    :root {
      --bg:#1e2128; --panel:#161a20; --text:#cdd6f4; --muted:#8b92aa;
      --border:#2d3342; --code:#242834; --link:#89b4fa; --heading:#ffffff;
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--text); font: 14px/1.65 system-ui, -apple-system, Segoe UI, sans-serif; }
    a { color: var(--link); text-decoration: none; }
    a:hover { text-decoration: underline; }
    .layout { display: grid; grid-template-columns: 280px minmax(0, 1fr); min-height: 100vh; }
    nav { background: var(--panel); border-right: 1px solid var(--border); padding: 18px 14px; overflow: auto; }
    main { max-width: 980px; padding: 42px 56px 80px; }
    h1 { color: var(--heading); margin: 0 0 8px; font-size: 2rem; }
    h2 { color: var(--heading); margin: 34px 0 12px; font-size: 1.25rem; border-bottom: 1px solid var(--border); padding-bottom: 6px; }
    h3 { margin: 22px 0 8px; }
    .subtitle, .muted { color: var(--muted); }
    .class-list { list-style: none; padding: 0; margin: 14px 0; display: grid; gap: 4px; }
    .class-list a { display: block; padding: 4px 8px; border-radius: 4px; }
    .class-list a:hover { background: rgba(137,180,250,0.1); text-decoration: none; }
    input[type=search] { width: 100%; padding: 8px 10px; background: var(--code); color: var(--text); border: 1px solid var(--border); border-radius: 4px; }
    code { background: var(--code); color: #f5c2e7; padding: 2px 5px; border-radius: 3px; font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: .9em; }
    pre { background: var(--code); border: 1px solid var(--border); border-radius: 6px; padding: 10px 12px; overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; margin: 10px 0 22px; }
    th, td { border: 1px solid var(--border); padding: 7px 10px; vertical-align: top; }
    th { background: var(--code); color: var(--heading); text-align: left; }
    td:first-child { white-space: nowrap; }
    .topline { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 22px; }
    .badge { color: var(--muted); border: 1px solid var(--border); border-radius: 999px; padding: 2px 9px; }
    .footer { margin-top: 48px; color: var(--muted); font-size: 12px; }
    @media (max-width: 780px) { .layout { display: block; } nav { border-right: 0; border-bottom: 1px solid var(--border); } main { padding: 28px 20px 60px; } }
    """


def render_nav(classes: list[ClassDoc], current: str = "") -> str:
    items = []
    docs_home = "../../../index.html" if current else "../../index.html"
    for class_doc in classes:
        active = ' aria-current="page"' if class_doc.name == current else ""
        prefix = "" if not current else "../"
        items.append(
            f'<li><a href="{prefix}classes/{html_text(class_page_name(class_doc.name))}"{active}>'
            f"{html_text(class_doc.name)}</a></li>"
        )
    return (
        "<nav>"
        f'<a href="{docs_home}">Docs Home</a>'
        "<h2>Generated API</h2>"
        '<input id="class-filter" type="search" placeholder="Filter classes">'
        f'<ul class="class-list" id="class-list">{"".join(items)}</ul>'
        "<script>"
        "const q=document.getElementById('class-filter');"
        "q&&q.addEventListener('input',()=>{const v=q.value.toLowerCase();"
        "document.querySelectorAll('#class-list li').forEach(li=>{li.style.display=li.textContent.toLowerCase().includes(v)?'':'none'})});"
        "</script>"
        "</nav>"
    )


def render_class_page(class_doc: ClassDoc, classes: list[ClassDoc]) -> str:
    method_rows = [
        [code(method_signature(method)), paragraph(method.description)]
        for method in class_doc.methods
        if method_section(method) == "Methods"
    ]
    hook_rows = [
        [code(method_signature(method)), paragraph(method.description)]
        for method in class_doc.methods
        if method_section(method) == "Hooks"
    ]
    lifecycle_rows = [
        [code(method_signature(method)), paragraph(method.description)]
        for method in class_doc.methods
        if method_section(method) == "Lifecycle Hooks"
    ]
    member_rows = [
        [
            code(member.name),
            code(member.type_name),
            code(member.default) if member.default else "",
            code(member.enum) if member.enum else "",
            paragraph(member.description),
        ]
        for member in class_doc.members
    ]
    signal_rows = [
        [code(signal_signature(signal)), paragraph(signal.description)]
        for signal in class_doc.signals
    ]
    constant_rows = [
        [
            code(constant.name),
            code(constant.value),
            code(constant.enum) if constant.enum else "",
            paragraph(constant.description),
        ]
        for constant in class_doc.constants
    ]

    body = f"""
    <div class="layout">
      {render_nav(classes, class_doc.name)}
      <main>
        <div class="topline"><a href="../index.html">Generated API</a><span class="badge">inherits {html_text(class_doc.inherits or "Object")}</span></div>
        <h1>{html_text(class_doc.name)}</h1>
        {paragraph(class_doc.brief)}
        {paragraph(class_doc.description) if class_doc.description else ""}
        {section("Signals", render_table(["Signature", "Description"], signal_rows))}
        {section("Properties", render_table(["Name", "Type", "Default", "Enum", "Description"], member_rows))}
        {section("Methods", render_table(["Signature", "Description"], method_rows))}
        {section("Hooks", render_table(["Signature", "Description"], hook_rows))}
        {section("Lifecycle Hooks", render_table(["Signature", "Description"], lifecycle_rows))}
        {section("Constants", render_table(["Name", "Value", "Enum", "Description"], constant_rows))}
        <div class="footer">Generated from Godot doctool XML. Update GDScript ## doc comments, then run make docs-api.</div>
      </main>
    </div>
    """
    return html_page(class_doc.name, body)


def render_index(classes: list[ClassDoc]) -> str:
    cards = []
    for class_doc in classes:
        cards.append(
            "<li>"
            f'<a href="classes/{html_text(class_page_name(class_doc.name))}">{html_text(class_doc.name)}</a>'
            f'<span class="muted"> inherits {html_text(class_doc.inherits or "Object")}</span>'
            "</li>"
        )
    body = f"""
    <div class="layout">
      {render_nav(classes)}
      <main>
        <div class="topline"><a href="../index.html">Docs Home</a><span class="badge">{len(classes)} classes</span></div>
        <h1>Generated API Reference</h1>
        <p>These pages are generated from Godot doctool XML. The source of truth is the adjacent <code>##</code> doc comment in <code>addons/mkit/**/*.gd</code>.</p>
        <h2>Classes</h2>
        <ul class="class-list">{"".join(cards)}</ul>
        <div class="footer">Generated from Godot doctool XML. Update GDScript ## doc comments, then run make docs-api.</div>
      </main>
    </div>
    """
    return html_page("Generated API Reference", body)


def html_page(title: str, body: str) -> str:
    return (
        "<!DOCTYPE html>\n"
        '<html lang="zh-CN">\n'
        "<head>\n"
        '  <meta charset="UTF-8">\n'
        '  <meta name="viewport" content="width=device-width, initial-scale=1.0">\n'
        f"  <title>{html_text(title)} - Mkit API</title>\n"
        f"  <style>{stylesheet()}</style>\n"
        "</head>\n"
        "<body>\n"
        f"{body}\n"
        "</body>\n"
        "</html>\n"
    )


def load_classes(xml_dir: Path) -> list[ClassDoc]:
    classes: list[ClassDoc] = []
    for path in sorted(xml_dir.glob("*.xml")):
        class_doc = parse_class(path)
        if class_doc is not None:
            classes.append(class_doc)
    return sorted(classes, key=lambda item: item.name.lower())


def write_html(xml_dir: Path, out_dir: Path) -> None:
    xml_dir = xml_dir.resolve()
    out_dir = out_dir.resolve()
    classes = load_classes(xml_dir)
    if not classes:
        raise RuntimeError(f"no renderable XML classes found in {xml_dir}")

    if out_dir.exists():
        shutil.rmtree(out_dir)
    classes_dir = out_dir / "classes"
    classes_dir.mkdir(parents=True, exist_ok=True)

    (out_dir / "index.html").write_text(render_index(classes), encoding="utf-8")
    for class_doc in classes:
        (classes_dir / class_page_name(class_doc.name)).write_text(
            render_class_page(class_doc, classes),
            encoding="utf-8",
        )

    try:
        display_path = out_dir.relative_to(ROOT)
    except ValueError:
        display_path = out_dir
    print(f"generated {len(classes)} API HTML pages in {display_path}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--xml-dir", type=Path, default=DEFAULT_XML_DIR)
    parser.add_argument("--out-dir", type=Path, default=DEFAULT_OUT_DIR)
    args = parser.parse_args()

    try:
        write_html(args.xml_dir, args.out_dir)
    except Exception as exc:
        print(f"generate_api_html failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
