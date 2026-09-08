"""Original Bellwake scores, editable MIDI, sampled stems and seamless game loops.

Run with the music venv (mido/numpy/scipy/soundfile) and FluidSynth + FFmpeg.
The reference recordings are not sampled, transcribed, or embedded in the score.
"""
from __future__ import annotations

import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
import json
import hashlib
from pathlib import Path
import random
import shutil
import subprocess
import tempfile

import mido
import numpy as np
from scipy import signal
import soundfile as sf

SAMPLE = Path(__file__).resolve().parents[1]
ART = SAMPLE / "art/audio/original-score"
OUT = SAMPLE / "assets/music"
SFONT = SAMPLE / "art/audio/vendor/GeneralUser-GS.sf2"
SR = 48000
TPB = 960


@dataclass
class Part:
    name: str
    channel: int
    program: int
    level: int
    pan: int
    group: str
    notes: list = field(default_factory=list)
    controls: list = field(default_factory=list)


class Score:
    def __init__(self, name, title, bpm, bars, seed, key):
        self.name, self.title, self.bpm, self.bars, self.key = name, title, bpm, bars, key
        self.tempo = mido.bpm2tempo(bpm)
        self.seconds = bars * 4 * self.tempo / 1_000_000
        self.rng = random.Random(seed)
        self.parts = {}
        self.sections = []

    def part(self, name, ch, program, level, pan, group):
        self.parts[name] = Part(name, ch, program, level, pan, group)

    def note(self, part, beat, duration, pitch, velocity=75, looseness=.013):
        if pitch is None:
            return
        # Small repeatable variations, never a random melody. Keep bar 1 on the grid.
        onset = max(0, beat + (self.rng.uniform(-looseness, looseness) if beat else 0))
        vel = int(np.clip(velocity + self.rng.randint(-4, 4), 1, 119))
        self.parts[part].notes.append((onset, max(.06, duration), int(pitch), vel))

    def chord(self, part, beat, duration, notes, velocity=60, roll=0):
        for i, pitch in enumerate(notes):
            self.note(part, beat + i * roll, duration, pitch, velocity)

    def melody(self, part, bar, phrase, velocity=83, shift=0):
        beat = bar * 4
        assert abs(sum(d for _, d in phrase) - 4) < .001, (bar, phrase)
        for i, (pitch, length) in enumerate(phrase):
            self.note(part, beat, length * (.88 if length <= .5 else .94),
                      None if pitch is None else pitch + shift,
                      velocity + (3 if i == 0 else -1))
            beat += length

    def expression(self, part, bar, strength):
        for offset, amount in [(0, -9), (.6, -2), (1.6, 4), (2.7, 0), (3.65, -7)]:
            self.parts[part].controls.append((bar * 4 + offset, 11, int(np.clip(strength + amount, 32, 122))))

    def midi(self, path, group=None, repeats=1):
        midi = mido.MidiFile(ticks_per_beat=TPB)
        meta = mido.MidiTrack()
        midi.tracks.append(meta)
        meta.extend([mido.MetaMessage("track_name", name=self.title),
                     mido.MetaMessage("set_tempo", tempo=self.tempo),
                     mido.MetaMessage("time_signature", numerator=4, denominator=4),
                     mido.MetaMessage("key_signature", key=self.key)])
        last = 0
        for rep in range(repeats):
            for bar, label in self.sections:
                tick = round((rep * self.bars + bar) * 4 * TPB)
                meta.append(mido.MetaMessage("marker", text=label, time=tick-last))
                last = tick
        meta.append(mido.MetaMessage("end_of_track", time=round(self.bars*4*repeats*TPB)-last))
        for part in self.parts.values():
            if group is not None and part.group != group:
                continue
            track = mido.MidiTrack()
            midi.tracks.append(track)
            track.append(mido.MetaMessage("track_name", name=part.name))
            track.append(mido.Message("program_change", channel=part.channel, program=part.program))
            for control, value in [(7, part.level), (10, part.pan), (11, 100), (91, 38), (93, 0)]:
                track.append(mido.Message("control_change", channel=part.channel, control=control, value=value))
            events = []
            for rep in range(repeats):
                base = self.bars * 4 * rep
                for beat, length, pitch, vel in part.notes:
                    events.append((round((base+beat)*TPB), 2,
                                   mido.Message("note_on", channel=part.channel, note=pitch, velocity=vel)))
                    events.append((round((base+beat+length)*TPB), 0,
                                   mido.Message("note_off", channel=part.channel, note=pitch, velocity=0)))
                for beat, cc, val in part.controls:
                    events.append((round((base+beat)*TPB), 1,
                                   mido.Message("control_change", channel=part.channel, control=cc, value=val)))
            last = 0
            for tick, _, msg in sorted(events, key=lambda e: (e[0], e[1])):
                track.append(msg.copy(time=max(0, tick-last)))
                last = tick
            track.append(mido.MetaMessage("end_of_track", time=max(0,round(self.bars*4*repeats*TPB)-last)))
        midi.save(path)


