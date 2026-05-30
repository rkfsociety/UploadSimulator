extends RefCounted
class_name GameWiringService
## Провода между портами модулей.

var _data: GameStateData
var _host: Node
var _field: GameFieldService
var _pipeline: GamePipelineService = null


func _init(data: GameStateData, host: Node, field: GameFieldService) -> void:
	_data = data
	_host = host
	_field = field


func bind_pipeline(pipeline: GamePipelineService) -> void:
	_pipeline = pipeline


func is_wired(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if link.matches(from_uid, from_port, to_uid, to_port):
			return true
	return false


func can_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> bool:
	return check_connect_ports(from_uid, from_port, to_uid, to_port).is_ok()


## Проверка нового провода out→in.
## Один провод на порт: WIRING_OUTPUT_BUSY / WIRING_INPUT_BUSY — линейный пайплайн без разветвлений.
## Типы только из ALLOWED_WIRES; направление out→in и одинаковый kind (file/money/net).
func check_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> GameOperationResult:
	var types := _port_types(from_uid, from_port, to_uid, to_port)
	if types[0] == "" or types[2] == "":
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_INVALID_MODULE)
	if not BlockDefs.is_allowed_wire(types[0], types[1], types[2], types[3]):
		return GameOperationResult.fail(
			GameOperationResult.Code.WIRING_TYPE_NOT_ALLOWED,
			_connection_error(types[0], types[2])
		)
	var from_def: Dictionary = BlockDefs.PORT_DEFS.get(types[0], {}).get(from_port, {})
	var to_def: Dictionary = BlockDefs.PORT_DEFS.get(types[2], {}).get(to_port, {})
	if from_def.is_empty() or to_def.is_empty():
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_INVALID_MODULE)
	if from_def.get("dir", "") != "out" or to_def.get("dir", "") != "in":
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_PORT_DIRECTION)
	if from_def.get("kind", "") != to_def.get("kind", ""):
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_PORT_KIND_MISMATCH)
	if port_has_output_link(from_uid, from_port):
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_OUTPUT_BUSY)
	if port_has_input_link(to_uid, to_port):
		return GameOperationResult.fail(GameOperationResult.Code.WIRING_INPUT_BUSY)
	return GameOperationResult.ok()


