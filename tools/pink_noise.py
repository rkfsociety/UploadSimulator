"""Упрощённый розовый шум (фильтр Paul Kellet) для атмосферных подложек."""

import random


class PinkNoise:
	# Количество полос фильтра
	_BAND_COUNT = 7

	def __init__(self, gain: float = 0.11) -> None:
		# Состояние полос; gain — итоговая громкость сэмпла
		self._bands: list[float] = [0.0] * self._BAND_COUNT
		self._gain = gain

	def sample(self) -> float:
		# Один сэмпл розового шума
		white = random.uniform(-1.0, 1.0)
		b = self._bands
		b[0] = 0.99886 * b[0] + white * 0.0555179
		b[1] = 0.99332 * b[1] + white * 0.0750759
		b[2] = 0.96900 * b[2] + white * 0.1538520
		b[3] = 0.86650 * b[3] + white * 0.3104856
		b[4] = 0.55000 * b[4] + white * 0.5329522
		b[5] = -0.7616 * b[5] - white * 0.0168980
		out = b[0] + b[1] + b[2] + b[3] + b[4] + b[5] + b[6] + white * 0.5362
		b[6] = white * 0.115926
		return out * self._gain
