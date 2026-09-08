#!/bin/zsh
set -eu
sample_dir="${0:A:h}"
exec /Applications/Godot.app/Contents/MacOS/Godot \
  --path "$sample_dir/../.." \
  --log-file /tmp/wf-elemental-live-review.log \
  --rendering-method gl_compatibility \
  --resolution 1280x720 \
  --scene res://game/whispering_forest/bootstrap.tscn \
  -- --wf-combat-review
