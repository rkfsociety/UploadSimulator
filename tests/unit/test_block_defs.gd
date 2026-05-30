extends RefCounted
## Unit-тесты схемы блоков и разрешённых соединений.

var case_count := 10


func run() -> Array[String]:
	var errors: Array[String] = []
	if BlockDefs.starter_kit_cost() <= 0:
		errors.append("starter_kit_cost должен быть > 0")
	if not BlockDefs.is_downloader_type("text_downloader"):
		errors.append("text_downloader должен быть типом загрузчика")
	if BlockDefs.get_downloader_file_type("text_downloader") != "text":
		errors.append("text_downloader → file_type text")
	if BlockDefs.max_stored_files("text_downloader") != 100:
		errors.append("text_downloader → max_stored_files 100")
	if BlockDefs.max_stored_files("uploader") != 0:
		errors.append("uploader не хранит файлы")
	if BlockDefs.is_upgradeable("text_downloader"):
		errors.append("text_downloader не должен улучшаться")
	if BlockDefs.is_upgradeable("collector"):
		errors.append("collector не должен улучшаться")
	if not BlockDefs.is_singleton_type("network"):
		errors.append("network должен быть singleton")
	if not BlockDefs.is_allowed_wire("network", "net_out", "text_downloader", "net_in"):
		errors.append("network→text_downloader (канал) должно быть разрешено")
	if not BlockDefs.is_allowed_wire("text_downloader", "file_out", "uploader", "file_in"):
		errors.append("text_downloader→uploader должно быть разрешено")
	if BlockDefs.TYPES.has("storage"):
		errors.append("модуль storage удалён из TYPES")
	var money := BlockDefs.resolve_wire_ports("uploader", "collector")
	if money.is_empty() or money["from_port"] != "money_out":
		errors.append("uploader→collector должно использовать money_out")
	for type_id in BlockDefs.starter_kit_types():
		if not BlockDefs.TYPES.has(type_id):
			errors.append("стартовый тип отсутствует в TYPES: %s" % type_id)
		if type_id == "storage":
			errors.append("storage не должен быть в стартовом наборе")
	_test_network_singleton(errors)
	return errors


func _test_network_singleton(errors: Array[String]) -> void:
	var host := _SingletonTestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	field.bind_wiring(wiring)
	data.add_block_stock("network", 1)
	data.set_money(500.0)
	var placed := field.place_block("network", 0, 0)
	if not placed.is_ok():
		errors.append("singleton: place network")
		host.free()
		return
	if field.check_buy_block("network").is_ok():
		errors.append("singleton: нельзя купить вторую сеть на карте")
	if field.check_place_block("network", 12, 0).is_ok():
		errors.append("singleton: нельзя поставить вторую сеть")
	if not field.remove_block(placed.get_uid()).is_ok():
		errors.append("singleton: remove network")
	elif field.check_buy_block("network").is_ok():
		errors.append("singleton: нельзя купить пока модуль на складе")
	elif not field.place_block("network", 12, 0).is_ok():
		errors.append("singleton: после снятия можно поставить со склада")
	else:
		var uid := field.get_block_at(12, 0).uid
		field.remove_block(uid)
		data.set_block_stock("network", 0)
		if not field.check_buy_block("network").is_ok():
			errors.append("singleton: после полного снятия можно купить снова")
		elif not field.buy_block("network").is_ok():
			errors.append("singleton: buy network после снятия")
	host.free()


class _SingletonTestHost:
	extends Node

	signal log_message(text: String)
	signal wiring_changed
	signal wire_transfers_changed
	signal field_changed
	signal stats_changed
	signal block_purchased(type_id: String)
