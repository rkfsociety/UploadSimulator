extends SaveBackend
class_name MemorySaveBackend
## In-memory бэкенд для тестов и отладки (не переживает перезапуск).


var _slots: Dictionary = {}


func is_persistent() -> bool:
	return false


func has_save(slot_id: String) -> bool:
	return _slots.has(slot_id)


func write_save(slot_id: String, payload: Dictionary) -> bool:
	_slots[slot_id] = payload.duplicate(true)
	return true


func read_save(slot_id: String) -> Dictionary:
	if not _slots.has(slot_id):
		return {}
	var stored: Variant = _slots[slot_id]
	if stored is Dictionary:
		return (stored as Dictionary).duplicate(true)
	return {}
