extends RefCounted
## Unit-тесты сервиса проводов без сцены.

var case_count := 4


func run() -> Array[String]:
	var errors: Array[String] = []
	var host := _TestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	var uids := _place_modules(field, data)
	var n_uid: String = uids.get("network", "")
	var d_uid: String = uids.get("text_downloader", "")
	var u_uid: String = uids.get("uploader", "")
	if n_uid == "" or d_uid == "" or u_uid == "":
		errors.append("не удалось разместить модули для теста проводов")
		return errors
	if not wiring.can_connect_ports(n_uid, "net_out", d_uid, "net_in"):
		errors.append("can_connect network→downloader")
	if not wiring.try_connect_ports(n_uid, "net_out", d_uid, "net_in").is_ok():
		errors.append("try_connect network→downloader")
	if wiring.get_download_chain().is_empty():
		errors.append("download_chain пуста после network→downloader")
	if not wiring.try_connect_ports(d_uid, "file_out", u_uid, "file_in").is_ok():
		errors.append("try_connect downloader→uploader")
	if not wiring.get_file_chain().is_empty():
		errors.append("file_chain не должна быть полной без uploader→network")
	wiring.try_connect_ports(u_uid, "net_out", n_uid, "net_in")
	if wiring.get_file_chain().is_empty():
		errors.append("полная file_chain после всех проводов")
	if wiring.get_file_chain().has("storage"):
		errors.append("file_chain не должна содержать storage")
	_test_module_level(errors)
	return errors


## Соединение на уровне модулей (один центральный порт): авто-выбор портов,
## авто-своп направления и тоггл — на отдельном чистом состоянии.
func _test_module_level(errors: Array[String]) -> void:
	var host := _TestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	var wiring := GameWiringService.new(data, host, field)
	var uids := _place_modules(field, data)
	var n_uid: String = uids.get("network", "")
	var d_uid: String = uids.get("text_downloader", "")
	if n_uid == "" or d_uid == "":
		errors.append("module-level: не удалось разместить модули")
		return
	# Кликнули загрузчик, затем сеть — направление обязано развернуться в network→downloader.
	var r := wiring.resolve_module_connection(d_uid, n_uid)
	if (
		r.get("from_uid", "") != n_uid
		or r.get("from_port", "") != "net_out"
		or r.get("to_uid", "") != d_uid
		or r.get("to_port", "") != "net_in"
	):
		errors.append("module-level: авто-своп должен дать network→downloader")
	if not wiring.can_connect_modules(n_uid, d_uid):
		errors.append("module-level: can_connect_modules до соединения")
	if not wiring.try_connect_modules(d_uid, n_uid).is_ok():
		errors.append("module-level: try_connect_modules не соединил")
	if wiring.get_download_chain().is_empty():
		errors.append("module-level: download_chain пуста после соединения")
	# Повторный вызов той же пары — снятие провода (тоггл).
	wiring.try_connect_modules(n_uid, d_uid)
	if not wiring.get_download_chain().is_empty():
		errors.append("module-level: повторный try_connect_modules должен снять провод")
	# Несоединимая пара (две «Сети» нельзя) — пустой резолв.
	if not wiring.resolve_module_connection(n_uid, n_uid).is_empty():
		errors.append("module-level: модуль сам с собой не должен резолвиться")


func _place_modules(field: GameFieldService, data: GameStateData) -> Dictionary:
	var uids := {}
	var gx := 0
	for type_id in ["network", "text_downloader", "uploader"]:
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
