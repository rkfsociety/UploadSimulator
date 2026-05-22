extends RefCounted
class_name FileDefs
## Типы передаваемых файлов (базовый — текстовый).

const DEFAULT_TYPE := "text"

const TYPES := {
	"text":
	{
		"name": "Текстовый файл",
	},
}


# Человекочитаемое название типа для UI модуля
static func get_type_label(type_id: String) -> String:
	return str(TYPES.get(type_id, TYPES[DEFAULT_TYPE]).get("name", "Файл"))


# Случайный размер скачиваемого файла: текст небольшой, верх — speed_bps × 50 байт
static func random_download_size_bytes(
	file_type_id: String, speed_bps: float, rng: RandomNumberGenerator
) -> float:
	var speed_cap := maxf(speed_bps * GameConstants.DOWNLOAD_SIZE_SPEED_MULTIPLIER, 1.0)
	match file_type_id:
		"text":
			var max_b := minf(GameConstants.TEXT_FILE_BYTES_MAX, speed_cap)
			var min_b := minf(GameConstants.TEXT_FILE_BYTES_MIN, max_b)
			return rng.randf_range(min_b, max_b)
		_:
			return rng.randf_range(
				minf(GameConstants.TEXT_FILE_BYTES_MIN, speed_cap), speed_cap
			)