# All pitches below are deliberately composed MIDI notes, not extracted reference notes.
CITY_A = [
    [(74,1),(78,.5),(81,.5),(78,1),(76,.5),(74,.5)],
    [(73,1),(76,.5),(78,.5),(81,1.5),(79,.5)],
    [(78,1),(76,.5),(74,.5),(78,1),(83,1)],
    [(79,1),(78,.5),(76,.5),(74,1),(71,1)],
    [(76,1),(78,.5),(79,.5),(81,1),(79,.5),(78,.5)],
    [(76,1),(73,1),(71,.5),(73,.5),(76,1)],
    [(78,1.5),(81,.5),(76,1),(74,1)],
    [(79,.5),(78,.5),(76,1),(73,1),(69,1)],
    [(74,.5),(76,.5),(78,1),(81,1),(86,1)],
    [(85,1),(81,.5),(78,.5),(76,1),(73,1)],
    [(83,1.5),(81,.5),(78,1),(74,1)],
    [(79,1),(83,.5),(81,.5),(79,1),(78,1)],
    [(76,.5),(79,.5),(83,1),(81,.5),(79,.5),(78,1)],
    [(76,1.5),(73,.5),(69,1),(73,1)],
    [(74,2),(78,1),(76,.5),(74,.5)],
    [(73,1),(76,1),(69,1),(None,1)],
]
CITY_B = [
    [(71,1.5),(74,.5),(78,1),(76,1)],
    [(73,1),(69,.5),(73,.5),(76,1),(78,1)],
    [(79,1.5),(78,.5),(74,1),(71,1)],
    [(69,1),(74,1),(78,1),(76,1)],
    [(76,.5),(79,.5),(78,1),(76,1),(71,1)],
    [(73,1),(76,.5),(79,.5),(81,1),(79,1)],
    [(78,1),(76,.5),(74,.5),(69,1),(74,1)],
    [(78,1),(81,1),(84,1),(81,1)],
    [(83,1),(81,.5),(79,.5),(78,1),(79,1)],
    [(81,1.5),(79,.5),(76,1),(73,1)],
    [(78,1),(81,.5),(78,.5),(76,1),(73,1)],
    [(74,1.5),(78,.5),(83,1),(81,1)],
    [(79,1),(78,.5),(76,.5),(74,1),(71,1)],
    [(73,.5),(76,.5),(79,1),(81,1),(73,1)],
    [(74,2),(78,1),(81,1)],
    [(79,1),(76,1),(73,1),(None,1)],
]


