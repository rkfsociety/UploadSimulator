extends RefCounted
class_name GameStorageService
## Ёмкость и занятость диска (в байтах).

var _data: GameStateData
var _field: GameFieldService


func _init(data: GameStateData, field: GameFieldService) -> void:
	_data = data
	_field = field


func get_storage_capacity_bytes() -> float:
	var total := 0.0
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.type_id == "storage":
			total += storage_capacity_for(inst.uid)
	return total


func storage_capacity_for(uid: String) -> float:
	return GameBonus.storage_capacity_bytes(_field.get_instance_level(uid))


func get_storage_used_bytes() -> float:
	var used := 0.0
	for job: FileTransferJob in _data.get_download_queue():
		used += job.size_bytes
	for entry: StoredFileEntry in _data.get_stored_files():
		used += entry.size_bytes
	for job: FileTransferJob in _data.get_upload_queue():
		used += job.size_bytes
	return used


func has_storage_space(for_bytes: float) -> bool:
	return get_storage_capacity_bytes() > 0.0 and get_storage_free_bytes() >= for_bytes


func get_storage_free_bytes() -> float:
	return maxf(0.0, get_storage_capacity_bytes() - get_storage_used_bytes())
