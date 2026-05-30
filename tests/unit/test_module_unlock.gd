extends RefCounted
## Открытие типов модулей: ◆ → магазин $.

var case_count := 3


func run() -> Array[String]:
	var errors: Array[String] = []
	var data := GameStateData.new()
	for type_id in BlockDefs.starter_kit_types():
		if not data.is_module_type_unlocked(type_id):
			errors.append("стартовый модуль должен быть открыт: %s" % type_id)
	var shop_types: Array[String] = []
	for k in BlockDefs.TYPES:
		if data.is_module_type_unlocked(k):
			shop_types.append(k)
	if shop_types.size() != BlockDefs.starter_kit_types().size():
		errors.append("в магазине $ только открытые типы")
	data.unlock_module_type("network")
	if not data.is_module_type_unlocked("network"):
		errors.append("unlock_module_type должен отмечать тип")
	return errors
