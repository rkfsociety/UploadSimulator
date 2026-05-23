extends RefCounted
class_name SaveBackend
## Абстрактный бэкенд: запись и чтение словаря снимка по идентификатору слота.
## Наследник переопределяет методы; базовая реализация — заглушка с ошибкой.


func is_persistent() -> bool:
	# По умолчанию бэкенд не пишет на диск
	return false


func has_save(_slot_id: String) -> bool:
	push_error("SaveBackend.has_save: переопределите в наследнике (%s)" % get_class())
	return false


func write_save(_slot_id: String, _payload: Dictionary) -> bool:
	push_error("SaveBackend.write_save: переопределите в наследнике (%s)" % get_class())
	return false


func read_save(_slot_id: String) -> Dictionary:
	push_error("SaveBackend.read_save: переопределите в наследнике (%s)" % get_class())
	return {}
