"""Original lightweight synthesized sample audio. No downloaded sound recordings."""
from pathlib import Path
import math, random, struct, wave
ROOT = Path(__file__).resolve().parents[1] / 'assets'
RATE = 22050
rng = random.Random(60103)
def save(name, seconds, fn):
    data = bytearray()
    for i in range(int(seconds * RATE)):
        t = i / RATE
        val = max(-1., min(1., fn(t)))
        data += struct.pack('<h', int(val * 24000))
    with wave.open(str(ROOT / (name + '.wav')), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(data)
def tone(t, f): return math.sin(math.tau * f * t)
def bell(t, f): return (tone(t,f)+.25*tone(t,f*2.76)+.13*tone(t,f*4.1))*math.exp(-t*3)
notes = [587.33,739.99,880,659.25,587.33,493.88,440,659.25]
def ambience(t):
    result = .034*tone(t,146.8)+.022*tone(t,220)+.016*tone(t,293.6)
    for i, f in enumerate(notes):
        age = (t-i*3) % 24
        if age < 5:
            result += .17*bell(age*.65,f)
    result += .006*rng.uniform(-1,1)
    return result * min(t/.2,1) * min((24-t)/.2,1)
save('ambience',24,ambience)
save('bell',1.8,lambda t: .7*bell(t,880))
save('quest',2,lambda t: sum(.3*bell(t-i*.15,f) for i,f in enumerate([523.25,659.25,783.99,1046.5]) if t>=i*.15))
save('bolt',.2,lambda t: .4*tone(t,1100-1800*t)*math.exp(-t*22))
save('hit',.15,lambda t: (.27*rng.uniform(-1,1)+.4*tone(t,190))*math.exp(-t*30))
save('fire',.45,lambda t: (.33*rng.uniform(-1,1)+.26*tone(t,110+200*t))*math.exp(-t*9))
save('wind',.4,lambda t: .2*rng.uniform(-1,1)*math.sin(math.pi*t/.4)**2)
save('water',.7,lambda t: .3*tone(t,500+350*math.sin(t*12))*math.exp(-t*6))
save('meteor',1.2,lambda t: (.5*tone(t,65-25*t)+.3*rng.uniform(-1,1))*math.exp(-t*5))
save('seal',1.3,lambda t: .28*(tone(t,293.6)+tone(t,440)+tone(t,587.2))*math.sin(math.pi*t/1.3)**2)
print('Generated 10 original WAVs in',ROOT)
