extends RefCounted
class_name FileTransferJob
## Задача скачивания или выгрузки файла.

var title: String = ""
var quality: float = 1.0
var size_mb: float = 0.0
var duration: float = 1.0
var progress: float = 0.0


static func from_legacy_dict(data: Dictionary) -> FileTransferJob:
	var job := FileTransferJob.new()
	job.title = str(data.get("title", ""))
	job.quality = float(data.get("quality", 1.0))
	job.size_mb = float(data.get("size_mb", 0.0))
	job.duration = float(data.get("duration", 1.0))
	job.progress = float(data.get("progress", 0.0))
	return job
