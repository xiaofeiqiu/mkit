#!/usr/bin/env python3
import math
import random
import struct
import wave
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIO_DIR = ROOT / "game" / "audio"
SAMPLE_RATE = 44100


def _freq(midi_note: float) -> float:
	return 440.0 * pow(2.0, (midi_note - 69.0) / 12.0)


def _env(t: float, duration: float, attack: float = 0.01, release: float = 0.08) -> float:
	if t < 0.0 or t > duration:
		return 0.0
	if t < attack:
		return t / max(attack, 0.001)
	if t > duration - release:
		return max(0.0, (duration - t) / max(release, 0.001))
	return 1.0


def _tone(phase: float, shape: str) -> float:
	if shape == "triangle":
		return 2.0 * abs(2.0 * (phase - math.floor(phase + 0.5))) - 1.0
	if shape == "square":
		return 1.0 if phase % 1.0 < 0.5 else -1.0
	return math.sin(phase * math.tau)


def _add_note(
	buffer: list[float],
	start: float,
	duration: float,
	midi_note: float,
	volume: float,
	shape: str = "sine",
	attack: float = 0.01,
	release: float = 0.08,
) -> None:
	start_i = max(0, int(start * SAMPLE_RATE))
	end_i = min(len(buffer), int((start + duration) * SAMPLE_RATE))
	freq = _freq(midi_note)
	for i in range(start_i, end_i):
		t = (i / SAMPLE_RATE) - start
		phase = freq * t
		buffer[i] += _tone(phase, shape) * volume * _env(t, duration, attack, release)


def _add_noise_hit(buffer: list[float], start: float, duration: float, volume: float, seed: int) -> None:
	rng = random.Random(seed)
	start_i = max(0, int(start * SAMPLE_RATE))
	end_i = min(len(buffer), int((start + duration) * SAMPLE_RATE))
	for i in range(start_i, end_i):
		t = (i / SAMPLE_RATE) - start
		decay = pow(max(0.0, 1.0 - (t / duration)), 2.5)
		buffer[i] += rng.uniform(-1.0, 1.0) * volume * decay


def _write_wav(path: Path, buffer: list[float]) -> None:
	peak = max(0.001, max(abs(v) for v in buffer))
	scale = 0.86 / peak
	path.parent.mkdir(parents=True, exist_ok=True)
	with wave.open(str(path), "wb") as out:
		out.setnchannels(1)
		out.setsampwidth(2)
		out.setframerate(SAMPLE_RATE)
		for value in buffer:
			clamped = max(-1.0, min(1.0, value * scale))
			out.writeframesraw(struct.pack("<h", int(clamped * 32767.0)))


def _music_buffer(seconds: float) -> list[float]:
	return [0.0 for _ in range(int(seconds * SAMPLE_RATE))]


def _render_village() -> None:
	seconds = 16.0
	buffer = _music_buffer(seconds)
	chords = [(60, 64, 67), (57, 60, 64), (65, 69, 72), (55, 59, 62)]
	for bar, chord in enumerate(chords * 2):
		base = bar * 2.0
		_add_note(buffer, base, 1.92, chord[0] - 12, 0.13, "triangle", 0.04, 0.18)
		for step, note in enumerate([chord[0], chord[1], chord[2], chord[1]]):
			_add_note(buffer, base + step * 0.5, 0.46, note + 12, 0.11, "triangle", 0.005, 0.18)
	melody = [72, 76, 74, 72, 69, 72, 74, 76, 77, 76, 74, 72, 71, 72, 69, 67]
	for i, note in enumerate(melody):
		_add_note(buffer, i * 0.5, 0.38, note, 0.08, "sine", 0.008, 0.13)
	_write_wav(AUDIO_DIR / "demo_village_loop.wav", buffer)


def _render_room() -> None:
	seconds = 12.0
	buffer = _music_buffer(seconds)
	chords = [(55, 60, 64), (53, 57, 60), (50, 55, 59), (52, 55, 60)]
	for bar, chord in enumerate(chords * 2):
		base = bar * 1.5
		for note in chord:
			_add_note(buffer, base, 1.45, note, 0.08, "sine", 0.18, 0.3)
		_add_note(buffer, base + 0.72, 0.55, chord[2] + 7, 0.045, "triangle", 0.02, 0.18)
	_write_wav(AUDIO_DIR / "demo_room_loop.wav", buffer)


def _render_field() -> None:
	seconds = 12.0
	buffer = _music_buffer(seconds)
	bass = [45, 45, 50, 48, 45, 43, 48, 50]
	for i, note in enumerate(bass):
		start = i * 1.5
		_add_note(buffer, start, 0.7, note, 0.16, "triangle", 0.015, 0.16)
		_add_note(buffer, start + 0.75, 0.22, note + 12, 0.08, "square", 0.004, 0.08)
	melody = [57, 60, 62, 65, 64, 62, 60, 57, 55, 57, 60, 62]
	for i, note in enumerate(melody):
		_add_note(buffer, i * 0.5, 0.28, note + 12, 0.055, "triangle", 0.006, 0.09)
	for i in range(24):
		_add_noise_hit(buffer, i * 0.5, 0.05, 0.025, 500 + i)
	_write_wav(AUDIO_DIR / "demo_field_loop.wav", buffer)


def _render_sfx(path: str, notes: list[tuple[float, float, float, float, str]], noise: bool = False) -> None:
	duration = max((start + length for start, length, _note, _volume, _shape in notes), default=0.3)
	buffer = _music_buffer(duration + 0.06)
	for start, length, note, volume, shape in notes:
		_add_note(buffer, start, length, note, volume, shape, 0.002, min(0.12, length * 0.65))
	if noise:
		_add_noise_hit(buffer, 0.0, min(0.22, duration), 0.22, hash(path) & 0xFFFF)
	_write_wav(AUDIO_DIR / path, buffer)


def main() -> None:
	_render_village()
	_render_room()
	_render_field()
	_render_sfx("demo_attack_slash.wav", [(0.00, 0.12, 78, 0.5, "square"), (0.04, 0.12, 69, 0.3, "sine")], True)
	_render_sfx("demo_hit.wav", [(0.00, 0.14, 45, 0.45, "triangle"), (0.02, 0.12, 36, 0.25, "sine")], True)
	_render_sfx("demo_death.wav", [(0.00, 0.36, 50, 0.35, "triangle"), (0.10, 0.42, 38, 0.42, "sine")], True)
	_render_sfx("demo_firebolt.wav", [(0.00, 0.16, 62, 0.28, "triangle"), (0.04, 0.22, 74, 0.32, "square"), (0.16, 0.18, 86, 0.24, "sine")], True)
	_render_sfx("demo_shop_coin.wav", [(0.00, 0.11, 84, 0.34, "sine"), (0.07, 0.16, 91, 0.28, "sine")])
	_render_sfx("demo_dialogue_blip.wav", [(0.00, 0.06, 76, 0.26, "triangle"), (0.07, 0.07, 79, 0.2, "triangle")])
	_render_sfx("demo_quest_fanfare.wav", [(0.00, 0.14, 72, 0.24, "triangle"), (0.12, 0.16, 76, 0.24, "triangle"), (0.26, 0.22, 79, 0.28, "triangle")])
	_render_sfx("demo_loot_sparkle.wav", [(0.00, 0.09, 88, 0.24, "sine"), (0.06, 0.12, 95, 0.26, "sine"), (0.16, 0.16, 100, 0.22, "sine")])


if __name__ == "__main__":
	main()
