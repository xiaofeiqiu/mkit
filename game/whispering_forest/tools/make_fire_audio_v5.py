"""Original L1 flame burst: short low blast and a closing tail, reference-guided.

No samples from the user's cgefc15.wav are included in the exported audio.
The reference informs duration, broad spectral balance and decay shape only.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/fire-audio-v5'
STEMS = ROOT / 'art/audio/fire-v5'
REFERENCE = Path('/Users/dev/Downloads/cgefc15.wav')
SR = 48000
RNG = np.random.default_rng(9061530)


def band(n, low, high):
    hz = np.fft.rfftfreq(n, 1/SR)
    filt = np.exp(-(hz/high)**4) * (1-np.exp(-(hz/low)**4))
    y = np.fft.irfft(np.fft.rfft(RNG.normal(size=n))*filt, n)
    return y/max(np.std(y), 1e-8)


def write(path, x):
    if x.ndim == 1:
        x = np.column_stack([x, x])
    assert np.isfinite(x).all() and np.max(abs(x)) < 1
    with wave.open(str(path), 'wb') as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes(np.round(x*32767).astype('<i2').tobytes())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    STEMS.mkdir(parents=True, exist_ok=True)
    with wave.open(str(REFERENCE)) as w:
        seconds = w.getnframes()/w.getframerate()
        ref = np.frombuffer(w.readframes(w.getnframes()), dtype='<i2')/32768
    n = round(seconds*SR)
    t = np.arange(n)/SR
    # An early blast with two low rolling folds, then a strongly closing tail.
    # These are authored coarse envelope points, not a copied source waveform.
    knots = [0, .006, .055, .13, .20, .27, .33, .42, .50, .60, .70, .82, 1.0, seconds]
    db = [-65, -10, -7.8, -10.2, -9.4, -12.6, -10.7, -13.3, -19, -29, -37, -48, -64, -88]
    envelope = 10**(np.interp(t, knots, db)/20)
    flutter = .84+.10*np.sin(2*np.pi*13*t+.4)+.06*np.sin(2*np.pi*21*t)
    pressure = (band(n, 26, 175)*.84+band(n, 95, 320)*.22)*flutter
    # A short descending pressure resonance adds weight without a long hum.
    pressure += np.sin(2*np.pi*(53*t+3.1*(1-np.exp(-t*14))))*.17*np.exp(-t*5)
    roar = (band(n, 155, 680)*.30+band(n, 540, 1850)*.085)*np.exp(-t*1.6)
    attack = band(n, 750, 4700)*.16*np.exp(-t*31)
    # Three tiny airy folds belong to the burst, not a persistent burning loop.
    for onset, gain in [(.11, .025), (.23, .019), (.36, .012)]:
        local = np.maximum(t-onset, 0)
        attack += band(n, 1000, 4800)*gain*(t>=onset)*np.exp(-local*60)
    taper = np.minimum(1, t/.0015)*np.minimum(1, (seconds-t)/.016)
    layers = {name: y*envelope*taper for name, y in
              [('pressure', pressure), ('roar', roar), ('attack', attack)]}
    mono = sum(layers.values())
    # A small decorrelated upper-air layer; bass and attack remain centered.
    side = band(n, 650, 2400)*envelope*taper*.014*np.exp(-t*2)
    stereo = np.column_stack([mono+side, mono-side])
    stereo -= stereo.mean(axis=0)
    stereo *= taper[:, None]
    scale = .87/np.max(abs(stereo))
    stereo *= scale
    stereo[0] = 0; stereo[-1] = 0
    path = OUT/'fire-level-1.wav'
    write(path, stereo)
    for name, y in layers.items():
        write(STEMS/(name+'.wav'), y*scale)
    write(STEMS/'stereo-air.wav', np.column_stack([side, -side])*scale)
    rms = float(np.sqrt(np.mean(stereo**2)))
    manifest = {
        'source': 'Original filtered-noise and pressure-resonance synthesis; reference audio is not sampled.',
        'reference': {'filename': REFERENCE.name, 'sha256': hashlib.sha256(REFERENCE.read_bytes()).hexdigest(),
                      'duration': seconds, 'rms_dbfs': float(20*np.log10(np.sqrt(np.mean(ref**2))))},
        'file': 'fire-level-1.wav', 'sha256': hashlib.sha256(path.read_bytes()).hexdigest(),
        'sample_rate': SR, 'channels': 2, 'frames': n, 'duration': n/SR,
        'peak_dbfs': float(20*np.log10(np.max(abs(stereo)))), 'rms_dbfs': float(20*np.log10(rms)),
        'timing': 'The runtime derives the 8-pose visual lifetime from this exact stream length, at pitch 1.0.',
    }
    (OUT/'manifest.json').write_text(json.dumps(manifest, indent=2)+'\n')
    assert n == 54274 and -.001 < float(stereo[-1, 0]) < .001
    assert -23 < 20*np.log10(rms) < -10
    print('WF_FIRE_AUDIO_OK:', n/SR, 's; original synthesis, unclipped, silent endpoints')


if __name__ == '__main__':
    main()
