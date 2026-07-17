#!/bin/sh
# 输出「从未在 docs/cookbook/*.md 出现」的 @export 字段（按整词匹配）。
# 有缺口时退出码非 0，可进 CI（见 reviews/cookbook-all.md 第五节）。
set -eu
cd "$(dirname "$0")/.."

status=0
for f in $(find addons/mkit/modules addons/mkit/kernel -name "*.gd" | sort); do
  cls=$(grep -m1 "^class_name" "$f" | awk '{print $2}') || true
  [ -z "$cls" ] && continue
  exports=$(grep -oE "@export[a-z_]*(\([^)]*\))? var [a-zA-Z_]+" "$f" | awk '{print $NF}') || true
  missing=""
  for field in $exports; do
    grep -rqw "$field" docs/cookbook/*.md || missing="$missing $field"
  done
  if [ -n "$missing" ]; then
    echo "$cls:$missing"
    status=1
  fi
done
exit $status