def city_score():
    s = Score("bellwake_city", "Bellwake - Sunlit Promenade", 104, 48, 60209, "D")
    for row in [
        ("Flute",0,73,91,55,"woodwinds"),("Oboe",1,68,66,77,"woodwinds"),
        ("Clarinet",2,71,79,72,"woodwinds"),("Legato strings",3,48,55,64,"strings"),
        ("Pizzicato",4,45,70,82,"strings"),("Harp",5,46,67,44,"plucked"),
        ("Nylon guitar",6,24,84,40,"plucked"),("Double bass",7,43,82,61,"bass"),
        ("French horns",8,60,47,74,"accents"),("Light percussion",9,0,62,64,"percussion"),
        ("Glockenspiel",10,9,52,85,"accents"),("Bassoon",11,70,49,52,"bass"),
    ]: s.part(*row)
    # Bass and closed upper voicing, including suspensions and secondary dominant D7.
    D=(38,[62,66,69,73]); AC=(37,[61,64,69,71]); B=(35,[62,66,69,71])
    G=(31,[62,66,67,71]); E=(40,[62,64,67,71]); A=(33,[61,64,67,69])
    DF=(30,[62,66,69,73]); F=(30,[61,64,66,69]); D7=(38,[62,66,69,72])
    harmony=[D,AC,B,G,E,A,DF,A,D,AC,B,G,E,A,D,A]
    bridge=[B,F,G,DF,E,A,D,D7,G,A,F,B,E,A,D,A]
    all_chords=harmony+bridge+harmony
    s.sections=[(0,"A - morning streets / flute"),(8,"A2 - woodwind answers"),
                (16,"B - garden courtyard / clarinet"),(24,"B2 - open square"),
                (32,"A reprise - full promenade"),(44,"turnaround / seamless return")]
    for bar,(root,chord) in enumerate(all_chords):
        b=bar*4
        middle=16<=bar<32
        lift=5 if 32<=bar<44 else 0
        phrase=(CITY_B if middle else CITY_A)[bar%16]
        lead="Clarinet" if middle else "Flute"
        s.melody(lead,bar,phrase,82+lift,shift=-12 if middle else 0)
        s.expression(lead,bar,103)
        # Counterlines occupy phrase endings and leave breathing room for the lead.
        if bar%4 in (2,3):
            response=[chord[1],chord[2],chord[0]+12,chord[1]]
            for j,n in enumerate(response): s.note("Oboe",b+2+j*.5,.42,n,55+lift)
        # Inversions keep the sustained middle register smooth.
        s.chord("Legato strings",b+.05,3.90,[n-12 for n in chord[:3]],55+lift)
        s.expression("Legato strings",bar,79+(8 if middle else 0)+lift)
        for beat,idx in [(0,0),(1.5,2),(2.5,1),(3.5,2)]:
            if bar>=4 or beat in (0,2.5): s.note("Pizzicato",b+beat,.32,chord[idx],59+lift)
        # Fingerpicked guitar; bass, inner voices and upper voice have distinct weights.
        pattern=[(0,0),(0.5,2),(1,1),(1.5,3),(2,0),(2.5,2),(3,1),(3.5,2)]
        for beat,idx in pattern:
            s.note("Nylon guitar",b+beat,.64,chord[idx]-12,66 if idx==0 else 54)
        if bar%2==0:
            s.chord("Harp",b+.06,1.6,[chord[0],chord[1],chord[2],chord[0]+12],48,roll=.055)
        if bar%4==3:
            for j,n in enumerate([chord[0],chord[1],chord[2],chord[0]+12]):
                s.note("Harp",b+3+j*.25,.65,n,47+j*2)
        s.note("Double bass",b,1.65,root,74)
        s.note("Double bass",b+2,1.25,root+7 if bar%2 else root,65)
        next_root=all_chords[(bar+1)%48][0]
        if bar%2: s.note("Double bass",b+3.5,.38,next_root+(1 if root>next_root else -1),51)
        if middle or 32<=bar<44:
            s.note("Bassoon",b+.06,2.85,root+12,47)
        if bar in (7,15,23,31,39,47):
            s.chord("French horns",b+1,2.6,[n-12 for n in chord[:3]],49)
            s.expression("French horns",bar,79)
        if bar%8 in (0,4) and bar not in (16,20):
            s.note("Glockenspiel",b+.02,1.2,chord[0]+24,45)
            s.note("Glockenspiel",b+2.5,1.1,chord[2]+12,39)
        if bar>=4:
            for beat in (0,2): s.note("Light percussion",b+beat,.12,36,39)
            for beat in (1,3): s.note("Light percussion",b+beat,.1,37,44)
            for j in range(8): s.note("Light percussion",b+j*.5,.09,70,37+(8 if j%2 else 0))
            if bar%4==3:
                for beat in (2.5,3,3.5): s.note("Light percussion",b+beat,.1,54,36)
    return s


