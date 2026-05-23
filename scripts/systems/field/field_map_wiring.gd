extends RefCounted
class_name FieldMapWiring
## Провода между портами и превью линии к курсору (батч через RenderingServer).

var _host: Control
var _wires_root: Control
var _blocks: FieldMapBlocks
var _renderer: WireBatchRenderer

var _ports: Array[ConnectionPort] = []
var _segments: Array[Dictionary] = []
var _pending_out: ConnectionPort = null
var _pending_segment: Dictionary = {}
var wire_cursor_screen: Vector2 = Vector2.ZERO


func _init(host: Control, wires_root: Control, blocks: FieldMapBlocks) -> void:
	_host = host
	_wires_root = wires_root
	_blocks = blocks
	_renderer = WireBatchRenderer.new()
	_renderer.name = "WireBatchRenderer"
	_wires_root.add_child(_renderer)


func collect_ports() -> void:
	_ports = PortUtils.gather_ports_from_nodes(_blocks.get_nodes().values(), _on_port_pressed)


func clear_pending() -> void:
	_pending_out = null
	_renderer.clear_pending()
	PortUtils.refresh_highlights(_ports, _pending_out)


func rebuild_wires() -> void:
	WirePool.release_segments(_segments)
	_segments.clear()
	for link: WireLink in GameState.access.get_wire_connections():
		var from_p := PortUtils.find_port(_ports, link.from_uid, link.from_port)
		var to_p := PortUtils.find_port(_ports, link.to_uid, link.to_port)
		if from_p == null or to_p == null:
			continue
		var kind: String = "money" if from_p.kind == ConnectionPort.Kind.MONEY else "file"
		var pooled := WirePool.acquire_link()
		pooled.copy_from(link)
		var seg := WirePool.acquire_segment()
		seg["link"] = pooled
		seg["color"] = PortUtils.wire_color_for_kind(kind)
		seg["animate"] = true
		seg["speed"] = PortUtils.wire_flow_speed(pooled)
		_segments.append(seg)
	update_positions()


func update_positions() -> void:
	for seg: Dictionary in _segments:
		var link: Variant = seg.get("link", null)
		if link is not WireLink:
			continue
		var wire: WireLink = link
		var from_p := PortUtils.find_port(_ports, wire.from_uid, wire.from_port)
		var to_p := PortUtils.find_port(_ports, wire.to_uid, wire.to_port)
		if from_p == null or to_p == null:
			continue
		seg["from"] = PortUtils.port_center_in_local(from_p, _wires_root)
		seg["to"] = PortUtils.port_center_in_local(to_p, _wires_root)
	_renderer.set_segments(_segments)
	_update_pending_wire()


func set_visible_rect(rect: Rect2) -> void:
	_renderer.set_visible_rect(rect)


func set_cursor_screen(pos: Vector2) -> void:
	wire_cursor_screen = pos
	_update_pending_wire()


func _on_port_pressed(port: ConnectionPort) -> void:
	if port.direction == ConnectionPort.Dir.OUT:
		if GameState.wiring.port_has_output_link(port.instance_uid, port.port_id):
			if _pending_out == port:
				GameState.wiring.disconnect_output_port(port.instance_uid, port.port_id)
				clear_pending()
				return
		_pending_out = port
		_update_pending_wire()
		PortUtils.refresh_highlights(_ports, _pending_out)
		return
	if _pending_out == null:
		GameState.log_message.emit("Сначала выход.")
		return
	GameState.report_operation(
		GameState.wiring.try_connect_ports(
			_pending_out.instance_uid,
			_pending_out.port_id,
			port.instance_uid,
			port.port_id,
		)
	)
	clear_pending()


func _update_pending_wire() -> void:
	if _pending_out == null:
		_renderer.clear_pending()
		return
	var from_pos := PortUtils.port_center_in_local(_pending_out, _wires_root)
	var global_pos: Vector2 = _host.get_global_transform() * wire_cursor_screen
	var to_pos := _wires_root.get_global_transform().affine_inverse() * global_pos
	_pending_segment["from"] = from_pos
	_pending_segment["to"] = to_pos
	_pending_segment["color"] = PortUtils.wire_color_for_port(_pending_out)
	_renderer.set_pending(_pending_segment)
