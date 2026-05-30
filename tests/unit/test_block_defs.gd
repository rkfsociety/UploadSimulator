extends RefCounted
## Unit-тесты схемы блоков и разрешённых соединений.

var case_count := 5


func run() -> Array[String]:
	var errors: Array[String] = []
	if BlockDefs.starter_kit_cost() <= 0:
		errors.append("starter_kit_cost должен быть > 0")
	if not BlockDefs.is_allowed_wire("network", "file_out", "storage", "file_in"):
		errors.append("network→storage (скачивание) должно быть разрешено")
	if not BlockDefs.is_allowed_wire("storage", "file_out", "network", "file_in"):
		errors.append("storage→network (выгрузка) должно быть разрешено")
	if BlockDefs.is_allowed_wire("network", "file_out", "network", "file_in"):
		errors.append("network→network напрямую запрещено")
	var resolved := BlockDefs.resolve_wire_ports("storage", "network")
	if resolved.is_empty():
		errors.append("storage→network должно резолвиться в порты")
	elif resolved["from_port"] != "file_out" or resolved["to_port"] != "file_in":
		errors.append("неверные порты storage→network")
	var money := BlockDefs.resolve_wire_ports("network", "collector")
	if money.is_empty() or money["from_port"] != "money_out":
		errors.append("network→collector должно использовать money_out")
	for type_id in BlockDefs.starter_kit_types():
		if not BlockDefs.TYPES.has(type_id):
			errors.append("стартовый тип отсутствует в TYPES: %s" % type_id)
	return errors
