extends RefCounted
class_name GameStateSave
## API сохранений для autoload GameState.


var _svc: GameSaveService


func _init(svc: GameSaveService) -> void:
	_svc = svc


func is_persistent() -> bool:
	return _svc.is_persistent()


func has_save(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	return _svc.has_save(slot_id)


func save(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	return _svc.save(slot_id)


func load(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	return _svc.load(slot_id)