## У выхода уже есть провод — второй исходящий с того же out запрещён.
func port_has_output_link(uid: String, port_id: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if link.from_uid == uid and link.from_port == port_id:
			return true
	return false


## У входа уже есть провод — второй входящий на тот же in запрещён.
func port_has_input_link(uid: String, port_id: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if link.to_uid == uid and link.to_port == port_id:
			return true
	return false


func try_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> GameOperationResult:
	if is_wired(from_uid, from_port, to_uid, to_port):
		disconnect_ports(from_uid, from_port, to_uid, to_port)
		_host.log_message.emit("Провод снят.")
		_host.wiring_changed.emit()
		return GameOperationResult.ok()
	var check := check_connect_ports(from_uid, from_port, to_uid, to_port)
	if not check.is_ok():
		return check
	_data.get_wire_connections().append(WireLink.create(from_uid, from_port, to_uid, to_port))
	_host.log_message.emit("Соединено: %s → %s" % [_type_name(from_uid), _type_name(to_uid)])
	_host.wiring_changed.emit()
	return GameOperationResult.ok()


func disconnect_output_port(uid: String, port_id: String) -> void:
	var links := _data.get_wire_connections()
	for i in range(links.size() - 1, -1, -1):
		if links[i].from_uid == uid and links[i].from_port == port_id:
			links.remove_at(i)
	_host.wiring_changed.emit()
	_notify_topology_changed()


func disconnect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> void:
	var links := _data.get_wire_connections()
	for i in range(links.size() - 1, -1, -1):
		if links[i].matches(from_uid, from_port, to_uid, to_port):
			links.remove_at(i)
	_notify_topology_changed()


func _notify_topology_changed() -> void:
	if _pipeline == null:
		return
	if get_download_chain().is_empty():
		_pipeline.cancel_download_queues()
	if get_file_chain().is_empty():
		_pipeline.cancel_upload_transfers()


## Скачивание: сеть → Text Downloader (достаточно для накопления файлов).
func get_download_chain() -> Dictionary:
	var net_dl := _find_network_to_downloader()
	if net_dl.is_empty():
		return {}
	return {
		"network": str(net_dl.get("from_uid", "")),
		"downloader": str(net_dl.get("to_uid", "")),
	}


## Полная цепочка выгрузки: сеть→загрузчик→аплоудер→сеть.
func get_file_chain() -> Dictionary:
	var files_a := _find_downloader_to_uploader()
	if files_a.is_empty():
		return {}
	var net_dl := _find_network_to_downloader()
	if net_dl.is_empty() or net_dl.get("to_uid", "") != files_a.get("from_uid", ""):
		return {}
	var net_ul := _find_wired_pair("uploader", "net_out", "network", "net_in")
	if net_ul.is_empty():
		return {}
	var net_uid := str(net_dl.get("from_uid", ""))
	if str(net_ul.get("to_uid", "")) != net_uid:
		return {}
	return {
		"network": net_uid,
		"downloader": files_a.get("from_uid", ""),
		"uploader": files_a.get("to_uid", ""),
	}


## Цепочка денег: uploader→collector (money_out→money_in).
func get_money_chain() -> Dictionary:
	return _find_wired_pair("uploader", "money_out", "collector", "money_in")


func _port_types(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> Array[String]:
	return [
		_field.get_instance_type(from_uid),
		from_port,
		_field.get_instance_type(to_uid),
		to_port,
	]


func _find_wired_pair(
	from_type: String, from_port: String, to_type: String, to_port: String
) -> Dictionary:
	for link: WireLink in _data.get_wire_connections():
		if (
			_field.get_instance_type(link.from_uid) == from_type
			and link.from_port == from_port
			and _field.get_instance_type(link.to_uid) == to_type
			and link.to_port == to_port
		):
			return {"from_uid": link.from_uid, "to_uid": link.to_uid}
	return {}


func _find_downloader_to_uploader() -> Dictionary:
	for link: WireLink in _data.get_wire_connections():
		if link.from_port != "file_out" or link.to_port != "file_in":
			continue
		if not BlockDefs.is_downloader_type(_field.get_instance_type(link.from_uid)):
			continue
		if _field.get_instance_type(link.to_uid) != "uploader":
			continue
		return {"from_uid": link.from_uid, "to_uid": link.to_uid}
	return {}


func _find_network_to_downloader() -> Dictionary:
	for link: WireLink in _data.get_wire_connections():
		if link.from_port != "net_out" or link.to_port != "net_in":
			continue
		if _field.get_instance_type(link.from_uid) != "network":
			continue
		if not BlockDefs.is_downloader_type(_field.get_instance_type(link.to_uid)):
			continue
		return {"from_uid": link.from_uid, "to_uid": link.to_uid}
	return {}


func _connection_error(from_type: String, to_type: String) -> String:
	if BlockDefs.is_downloader_type(from_type) and to_type == "uploader":
		return "Нельзя напрямую: нужен провод file_out → file_in."
	if BlockDefs.is_downloader_type(from_type) and to_type == "collector":
		return "Нельзя: загрузчик → коллектор."
	if from_type == "network" and to_type == "collector":
		return "Нельзя: сеть → коллектор. Деньги идут через аплоудер."
	if from_type == "network" and to_type == "network":
		return "Нельзя соединять два модуля «Сеть»."
	return "Соединение недоступно."


func _type_name(uid: String) -> String:
	return BlockDefs.TYPES.get(_field.get_instance_type(uid), {}).get("name", uid)
