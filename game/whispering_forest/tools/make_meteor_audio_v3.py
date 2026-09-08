"""Produce separately timed descent / contact sounds for earth and fire meteors.

Original synthesis + the project's Kenney CC0 Foley. User WAVs inform envelope
and spectral emphasis; their samples are not mixed into the shipped sounds.
This exporter only writes its own meteor-v3 bank and its three listening clips.
"""
from pathlib import Path
import hashlib
import json
import wave
import numpy as np
import make_spell_audio_v2 as source

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/meteor-audio-v3'
STEMS = ROOT / 'art/audio/meteor-v3'
PREVIEW = ROOT / 'preview'
SR = 48000
RNG = np.random.default_rng(9061230)
MANIFEST = {'format': {'sample_rate': SR, 'channels': 2, 'bits': 16},
            'clips': {}, 'sources': {}, 'reference_analysis': {}}


def band(n, low, high):
    hz = np.fft.rfftfreq(n, 1 / SR)
    filt = np.exp(-(hz / high) ** 4)
    if low:
        filt *= 1 - np.exp(-(hz / low) ** 4)
    y = np.fft.irfft(np.fft.rfft(RNG.normal(size=n)) * filt, n)
    return y / max(np.std(y), 1e-8)


def foley(pack, name, speed=1.0):
    path = ROOT / 'art/impact-sources' / pack / name
    MANIFEST['sources'][str(path.relative_to(ROOT))] = hashlib.sha256(path.read_bytes()).hexdigest()
    return source.foley(pack, name, speed)


def add(dst, clip, gain=1, at=0):
    offset = round(at * SR)
    count = min(len(clip), len(dst) - offset)
    if count > 0:
        dst[offset:offset+count] += clip[:count] * gain


def crackle(n, seconds, density, gain):
    out = np.zeros(n)
    for onset in sorted(RNG.uniform(.015, seconds-.025, density)):
        length = int(RNG.uniform(.005, .026) * SR)
        t = np.arange(length) / SR
        pop = band(length, 1200, 8500) * np.exp(-t / .005)
        pop *= np.minimum(1, t/.0007)
        add(out, pop, gain * RNG.uniform(.4, 1), onset)
    return out


def descent(full=False, ultimate=False):
    seconds = 1.05 if ultimate else .95
    t = np.arange(round(seconds * SR)) / SR
    u = t / seconds
    n = len(t)
    approach = (.14 + .86 * u**1.1) * np.minimum(1, t/.024)
    flutter = .82 + .13*np.sin(2*np.pi*(6*t + 2*t*t)) + .05*np.sin(2*np.pi*17*t)
    # Broad air rush is an identifiable continuous layer, separate from grit.
    wind = (band(n, 150, 700)*(.13+.09*u)
            + band(n, 550, 2600)*(.17+.09*u)
            + band(n, 2400, 7600)*(.025+.06*u)) * approach * flutter
    if full or ultimate:
        wind += band(n, 45, 280)*.16*approach
    cloth = np.zeros(n)
    add(cloth, foley('rpg', 'cloth1.ogg', .68 if full else 1.02), .065, .025)
    wind += cloth * approach
    # A quiet descending whistle follows speed without turning into a tone.
    wind += np.sin(2*np.pi*(780*t - 250*t*t/seconds))*.012*approach
    grit = np.zeros(n)
    for index, onset in enumerate([.21, .42, .64, .80]):
        add(grit, foley('impact', 'impactMining_003.ogg', 1.6+index*.13), .015*(1+onset), onset)
    grit *= approach
    layers = {'wind': wind, 'grit': grit}
    if ultimate:
        # Fire is not merely a pitched copy of the wind: warm, irregular roar
        # plus discrete bright crackles remain audible throughout approach.
        billow = .70 + .18*np.sin(2*np.pi*8*t+.7) + .12*np.sin(2*np.pi*13*t)
        flame = (band(n, 45, 330)*.18 + band(n, 350, 1900)*.11) * billow * approach
        flame += crackle(n, seconds, 36, .12) * (.30+.70*u)
        layers['fire'] = flame
    return layers


