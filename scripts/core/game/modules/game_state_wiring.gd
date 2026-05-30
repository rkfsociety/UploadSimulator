extends RefCounted
class_name GameStateWiring
## Провода между портами модулей.

var _svc: GameWiringService


func _init(svc: GameWiringService) -> void:
	_svc = svc


func is_wired(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	return _svc.is_wired(from_uid, from_port, to_uid, to_port)


func can_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> bool:
	return _svc.can_connect_ports(from_uid, from_port, to_uid, to_port)


func check_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> GameOperationResult:
	return _svc.check_connect_ports(from_uid, from_port, to_uid, to_port)


func port_has_output_link(uid: String, port_id: String) -> bool:
	return _svc.port_has_output_link(uid, port_id)


func port_has_input_link(uid: String, port_id: String) -> bool:
	return _svc.port_has_input_link(uid, port_id)


func try_connect_ports(
	from_uid: String, from_port: String, to_uid: String, to_port: String
) -> GameOperationResult:
	return _svc.try_connect_ports(from_uid, from_port, to_uid, to_port)


func resolve_module_connection(a_uid: String, b_uid: String) -> Dictionary:
	return _svc.resolve_module_connection(a_uid, b_uid)


func can_connect_modules(a_uid: String, b_uid: String) -> bool:
	return _svc.can_connect_modules(a_uid, b_uid)


func try_connect_modules(a_uid: String, b_uid: String) -> GameOperationResult:
	return _svc.try_connect_modules(a_uid, b_uid)


func disconnect_output_port(uid: String, port_id: String) -> void:
	_svc.disconnect_output_port(uid, port_id)


func disconnect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> void:
	_svc.disconnect_ports(from_uid, from_port, to_uid, to_port)


func get_download_chain() -> Dictionary:
	return _svc.get_download_chain()


func get_file_chain() -> Dictionary:
	return _svc.get_file_chain()


func get_money_chain() -> Dictionary:
	return _svc.get_money_chain()
