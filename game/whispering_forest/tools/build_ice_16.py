"""Rebuild the ice-only model → Aseprite timeline → engine atlas pipeline."""
from pathlib import Path
import os
import subprocess

sample = Path(__file__).resolve().parents[1]
root = sample.parents[1]
godot = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
aseprite = os.environ.get("ASEPRITE", str(Path.home()/"Applications/Aseprite.app/Contents/MacOS/aseprite"))
art = sample / "art/combat/ice-16"
out = sample / "assets/combat-vfx/ice-16"
out.mkdir(parents=True, exist_ok=True)

def run(args, marker=None):
    result = subprocess.run(args, cwd=root, capture_output=True, text=True, timeout=90)
    output = result.stdout + result.stderr
    if result.returncode or "SCRIPT ERROR" in output or (marker and marker not in output):
        raise RuntimeError(output)
    print(marker or "Aseprite atlas exported")

run([godot,"--path",str(root),"--log-file","/tmp/wf-ice16-bake.log",
     "--rendering-method","forward_plus","--resolution","384x384",
     "--script","res://game/whispering_forest/tools/bake_ice_16.gd"], "WF_ICE_BASE_OK")
run([aseprite,"--batch","--script-param",f"root={root}","--script",str(art/"author_ice.lua")], "WF_ASEPRITE_ICE_OK")
run([aseprite,"--batch",str(art/"ice-spear-16.aseprite"),"--list-layers","--list-tags",
     "--sheet-type","horizontal","--sheet",str(out/"ice.png"),"--data",str(out/"aseprite.json"),"--format","json-array"])
run([godot,"--headless","--path",str(root),"--log-file","/tmp/wf-ice16-register.log",
     "--script","res://game/whispering_forest/tools/register_ice_16.gd"], "WF_ICE_REGISTERED_OK")
run([aseprite,"--batch","--script-param",f"root={root}","--script",str(art/"preview_ice.lua")], "WF_ICE_PREVIEW_EXPORTED")
