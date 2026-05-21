extends RefCounted
class_name PortUtils
## Общая логика портов: поиск, подсветка, цвета проводов.


## Собирает порты со всех корневых узлов (например PlacedBlock).
static func gather_ports_from_nodes(nodes: Array, on_pressed: Callable) -> Array[ConnectionPort]:
	var ports: Array[ConnectionPort] = []
	for node in nodes:
		if node is Node:
			_gather_ports_recursive(node, ports, on_pressed)
	return ports


static func _gather_ports_recursive(node: Node, ports: Array[ConnectionPort], on_pressed: Callable) -> void:
	for child in node.get_children():
		if child is ConnectionPort:
			var port: ConnectionPort = child
			ports.append(port)
			if not port.port_pressed.is_connected(on_pressed):
				port.port_pressed.connect(on_pressed)
		_gather_ports_recursive(child, ports, on_pressed)


static func find_port(ports: Array[ConnectionPort], uid: String, port_id: String) -> ConnectionPort:
	for port: ConnectionPort in ports:
		if port.instance_uid == uid and port.port_id == port_id:
			return port
	return null


static func port_center_in_local(port: ConnectionPort, space: Control) -> Vector2:
	return space.get_global_transform().affine_inverse() * port.get_global_rect().get_center()


static func wire_color_for_port(port: ConnectionPort) -> Color:
	if port.kind == ConnectionPort.Kind.MONEY:
		return MinimalUI.WIRE_MONEY
	return MinimalUI.WIRE_FILE


static func wire_color_for_kind(kind: String) -> Color:
	return MinimalUI.WIRE_MONEY if kind == "money" else MinimalUI.WIRE_FILE


static func refresh_highlights(
	ports: Array[ConnectionPort],
	pending_out: ConnectionPort,
) -> void:
	for port: ConnectionPort in ports:
		var can_connect := false
		if pending_out != null and port.direction == ConnectionPort.Dir.IN:
			can_connect = GameState.wiring.can_connect_ports(
				pending_out.instance_uid,
				pending_out.port_id,
				port.instance_uid,
				port.port_id,
			)
		port.set_highlight(port == pending_out, can_connect)


static func wire_flow_speed(link: WireLink) -> float:
	var from_type: String = GameState.field.get_instance_type(link.from_uid)
	if from_type == "downloader" and not GameState.access.get_download_queue().is_empty():
		return FieldMapConstants.WIRE_FLOW_ACTIVE
	if from_type == "storage" and not GameState.access.get_upload_queue().is_empty():
		return FieldMapConstants.WIRE_FLOW_ACTIVE
	if from_type == "uploader" and GameState.access.get_uploader_balance() > 0.0:
		return FieldMapConstants.WIRE_FLOW_ACTIVE
	return FieldMapConstants.WIRE_FLOW_IDLE
