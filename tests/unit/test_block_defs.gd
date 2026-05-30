extends RefCounted
## Unit-тесты схемы блоков и разрешённых соединений.

var case_count := 6


func run() -> Array[String]:
	var errors: Array[String] = []
	if BlockDefs.starter_kit_cost() <= 0:
		errors.append("starter_kit_cost должен быть > 0")
	if not BlockDefs.is_allowed_wire("network", "net_out", "downloader", "net_in"):
		errors.append("network→downloader (канал) должно быть разрешено")
	if not BlockDefs.is_allowed_wire("downloader", "file_out", "storage", "file_in"):
		errors.append("downloader→storage должно быть разрешено")
	if not BlockDefs.is_allowed_wire("storage", "file_out", "uploader", "file_in"):
		errors.append("storage→uploader должно быть разрешено")
	if not BlockDefs.is_allowed_wire("uploader", "net_out", "network", "net_in"):
		errors.append("uploader→network (канал) должно быть разрешено")
	if BlockDefs.is_allowed_wire("downloader", "file_out", "uploader", "file_in"):
		errors.append("downloader→uploader напрямую запрещено")
	var money := BlockDefs.resolve_wire_ports("uploader", "collector")
	if money.is_empty() or money["from_port"] != "money_out":
		errors.append("uploader→collector должно использовать money_out")
	for type_id in BlockDefs.starter_kit_types():
		if not BlockDefs.TYPES.has(type_id):
			errors.append("стартовый тип отсутствует в TYPES: %s" % type_id)
	return errors
