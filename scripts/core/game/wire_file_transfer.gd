extends RefCounted
class_name WireFileTransfer
## Файл в пути между модулями по проводу (до появления в целевом модуле).

enum Purpose { TO_UPLOADER, TO_NETWORK }

var purpose: Purpose = Purpose.TO_UPLOADER
var from_uid: String = ""
var from_port: String = ""
var to_uid: String = ""
var to_port: String = ""
var title: String = ""
var file_type_id: String = FileDefs.DEFAULT_TYPE
var quality: float = 1.0
var size_bytes: float = 0.0
var duration: float = 1.0
var progress: float = 0.0


func matches_link(from: String, from_p: String, to: String, to_p: String) -> bool:
	return from_uid == from and from_port == from_p and to_uid == to and to_port == to_p


func to_dict() -> Dictionary:
	return {
		"purpose": int(purpose),
		"from_uid": from_uid,
		"from_port": from_port,
		"to_uid": to_uid,
		"to_port": to_port,
		"title": title,
		"file_type_id": file_type_id,
		"quality": quality,
		"size_bytes": size_bytes,
		"duration": duration,
		"progress": progress,
	}


static func from_dict(data: Dictionary) -> WireFileTransfer:
	var transfer := WireFileTransfer.new()
	transfer.purpose = int(data.get("purpose", Purpose.TO_UPLOADER)) as Purpose
	transfer.from_uid = str(data.get("from_uid", ""))
	transfer.from_port = str(data.get("from_port", ""))
	transfer.to_uid = str(data.get("to_uid", ""))
	transfer.to_port = str(data.get("to_port", ""))
	transfer.title = str(data.get("title", ""))
	transfer.file_type_id = str(data.get("file_type_id", FileDefs.DEFAULT_TYPE))
	transfer.quality = GameValueBounds.quality(float(data.get("quality", 1.0)))
	transfer.size_bytes = GameValueBounds.size_bytes(float(data.get("size_bytes", 0.0)))
	transfer.duration = GameValueBounds.job_duration(float(data.get("duration", 1.0)))
	transfer.progress = GameValueBounds.progress(float(data.get("progress", 0.0)))
	return transfer


static func from_job(
	purpose: Purpose,
	from: String,
	from_p: String,
	to: String,
	to_p: String,
	job: FileTransferJob,
) -> WireFileTransfer:
	var transfer := WireFileTransfer.new()
	transfer.purpose = purpose
	transfer.from_uid = from
	transfer.from_port = from_p
	transfer.to_uid = to
	transfer.to_port = to_p
	transfer.title = job.title
	transfer.file_type_id = job.file_type_id
	transfer.quality = job.quality
	transfer.size_bytes = job.size_bytes
	transfer.duration = job.duration
	transfer.progress = 0.0
	transfer.apply_bounds()
	return transfer


static func from_entry(
	purpose: Purpose,
	from: String,
	from_p: String,
	to: String,
	to_p: String,
	entry: StoredFileEntry,
	duration_sec: float,
) -> WireFileTransfer:
	var transfer := WireFileTransfer.new()
	transfer.purpose = purpose
	transfer.from_uid = from
	transfer.from_port = from_p
	transfer.to_uid = to
	transfer.to_port = to_p
	transfer.title = entry.title
	transfer.file_type_id = entry.file_type_id
	transfer.quality = entry.quality
	transfer.size_bytes = entry.size_bytes
	transfer.duration = duration_sec
	transfer.progress = 0.0
	transfer.apply_bounds()
	return transfer


func to_job() -> FileTransferJob:
	var job := FileTransferJob.new()
	job.title = title
	job.file_type_id = file_type_id
	job.quality = quality
	job.size_bytes = size_bytes
	job.duration = duration
	job.progress = progress
	job.apply_bounds()
	return job


func apply_bounds() -> void:
	quality = GameValueBounds.quality(quality)
	size_bytes = GameValueBounds.size_bytes(size_bytes)
	duration = GameValueBounds.job_duration(duration)
	progress = GameValueBounds.progress(progress)
