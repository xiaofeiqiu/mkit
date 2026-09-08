"""Original staged spell design using existing Kenney CC0 Foley and synthesis.

The reference movie guides action timing only. Its audio is never sampled into
these files. No city music, impact-mix assets, or user volume settings are edited.
"""
from pathlib import Path
import json
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/spell-audio-v2"
SOURCE = ROOT / "art/impact-sources"
SR = 48000
RNG = np.random.default_rng(9061740)
CACHE = {}
MANIFEST = {}


def foley(pack, name, speed=1.0):
    key = (pack, name)
    if key not in CACHE:
        raw = subprocess.check_output(["/opt/homebrew/bin/ffmpeg", "-v", "error", "-i",
            str(SOURCE / pack / name), "-f", "f32le", "-ac", "1", "-ar", str(SR), "-"])
        y = np.frombuffer(raw, dtype="<f4").copy()
        active = np.flatnonzero(abs(y) > max(abs(y)) * .012)
        if len(active): y = y[max(0, active[0]-48):active[-1]+1]
        CACHE[key] = y / max(float(max(abs(y))), 1e-6)
    y = CACHE[key]
    return np.interp(np.arange(0, len(y)-1, speed), np.arange(len(y)), y)


def band(n, lo, hi):
    hz = np.fft.rfftfreq(n, 1/SR)
    filt = np.exp(-(hz/hi)**4)
    if lo: filt *= 1-np.exp(-(hz/lo)**4)
    y = np.fft.irfft(np.fft.rfft(RNG.normal(size=n))*filt, n)
    return y / max(np.std(y), 1e-5)


def add(dst, src, gain, delay=0):
    i = int(delay*SR)
    n = min(len(src), len(dst)-i)
    if n > 0: dst[i:i+n] += src[:n]*gain


def make(kind, full):
    seconds = {"fire-ignite":.40, "fire":1.8, "wind":.7, "wind-loop":2.,
        "fall":.95, "rock":1.7, "ice-seal":.52, "ice-rise":.88,
        "ice":1.25, "ice-settle":1.15, "ultimate-seal":1.3,
        "ultimate-fall":1.05, "ultimate-impact":2.7}[kind]
    t = np.arange(round(seconds*SR))/SR
    x = np.zeros_like(t)
    n = len(x)
    intensity = 1.0 if full else .72
    stone = foley("impact", "impactMining_001.ogg", .70 if full else .96)
    glass = foley("impact", "impactGlass_medium_002.ogg", .8 if full else 1.12)
    body = foley("impact", "impactSoft_heavy_001.ogg", .67 if full else .92)
    if kind in ["fire-ignite", "ultimate-seal", "ice-seal"]:
        u = t/seconds
        if kind == "fire-ignite":
            x = (band(n,100,1700)*.30 + band(n,0,150)*.15)*np.sin(np.pi*u)**.9
        else:
            add(x, foley("impact", "impactBell_heavy_002.ogg", .55 if kind=="ultimate-seal" else 1.18), .16)
            x += band(n,400,2700)*.075*np.sin(np.pi*u)
            frequencies = [148,223,301] if kind=="ultimate-seal" else [659,1041,1531]
            for i, frequency in enumerate(frequencies):
                x += np.sin(2*np.pi*(frequency*t+(4+i)*t*t))*.032*np.sin(np.pi*u)**.6
            if kind=="ultimate-seal": x += band(n,0,240)*.22*u**1.5
    elif kind in ["fire","ultimate-impact"]:
        add(x, body, .3); add(x, stone, .12)
        slow = 2.1 if kind=="ultimate-impact" else 3.1
        x += band(n,0,450)*.36*(1-np.exp(-t*85))*np.exp(-t*slow)
        x += band(n,200,2200)*.15*np.exp(-t*8)
        x += np.sin(2*np.pi*(52*t+1.4*(1-np.exp(-t*24))))*.33*intensity*np.exp(-t*5)
        for i, onset in enumerate([.13,.28,.44,.68,.93]):
            local = np.maximum(t-onset,0)
            x += band(n,800,5200)*.024*(t>=onset)*np.exp(-local*48)
        if kind=="ultimate-impact":
            add(x, stone, .25, .12); add(x, body, .18, .23)
            x += band(n,0,130)*.16*np.exp(-t*1.7)
    elif kind in ["wind","wind-loop"]:
        # Periodic FFT noise and integer-period modulation give a seamless loop.
        u = t/seconds
        x = band(n,80,520)*(.13+.07*np.sin(2*np.pi*3*u))
        x += band(n,450,2200)*(.11+.09*np.sin(2*np.pi*5*u+.7))
        x += band(n,1700,5200)*.025*(1+np.sin(2*np.pi*7*u))
        if kind=="wind":
            x *= np.sin(np.pi*u)**.75
            add(x, foley("rpg","cloth3.ogg",.65), .12)
    elif kind in ["fall","ultimate-fall"]:
        u = t/seconds
        # Audible rushing air grows throughout descent; coarse grit is separate
        # from the actual contact sound, which is triggered by impact gameplay.
        x = (band(n,0,330)*.18 + band(n,350,2800)*.16)*(0.10+.9*u**1.7)
        x += np.sin(2*np.pi*(240*t-70*t*t/seconds))*.055*u
        for onset in [.20,.39,.56,.72]:
            add(x, foley("impact","impactMining_003.ogg",1.75), .026, onset)
        if full: x += band(n,0,150)*.10*u**2
    elif kind=="rock":
        add(x, stone, .50); add(x, body, .30)
        x += band(n,0,330)*.25*np.exp(-t*4.7)
        x += np.sin(2*np.pi*(64*t+1.2*(1-np.exp(-t*26))))*.26*intensity*np.exp(-t*6)
        for i, onset in enumerate([.07,.16,.29,.44,.65,.89]):
            add(x, foley("impact",f"impactMining_{i%4:03}.ogg",1.15+i*.13), .10*np.exp(-i*.32), onset)
    elif kind=="ice-rise":
        u = t/seconds
        add(x, glass[::-1], .20)
        x += band(n,0,450)*.18*np.sin(np.pi*u)**.8
        x += band(n,700,3800)*.09*np.sin(np.pi*u)**.7
        for i, onset in enumerate([.03,.18,.36,.57]):
            add(x, foley("impact",f"impactGlass_medium_{i:03}.ogg",.8+i*.11), .16, onset)
    elif kind=="ice":
        add(x, glass, .48); add(x, body, .22)
        x += band(n,0,330)*.21*np.exp(-t*6)
        for i, f in enumerate([733,1177,1871,2893]):
            x += np.sin(2*np.pi*f*t)*.022*np.exp(-t*(3+i))
    else: # ice folds back into a shorter cone, then a delicate crystal tail
        for i, onset in enumerate([0,.12,.29,.49]):
            add(x, foley("impact",f"impactGlass_light_{i:03}.ogg",.85+i*.09), .23*np.exp(-i*.30), onset)
        x += band(n,600,4100)*.026*np.exp(-t*3)
    return x, kind=="wind-loop"