BATTLE_A=[
    [(74,.5),(69,.5),(77,1),(76,.5),(74,.5),(69,1)],
    [(76,.5),(77,.5),(76,.5),(74,.5),(69,1),(72,1)],
    [(74,1),(77,.5),(79,.5),(77,1),(74,1)],
    [(72,1),(69,.5),(72,.5),(77,1),(76,1)],
    [(74,.5),(70,.5),(67,1),(70,.5),(74,.5),(77,1)],
    [(76,.5),(74,.5),(69,1),(65,.5),(69,.5),(74,1)],
    [(76,1),(79,.5),(77,.5),(76,1),(70,1)],
    [(73,.5),(76,.5),(81,1),(79,.5),(76,.5),(73,1)],
    [(74,.5),(77,.5),(81,1),(77,.5),(76,.5),(74,1)],
    [(76,1),(74,.5),(72,.5),(69,1),(72,1)],
    [(77,1),(82,.5),(81,.5),(77,1),(74,1)],
    [(79,.5),(77,.5),(76,1),(72,1),(69,1)],
    [(70,1),(74,.5),(77,.5),(79,1),(77,1)],
    [(76,.5),(74,.5),(69,1),(74,1),(77,1)],
    [(76,1),(79,.5),(82,.5),(79,1),(76,1)],
    [(73,1),(76,.5),(79,.5),(81,1),(None,1)],
]
BATTLE_B=[
    [(77,1.5),(74,.5),(70,1),(74,1)],
    [(76,1),(79,.5),(76,.5),(72,1),(67,1)],
    [(77,1),(81,1),(79,.5),(77,.5),(76,1)],
    [(74,1.5),(77,.5),(81,1),(77,1)],
    [(79,1),(77,.5),(74,.5),(70,1),(74,1)],
    [(77,.5),(76,.5),(72,1),(69,1),(72,1)],
    [(76,1),(79,1),(82,1),(79,1)],
    [(81,1),(79,.5),(76,.5),(73,1),(None,1)],
]


