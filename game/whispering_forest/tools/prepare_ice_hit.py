"""Prepare the distinct local 冰1.wav recording for the ice-audio correction."""
from pathlib import Path
import array
import hashlib
import json
import shutil
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
INPUT = Path('/Users/dev/Downloads/冰1.wav')
SOURCE = ROOT/'art/audio/ice-v8/user-supplied/ice-level-1-source.wav'
OUT = ROOT/'assets/ice-audio-v8'


def main():
    SOURCE.parent.mkdir(parents=True, exist_ok=True)
    OUT.mkdir(parents=True, exist_ok=True)
    if INPUT.is_file():
        shutil.copyfile(INPUT, SOURCE)
    elif not SOURCE.is_file():
        raise FileNotFoundError(INPUT)
    with wave.open(str(SOURCE)) as w:
        duration = w.getnframes()/w.getframerate()
    output = OUT/'hit-level-1.wav'
    subprocess.run(['/opt/homebrew/bin/ffmpeg', '-v', 'error', '-y', '-i', str(SOURCE),
                    '-af', f'pan=stereo|c0=c0|c1=c0,volume=-2dB,afade=t=out:st={duration-.012:.9f}:d=0.012',
                    '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s16le', str(output)], check=True)
    with wave.open(str(output)) as w:
        assert w.getframerate()==48000 and w.getnchannels()==2
        data = array.array('h', w.readframes(w.getnframes()))
    assert max(abs(x) for x in data)<32760 and max(abs(x) for x in data[-2:])<8
    manifest = {'origin': 'Local recording 冰1.wav, selected by filename after the incorrect-ice-audio report; not synthesis.',
                'original_filename': '冰1.wav', 'source': str(SOURCE.relative_to(ROOT)),
                'source_sha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
                'file': output.name, 'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                'duration': duration, 'sample_rate': 48000, 'channels': 2, 'gain_db': -2,
                'trigger': 'At each ice pillar\'s maximum height; sequential pillars keep independent timing.'}
    (OUT/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    print('WF_ICE_HIT_OK: supplied L1 recording, original pitch, 48 kHz stereo, unclipped')


if __name__=='__main__':
    main()
