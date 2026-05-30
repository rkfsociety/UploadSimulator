extends RefCounted
class_name FieldMapWiring
## Провода между портами и превью линии к курсору (батч через RenderingServer).

var _host: Control
var _wires_root: Control
var _blocks: FieldMapBlocks
var _renderer: WireBatchRenderer
var _token_layer: WireFileTokenLayer

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
	_token_layer = WireFileTokenLayer.new()
	_token_layer.name = "WireFileTokenLayer"
	_token_layer.z_index = FieldMapConstants.WIRES_Z_INDEX + 1
	_wires_root.add_child(_token_layer)


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
		var from_p := PortUtils.find_module_port(_ports, link.from_uid)
		var to_p := PortUtils.find_module_port(_ports, link.to_uid)
		if from_p == null or to_p == null:
			continue
		var kind: String = _link_kind(link)
		var pooled := WirePool.acquire_link()
		pooled.copy_from(link)
		var seg := WirePool.acquire_segment()
		seg["link"] = pooled
		seg["color"] = PortUtils.wire_color_for_kind(kind)
		_segments.append(seg)
	update_positions()


func refresh_tokens() -> void:
	_token_layer.refresh()


func update_positions() -> void:
	var obstacles := _gather_obstacle_rects()
	for seg: Dictionary in _segments:
		var link: Variant = seg.get("link", null)
		if link is not WireLink:
			continue
		var wire: WireLink = link
		var from_p := PortUtils.find_module_port(_ports, wire.from_uid)
		var to_p := PortUtils.find_module_port(_ports, wire.to_uid)
		if from_p == null or to_p == null:
			continue
		seg["from"] = PortUtils.port_center_in_local(from_p, _wires_root)
		seg["to"] = PortUtils.port_center_in_local(to_p, _wires_root)
		var path := WireRouteUtils.build_path(
			seg["from"],
			seg["to"],
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
			_obstacles_except(obstacles, [wire.from_uid, wire.to_uid]),
		)
		# Обрезаем концы по краям модулей — линия «выходит» из края (перекрестие).
		seg["path"] = WireRouteUtils.trim_path_to_rects(
			path, _rect_for(obstacles, wire.from_uid), _rect_for(obstacles, wire.to_uid)
		)
	_renderer.set_segments(_segments)
	_token_layer.set_segments(_segments)
	_update_pending_wire()


## Прямоугольник модуля по uid из списка препятствий (или пустой, если не найден).
func _rect_for(rects: Array[Dictionary], uid: String) -> Rect2:
	for entry: Dictionary in rects:
		if str(entry["uid"]) == uid:
			return entry["rect"]
	return Rect2()


func set_visible_rect(rect: Rect2) -> void:
	_renderer.set_visible_rect(rect)


func set_cursor_screen(pos: Vector2) -> void:
	wire_cursor_screen = pos
	_update_pending_wire()


func _on_port_pressed(port: ConnectionPort) -> void:
	# Первый клик — выбираем модуль-источник.
	if _pending_out == null:
		_pending_out = port
		_update_pending_wire()
		PortUtils.refresh_highlights(_ports, _pending_out)
		return
	# Повторный клик по тому же модулю — отмена выбора.
	if _pending_out.instance_uid == port.instance_uid:
		clear_pending()
		return
	# Второй модуль — соединяем/снимаем. Тип данных и направление подбираются сами.
	GameState.report_operation(
		GameState.wiring.try_connect_modules(_pending_out.instance_uid, port.instance_uid)
	)
	clear_pending()


## Тип данных провода (money/file) по логическому порту-источнику в линке.
func _link_kind(link: WireLink) -> String:
	var from_type: String = GameState.field.get_instance_type(link.from_uid)
	var def: Dictionary = BlockDefs.PORT_DEFS.get(from_type, {}).get(link.from_port, {})
	return "money" if str(def.get("kind", "")) == "money" else "file"


func _update_pending_wire() -> void:
	if _pending_out == null:
		_renderer.clear_pending()
		return
	var from_pos := PortUtils.port_center_in_local(_pending_out, _wires_root)
	var global_pos: Vector2 = _host.get_global_transform() * wire_cursor_screen
	var to_pos := _wires_root.get_global_transform().affine_inverse() * global_pos
	_pending_segment["from"] = from_pos
	_pending_segment["to"] = to_pos
	var obstacles := _gather_obstacle_rects()
	var path := WireRouteUtils.build_path(
		from_pos,
		to_pos,
		ConnectionPort.Dir.OUT,
		ConnectionPort.Dir.IN,
		_obstacles_except(obstacles, [_pending_out.instance_uid]),
	)
	# Старт обрезаем по краю модуля-источника; конец (курсор) оставляем как есть.
	_pending_segment["path"] = WireRouteUtils.trim_path_to_rects(
		path, _rect_for(obstacles, _pending_out.instance_uid), Rect2()
	)
	_pending_segment["color"] = MinimalUI.NEON_CYAN
	_renderer.set_pending(_pending_segment)


## Прямоугольники всех модулей в координатах _wires_root (= мировые пиксели сетки).
func _gather_obstacle_rects() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for inst: BlockInstance in GameState.access.get_placed_blocks():
		out.append(
			{
				"uid": inst.uid,
				"rect": Rect2(
					GridDefs.cell_to_pixel(inst.gx, inst.gy),
					GridDefs.block_pixel_size(inst.type_id),
				),
			}
		)
	return out


func _obstacles_except(rects: Array[Dictionary], skip_uids: Array) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for entry: Dictionary in rects:
		if str(entry["uid"]) in skip_uids:
			continue
		out.append(entry["rect"])
	return out
