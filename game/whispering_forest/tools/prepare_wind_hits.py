"""Prepare the user's two wind CONTACT cues, keeping their original character."""
from pathlib import Path
import array
import hashlib
import json
import shutil
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
SOURCES = ROOT / 'art/audio/wind-v4/user-supplied'
OUTPUT = ROOT / 'assets/wind-audio-v4'


def prepare():
    SOURCES.mkdir(parents=True, exist_ok=True)
    OUTPUT.mkdir(parents=True, exist_ok=True)
    manifest = {'origin': 'User-supplied wind hit recordings; not original synthesis or CC0 stock.', 'clips': []}
    for number, suffix, gain in [(1, 'small', -2), (2, 'full', -1)]:
        source = SOURCES / f'wind-hit-level-{1 if number == 1 else 10}-source.wav'
        if not source.exists():
            shutil.copyfile(Path('/Users/dev/Downloads') / f'风{number}.wav', source)
        with wave.open(str(source)) as w:
            duration = w.getnframes() / w.getframerate()
        output = OUTPUT / f'hit-{suffix}.wav'
        # Keep the attack intact; only fade the final 12 ms to avoid a cut click.
        subprocess.run(['/opt/homebrew/bin/ffmpeg', '-v', 'error', '-y', '-i', str(source),
                        '-af', f'pan=stereo|c0=c0|c1=c0,volume={gain}dB,afade=t=out:st={duration-.012:.9f}:d=0.012',
                        '-ar', '48000', '-ac', '2', '-c:a', 'pcm_s16le', str(output)], check=True)
        with wave.open(str(output)) as w:
            assert w.getframerate() == 48000 and w.getnchannels() == 2
            data = array.array('h', w.readframes(w.getnframes()))
            peak = max(abs(x) for x in data) / 32768
            assert peak < .96 and max(abs(x) for x in data[-2:]) < 8
        manifest['clips'].append({'file': str(output.relative_to(ROOT)),
                                  'source': str(source.relative_to(ROOT)),
                                  'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
                                  'sha256': hashlib.sha256(output.read_bytes()).hexdigest(),
                                  'source_level': 1 if number == 1 else 10,
                                  'duration': duration, 'gain_db': gain, 'peak': peak})
    (OUTPUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('WF_WIND_HITS_OK: supplied L1/L10 contact cues, 48 kHz stereo, unclipped, faded endpoints')


if __name__ == '__main__':
    prepare()