def contact(full=False, ultimate=False):
    seconds = 2.15 if ultimate else (1.50 if full else 1.10)
    t = np.arange(round(seconds * SR)) / SR
    n = len(t)
    body = np.zeros(n)
    add(body, foley('impact', 'impactMining_001.ogg', .64 if full else 1.03), .59)
    add(body, foley('impact', 'impactSoft_heavy_001.ogg', .67 if full else .98), .31)
    # Contact onset stays within a few milliseconds of the actual hit event.
    attack = (1-np.exp(-t*1300))
    hard_edge = band(n, 600, 4000)*.19*attack*np.exp(-t*32)
    body += hard_edge
    low = 46 if full else 69
    drop = 90 if full else 110
    bass = np.sin(2*np.pi*(low*t + drop*.026*(1-np.exp(-t/.026))))
    bass *= (.48 if full else .24)*attack*np.exp(-t*(8 if full else 13))
    # Mid-low rock resonance echoes the reference's dense, heavy body and
    # remains audible on small speakers alongside the lower impact layer.
    mids = band(n, 160, 470)*(.25 if full else .18)*attack*np.exp(-t*(6.8 if full else 10))
    rumble = band(n, 25, 210)*(.17 if full else .045)*attack*np.exp(-t*(4.8 if full else 8))
    # The reference keeps weight after the transient. A short stone roll
    # prevents the landing from becoming only a click followed by silence.
    roll = (band(n, 140, 420)*(.20 if full else .065)
            + band(n, 30, 180)*(.23 if full else .040))
    roll *= attack*np.exp(-np.maximum(t-(.14 if full else .025),0)*(4.5 if full else 12))
    roll *= .85+.15*np.sin(2*np.pi*6.5*t+.3)
    gravel = np.zeros(n)
    onsets = [.047, .11, .19, .30, .43, .62, .81] if full else [.047, .14, .27, .42]
    for index, onset in enumerate(onsets):
        add(gravel, foley('impact', f'impactMining_{index%4:03}.ogg', 1.12+index*.16),
            .135*np.exp(-index*.30), onset)
    layers = {'contact': body, 'weight': bass+mids+rumble+roll, 'debris': gravel}
    if ultimate:
        layers['weight'] *= 1.35
        flame = (band(n, 30, 240)*.18 + band(n, 250, 2200)*.13)*attack*np.exp(-t*2.3)
        flame += crackle(n, seconds, 45, .085)*np.exp(-t*1.4)
        layers['fire'] = flame
    return layers


def stereoize(x):
    # Keep the initial impulse/low end centred; the very quiet room response
    # creates width without an audible discrete echo or opposite-phase bass.
    n = len(x)
    delayed = np.zeros(n)
    add(delayed, x, .055, .037)
    right_room = np.zeros(n)
    add(right_room, x, .044, .051)
    return np.column_stack([x*.99 + delayed, x*.99 + right_room])


def write_wav(path, stereo):
    assert stereo.ndim==2 and stereo.shape[1]==2
    assert np.max(np.abs(stereo)) < .999, f'Clipping: {path}'
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), 'wb') as f:
        f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
        f.writeframes((stereo*32767).astype('<i2').tobytes())


