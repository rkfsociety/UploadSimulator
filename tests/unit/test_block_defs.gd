extends RefCounted
## Unit-тесты схемы блоков и разрешённых соединений.

var case_count := 5


func run() -> Array[String]:
	var errors: Array[String] = []
	if BlockDefs.starter_kit_cost() <= 0:
		errors.append("starter_kit_cost должен быть > 0")
	if not BlockDefs.is_allowed_wire("downloader", "file_out", "storage", "file_in"):
		errors.append("downloader→storage должно быть разрешено")
	if BlockDefs.is_allowed_wire("downloader", "file_out", "uploader", "file_in"):
		errors.append("downloader→uploader напрямую запрещено")
	var resolved := BlockDefs.resolve_wire_ports("storage", "uploader")
	if resolved.is_empty():
		errors.append("storage→uploader должно резолвиться в порты")
	elif resolved["from_port"] != "file_out" or resolved["to_port"] != "file_in":
		errors.append("неверные порты storage→uploader")
	for type_id in BlockDefs.starter_kit_types():
		if not BlockDefs.TYPES.has(type_id):
			errors.append("стартовый тип отсутствует в TYPES: %s" % type_id)
	return errors
