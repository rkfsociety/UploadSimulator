extends RefCounted
## Unit-тесты снимка состояния и in-memory бэкенда сохранений.

var case_count := 4


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_snapshot_roundtrip(errors)
	_test_memory_backend(errors)
	return errors


func _test_snapshot_roundtrip(errors: Array[String]) -> void:
	var data := GameStateData.new()
	data.add_money(50.0)
	data.add_diamonds(2)
	data.unlock_module_type("cache")
	data.set_block_stock("storage", 1)
	var inst := BlockInstance.create("downloader", 1, 2, "blk_test", 2)
	data.get_placed_blocks().append(inst)
	var payload := GameSaveSnapshot.capture(data).to_payload()
	var restored := GameStateData.new()
	if not GameSaveSnapshot.from_payload(payload).apply_to(restored):
		errors.append("GameSaveSnapshot.apply_to")
		return
	if restored.get_money() != data.get_money():
		errors.append("snapshot: money")
	if restored.get_diamonds() != data.get_diamonds():
		errors.append("snapshot: diamonds")
	if not restored.is_module_type_unlocked("cache"):
		errors.append("snapshot: unlocked cache")
	if restored.get_placed_blocks().size() != 1:
		errors.append("snapshot: placed_blocks size")
	elif restored.get_placed_blocks()[0].uid != "blk_test":
		errors.append("snapshot: placed block uid")


func _test_memory_backend(errors: Array[String]) -> void:
	var host := Node.new()
	var data := GameStateData.new()
	var backend := MemorySaveBackend.new()
	var svc := GameSaveService.new(data, host, backend)
	data.add_money(10.0)
	if not svc.save("test_slot"):
		errors.append("GameSaveService.save memory")
	if not backend.has_save("test_slot"):
		errors.append("MemorySaveBackend.has_save")
	var fresh := GameStateData.new()
	var load_svc := GameSaveService.new(fresh, host, backend)
	if not load_svc.load("test_slot"):
		errors.append("GameSaveService.load memory")
	if fresh.get_money() != data.get_money():
		errors.append("load restored money")
	host.free()
