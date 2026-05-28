extends SaveBackend
class_name NullSaveBackend
## Заглушка: снимок не сохраняется (до подключения файлового бэкенда).


func is_persistent() -> bool:
	return false


func has_save(_slot_id: String) -> bool:
	return false


func write_save(_slot_id: String, _payload: Dictionary) -> bool:
	return false


func read_save(_slot_id: String) -> Dictionary:
	return {}


func delete_save(_slot_id: String) -> bool:
	return true
