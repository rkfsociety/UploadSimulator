extends RefCounted
class_name GameWiringService
## Провода между портами модулей.

var _data: GameStateData
var _host: Node
var _field: GameFieldService


func _init(data: GameStateData, host: Node, field: GameFieldService) -> void:
	_data = data
	_host = host
	_field = field


func is_wired(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if (
			link.from_uid == from_uid
			and link.from_port == from_port
			and link.to_uid == to_uid
			and link.to_port == to_port
		):
			return true
	return false


func can_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> bool:
	var types := _port_types(from_uid, from_port, to_uid, to_port)
	if types[0] == "" or types[2] == "":
		return false
	if not BlockDefs.is_allowed_wire(types[0], types[1], types[2], types[3]):
		return false
	var from_def: Dictionary = BlockDefs.PORT_DEFS.get(types[0], {}).get(from_port, {})
	var to_def: Dictionary = BlockDefs.PORT_DEFS.get(types[2], {}).get(to_port, {})
	if from_def.is_empty() or to_def.is_empty():
		return false
	if from_def.get("dir", "") != "out" or to_def.get("dir", "") != "in":
		return false
	if from_def.get("kind", "") != to_def.get("kind", ""):
		return false
	if port_has_output_link(from_uid, from_port):
		return false
	if port_has_input_link(to_uid, to_port):
		return false
	return true


func port_has_output_link(uid: String, port_id: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if link.from_uid == uid and link.from_port == port_id:
			return true
	return false


func port_has_input_link(uid: String, port_id: String) -> bool:
	for link: WireLink in _data.get_wire_connections():
		if link.to_uid == uid and link.to_port == port_id:
			return true
	return false


func try_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> bool:
	if is_wired(from_uid, from_port, to_uid, to_port):
		disconnect_ports(from_uid, from_port, to_uid, to_port)
		_host.log_message.emit("Провод снят.")
		_host.wiring_changed.emit()
		return true
	if not can_connect_ports(from_uid, from_port, to_uid, to_port):
		_host.log_message.emit(
			_connection_error(_field.get_instance_type(from_uid), _field.get_instance_type(to_uid))
		)
		return false
	var link := WireLink.new()
	link.from_uid = from_uid
	link.from_port = from_port
	link.to_uid = to_uid
	link.to_port = to_port
	_data.get_wire_connections().append(link)
	_host.log_message.emit("Соединено: %s → %s" % [_type_name(from_uid), _type_name(to_uid)])
	_host.wiring_changed.emit()
	return true


func disconnect_output_port(uid: String, port_id: String) -> void:
	var links := _data.get_wire_connections()
	for i in range(links.size() - 1, -1, -1):
		if links[i].from_uid == uid and links[i].from_port == port_id:
			links.remove_at(i)
	_host.wiring_changed.emit()


func disconnect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> void:
	var links := _data.get_wire_connections()
	for i in range(links.size() - 1, -1, -1):
		var link: WireLink = links[i]
		if (
			link.from_uid == from_uid
			and link.from_port == from_port
			and link.to_uid == to_uid
			and link.to_port == to_port
		):
			links.remove_at(i)


func get_file_chain() -> Dictionary:
	var a := _find_wired_pair("downloader", "file_out", "storage", "file_in")
	if a.is_empty():
		return {}
	var b := _find_wired_pair("storage", "file_out", "uploader", "file_in")
	if b.is_empty() or b.get("from_uid", "") != a.get("to_uid", ""):
		return {}
	return {
		"downloader": a.get("from_uid", ""),
		"storage": a.get("to_uid", ""),
		"uploader": b.get("to_uid", ""),
	}


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


func _connection_error(from_type: String, to_type: String) -> String:
	if from_type == "downloader" and to_type == "uploader":
		return "Нельзя напрямую: загрузчик → аплоудер. Нужно хранилище."
	if from_type == "downloader" and to_type == "collector":
		return "Нельзя: загрузчик → коллектор."
	if from_type == "storage" and to_type == "collector":
		return "Нельзя: хранилище → коллектор."
	return "Соединение недоступно."


func _type_name(uid: String) -> String:
	return BlockDefs.TYPES.get(_field.get_instance_type(uid), {}).get("name", uid)
