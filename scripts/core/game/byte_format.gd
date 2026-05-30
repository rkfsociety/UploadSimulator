extends RefCounted
class_name ByteFormat
## Форматирование размеров и скорости в байтах для UI.


# Скорость передачи в байтах в секунду (локализованный UI)
static func format_speed_bps(speed_bps: float) -> String:
	if speed_bps < 1024.0:
		return "%.0f Б/с" % speed_bps
	if speed_bps < 1024.0 * 1024.0:
		return "%.1f КБ/с" % (speed_bps / 1024.0)
	return "%.1f МБ/с" % (speed_bps / (1024.0 * 1024.0))


## Подпись скорости для панели «Сеть» (как в макете: «8.00 bps»).
static func format_speed_bps_label(speed_bps: float) -> String:
	return "%.2f bps" % maxf(0.0, speed_bps)


# Размер файла или диска в байтах
static func format_bytes(size_bytes: float) -> String:
	var n := maxf(0.0, size_bytes)
	if n < 1024.0:
		return "%.0f Б" % n
	if n < 1024.0 * 1024.0:
		return "%.1f КБ" % (n / 1024.0)
	if n < 1024.0 * 1024.0 * 1024.0:
		return "%.1f МБ" % (n / (1024.0 * 1024.0))
	return "%.1f ГБ" % (n / (1024.0 * 1024.0 * 1024.0))