def save(name, x, full, loop):
    x -= np.mean(x)
    if not loop:
        x[:144] *= np.linspace(0,1,144)
        x[-1920:] *= np.linspace(1,0,1920)
    x = np.tanh(x*1.3)
    target = .84 if full else .64
    x *= target/max(float(max(abs(x))),1e-5)
    # Very short reflected ambience, with no dry attack smeared across channels.
    delay = round(.017*SR)
    side = np.roll(x,delay)*.085
    if not loop: side[:delay] = 0
    stereo = np.column_stack([x*.96+side*.2, x*.94+side*.6])
    if not loop: stereo[-1920:] *= np.linspace(1,0,1920)[:,None]
    with wave.open(str(OUT/(name+".wav")),"wb") as stream:
        stream.setnchannels(2); stream.setsampwidth(2); stream.setframerate(SR)
        stream.writeframes((np.clip(stereo,-.98,.98)*32767).astype("<i2").tobytes())
    MANIFEST[name] = {"seconds":len(x)/SR,"loop":loop,
        "peak_dbfs":round(float(20*np.log10(max(abs(stereo).max(),1e-6))),2),
        "rms_dbfs":round(float(20*np.log10(np.sqrt(np.mean(stereo**2)))),2)}


if __name__ == "__main__":
    OUT.mkdir(parents=True,exist_ok=True)
    for kind in ["fire-ignite","fire","wind","wind-loop","fall","rock",
                 "ice-seal","ice-rise","ice","ice-settle",
                 "ultimate-seal","ultimate-fall","ultimate-impact"]:
        for full in [False,True]:
            sound, loop = make(kind,full)
            save(f'{kind}-{"full" if full else "small"}',sound,full,loop)
    (OUT/"manifest.json").write_text(json.dumps(MANIFEST,indent=2)+"\n")
    print(f"WF_SPELL_AUDIO_OK: {len(MANIFEST)} staged stereo effects at 48 kHz")
