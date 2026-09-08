"""Reproducible impact mix: Kenney CC0 foley + original elemental layers.

Uses numpy and ffmpeg. Does not change the city music or existing spell assets.
Each hit has a crisp contact, a short low body, and a filtered elemental tail.
"""
from pathlib import Path
import json
import subprocess
import wave
import numpy as np

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "art/impact-sources"
OUT = ROOT / "assets/impact-audio"
RATE = 48000
rng = np.random.default_rng(20260906)
cache = {}
manifest = {}

def sample(pack, name, speed=1.0):
    key = (pack, name)
    if key not in cache:
        raw = subprocess.check_output(["ffmpeg", "-v", "error", "-i", str(SOURCE/pack/name),
                                       "-f", "f32le", "-ac", "1", "-ar", str(RATE), "-"])
        data = np.frombuffer(raw, dtype="<f4").copy()
        active = np.flatnonzero(np.abs(data) > 0.012 * np.max(np.abs(data)))
        data = data[max(0, active[0]-60):active[-1]+1] if len(active) else data
        cache[key] = data / max(np.max(np.abs(data)), 1e-5)
    data = cache[key]
    return np.interp(np.arange(0, len(data)-1, speed), np.arange(len(data)), data)

def lowpass(data, hz):
    # A stable one-pole low pass; used on texture tails, never on contact attacks.
    a = 1-np.exp(-2*np.pi*hz/RATE)
    result = np.empty_like(data)
    value = 0.0
    for i, x in enumerate(data):
        value += a*(x-value)
        result[i] = value
    return result

def add(dst, data, gain=1, delay=0):
    start = int(delay*RATE)
    length = min(len(data), len(dst)-start)
    if length>0:
        dst[start:start+length] += data[:length]*gain

def save(name, mono, gain=0.82):
    # Remove DC, fade both ends, retain headroom. Very narrow stereo tail.
    mono -= np.mean(mono)
    mono[:48] *= np.linspace(0,1,48)
    mono[-480:] *= np.linspace(1,0,480)
    mono = np.tanh(mono*1.25)
    mono *= gain/max(np.max(np.abs(mono)),1e-5)
    delay = int(RATE*0.017)
    tail = np.zeros_like(mono)
    tail[delay:] = mono[:-delay]*0.06
    stereo = np.stack([mono, mono*0.94+tail],axis=1)
    pcm = (np.clip(stereo,-0.99,0.99)*32767).astype("<i2")
    with wave.open(str(OUT/(name+".wav")),"wb") as w:
        w.setnchannels(2); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(pcm.tobytes())
    manifest[name] = {"seconds":round(len(mono)/RATE,3), "peak_dbfs":round(20*np.log10(np.max(np.abs(stereo))),2)}

OUT.mkdir(parents=True,exist_ok=True)
for variant in range(3):
    speed = [0.94,1.0,1.06][variant]
    body = sample("impact",f"impactSoft_heavy_{variant:03}.ogg",speed)
    crack = sample("impact",f"impactWood_medium_{variant:03}.ogg",speed)
    stone = sample("impact",f"impactMining_{variant:03}.ogg",speed)
    glass = sample("impact",f"impactGlass_light_{variant:03}.ogg",speed)
    cloth = sample("rpg",f"cloth{variant+1}.ogg",speed)
    for kind in ["physical","fire","wind","earth","water","critical","meteor","death","launch","dodge"]:
        seconds = {"meteor":1.35,"death":0.85,"earth":0.68,"fire":0.50}.get(kind,0.34)
        t = np.arange(int(seconds*RATE))/RATE
        mix = np.zeros_like(t)
        noise = rng.normal(0,1,len(t))
        boom = np.sin(2*np.pi*(82*t+1.3*(1-np.exp(-t*45))))*np.exp(-t*19)
        if kind in ["physical","critical","death"]:
            add(mix,body,0.64); add(mix,crack,0.22)
            mix += boom*(0.21 if kind=="physical" else 0.34)
            if kind=="critical":
                add(mix,glass,0.20)
                mix += lowpass(noise,3800)*np.exp(-t*35)*0.09
            if kind=="death":
                add(mix,cloth,0.3,0.13); add(mix,body,0.48,0.26)
        elif kind in ["fire","earth","meteor"]:
            add(mix,crack,0.4); add(mix,stone,0.48 if kind!="fire" else 0.22)
            decay = {"fire":11,"earth":8,"meteor":4.5}[kind]
            mix += lowpass(noise,1300 if kind=="fire" else 650)*np.exp(-t*decay)*0.9
            mix += np.sin(2*np.pi*(58*t+1.2*(1-np.exp(-t*23))))*np.exp(-t*(8 if kind=="meteor" else 14))*0.42
            if kind=="meteor":
                add(mix,stone,0.25,0.11); add(mix,stone[::-1],0.07,0.35)
        elif kind=="water":
            add(mix,glass,0.68); add(mix,body,0.20)
            mix += np.sin(2*np.pi*(1250*t-200*t*t))*np.exp(-t*25)*0.09
        elif kind=="wind":
            add(mix,cloth,0.3); add(mix,crack,0.23)
            mix += (noise-lowpass(noise,700))*np.sin(np.pi*np.minimum(t/.12,1))**2*np.exp(-t*15)*0.11
        elif kind=="launch":
            add(mix,cloth,0.15)
            envelope = (1-np.exp(-t*450))*np.exp(-t*28)
            mix += np.sin(2*np.pi*(1350*t-1800*t*t))*envelope*0.24
            mix += lowpass(noise,2200)*envelope*0.16
        else:
            add(mix,cloth,0.5)
            mix += lowpass(noise,2200)*np.sin(np.pi*t/seconds)**2*0.12
        save(f"{kind}-{variant}",mix,0.56 if kind in ["launch","dodge"] else 0.82)
    for terrain in ["grass","concrete"]:
        data = sample("impact",f"footstep_{terrain}_{variant:03}.ogg",speed)
        mix = np.zeros(int(RATE*.30)); add(mix,data)
        save(f"step-{terrain}-{variant}",mix,0.52)

(OUT/"manifest.json").write_text(json.dumps(manifest,indent=2)+"\n")
print(f"WF_IMPACT_AUDIO_OK: {len(manifest)} stereo effects; 48 kHz; peak <= -1.7 dBFS")
