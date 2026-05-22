#!/usr/bin/env python3
"""Генерация бесшовного кибер-ambient (без слов) в WAV."""

import math
import random
import struct
import wave
from pathlib import Path

from pink_noise import PinkNoise

SAMPLE_RATE = 44100
DURATION_SEC = 48.0
OUTPUT = Path(__file__).resolve().parent.parent / "assets" / "audio" / "cyber_ambient.wav"

# Частоты с целым числом циклов за DURATION_SEC — бесшовный луп
LAYERS = [
	(55.0, 0.22),
	(110.0, 0.1),
	(165.0, 0.07),
	(220.0, 0.05),
	(277.18, 0.04),
]
# Ноты минорной пентатоники для редких «блипов»
ARP_NOTES = [220.0, 261.63, 329.63, 392.0, 493.88, 659.25]
ARP_STEP = 0.38


def sample_layers(t: float) -> float:
	v = 0.0
	for freq, amp in LAYERS:
		v += amp * math.sin(2.0 * math.pi * freq * t)
	# Медленная модуляция «пульса»
	v *= 0.82 + 0.18 * math.sin(2.0 * math.pi * 0.08 * t)
	v += _arp_blip(t)
	return v


def _arp_blip(t: float) -> float:
	step_i = int(t / ARP_STEP)
	rnd = random.Random(step_i * 9176)
	if rnd.random() > 0.52:
		return 0.0
	note = ARP_NOTES[rnd.randrange(len(ARP_NOTES))]
	local_t = t - step_i * ARP_STEP
	dur = 0.14
	if local_t > dur:
		return 0.0
	env = 1.0 - local_t / dur
	# Лёгкий «квадрат» для синтезаторного оттенка
	wave = math.sin(2.0 * math.pi * note * t)
	if wave > 0.25:
		wave = 0.55
	elif wave < -0.25:
		wave = -0.55
	return wave * env * 0.09


def main() -> None:
	OUTPUT.parent.mkdir(parents=True, exist_ok=True)
	n_samples = int(SAMPLE_RATE * DURATION_SEC)
	fade_samples = int(SAMPLE_RATE * 2.5)
	frames: list[int] = []
	noise = PinkNoise()

	for i in range(n_samples):
		t = i / SAMPLE_RATE
		s = sample_layers(t) + noise.sample()
		# Плавное затухание на стыке лупа
		if i < fade_samples:
			env = i / fade_samples
		elif i > n_samples - fade_samples:
			env = (n_samples - i) / fade_samples
		else:
			env = 1.0
		s *= env * 0.85
		s = max(-1.0, min(1.0, s))
		frames.append(int(s * 32767))

	with wave.open(str(OUTPUT), "w") as wf:
		wf.setnchannels(1)
		wf.setsampwidth(2)
		wf.setframerate(SAMPLE_RATE)
		wf.writeframes(struct.pack(f"<{len(frames)}h", *frames))

	print(f"OK: {OUTPUT} ({DURATION_SEC}s)")


if __name__ == "__main__":
	main()
