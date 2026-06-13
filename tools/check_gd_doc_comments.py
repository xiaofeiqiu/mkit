#!/usr/bin/env python3
"""Check Godot ## doc comment coverage for public mkit GDScript API."""

from __future__ import annotations

import re
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
ADDON = ROOT / "addons" / "mkit"
SCAN_ROOTS = (ADDON / "kernel", ADDON / "modules")

CLASS_NAME_RE = re.compile(r"^class_name\s+([A-Za-z_][A-Za-z0-9_]*)\b")
EXTENDS_RE = re.compile(r"^extends\s+(.+)$")
FUNC_RE = re.compile(r"^(static\s+)?func\s+([A-Za-z_][A-Za-z0-9_]*)\b")
SIGNAL_RE = re.compile(r"^signal\s+([A-Za-z_][A-Za-z0-9_]*)\b")
CONST_RE = re.compile(r"^const\s+([A-Za-z_][A-Za-z0-9_]*)\b")
ENUM_RE = re.compile(r"^enum(?:\s+([A-Za-z_][A-Za-z0-9_]*))?\b")
VAR_RE = re.compile(r"^(?:@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\s+)*var\s+([A-Za-z_][A-Za-z0-9_]*)\b")
ANNOTATION_RE = re.compile(r"^@[A-Za-z_][A-Za-z0-9_]*(?:\([^)]*\))?\b")
BANNED_DOC_PATTERNS = (
    (re.compile(r"读取或维护。"), "generated maintenance boilerplate"),
    (re.compile(r"^(编辑器配置|运行时状态)：`[^`]+` 表示"), "generated field template"),
    (re.compile(r"字段值"), "placeholder field-value wording"),
    (re.compile(r"领域契约一致"), "generated method template"),
    (re.compile(r"对应的公开操作"), "generated method template"),
    (re.compile(r"对应的数据或对象"), "generated method template"),
    (re.compile(r"当前是否成立"), "generated predicate template"),
    (re.compile(r"公开常量 `[^`]+`，作为"), "generated constant template"),
)

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
class Declaration:
    kind: str
    name: str
    line: int
    doc: tuple[str, ...]
    signature: str
    exported: bool = False

    @property
    def is_private(self) -> bool:
        return self.name.startswith("_")


@dataclass
class ClassApi:
    path: Path
    name: str
    line: int
    doc: tuple[str, ...]
    declarations: list[Declaration]


def rel(path: Path) -> str:
    return path.relative_to(ROOT).as_posix()


def doc_line(raw: str) -> str:
    text = raw.lstrip()[2:]
    if text.startswith(" "):
        text = text[1:]
    return text.rstrip()


def trim_doc(lines: list[str]) -> tuple[str, ...]:
    result = list(lines)
    while result and result[0] == "":
        result.pop(0)
    while result and result[-1] == "":
        result.pop()
    return tuple(result)


def collect_doc_before(lines: list[str], index: int) -> tuple[tuple[str, ...], set[int]]:
    docs: list[str] = []
    consumed: set[int] = set()
    i = index - 1
    while i >= 0 and lines[i].lstrip().startswith("##"):
        docs.append(doc_line(lines[i]))
        consumed.add(i)
        i -= 1
    docs.reverse()
    return trim_doc(docs), consumed


def collect_doc_after_header(lines: list[str], start_index: int) -> tuple[tuple[str, ...], set[int]]:
    i = start_index
    while i < len(lines) and lines[i].strip() == "":
        i += 1
    if i >= len(lines) or not lines[i].lstrip().startswith("##"):
        return (), set()

    docs: list[str] = []
    consumed: set[int] = set()
    while i < len(lines) and lines[i].lstrip().startswith("##"):
        docs.append(doc_line(lines[i]))
        consumed.add(i)
        i += 1
    return trim_doc(docs), consumed


def statement_balance(text: str) -> int:
    return text.count("(") + text.count("[") + text.count("{") - text.count(")") - text.count("]") - text.count("}")


def statement_complete(first_line: str, current_line: str, balance: int) -> bool:
    if balance > 0:
        return False
    stripped = first_line.strip()
    if stripped.startswith(("func ", "static func ")):
        return current_line.endswith(":")
    return True


def normalize_statement(lines: list[str]) -> str:
    return " ".join(line.strip() for line in lines if line.strip())


def collect_statement(lines: list[str], index: int) -> tuple[str, int]:
    collected = [lines[index]]
    balance = statement_balance(lines[index])
    i = index
    while i + 1 < len(lines):
        if statement_complete(collected[0], collected[-1].strip(), balance):
            break
        i += 1
        collected.append(lines[i])
        balance += statement_balance(lines[i])
    return normalize_statement(collected), i


def is_declaration_line(stripped: str) -> bool:
    if stripped.startswith(("func ", "static func ", "signal ", "const ", "enum ", "var ")):
        return True
    return bool(ANNOTATION_RE.match(stripped) and " var " in f" {stripped} ")