def battle_score():
    s=Score("rift_battle","Riftbound - Against the Closing Gate",144,64,60503,"Dm")
    for row in [
        ("String ostinato",0,48,81,47,"strings"),("Solo violin",1,40,66,39,"strings"),
        ("Cellos",2,42,86,79,"bass"),("Double bass",3,43,83,61,"bass"),
        ("French horns",4,60,89,67,"brass"),("Trumpets",5,56,70,53,"brass"),
        ("Trombones",6,57,72,80,"brass"),("Timpani",7,47,85,55,"percussion"),
        ("Wordless choir",8,52,43,66,"atmosphere"),("Orchestral percussion",9,48,88,64,"percussion"),
        ("Tubular bells",10,14,55,87,"accents"),("Taiko",11,116,79,77,"percussion"),
        ("Harp",12,46,55,37,"accents"),
    ]: s.part(*row)
    D=(38,[62,65,69]); DC=(36,[62,65,69]); B=(34,[62,65,70]); F=(33,[60,65,69])
    G=(31,[62,67,70]); DF=(29,[62,65,69]); E=(40,[64,67,70]); A=(33,[61,64,67,69])
    C=(36,[60,64,67]); EB=(39,[63,67,70])
    a=[D,DC,B,F,G,DF,E,A,D,DC,B,F,G,DF,E,A]
    b=[B,C,F,D,G,F,E,A]*2
    breakdown=[D,D,B,EB,G,DF,E,A]
    climax=[D,DC,B,EB,G,E,A,A]
    harmony=a+b+breakdown+a+climax
    s.sections=[(0,"A - pursuit"),(8,"A2 - counterattack"),(16,"B - fighting forward"),
                (24,"B2 - rising pressure"),(32,"C - heartbeat / held breath"),
                (40,"A3 - renewed assault"),(56,"D - closing gate / dominant return")]
    for bar,(root,chord) in enumerate(harmony):
        beat=bar*4
        break_section=32<=bar<40
        climax_section=bar>=56
        energy=10 if climax_section else (4 if bar>=40 else 0)
        # A low 3+3+2 ostinato makes the pulse urgent without washing out the melody.
        pulse=[0,0,2,0,1,2,0,2]
        for j,idx in enumerate(pulse):
            s.note("Cellos",beat+j*.5,.30,chord[idx]-24,68+(14 if j in (0,3,6) else 0)+energy)
        if not break_section:
            for j in range(16):
                pattern=[0,2,1,2,0,2,1,2,1,2,0,2,1,2,0,2]
                pitch=chord[pattern[j]]+(12 if j in (7,15) and bar%4==3 else 0)
                s.note("String ostinato",beat+j*.25,.145,pitch,
                       57+(15 if j%4==0 else (6 if j%2==0 else 0))+energy,looseness=.008)
        else:
            s.chord("String ostinato",beat+.04,3.8,chord,48)
            s.expression("String ostinato",bar,65+(bar-32)*3)
        for when,length,n in [(0,1.30,root),(1.5,.32,root),(2,1.20,root),(3.5,.30,root+12)]:
            s.note("Double bass",beat+when,length,n,75+energy)
        if break_section:
            # Leave space, then rebuild with rising violin and horn suspensions.
            if bar>=36:
                s.note("French horns",beat+.1,2.7,chord[0],66+(bar-36)*3)
                s.expression("French horns",bar,88)
            s.note("Solo violin",beat+.1,3.7,chord[1]+12,55)
            s.expression("Solo violin",bar,75+(bar-32)*3)
        else:
            phrase=BATTLE_B[bar%8] if 16<=bar<32 else BATTLE_A[(bar if bar<32 else bar-40)%16]
            # Revoice the final Phrygian colour rather than playing a major-third clash.
            if bar==59: phrase=[(79,1),(75,.5),(74,.5),(70,1),(67,1)]
            s.melody("French horns",bar,phrase,84+energy,shift=-12)
            s.expression("French horns",bar,106)
            if bar%8>=4 or climax_section:
                s.melody("Solo violin",bar,phrase,69+energy)
                s.expression("Solo violin",bar,95)
            if bar in (3,7,11,15,19,23,27,31,43,47,51,55) or climax_section:
                s.chord("Trumpets",beat,.63,chord[:3],67+energy)
                s.chord("Trumpets",beat+2.5,.55,chord[:3],64+energy)
            if bar%4==0 or climax_section:
                s.chord("Trombones",beat,1.0,[n-12 for n in chord[:3]],68+energy)
                s.chord("Trombones",beat+3,.40,[n-12 for n in chord[:3]],62+energy)
        if (24<=bar<32 or bar>=48) and bar%2==0:
            s.chord("Wordless choir",beat+.1,7.7,[n-12 for n in chord[:3]],48)
            s.expression("Wordless choir",bar,71)
        if bar in (0,16,40,56):
            s.note("Tubular bells",beat+.02,3.2,root+24,68)
        if bar%8==7:
            for j in range(8): s.note("Harp",beat+2+j*.25,.8,chord[j%len(chord)]+12*(j//len(chord)),53+j)
        # Timpani/taiko and orchestral bass drum are complementary, not constant crashes.
        for when in (0,2.5):
            s.note("Timpani",beat+when,.65,root+12,65+(9 if when==0 else -5)+energy)
        for when in ((0,2) if break_section else (0,1.5,2,3.5)):
            s.note("Taiko",beat+when,.18,48 if when in (0,2) else 55,61+energy)
            s.note("Orchestral percussion",beat+when,.14,36,76+energy)
        if not break_section:
            for when in (1,3):
                s.note("Orchestral percussion",beat+when,.15,38,73+energy)
            for j in range(8):
                s.note("Orchestral percussion",beat+j*.5,.12,42,45+(13 if j%2 else 0)+energy)
            if bar%8==0:
                s.note("Orchestral percussion",beat,2,49,71+energy)
            if bar%4==3:
                for j in range(4):
                    s.note("Orchestral percussion",beat+3+j*.25,.12,[45,47,43,41][j],59+j*6)
        if bar in (15,31,39,55,63):
            for j in range(8):
                s.note("Orchestral percussion",beat+2+j*.25,.12,38,40+j*6)
                s.note("Timpani",beat+2+j*.25,.15,root+12,43+j*5)
    return s


def run(cmd):
    r=subprocess.run([str(x) for x in cmd],capture_output=True,text=True,timeout=300)
    if r.returncode: raise RuntimeError(r.stdout+'\n'+r.stderr)
    return r.stderr


def render_stem(score,group,folder):
    stem_dir=folder/'stems'
    stem_dir.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='wf-score-') as temp:
        midi,wav=Path(temp)/'twice.mid',Path(temp)/'twice.wav'
        score.midi(midi,group,repeats=2)
        run(['fluidsynth','-ni','-q','-r',SR,'-g','0.55','-C','0','-R','1',
             '-o','synth.reverb.room-size=0.62','-o','synth.reverb.damp=0.45',
             '-o','synth.reverb.width=65','-o','synth.reverb.level=0.22',
             '-o','synth.polyphony=512','-T','wav','-O','float','-F',wav,SFONT,midi])
        n=round(score.seconds*SR)
        with sf.SoundFile(wav) as f:
            f.seek(n)
            data=f.read(n,dtype='float32',always_2d=True)
        if len(data)!=n: raise ValueError('Incomplete audio render')
        # The second complete traversal already contains release/reverb from the loop end.
        # A tiny periodic endpoint correction removes any residual synth block alignment step.
        width=96
        target=(data[-1]+data[0])/2
        weight=np.linspace(1,0,width,dtype=np.float32)[:,None]**2
        data[:width]+=(target-data[0])*weight
        data[-width:]+=(target-data[-1])*weight[::-1]
        path=stem_dir/(group+'.flac')
        sf.write(path,data,SR,subtype='PCM_24')
    print(f'{score.name}: {group} rendered',flush=True)
    return path


def loudness(path):
    log=run(['ffmpeg','-hide_banner','-nostats','-i',path,'-af',
             'loudnorm=I=-18:TP=-1.5:LRA=11:print_format=json','-f','null','-'])
    return json.loads(log[log.rfind('{'):log.rfind('}')+1])


def finish(score,folder):
    n=round(score.seconds*SR)
    mix=np.zeros((n,2),dtype=np.float32)
    # GM patches have very different output levels. Balance the instrument families
    # explicitly so strings and plucked accompaniment remain present below the lead.
    bus_gains=({'woodwinds':-3,'strings':7,'plucked':3,'bass':1,'accents':7,'percussion':6}
               if score.name=='bellwake_city' else
               {'strings':10,'bass':3,'brass':-2,'percussion':-4,'atmosphere':13,'accents':4})
    for group in sorted({p.group for p in score.parts.values()}):
        data,_=sf.read(folder/'stems'/f'{group}.flac',dtype='float32',always_2d=True)
        assert np.max(np.abs(data)) < .99, f'Clipped instrument stem: {group}'
        mix+=data*10**(bus_gains[group]/20)
    # Phase-consistent cyclic EQ: remove rumble and a little upper-mid hardness.
    sos=signal.butter(2,35,fs=SR,btype='highpass',output='sos')
    pad=SR
    mix=signal.sosfilt(sos,np.concatenate([mix[-pad:],mix,mix[:pad]]),axis=0)[pad:pad+n].astype('float32')
    raw=folder/'premaster.wav'
    sf.write(raw,mix,SR,subtype='FLOAT')
    measure=loudness(raw)
    target=-18.0 if score.name=='bellwake_city' else -17.0
    gain_db=min(target-float(measure['input_i']),-1.8-float(measure['input_tp']))
    mix*=10**(gain_db/20)
    master=folder/f'{score.name}.wav'
    sf.write(master,mix,SR,subtype='PCM_24')
    raw.unlink()
    # High quality Vorbis stream for Godot, lossless master and editable stems retained.
    ogg=OUT/f'{score.name}.ogg'
    run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',master,'-c:a','libvorbis','-q:a','7',
         '-metadata',f'title={score.title}','-metadata','artist=Whispering Forest - Original Score',ogg])
    # Standalone preview has fades; the game asset never fades at the musical loop point.
    preview=folder/f'{score.name}_preview.mp3'
    run(['ffmpeg','-y','-hide_banner','-loglevel','error','-i',master,'-af',
         f'afade=t=in:d=0.06,afade=t=out:st={score.seconds-2}:d=2','-c:a','libmp3lame','-b:a','256k',preview])
    final=loudness(master)
    encoded=loudness(ogg)
    assert float(encoded['input_tp']) < -.5, encoded
    assert np.isfinite(mix).all() and np.max(np.abs(mix)) < 1
    jump=float(np.max(np.abs(mix[0]-mix[-1])))
    report={'title':score.title,'seconds':score.seconds,'bpm':score.bpm,'key':score.key,
            'bars':score.bars,'sample_rate':SR,'channels':2,'gain_db':gain_db,
            'master_lufs':float(final['input_i']),'master_true_peak_db':float(final['input_tp']),
            'ogg_lufs':float(encoded['input_i']),'ogg_true_peak_db':float(encoded['input_tp']),
            'loudness_range_lu':float(final['input_lra']),'loop_sample_jump':jump,
            'family_mix_gain_db':bus_gains,
            'parts':[{'name':p.name,'gm_program_0_based':p.program,'group':p.group,
                      'note_count':len(p.notes)} for p in score.parts.values()],
            'sections':[{'bar':bar+1,'label':label,'seconds':bar*4*score.tempo/1e6} for bar,label in score.sections],
            'qa_scope':'Signal, timing and integration checks; not a claim of human listening or reference-quality parity.'}
    (folder/'render-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({k:report[k] for k in ['title','seconds','master_lufs','ogg_true_peak_db','loop_sample_jump']}),flush=True)
    return report


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--score',choices=['all','city','battle'],default='all')
    parser.add_argument('--finish-only',action='store_true')
    args=parser.parse_args()
    for executable in ('fluidsynth','ffmpeg'):
        if not shutil.which(executable): raise RuntimeError(f'Missing {executable}')
    if not SFONT.is_file(): raise RuntimeError(f'Missing {SFONT}')
    ART.mkdir(parents=True,exist_ok=True)
    (ART/'.gdignore').write_text('')
    OUT.mkdir(parents=True,exist_ok=True)
    scores=[city_score(),battle_score()]
    if args.score!='all': scores=[scores[0 if args.score=='city' else 1]]
    for score in scores:
        folder=ART/score.name
        folder.mkdir(exist_ok=True)
        score.midi(folder/f'{score.name}.mid')
        if not args.finish_only:
            with ThreadPoolExecutor(max_workers=3) as pool:
                tasks=[pool.submit(render_stem,score,g,folder) for g in sorted({p.group for p in score.parts.values()})]
                for task in as_completed(tasks): task.result()
        finish(score,folder)
    tracks=[]
    for cue,title_zh in [('bellwake_city','晨铃城·晴日回廊'),('rift_battle','裂隙交锋')]:
        report=ART/cue/'render-report.json'
        asset=OUT/f'{cue}.ogg'
        if report.exists() and asset.exists():
            data=json.loads(report.read_text())
            tracks.append({'id':cue,'title_zh':title_zh,'title_en':data['title'],
                           'file':asset.name,'sha256':hashlib.sha256(asset.read_bytes()).hexdigest(),
                           'duration_seconds':data['seconds'],'bpm':data['bpm'],
                           'loop':True,'loop_offset':0,'channels':2,'sample_rate':SR,
                           'lufs':data['ogg_lufs'],'true_peak_db':data['ogg_true_peak_db'],
                           'instrument_parts':len(data['parts'])})
    (OUT/'manifest.json').write_text(json.dumps({'version':1,'generator':'tools/compose_music.py',
        'instrument_library':'GeneralUser GS 2.0.3','license':'art/audio/vendor/GeneralUser-GS-LICENSE.txt',
        'composition':'Original authored MIDI; no reference recording samples used.',
        'tracks':tracks},ensure_ascii=False,indent=2)+'\n')


if __name__=='__main__': main()
