extends RefCounted
## Unit-тесты сервиса проводов без сцены.

var case_count := 3


func run() -> Array[String]:
	var errors: Array[String] = []
	var host := _TestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	var uids := _place_modules(field, data)
	var n_uid: String = uids.get("network", "")
	var s_uid: String = uids.get("storage", "")
	if n_uid == "" or s_uid == "":
		errors.append("не удалось разместить модули для теста проводов")
		return errors
	if not wiring.can_connect_ports(n_uid, "file_out", s_uid, "file_in"):
		errors.append("can_connect network→storage")
	if not wiring.try_connect_ports(n_uid, "file_out", s_uid, "file_in").is_ok():
		errors.append("try_connect network→storage")
	# Цепочка неполная (нет storage→network) — get_file_chain должна быть пустой
	if not wiring.get_file_chain().is_empty():
		errors.append("file_chain не должна быть полной только с network→storage")
	if wiring.can_connect_ports(n_uid, "file_out", n_uid, "file_in"):
		errors.append("network→network должно быть запрещено")
	if wiring.try_connect_ports(s_uid, "file_out", n_uid, "file_in").is_ok():
		var chain := wiring.get_file_chain()
		if chain.is_empty():
			errors.append("полная file_chain после storage→network")
	return errors


func _place_modules(field: GameFieldService, data: GameStateData) -> Dictionary:
	var uids := {}
	var gx := 0
	for type_id in ["network", "storage"]:
		data.add_block_stock(type_id, 1)
		var place := field.place_block(type_id, gx, 0)
		uids[type_id] = place.get_uid() if place.is_ok() else ""
		gx += GridDefs.block_cells(type_id).x
	return uids


class _TestHost:
	extends Node

	signal log_message(text: String)
	signal wiring_changed
	signal field_changed
	signal stats_changed
	signal block_purchased(type_id: String)
	signal placement_requested(type_id: String)
	signal queue_changed
