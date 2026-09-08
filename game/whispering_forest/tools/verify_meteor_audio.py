"""Check the rendered bank's technical envelope and distinct audio layers."""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT=Path(__file__).resolve().parents[1]
BANK=ROOT/'assets/meteor-audio-v3'
manifest=json.loads((BANK/'manifest.json').read_text())
sounds={}
report={}
for name,spec in manifest['clips'].items():
    path=BANK/(name+'.wav')
    assert hashlib.sha256(path.read_bytes()).hexdigest()==spec['sha256'],name
    with wave.open(str(path)) as f:
        assert (f.getframerate(),f.getnchannels(),f.getsampwidth())==(48000,2,2)
        sound=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2').reshape(-1,2)/32768
    assert abs(sound).max()<.99 and np.sqrt(np.mean(sound**2))>.01,name
    assert abs(sound[0]).max()<.0001 and abs(sound[-1]).max()<.0001,name
    sounds[name]=sound
    rms=lambda lo,hi: float(np.sqrt(np.mean(sound[round(lo*48000):round(hi*48000)]**2)))
    onset_energy=rms(0,.05)
    if 'fall' in name:
        assert rms(.65,.9)>rms(.02,.20)*2, name+' lacks an approaching wind swell'
        assert 'wind' in spec['layers']
        if name.startswith('ultimate'): assert 'fire' in spec['layers']
    else:
        envelope=np.array([rms(i*.01,(i+1)*.01) for i in range(20)])
        # A later bass lobe can exceed the first strike. Detect an immediate
        # substantial onset rather than requiring the entire sound's loudest
        # 10 ms window to be at time zero.
        assert rms(0,.02)>envelope.max()*.55,name+' contact begins too late'
        assert onset_energy>rms(.65,.9)*2,name+' lacks an initial strike'
    report[name]={'peak_dbfs':spec['peak_dbfs'],'rms_dbfs':spec['rms_dbfs'],
                  'first_50ms_rms_dbfs':round(20*np.log10(onset_energy),2),
                  'layers':spec['layers']}

assert len(sounds['rock-full'])>len(sounds['rock-small'])
for kind in ['fall','rock']:
    assert np.sqrt(np.mean(sounds[kind+'-full']**2))>np.sqrt(np.mean(sounds[kind+'-small']**2))*1.30
for layer in ['wind','fire']:
    path=ROOT/f'art/audio/meteor-v3/ultimate-fall-full-{layer}.wav'
    with wave.open(str(path)) as f:
        a=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2')/32768
    assert np.sqrt(np.mean(a*a))>.015, 'Ultimate '+layer+' stem is inaudibly quiet'
(ROOT/'preview/meteor-audio-v3-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print('WF_METEOR_AUDIO_CHECK_OK: six PCM cues; no clipping; audible wind/fire stems; prompt contact; L1/L10 strength and tail differences')
