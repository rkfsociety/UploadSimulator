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
	var d_uid: String = uids.get("downloader", "")
	var s_uid: String = uids.get("storage", "")
	var u_uid: String = uids.get("uploader", "")
	if d_uid == "" or s_uid == "" or u_uid == "":
		errors.append("не удалось разместить модули для теста проводов")
		return errors
	if not wiring.can_connect_ports(d_uid, "file_out", s_uid, "file_in"):
		errors.append("can_connect downloader→storage")
	if not wiring.try_connect_ports(d_uid, "file_out", s_uid, "file_in").is_ok():
		errors.append("try_connect downloader→storage")
	if wiring.get_file_chain().is_empty():
		errors.append("file_chain пуст после downloader→storage (нужен ещё storage→uploader)")
	if wiring.can_connect_ports(d_uid, "file_out", u_uid, "file_in"):
		errors.append("downloader→uploader должно быть запрещено")
	if wiring.try_connect_ports(s_uid, "file_out", u_uid, "file_in").is_ok():
		var chain := wiring.get_file_chain()
		if chain.is_empty():
			errors.append("полная file_chain после storage→uploader")
	return errors


func _place_modules(field: GameFieldService, data: GameStateData) -> Dictionary:
	var uids := {}
	var gx := 0
	for type_id in ["downloader", "storage", "uploader"]:
		data.add_block_stock(type_id, 1)
		var place := field.place_block(type_id, gx, 0)
		uids[type_id] = place.get_uid() if place.is_ok() else ""
		gx += GridDefs.BLOCK_CELLS_W
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
