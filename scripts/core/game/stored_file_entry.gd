extends RefCounted
class_name StoredFileEntry
## Файл на диске хранилища.

var title: String = ""
var quality: float = 1.0
var size_mb: float = 0.0


static func from_legacy_dict(data: Dictionary) -> StoredFileEntry:
	var entry := StoredFileEntry.new()
	entry.title = str(data.get("title", ""))
	entry.quality = float(data.get("quality", 1.0))
	entry.size_mb = float(data.get("size_mb", 0.0))
	return entry
