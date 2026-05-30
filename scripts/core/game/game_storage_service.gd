extends RefCounted
class_name GameStorageService
## Вместимость файлов в Text Downloader (и других типах загрузчиков).

var _data: GameStateData
var _field: GameFieldService


func _init(data: GameStateData, field: GameFieldService) -> void:
	_data = data
	_field = field


func max_files_for(uid: String) -> int:
	return BlockDefs.max_stored_files(_field.get_instance_type(uid))


func files_stored_in(uid: String) -> int:
	return _data.get_module_files(uid).size()


func get_module_used_files(uid: String, chain: Dictionary) -> int:
	var used := files_stored_in(uid)
	if chain.get("downloader", "") == uid:
		if not _data.get_download_queue().is_empty():
			used += 1
		used += _data.count_incoming_wire_transfers(uid)
	return used


func has_module_space(uid: String, count: int = 1, include_active_download: bool = true) -> bool:
	var cap := max_files_for(uid)
	if cap <= 0:
		return false
	var used := files_stored_in(uid)
	if include_active_download:
		if not _data.get_download_queue().is_empty():
			used += 1
		used += _data.count_incoming_wire_transfers(uid)
	return float(used + count) <= float(cap)


func can_store_in_module(uid: String, count: int = 1) -> bool:
	return float(files_stored_in(uid) + count) <= float(max_files_for(uid))


func get_storage_capacity_files() -> float:
	var total := 0.0
	for inst: BlockInstance in _data.get_placed_blocks():
		if BlockDefs.stores_files(inst.type_id):
			total += float(max_files_for(inst.uid))
	return total


func get_storage_used_files() -> int:
	var total := 0
	var chain := {"downloader": _primary_downloader_uid()}
	for inst: BlockInstance in _data.get_placed_blocks():
		if BlockDefs.stores_files(inst.type_id):
			total += get_module_used_files(inst.uid, chain)
	return total


func has_storage_space(count: int = 1) -> bool:
	for inst: BlockInstance in _data.get_placed_blocks():
		if BlockDefs.stores_files(inst.type_id):
			if has_module_space(inst.uid, count):
				return true
	return false


func get_storage_free_files() -> float:
	return maxf(0.0, get_storage_capacity_files() - float(get_storage_used_files()))


func _primary_downloader_uid() -> String:
	for inst: BlockInstance in _data.get_placed_blocks():
		if BlockDefs.is_downloader_type(inst.type_id):
			return inst.uid
	return ""