def declaration_from(statement: str, doc: tuple[str, ...], line: int) -> Declaration | None:
    signature = statement.rstrip(":")
    stripped = signature.strip()
    if match := SIGNAL_RE.match(stripped):
        return Declaration("signal", match.group(1), line, doc, signature)
    if match := ENUM_RE.match(stripped):
        return Declaration("enum", match.group(1) or "<anonymous>", line, doc, signature)
    if match := CONST_RE.match(stripped):
        return Declaration("constant", match.group(1), line, doc, signature)
    if match := VAR_RE.match(stripped):
        return Declaration("property", match.group(1), line, doc, signature, exported=stripped.startswith("@export"))
    if match := FUNC_RE.match(stripped):
        return Declaration("method", match.group(2), line, doc, signature)
    return None


def parse_class(path: Path) -> ClassApi | None:
    lines = path.read_text(encoding="utf-8").splitlines()
    class_name = ""
    class_index = -1
    extends_index = -1

    for index, line in enumerate(lines):
        stripped = line.strip()
        if class_index == -1 and (match := CLASS_NAME_RE.match(stripped)):
            class_name = match.group(1)
            class_index = index
        if extends_index == -1 and EXTENDS_RE.match(stripped):
            extends_index = index

    if not class_name and path.as_posix().endswith("kernel/services/service_registry.gd"):
        class_name = "ServiceRegistry"
        class_index = 0
    if not class_name:
        return None

    doc, consumed = collect_doc_before(lines, class_index)
    if not doc:
        header_end = extends_index if extends_index != -1 else class_index
        doc, consumed = collect_doc_after_header(lines, header_end + 1)

    declarations: list[Declaration] = []
    pending_doc: list[str] = []
    pending_annotations: list[str] = []
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()

        if raw.startswith((" ", "\t")):
            pending_doc = []
            pending_annotations = []
            i += 1
            continue
        if i in consumed:
            i += 1
            continue
        if stripped == "":
            pending_doc = []
            pending_annotations = []
            i += 1
            continue
        if stripped.startswith("##"):
            pending_doc.append(doc_line(raw))
            i += 1
            continue
        if stripped.startswith(("class_name ", "extends ")):
            pending_doc = []
            pending_annotations = []
            i += 1
            continue
        if ANNOTATION_RE.match(stripped) and " var " not in f" {stripped} ":
            pending_annotations.append(stripped)
            i += 1
            continue
        if not is_declaration_line(stripped):
            pending_doc = []
            pending_annotations = []
            i += 1
            continue

        statement, end_index = collect_statement(lines, i)
        if pending_annotations:
            statement = " ".join(pending_annotations + [statement])
        declaration = declaration_from(statement, trim_doc(pending_doc), i + 1)
        if declaration is not None:
            declarations.append(declaration)
        pending_doc = []
        pending_annotations = []
        i = end_index + 1

    return ClassApi(path, class_name, max(class_index + 1, 1), doc, declarations)


def requires_doc(declaration: Declaration) -> bool:
    if declaration.kind in {"signal", "enum"}:
        return True
    if declaration.kind == "constant":
        return (
            declaration.name == "SERVICE_ID"
            or declaration.name.endswith("_TYPE")
            or declaration.name.endswith("_TYPE_NAME")
            or declaration.name.isupper()
        )
    if declaration.kind == "property":
        return declaration.exported or not declaration.is_private
    if declaration.kind == "method":
        if declaration.name in LIFECYCLE_METHODS:
            return False
        return not declaration.is_private or declaration.name in PUBLIC_HOOKS
    return False


def banned_doc_issue(doc: tuple[str, ...]) -> str:
    for line in doc:
        for pattern, label in BANNED_DOC_PATTERNS:
            if pattern.search(line):
                return label
    return ""


def main() -> int:
    issues: list[str] = []

    for root in SCAN_ROOTS:
        for path in sorted(root.rglob("*.gd")):
            class_api = parse_class(path)
            if class_api is None:
                continue
            if not class_api.doc:
                issues.append(f"{rel(path)}:{class_api.line} class {class_api.name} missing doc")
            elif issue := banned_doc_issue(class_api.doc):
                issues.append(f"{rel(path)}:{class_api.line} class {class_api.name} has {issue}")
            for declaration in class_api.declarations:
                if requires_doc(declaration) and not declaration.doc:
                    issues.append(
                        f"{rel(path)}:{declaration.line} {declaration.kind} "
                        f"{declaration.name} missing doc"
                    )
                elif declaration.doc and (issue := banned_doc_issue(declaration.doc)):
                    issues.append(
                        f"{rel(path)}:{declaration.line} {declaration.kind} "
                        f"{declaration.name} has {issue}"
                    )

    if issues:
        print("doc comment coverage failed:")
        for issue in issues:
            print(f"  {issue}")
        return 1

    print("doc comment coverage passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
