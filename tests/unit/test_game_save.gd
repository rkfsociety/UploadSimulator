extends RefCounted
## Unit-тесты снимка состояния и in-memory бэкенда сохранений.

var case_count := 6


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_snapshot_roundtrip(errors)
	_test_memory_backend(errors)
	_test_file_backend(errors)
	_test_reset_progress(errors)
	return errors


func _test_snapshot_roundtrip(errors: Array[String]) -> void:
	var host := _SaveTestHost.new()
	var data := GameStateData.new()
	var premium := PremiumCurrencyService.new(host, GameConstants.START_DIAMONDS)
	data.add_money(50.0)
	premium.grant(2, PremiumCurrencyService.Source.ADMIN)
	data.unlock_module_type("cache")
	data.set_block_stock("storage", 1)
	var inst := BlockInstance.create("text_downloader", 1, 2, "blk_test", 2)
	data.get_placed_blocks().append(inst)
	var payload := GameSaveSnapshot.capture(data, premium).to_payload()
	var restored := GameStateData.new()
	var restored_premium := PremiumCurrencyService.new(host, 0)
	if not GameSaveSnapshot.from_payload(payload).apply_to(restored, restored_premium):
		errors.append("GameSaveSnapshot.apply_to")
		host.free()
		return
	if restored.get_money() != data.get_money():
		errors.append("snapshot: money")
	if restored_premium.get_balance() != premium.get_balance():
		errors.append("snapshot: diamonds")
	host.free()
	if not restored.is_module_type_unlocked("cache"):
		errors.append("snapshot: unlocked cache")
	if restored.get_placed_blocks().size() != 1:
		errors.append("snapshot: placed_blocks size")
	elif restored.get_placed_blocks()[0].uid != "blk_test":
		errors.append("snapshot: placed block uid")


func _test_memory_backend(errors: Array[String]) -> void:
	var host := _SaveTestHost.new()
	var data := GameStateData.new()
	var premium := PremiumCurrencyService.new(host)
	var backend := MemorySaveBackend.new()
	var svc := GameSaveService.new(data, premium, host, backend)
	data.add_money(10.0)
	if not svc.save("test_slot"):
		errors.append("GameSaveService.save memory")
	if not backend.has_save("test_slot"):
		errors.append("MemorySaveBackend.has_save")
	var fresh := GameStateData.new()
	var fresh_premium := PremiumCurrencyService.new(host, 0)
	var load_svc := GameSaveService.new(fresh, fresh_premium, host, backend)
	if not load_svc.load("test_slot"):
		errors.append("GameSaveService.load memory")
	if fresh.get_money() != data.get_money():
		errors.append("load restored money")
	host.free()


func _test_file_backend(errors: Array[String]) -> void:
	var host := _SaveTestHost.new()
	var data := GameStateData.new()
	var premium := PremiumCurrencyService.new(host)
	var backend := FileSaveBackend.new()
	var svc := GameSaveService.new(data, premium, host, backend)
	var slot := "test_file_slot"
	backend.delete_save(slot)  # чистый старт
	data.add_money(123.0)
	if not svc.save(slot):
		errors.append("FileSaveBackend: save")
	if not backend.has_save(slot):
		errors.append("FileSaveBackend: has_save после save")
	var fresh := GameStateData.new()
	var fresh_premium := PremiumCurrencyService.new(host, 0)
	var load_svc := GameSaveService.new(fresh, fresh_premium, host, backend)
	if not load_svc.load(slot):
		errors.append("FileSaveBackend: load")
	if fresh.get_money() != data.get_money():
		errors.append("FileSaveBackend: восстановление money")
	if not backend.delete_save(slot):
		errors.append("FileSaveBackend: delete_save")
	if backend.has_save(slot):
		errors.append("FileSaveBackend: has_save после delete")
	host.free()


func _test_reset_progress(errors: Array[String]) -> void:
	var host := _SaveTestHost.new()
	var data := GameStateData.new()
	var premium := PremiumCurrencyService.new(host)
	var backend := MemorySaveBackend.new()
	var svc := GameSaveService.new(data, premium, host, backend)
	var starter := float(BlockDefs.starter_kit_cost())
	data.add_money(500.0)
	premium.grant(7, PremiumCurrencyService.Source.ADMIN)
	data.get_placed_blocks().append(BlockInstance.create("text_downloader", 0, 0, "blk_x", 3))
	svc.save("reset_slot")
	if not svc.reset_progress("reset_slot"):
		errors.append("reset_progress: возврат true")
	if data.get_money() != starter:
		errors.append("reset: money к стартовому")
	if premium.get_balance() != GameConstants.START_DIAMONDS:
		errors.append("reset: алмазы к стартовым")
	if not data.get_placed_blocks().is_empty():
		errors.append("reset: поле очищено")
	if backend.has_save("reset_slot"):
		errors.append("reset: слот удалён")
	host.free()


class _SaveTestHost:
	extends Node

	signal stats_changed
	signal queue_changed
	signal wiring_changed
	signal field_changed
