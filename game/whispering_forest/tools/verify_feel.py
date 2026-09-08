"""Run contact and elemental integration checks and reject engine script errors."""
from pathlib import Path
import os
import subprocess
import tempfile

SAMPLE = Path(__file__).resolve().parents[1]
ROOT = SAMPLE.parents[1]
GODOT = os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot")
for flag, marker, name in [("--wf-feel-test","WF_FEEL_OK:","combat-feel"),
                            ("--wf-combat-test","WF_COMBAT_OK:","combat-regression")]:
    with tempfile.TemporaryDirectory(prefix="wf-feel-check-") as temp:
        result = subprocess.run([GODOT,"--headless","--path",str(ROOT),"--rendering-method","gl_compatibility",
                                 "--log-file",str(Path(temp)/"engine.log"),"--scene",
                                 "res://game/whispering_forest/bootstrap.tscn","--",flag],
                                capture_output=True,text=True,timeout=55)
        output = result.stdout+result.stderr
        (SAMPLE/"preview"/(name+"-verification.log")).write_text(output)
        if result.returncode or marker not in output or "SCRIPT ERROR" in output or "Failed to load" in output:
            print(output[-10000:]); raise SystemExit(1)
        print(next(line for line in output.splitlines() if line.startswith(marker)))
