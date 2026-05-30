extends RefCounted
## Unit-тесты схемы блоков и разрешённых соединений.

var case_count := 8


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
	if BlockDefs.is_upgradeable("text_downloader"):
		errors.append("text_downloader не должен улучшаться")
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
	return errors
