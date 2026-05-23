extends RefCounted
class_name StoredFileEntry
## Файл на диске хранилища.

var title: String = ""
var file_type_id: String = FileDefs.DEFAULT_TYPE
var quality: float = 1.0
var size_bytes: float = 0.0


static func _read_size_bytes(data: Dictionary) -> float:
	if data.has("size_bytes"):
		return float(data["size_bytes"])
	return float(data.get("size_mb", 0.0)) * GameConstants.BYTE_SIZE_SCALE


func to_dict() -> Dictionary:
	return {
		"title": title,
		"file_type_id": file_type_id,
		"quality": quality,
		"size_bytes": size_bytes,
	}


static func from_dict(data: Dictionary) -> StoredFileEntry:
	return from_legacy_dict(data)


static func from_legacy_dict(data: Dictionary) -> StoredFileEntry:
	var entry := StoredFileEntry.new()
	entry.title = str(data.get("title", ""))
	entry.file_type_id = str(data.get("file_type_id", FileDefs.DEFAULT_TYPE))
	entry.quality = GameValueBounds.quality(float(data.get("quality", 1.0)))
	entry.size_bytes = GameValueBounds.size_bytes(_read_size_bytes(data))
	return entry


# Нормализация полей после прямого присваивания
func apply_bounds() -> void:
	quality = GameValueBounds.quality(quality)
	size_bytes = GameValueBounds.size_bytes(size_bytes)
