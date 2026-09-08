"""Original layered spell Foley, 48 kHz stereo. No source-video audio is copied."""
from pathlib import Path
import wave
import numpy as np

OUT = Path(__file__).resolve().parents[1] / 'assets/combat-audio'
OUT.mkdir(parents=True, exist_ok=True)
SR = 48000
rng = np.random.default_rng(90426)

def noise(n, cutoff, high=0):
    freqs = np.fft.rfftfreq(n, 1/SR)
    filt = np.exp(-(freqs/cutoff)**4)
    if high: filt *= 1-np.exp(-(freqs/high)**4)
    x = np.fft.irfft(np.fft.rfft(rng.normal(size=n))*filt, n)
    return x/(np.std(x)+1e-8)

def make(kind, full):
    duration = dict(fire=1.65, wind=2.2, fall=.8, rock=1.2, ice=1.6, hurt=.25, death=.65)[kind]
    t = np.arange(int(duration*SR))/SR
    n = len(t)
    attack = 1-np.exp(-t*180)
    if kind == 'fire':
        body = noise(n, 1400 if full else 1800)*np.exp(-t*(3 if full else 6))
        thump = np.sin(2*np.pi*(68*t+4*(1-np.exp(-t*16))))*np.exp(-t*13)
        crack = noise(n, 11000, 1800)*np.exp(-t*30)
        x = body*.34 + thump*(.46 if full else .18) + crack*.18
    elif kind == 'wind':
        swirl = noise(n, 2500, 200)*(0.58+0.42*np.sin(t*2*np.pi*7))
        airy = noise(n, 6500, 2600)*.07
        x=(swirl*.28+airy)*(np.sin(np.minimum(t/duration,1)*np.pi)**.7)
        if full: x += np.sin(2*np.pi*(160*t+8*np.sin(t*3)))*.055*np.sin(t/duration*np.pi)
    elif kind == 'fall':
        sweep = np.sin(2*np.pi*(600*t-230*t*t))
        x = (noise(n, 3600, 450)*.17+sweep*.08)*np.sin(t/duration*np.pi)**.6
    elif kind == 'rock':
        x = noise(n, 550)*np.exp(-t*7)*.32
        x += np.sin(2*np.pi*73*t)*np.exp(-t*17)*(.46 if full else .20)
        for offset in [.02,.07,.14,.24,.38]:
            local = np.maximum(t-offset,0)
            x += noise(n, 5700, 1400)*np.exp(-local*65)*(t>=offset)*.11
    elif kind == 'ice':
        x=noise(n, 7000, 2500)*np.exp(-t*14)*.16
        for i,f in enumerate([640,1031,1778,2713,4099,5381] if full else [1031,1778,2713]):
            onset=i*.026
            local=np.maximum(t-onset,0)
            x += np.sin(2*np.pi*f*local)*(t>=onset)*np.exp(-local*(3+i*.6))*.095
        x += noise(n, 2400)*np.exp(-t*7)*.11
    elif kind == 'hurt':
        x=noise(n, 2300)*np.exp(-t*40)*.25+np.sin(2*np.pi*(180*t-230*t*t))*np.exp(-t*27)*.22
    else:
        x=noise(n, 1100)*np.exp(-t*10)*.18+np.sin(2*np.pi*(190*t-80*t*t))*np.exp(-t*6)*.18
    x*=attack
    if not full: x*=.72
    stereo=np.column_stack([x,x])
    # Sparse early reflections create width without a long, muddy combat tail.
    for delay,gain in [(0.041,.15),(.079,.09),(.131,.05)]:
        shift=int(delay*SR)
        stereo[shift:,0]+=x[:-shift]*gain
        shift+=int(.009*SR)
        stereo[shift:,1]+=x[:-shift]*gain
    stereo*=np.minimum((duration-t)/.04,1)[:,None]
    peak=np.max(np.abs(stereo))
    if peak>.92: stereo*=.92/peak
    return stereo

for kind in ['fire','wind','fall','rock','ice','hurt','death']:
    for full in [False,True]:
        value=make(kind,full)
        path=OUT/f'{kind}-{"full" if full else "small"}.wav'
        with wave.open(str(path),'wb') as f:
            f.setnchannels(2); f.setsampwidth(2); f.setframerate(SR)
            f.writeframes((value*32767).astype('<i2').tobytes())
        print(path.name, 'peak',round(float(np.max(np.abs(value))),3))
