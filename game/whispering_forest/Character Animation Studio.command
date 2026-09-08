#!/bin/zsh
set -eu
sample_dir="${0:A:h}"
project_dir="${sample_dir:h:h}"
exec /Applications/Godot.app/Contents/MacOS/Godot --path "$project_dir" --rendering-method gl_compatibility --resolution 1280x720 --scene res://game/whispering_forest/art/characters/animation_studio.tscn "$@"
