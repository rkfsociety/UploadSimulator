extends RefCounted
class_name GameValueBounds
## Приведение числовых значений к допустимым границам (касса, скорости, очереди).

# Минимальная скорость канала (байт/с): ноль и отрицательные недопустимы
const MIN_SPEED_BPS := 1.0


# Касса и сейф аплоудера — не ниже нуля
static func money(value: float) -> float:
	return maxf(0.0, value)


# Сумма начисления/списания — не отрицательная (отрицательное списание — через try_spend)
static func money_delta(amount: float) -> float:
	return maxf(0.0, amount)


static func diamonds(value: int) -> int:
	return maxi(0, value)


static func diamond_delta(amount: int) -> int:
	return maxi(0, amount)


# Скорость канала: ноль и отрицательные недопустимы
static func speed_bps(speed: float) -> float:
	return maxf(MIN_SPEED_BPS, speed)


# Длительность задачи передачи (сек), в пределах баланса
static func job_duration(duration: float) -> float:
	return clampf(
		duration,
		GameConstants.MIN_JOB_DURATION_SEC,
		GameConstants.MAX_TRANSFER_JOB_DURATION_SEC,
	)


# Длительность из размера и скорости (нулевая скорость → MIN_SPEED_BPS)
static func job_duration_from_bytes(size_bytes: float, speed_bps: float) -> float:
	var bytes_safe := size_bytes(size_bytes)
	var safe_speed := speed_bps(speed_bps)
	return job_duration(bytes_safe / safe_speed)


static func progress(value: float) -> float:
	return clampf(value, 0.0, 1.0)


static func size_bytes(value: float) -> float:
	return maxf(0.0, value)


static func quality(value: float) -> float:
	return maxf(0.0, value)


static func count(value: int) -> int:
	return maxi(0, value)


static func env_level(level: int) -> int:
	return maxi(0, level)
