#!/usr/bin/env python3
"""Strip all # and ## comments from GDScript files."""

import os
import sys


def strip_line_comment(line: str) -> str:
    """Remove a trailing # comment from a code line, respecting string literals."""
    result = []
    i = 0
    n = len(line)

    while i < n:
        c = line[i]

        # Triple-quoted string (""" or ''')
        if c in ('"', "'") and line[i:i+3] in ('"""', "'''"):
            quote = line[i:i+3]
            result.append(quote)
            i += 3
            while i < n:
                if line[i:i+3] == quote:
                    result.append(quote)
                    i += 3
                    break
                if line[i] == '\\':
                    result.append(line[i:i+2])
                    i += 2
                else:
                    result.append(line[i])
                    i += 1
            continue

        # Single-quoted string (" or ')
        if c in ('"', "'"):
            quote = c
            result.append(c)
            i += 1
            while i < n:
                if line[i] == '\\':
                    result.append(line[i:i+2])
                    i += 2
                elif line[i] == quote:
                    result.append(line[i])
                    i += 1
                    break
                else:
                    result.append(line[i])
                    i += 1
            continue

        # Comment start
        if c == '#':
            break

        result.append(c)
        i += 1

    return ''.join(result).rstrip()


def process_file(filepath: str) -> bool:
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    cleaned = []
    for line in lines:
        stripped = line.lstrip()
        # Pure comment line — drop entirely
        if stripped.startswith('#'):
            continue
        # Mixed line — strip inline comment
        eol = '\n' if line.endswith('\n') else ''
        code = strip_line_comment(line.rstrip('\n'))
        if code.strip() == '':
            continue  # line became empty after stripping inline comment
        cleaned.append(code + eol)

    if cleaned != lines:
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
                    print(f'  stripped: {os.path.relpath(path, root)}')
                    changed += 1
    print(f'\n{changed} file(s) updated.')
