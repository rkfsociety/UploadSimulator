extends SaveBackend
class_name FileSaveBackend
## Файловый бэкенд: снимок прогресса в user:// как JSON (по слоту).

const SAVE_DIR := "user://saves"


func is_persistent() -> bool:
	return true


func has_save(slot_id: String) -> bool:
	return FileAccess.file_exists(_slot_path(slot_id))


func write_save(slot_id: String, payload: Dictionary) -> bool:
	if not _ensure_dir():
		return false
	var file := FileAccess.open(_slot_path(slot_id), FileAccess.WRITE)
	if file == null:
		push_error(
			(
				"FileSaveBackend.write_save: не открыть %s (%d)"
				% [_slot_path(slot_id), FileAccess.get_open_error()]
			)
		)
		return false
	file.store_string(JSON.stringify(payload))
	file.close()
	return true


func read_save(slot_id: String) -> Dictionary:
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("FileSaveBackend.read_save: не открыть %s" % path)
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	push_warning("FileSaveBackend.read_save: повреждён слот «%s», игнорируем." % slot_id)
	return {}


func delete_save(slot_id: String) -> bool:
	var path := _slot_path(slot_id)
	if not FileAccess.file_exists(path):
		return true
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("FileSaveBackend.delete_save: нет каталога %s" % SAVE_DIR)
		return false
	return dir.remove("%s.save" % slot_id) == OK


func _slot_path(slot_id: String) -> String:
	return "%s/%s.save" % [SAVE_DIR, slot_id]


func _ensure_dir() -> bool:
	if DirAccess.dir_exists_absolute(SAVE_DIR):
		return true
	return DirAccess.make_dir_recursive_absolute(SAVE_DIR) == OK
