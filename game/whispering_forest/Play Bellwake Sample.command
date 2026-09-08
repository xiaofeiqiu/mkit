#!/bin/zsh
set -eu
sample_dir="${0:A:h}"
project_dir="${sample_dir:h:h}"
godot_binary="/Applications/Godot.app/Contents/MacOS/Godot"
if [[ ! -x "$godot_binary" ]]; then
  print 'Godot 未找到。请安装 Godot 4.6 或更新版本到 /Applications/Godot.app。'
  read -k 1
  exit 1
fi
exec "$godot_binary" --path "$project_dir" --rendering-method gl_compatibility --resolution 1280x720 --scene res://game/whispering_forest/bootstrap.tscn "$@"
