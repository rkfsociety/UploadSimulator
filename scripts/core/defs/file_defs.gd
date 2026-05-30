extends RefCounted
class_name FileDefs
## Типы файлов из интернета; у каждого — свой диапазон размера при скачивании.

const DEFAULT_TYPE := "text"

# weight — для будущего случайного выбора типа; bytes_* — лимиты размера
const TYPES := {
	"text":
	{
		"name": "Текстовый файл",
		"weight": 1.0,
		# bytes_min/max синхронизируются из GameBalanceConfig (см. sync_limits_from_balance)
		"bytes_min": 100.0,
		"bytes_max": 100.0,
	},
	# Заготовки под будущие типы (пока не выпадают в pick_random_download_type)
	"image":
	{
		"name": "Изображение",
		"weight": 0.0,
		"bytes_min": 8_000.0,
		"bytes_max": 48_000.0,
	},
	"archive":
	{
		"name": "Архив",
		"weight": 0.0,
		"bytes_min": 12_000.0,
		"bytes_max": 96_000.0,
	},
}


static func _static_init() -> void:
	for type_id in TYPES:
		var def: Dictionary = TYPES[type_id]
		if not def.has("name") or not def.has("bytes_min") or not def.has("bytes_max"):
			push_error("FileDefs: тип «%s» должен иметь name, bytes_min, bytes_max." % type_id)


# Лимиты текстового типа — из GameConstants (без записи в const TYPES)
static func sync_limits_from_balance() -> void:
	pass


static func _bytes_min_for_type(type_id: String, def: Dictionary) -> float:
	if type_id == "text":
		return GameConstants.TEXT_FILE_BYTES_MIN
	return float(def.get("bytes_min", GameConstants.TEXT_FILE_BYTES_MIN))


static func _bytes_max_for_type(type_id: String, def: Dictionary) -> float:
	if type_id == "text":
		return GameConstants.TEXT_FILE_BYTES_MAX
	return float(def.get("bytes_max", GameConstants.TEXT_FILE_BYTES_MAX))


# Символ типа файла на маркере провода
static func get_type_icon_char(type_id: String) -> String:
	match type_id:
		"text":
			return "T"
		"image":
			return "I"
		"archive":
			return "A"
		_:
			return "F"


# Человекочитаемое название типа для UI модуля
static func get_type_label(type_id: String) -> String:
	return str(TYPES.get(type_id, TYPES[DEFAULT_TYPE]).get("name", "Файл"))


# Тип доступен для скачивания (weight > 0)
static func is_downloadable_type(type_id: String) -> bool:
	if not TYPES.has(type_id):
		return false
	return float(TYPES[type_id].get("weight", 0.0)) > 0.0


# Случайный тип для скачивания (сейчас только текст; позже — по weight)
static func pick_random_download_type(rng: RandomNumberGenerator) -> String:
	var pool: Array[String] = []
	var weights: Array[float] = []
	for type_id in TYPES:
		var w: float = float(TYPES[type_id].get("weight", 0.0))
		if w <= 0.0:
			continue
		pool.append(type_id)
		weights.append(w)
	if pool.is_empty():
		return DEFAULT_TYPE
	var total := 0.0
	for w in weights:
		total += w
	var roll := rng.randf() * total
	var acc := 0.0
	for i in pool.size():
		acc += weights[i]
		if roll <= acc:
			return pool[i]
	return pool[pool.size() - 1]


# Случайный размер: min/max типа и потолок speed_bps × множитель (≈ 50 с на линии)
static func random_download_size_bytes(
	file_type_id: String, speed_bps: float, rng: RandomNumberGenerator
) -> float:
	var def: Dictionary = TYPES.get(file_type_id, TYPES[DEFAULT_TYPE])
	# Без GameValueBounds — иначе цикл с GameConstants._static_init
	var safe_speed := maxf(speed_bps, 1.0)
	var speed_cap := maxf(safe_speed * GameConstants.MAX_TRANSFER_JOB_DURATION_SEC, 1.0)
	var type_max := _bytes_max_for_type(file_type_id, def)
	var type_min := _bytes_min_for_type(file_type_id, def)
	var max_b := minf(type_max, speed_cap)
	var min_b := minf(type_min, max_b)
	return rng.randf_range(min_b, max_b)
