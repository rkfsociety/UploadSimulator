extends Control
## Рисует провода между ячейками и обрабатывает клики по портам.

@onready var wires_root: Control = %WiresRoot
@onready var modules_host: Control = %ModulesHost

var _ports: Array[ConnectionPort] = []
var _pending_out: ConnectionPort = null
var _line_nodes: Array[Line2D] = []


func _ready() -> void:
	await get_tree().process_frame
	_collect_ports()
	for port: ConnectionPort in _ports:
		port.port_pressed.connect(_on_port_pressed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	_on_wiring_changed()


func _process(_delta: float) -> void:
	_redraw_wires()


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
		if GameState.port_has_output_link(port.block_id, port.port_id):
			if _pending_out == port:
				GameState.disconnect_output_port(port.block_id, port.port_id)
				GameState.log_message.emit("Отключено: %s" % port.block_id)
				_clear_pending()
				return
		_set_pending(port)
		return
	if _pending_out == null:
		GameState.log_message.emit("Сначала выберите выход (круг или квадрат справа).")
		return
	GameState.try_connect_ports(
		_pending_out.block_id, _pending_out.port_id, port.block_id, port.port_id
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
				GameState
				. can_connect_ports(
					_pending_out.block_id,
					_pending_out.port_id,
					port.block_id,
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
	for link: Dictionary in GameState.wire_connections:
		var from_port := _find_port(link["from_block"], link["from_port"])
		var to_port := _find_port(link["to_block"], link["to_port"])
		if from_port == null or to_port == null:
			continue
		var line := Line2D.new()
		line.width = 3.0
		line.default_color = _wire_color(link)
		line.points = PackedVector2Array(
			[
				_port_center_local(from_port),
				_port_center_local(to_port),
			]
		)
		line.antialiased = true
		wires_root.add_child(line)
		_line_nodes.append(line)


func _wire_color(link: Dictionary) -> Color:
	var from_port := _find_port(link["from_block"], link["from_port"])
	if from_port and from_port.kind == ConnectionPort.Kind.MONEY:
		return Color(0.95, 0.78, 0.25, 0.9)
	return Color(0.45, 0.8, 1.0, 0.9)


func _find_port(block_id: String, port_id: String) -> ConnectionPort:
	for port: ConnectionPort in _ports:
		if port.block_id == block_id and port.port_id == port_id:
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
