#!/usr/bin/env python3
"""Remove auto-generated spec comment blocks from GDScript files."""

import re
import os
import sys

HAS_CHINESE = re.compile(r'[一-鿿㐀-䶿豈-﫿]')
SPEC_BLOCK_START = re.compile(r'^##\s+SPEC\s+(FIELD|FUNC|SIGNAL)\s+BEGIN')
SPEC_BLOCK_END = re.compile(r'^##\s+SPEC\s+(FIELD|FUNC|SIGNAL)\s+END')
MEMBER_COMMENT = re.compile(r'^##\s+(Purpose|Example|Scenario):')
EMPTY_DOC = re.compile(r'^##\s*$')


def strip_header(lines):
    """Remove the auto-generated ## header block before class_name / extends."""
    # Case 1: file declares class_name — drop everything before it
    for i, line in enumerate(lines):
        if line.strip().startswith('class_name '):
            return lines[i:]

    # Case 2: no class_name — remove ## lines that appear before the first
    # 'extends' declaration; keep single-# comments, @tool, blank lines, etc.
    result = []
    header_done = False
    for line in lines:
        stripped = line.strip()
        if not header_done:
            if stripped.startswith('extends '):
                header_done = True
                result.append(line)
                continue
            if stripped.startswith('##'):
                continue  # drop header ## comment
            result.append(line)
        else:
            result.append(line)
    return result


def strip_body_comments(lines):
    """Remove per-member comment blocks from the class body."""
    filtered = []
    in_spec_block = False

    for line in lines:
        stripped = line.strip()

        if in_spec_block:
            if SPEC_BLOCK_END.match(stripped):
                in_spec_block = False
            continue

        if SPEC_BLOCK_START.match(stripped):
            in_spec_block = True
            continue

        if MEMBER_COMMENT.match(stripped):
            continue

        if EMPTY_DOC.match(stripped):
            continue

        if stripped.startswith('##') and HAS_CHINESE.search(stripped):
            continue

        filtered.append(line)

    return filtered


def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        original = f.readlines()

    after_header = strip_header(original)
    cleaned = strip_body_comments(after_header)

    if cleaned != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(cleaned)
        return True
    return False


if __name__ == '__main__':
    root = sys.argv[1] if len(sys.argv) > 1 else '/Users/dev/workspace/gamedev/mkit/addons/mkit'
    changed = 0
    for dirpath, _, filenames in os.walk(root):
        for name in sorted(filenames):
            if name.endswith('.gd'):
                path = os.path.join(dirpath, name)
                if process_file(path):
                    print(f'  cleaned: {os.path.relpath(path, root)}')
                    changed += 1
    print(f'\n{changed} file(s) updated.')
