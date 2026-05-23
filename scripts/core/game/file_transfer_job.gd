extends RefCounted
class_name FileTransferJob
## Задача скачивания или выгрузки файла.

var title: String = ""
var file_type_id: String = FileDefs.DEFAULT_TYPE
var quality: float = 1.0
var size_bytes: float = 0.0
var duration: float = 1.0
var progress: float = 0.0


static func _read_size_bytes(data: Dictionary) -> float:
	if data.has("size_bytes"):
		return float(data["size_bytes"])
	# Старые сохранения и очереди в условных «МБ»
	return float(data.get("size_mb", 0.0)) * GameConstants.BYTE_SIZE_SCALE


func to_dict() -> Dictionary:
	return {
		"title": title,
		"file_type_id": file_type_id,
		"quality": quality,
		"size_bytes": size_bytes,
		"duration": duration,
		"progress": progress,
	}


static func from_dict(data: Dictionary) -> FileTransferJob:
	return from_legacy_dict(data)


static func from_legacy_dict(data: Dictionary) -> FileTransferJob:
	var job := FileTransferJob.new()
	job.title = str(data.get("title", ""))
	job.file_type_id = str(data.get("file_type_id", FileDefs.DEFAULT_TYPE))
	job.quality = GameValueBounds.quality(float(data.get("quality", 1.0)))
	job.size_bytes = GameValueBounds.size_bytes(_read_size_bytes(data))
	job.duration = GameValueBounds.job_duration(float(data.get("duration", 1.0)))
	job.progress = GameValueBounds.progress(float(data.get("progress", 0.0)))
	return job


# Нормализация полей после прямого присваивания
func apply_bounds() -> void:
	quality = GameValueBounds.quality(quality)
	size_bytes = GameValueBounds.size_bytes(size_bytes)
	duration = GameValueBounds.job_duration(duration)
	progress = GameValueBounds.progress(progress)
