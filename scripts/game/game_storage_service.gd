extends RefCounted
class_name GameStorageService
## Ёмкость и занятость диска.

var _data: GameStateData
var _field: GameFieldService


func _init(data: GameStateData, field: GameFieldService) -> void:
	_data = data
	_field = field


func get_storage_capacity_mb() -> float:
	var total_gb := 0.0
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.type_id == "storage":
			total_gb += storage_capacity_for(inst.uid) / GameConstants.MB_PER_GB
	if total_gb <= 0.0:
		return 0.0
	return total_gb * GameConstants.MB_PER_GB


func storage_capacity_for(uid: String) -> float:
	return GameBonus.storage_capacity_mb(_field.get_instance_level(uid))


func get_storage_used_mb() -> float:
	var used := 0.0
	used += float(_data.get_recorded_files()) * GameConstants.RAW_FILE_MB
	for job: FileTransferJob in _data.get_download_queue():
		used += job.size_mb
	for entry: StoredFileEntry in _data.get_stored_files():
		used += entry.size_mb
	for job: FileTransferJob in _data.get_upload_queue():
		used += job.size_mb
	return used


func has_storage_space(for_mb: float) -> bool:
	return get_storage_capacity_mb() > 0.0 and get_storage_free_mb() >= for_mb


func get_storage_free_mb() -> float:
	return maxf(0.0, get_storage_capacity_mb() - get_storage_used_mb())
