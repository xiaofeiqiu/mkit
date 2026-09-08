"""End-to-end spell / wave checks, with failure detection beyond Godot's exit code."""
from pathlib import Path
import os, subprocess, tempfile

sample=Path(__file__).resolve().parents[1]
root=sample.parents[1]
with tempfile.TemporaryDirectory(prefix='wf-combat-') as tmp:
    result=subprocess.run([
        os.environ.get('GODOT','/Applications/Godot.app/Contents/MacOS/Godot'),
        '--headless','--path',str(root),'--log-file',str(Path(tmp)/'engine.log'),
        '--rendering-method','gl_compatibility','--quit-after','240',
        '--scene','res://game/whispering_forest/bootstrap.tscn','--','--wf-combat-test'
    ],capture_output=True,text=True,timeout=60)
    output=result.stdout+result.stderr
    (sample/'preview/combat-verification.log').write_text(output)
    assert result.returncode==0 and 'WF_COMBAT_OK:' in output and not any(
        s in output for s in ['SCRIPT ERROR','WF_COMBAT_FAILED','WF_COMBAT_CHECK_FAILED']
    ),output[-12000:]
    print(next(line for line in output.splitlines() if line.startswith('WF_COMBAT_OK:')))