def export(name, layers, peak):
    summed = sum(layers.values())
    summed -= np.mean(summed)
    summed = np.tanh(summed*.70)
    # Gentle end fades prevent discontinuities; the impact attack is retained.
    summed[:72] *= np.linspace(0, 1, 72)
    summed[-720:] *= np.linspace(1, 0, 720)
    stereo = stereoize(summed)
    stereo *= peak / np.max(np.abs(stereo))
    stereo[-720:] *= np.linspace(1, 0, 720)[:, None]
    write_wav(OUT/(name+'.wav'), stereo)
    rms = float(np.sqrt(np.mean(stereo**2)))
    MANIFEST['clips'][name] = dict(seconds=len(stereo)/SR,
        peak_dbfs=round(float(20*np.log10(abs(stereo).max())),2),
        rms_dbfs=round(20*np.log10(rms),2), layers=list(layers),
        sha256=hashlib.sha256((OUT/(name+'.wav')).read_bytes()).hexdigest())
    # Editable stems are review/source assets, not additional runtime voices.
    scale = .65 / max(max(abs(x).max() for x in layers.values()), 1e-8)
    for layer, raw in layers.items():
        y=raw.copy()*scale
        y[:72] *= np.linspace(0,1,72); y[-720:] *= np.linspace(1,0,720)
        write_wav(STEMS/f'{name}-{layer}.wav', np.column_stack([y,y]))
    return stereo


def read_stereo(path):
    with wave.open(str(path)) as f:
        assert f.getframerate()==SR and f.getnchannels()==2
        return np.frombuffer(f.readframes(f.getnframes()), dtype='<i2').reshape(-1,2)/32768


def listen_clip(name, cues):
    length = max(at + len(clip)/SR for at, clip, gain in cues) + .25
    y = np.zeros((round(length*SR),2))
    for at, clip, gain in cues:
        start = round(at*SR)
        y[start:start+len(clip)] += clip*10**(gain/20)
    if abs(y).max()>.94: y *= .94/abs(y).max()
    write_wav(PREVIEW/name, y)


def analyze_references():
    for name in ['陨石1.wav','陨石2.wav']:
        path=Path('/Users/dev/Downloads')/name
        if not path.exists(): continue
        with wave.open(str(path)) as f:
            rate=f.getframerate()
            x=np.frombuffer(f.readframes(f.getnframes()),dtype='<i2')/32768
        spectrum=abs(np.fft.rfft(x*np.hanning(len(x))))**2
        hz=np.fft.rfftfreq(len(x),1/rate)
        MANIFEST['reference_analysis'][name] = dict(seconds=len(x)/rate,
            sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
            energy_bands_hz={f'{low}-{high}': round(float(spectrum[(hz>=low)&(hz<high)].sum()/spectrum.sum()),4)
                            for low,high in [(0,160),(160,500),(500,1800),(1800,5000),(5000,11025)]})


if __name__=='__main__':
    OUT.mkdir(parents=True, exist_ok=True)
    bank={}
    for full in [False,True]:
        suffix='full' if full else 'small'
        bank['fall-'+suffix]=export('fall-'+suffix,descent(full), .65 if full else .43)
        bank['rock-'+suffix]=export('rock-'+suffix,contact(full), .88 if full else .66)
    bank['ultimate-fall-full']=export('ultimate-fall-full',descent(True,True),.74)
    bank['ultimate-impact-full']=export('ultimate-impact-full',contact(True,True),.88)
    listen_clip('meteor-level-1-v3.wav',[(.15,bank['fall-small'],-5), (1.10,bank['rock-small'],-4)])
    # Actual level-ten volley: four stones, 180 ms stagger, bounded layer gain.
    count_gain=-min(6, 6*np.log10(4))
    listen_clip('meteor-level-10-v3.wav',[(.15+i*.18,bank['fall-full'],-3+count_gain) for i in range(4)]
                +[(1.10+i*.18,bank['rock-full'],-2+count_gain) for i in range(4)])
    seal=read_stereo(ROOT/'assets/spell-audio-v2/ultimate-seal-full.wav')
    listen_clip('ultimate-meteor-v3.wav',[(.15,seal,-5),(.40,bank['ultimate-fall-full'],-2),(1.45,bank['ultimate-impact-full'],-2)])
    analyze_references()
    MANIFEST['exporter_sha256']=hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
    (OUT/'manifest.json').write_text(json.dumps(MANIFEST,indent=2,ensure_ascii=False)+'\n')
    print('WF_METEOR_AUDIO_V3_OK: six stereo runtime cues, editable wind/fire/impact stems, L1/L10/ultimate listening clips')
