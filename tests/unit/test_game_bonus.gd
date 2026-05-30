extends RefCounted
## Unit-тесты расчёта бонусов от уровня модуля.

var case_count := 3


func run() -> Array[String]:
	var errors: Array[String] = []
	_assert_close(
		errors,
		GameBonus.speed_scaled(GameConstants.BASE_DOWNLOAD_SPEED_BPS, "network", 1),
		GameConstants.BASE_DOWNLOAD_SPEED_BPS,
		"скорость ур.1 = база",
	)
	# network effect_per_level = 0.11 → ур.2 = база +11% (уровень 1 = база)
	_assert_close(
		errors,
		GameBonus.speed_scaled(GameConstants.BASE_DOWNLOAD_SPEED_BPS, "network", 2),
		GameConstants.BASE_DOWNLOAD_SPEED_BPS * 1.11,
		"скорость ур.2 network +11%",
	)
	var cap_l1 := GameBonus.storage_capacity_files(1)
	var cap_l2 := GameBonus.storage_capacity_files(2)
	if cap_l2 <= cap_l1:
		errors.append("вместимость хранилища растёт с уровнем")
	return errors


func _assert_close(errors: Array[String], actual: float, expected: float, label: String) -> void:
	if absf(actual - expected) > 0.001:
		errors.append("%s: ожидалось %.4f, получено %.4f" % [label, expected, actual])
