extends RefCounted
class_name GameStateAccess
## Чтение снимка состояния (деньги, очереди, фаза).

var _data: GameStateData


func _init(data: GameStateData) -> void:
	_data = data


func get_money() -> float:
	return _data.get_money()


func get_env_multiplier(effect_key: String) -> float:
	return _data.get_env_multiplier(effect_key)


func is_module_type_unlocked(type_id: String) -> bool:
	return _data.is_module_type_unlocked(type_id)


func get_network_balance() -> float:
	return _data.get_network_balance()


func get_placed_blocks() -> Array[BlockInstance]:
	return _data.get_placed_blocks()


func get_wire_connections() -> Array[WireLink]:
	return _data.get_wire_connections()


func get_download_queue() -> Array[FileTransferJob]:
	return _data.get_download_queue()


func get_upload_queue() -> Array[FileTransferJob]:
	return _data.get_upload_queue()


func get_phase() -> GameStateData.Phase:
	return _data.get_phase()
