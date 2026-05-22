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


static func from_legacy_dict(data: Dictionary) -> StoredFileEntry:
	var entry := StoredFileEntry.new()
	entry.title = str(data.get("title", ""))
	entry.file_type_id = str(data.get("file_type_id", FileDefs.DEFAULT_TYPE))
	entry.quality = float(data.get("quality", 1.0))
	entry.size_bytes = _read_size_bytes(data)
	return entry
