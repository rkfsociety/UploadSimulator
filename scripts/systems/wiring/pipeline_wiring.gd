extends Control
## Рисует провода между ячейками и обрабатывает клики по портам.

const _AsyncSafety := preload("res://scripts/core/async_safety.gd")

@onready var wires_root: Control = %WiresRoot
@onready var modules_host: Control = %ModulesHost

var _ports: Array[ConnectionPort] = []
var _pending_out: ConnectionPort = null
var _line_nodes: Array[Line2D] = []


func _ready() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	# Узел проводки могли удалить до завершения отложенной инициализации
	if not _AsyncSafety.is_node_in_scene(self):
		return
	_collect_ports()
	for port: ConnectionPort in _ports:
		port.port_pressed.connect(_on_port_pressed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	_on_wiring_changed()


func _collect_ports() -> void:
	_ports.clear()
	_gather_ports(modules_host)


func _gather_ports(node: Node) -> void:
	for child in node.get_children():
		if child is ConnectionPort:
			_ports.append(child)
		_gather_ports(child)


func _on_port_pressed(port: ConnectionPort) -> void:
	if port.direction == ConnectionPort.Dir.OUT:
		if GameState.wiring.port_has_output_link(port.instance_uid, port.port_id):
			if _pending_out == port:
				GameState.wiring.disconnect_output_port(port.instance_uid, port.port_id)
				GameState.log_message.emit("Отключено: %s" % port.instance_uid)
				_clear_pending()
				return
		_set_pending(port)
		return
	if _pending_out == null:
		GameState.log_message.emit("Сначала выберите выход (круг или квадрат справа).")
		return
	GameState.report_operation(
		GameState.wiring.try_connect_ports(
			_pending_out.instance_uid,
			_pending_out.port_id,
			port.instance_uid,
			port.port_id,
		)
	)
	_clear_pending()


func _set_pending(port: ConnectionPort) -> void:
	_pending_out = port
	_refresh_port_highlights()
	GameState.log_message.emit("Выбран выход: %s" % port.tooltip_text)


func _clear_pending() -> void:
	_pending_out = null
	_refresh_port_highlights()


func _refresh_port_highlights() -> void:
	for port: ConnectionPort in _ports:
		var valid := false
		if _pending_out != null and port.direction == ConnectionPort.Dir.IN:
			valid = (
				GameState.wiring.can_connect_ports(
					_pending_out.instance_uid,
					_pending_out.port_id,
					port.instance_uid,
					port.port_id,
				)
			)
		port.set_highlight(port == _pending_out, valid)


func _on_wiring_changed() -> void:
	_clear_pending()
	_redraw_wires()
	_refresh_port_highlights()


func _redraw_wires() -> void:
	for line: Line2D in _line_nodes:
		line.queue_free()
	_line_nodes.clear()
	for link: WireLink in GameState.access.get_wire_connections():
		var from_port := _find_port(link.from_uid, link.from_port)
		var to_port := _find_port(link.to_uid, link.to_port)
		if from_port == null or to_port == null:
			continue
		var from_pos := _port_center_local(from_port)
		var to_pos := _port_center_local(to_port)
		var path := WireRouteUtils.build_path(
			from_pos, to_pos, from_port.direction, to_port.direction
		)
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = _wire_color(link)
		line.points = path
		line.antialiased = true
		wires_root.add_child(line)
		_line_nodes.append(line)


func _wire_color(link: WireLink) -> Color:
	var from_port := _find_port(link.from_uid, link.from_port)
	if from_port and from_port.kind == ConnectionPort.Kind.MONEY:
		return Color(0.95, 0.78, 0.25, 0.9)
	return Color(0.45, 0.8, 1.0, 0.9)


func _find_port(instance_uid: String, port_id: String) -> ConnectionPort:
	for port: ConnectionPort in _ports:
		if port.instance_uid == instance_uid and port.port_id == port_id:
			return port
	return null


func _port_center_local(port: ConnectionPort) -> Vector2:
	return wires_root.get_global_transform().affine_inverse() * port.get_global_rect().get_center()


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_RIGHT
	):
		_clear_pending()
