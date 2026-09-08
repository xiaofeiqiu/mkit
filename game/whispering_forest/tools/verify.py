"""Run the sample's real mkit / viewport-input integration checks."""
from pathlib import Path
import os, subprocess, sys, tempfile
SAMPLE = Path(__file__).resolve().parents[1]
ROOT = SAMPLE.parents[1]
GODOT = os.environ.get('GODOT', '/Applications/Godot.app/Contents/MacOS/Godot')
with tempfile.TemporaryDirectory(prefix='wf-verify-') as temp:
    command = [GODOT, '--headless', '--path', str(ROOT), '--log-file', str(Path(temp)/'engine.log'),
               '--rendering-method', 'gl_compatibility', '--quit-after', '240',
               '--scene', 'res://game/whispering_forest/bootstrap.tscn', '--', '--wf-smoke']
    result = subprocess.run(command, capture_output=True, text=True, timeout=45)
    output = result.stdout + result.stderr
    (SAMPLE/'preview'/'verification.log').write_text(output)
    bad = any(message in output for message in ['SCRIPT ERROR', 'WF_SMOKE_FAILED', 'Failed to load script'])
    if result.returncode or bad or 'WF_SMOKE_OK:' not in output:
        print(output[-14000:])
        sys.exit(1)
    print(next(line for line in output.splitlines() if line.startswith('WF_SMOKE_OK:')))
print('Verified: city frontage/waystone/bridge routes, actual click navigation and collisions; eight-direction animation; viewport input and independent quest instances; save/reload.')
