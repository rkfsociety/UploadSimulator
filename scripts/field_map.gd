extends Control
## Поле карты (лимит 100×100 клеток).

const ZOOM_MIN := 0.2
const ZOOM_MAX := 3.5
const ZOOM_WHEEL_STEP := 1.12
const DRAG_THRESHOLD := 6.0

signal placement_mode_changed(type_id: String)

@onready var map_viewport: Control = $MapViewport
@onready var grid_draw: Control = $GridDraw
@onready var wires_root: Control = $MapViewport/WiresRoot
@onready var blocks_root: Control = $MapViewport/BlocksRoot

var _zoom: float = 1.0
var _pan := Vector2.ZERO
var _selected_type: String = ""
var _block_nodes: Dictionary = {}
var _pending_out: ConnectionPort = null
var _wire_nodes: Array[DataWire] = []
var _pending_wire: DataWire = null
var _wire_cursor_screen := Vector2.ZERO
var _ports: Array[ConnectionPort] = []
var _drag_pan: bool = false
var _drag_start := Vector2.ZERO
var _pan_at_drag := Vector2.ZERO
var _pointer_down := false
var _pointer_moved := false
var _press_pos := Vector2.ZERO
var _touch_positions: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0
var _pinch_focal := Vector2.ZERO
var _place_preview: ColorRect
var _hover_cell := Vector2i(-1, -1)


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	map_viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_viewport.clip_contents = true
	for node in [wires_root, blocks_root]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Провода поверх блоков, чтобы линии были видны между портами
	wires_root.z_index = 5
	_setup_placement_preview()
	GameState.field_changed.connect(_on_field_changed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	GameState.stats_changed.connect(_on_field_changed)
	GameState.queue_changed.connect(_on_field_changed)
	grid_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await get_tree().process_frame
	_start_at_origin()
	_on_field_changed()
	_collect_ports()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_clamp_pan()
		_apply_camera()


func _process(_delta: float) -> void:
	_update_grid_view()
	_update_wire_positions()


func _world_pixel_size() -> Vector2:
	return GridDefs.world_pixel_size()


func _screen_to_world(screen: Vector2) -> Vector2:
	return (screen - _pan) / _zoom


func _visible_world_rect() -> Rect2:
	var a := _screen_to_world(Vector2.ZERO)
	var b := _screen_to_world(size)
	return Rect2(a, b - a).grow(float(GridDefs.CELL_SIZE))


func _update_grid_view() -> void:
	if grid_draw == null or not grid_draw.has_method("set_camera"):
		return
	grid_draw.set_camera(size, _pan, _zoom, GridDefs.world_bounds_rect())


func _start_at_origin() -> void:
	# Старт в центре карты — мировые координаты (0, 0)
	_center_on_world_pixel(GridDefs.world_center_pixel())


func focus_map_center() -> void:
	# Переместить камеру в центр карты (0, 0)
	_center_on_world_pixel(GridDefs.world_center_pixel())


func _center_on_world_pixel(world_px: Vector2) -> void:
	_pan = size * 0.5 - world_px * _zoom
	_clamp_pan()
	_apply_camera()


func _apply_camera() -> void:
	if map_viewport == null or not is_node_ready():
		return
	_clamp_pan()
	# Единый масштаб по X и Y — клетки остаются 1:1
	map_viewport.scale = Vector2.ONE * _zoom
	map_viewport.position = _pan
	_update_grid_view()


func _clamp_pan() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	var bounds := GridDefs.world_bounds_rect()
	var margin := 2.0
	_pan.x = _clamp_pan_axis_ranged(
		_pan.x, size.x, _zoom, margin, bounds.position.x, bounds.position.x + bounds.size.x
	)
	_pan.y = _clamp_pan_axis_ranged(
		_pan.y, size.y, _zoom, margin, bounds.position.y, bounds.position.y + bounds.size.y
	)


func _clamp_pan_axis_ranged(
	value: float,
	view_size: float,
	zoom: float,
	margin: float,
	world_min: float,
	world_max: float,
) -> float:
	var span := world_max - world_min
	var span_screen := span * zoom
	if span_screen <= view_size:
		var center_w := (world_min + world_max) * 0.5
		return view_size * 0.5 - center_w * zoom
	var m := margin / maxf(zoom, 0.001)
	var lo := view_size - (world_max - m) * zoom
	var hi := -(world_min + m) * zoom
	if lo > hi:
		return (lo + hi) * 0.5
	return clampf(value, lo, hi)


func _zoom_at(factor: float, screen_pos: Vector2) -> void:
	var old_zoom := _zoom
	_zoom = clampf(_zoom * factor, _min_zoom(), ZOOM_MAX)
	if is_equal_approx(old_zoom, _zoom):
		return
	var map_point := (screen_pos - _pan) / old_zoom
	_pan = screen_pos - map_point * _zoom
	_clamp_pan()
	_apply_camera()


func _min_zoom() -> float:
	return ZOOM_MIN


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_pointer_motion(event.position)
	elif event is InputEventMagnifyGesture:
		_zoom_at(1.0 + (event as InputEventMagnifyGesture).factor, event.position)
		accept_event()


func _input(event: InputEvent) -> void:
	# Только реальный тач-экран (без дубля с мышью)
	if not DisplayServer.is_touchscreen_available():
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	var local_pos := mb.position
	if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_zoom_at(ZOOM_WHEEL_STEP, local_pos)
		accept_event()
		return
	if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_zoom_at(1.0 / ZOOM_WHEEL_STEP, local_pos)
		accept_event()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
		if mb.pressed:
			_begin_pan_local(local_pos)
		else:
			_end_pointer_local(local_pos)
		accept_event()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_begin_pointer_local(local_pos)
	else:
		_end_pointer_local(local_pos)
	accept_event()


func _to_local_screen(screen_pos: Vector2) -> Vector2:
	return get_global_transform().affine_inverse() * screen_pos


func _begin_pointer_local(local_pos: Vector2) -> void:
	_pointer_down = true
	_pointer_moved = false
	_press_pos = local_pos
	_drag_pan = false
	_drag_start = local_pos
	_pan_at_drag = _pan
	_wire_cursor_screen = local_pos
	_update_placement_preview(local_pos)


func _end_pointer_local(local_pos: Vector2) -> void:
	_wire_cursor_screen = local_pos
	if _pointer_down and _selected_type != "" and not _pointer_moved:
		_try_place_at_screen(local_pos)
	_pointer_down = false
	_pointer_moved = false
	_drag_pan = false


func _begin_pan_local(local_pos: Vector2) -> void:
	_pointer_down = true
	_pointer_moved = true
	_drag_pan = true
	_drag_start = local_pos
	_pan_at_drag = _pan


func _apply_pan_drag_local(local_pos: Vector2) -> void:
	_wire_cursor_screen = local_pos
	_update_placement_preview(local_pos)
	if not _pointer_down:
		return
	if not _pointer_moved and local_pos.distance_to(_press_pos) >= DRAG_THRESHOLD:
		_pointer_moved = true
		_drag_pan = true
	if _drag_pan:
		_pan = _pan_at_drag + (local_pos - _drag_start)
		_clamp_pan()
		_apply_camera()


func _handle_pointer_motion(screen_pos: Vector2) -> void:
	_apply_pan_drag_local(screen_pos)
	if _drag_pan:
		accept_event()


func _handle_screen_touch(st: InputEventScreenTouch) -> void:
	if st.pressed:
		_touch_positions[st.index] = st.position
		if _touch_positions.size() == 1:
			_begin_pointer_local(_to_local_screen(st.position))
		elif _touch_positions.size() >= 2:
			_pointer_down = false
			_drag_pan = false
			_begin_pinch()
	else:
		_touch_positions.erase(st.index)
		if _touch_positions.size() < 2:
			_pinch_start_dist = 0.0
		if _touch_positions.is_empty():
			_end_pointer_local(_to_local_screen(st.position))
		elif _touch_positions.size() == 1:
			var remaining: Vector2 = _touch_positions.values()[0]
			_begin_pointer_local(_to_local_screen(remaining))


func _handle_screen_drag(sd: InputEventScreenDrag) -> void:
	_touch_positions[sd.index] = sd.position
	if _touch_positions.size() >= 2:
		_update_pinch()
	elif _drag_pan:
		# relative в экранных пикселях — для панорамы подходит по обеим осям
		_pan += sd.relative
		_clamp_pan()
		_apply_camera()
		accept_event()
	else:
		_apply_pan_drag_local(_to_local_screen(sd.position))


func _begin_pinch() -> void:
	var pts: Array[Vector2] = []
	for p in _touch_positions.values():
		pts.append(p)
	if pts.size() < 2:
		return
	_pinch_start_dist = pts[0].distance_to(pts[1])
	_pinch_start_zoom = _zoom
	_pinch_focal = _to_local_screen((pts[0] + pts[1]) * 0.5)


func _update_pinch() -> void:
	if _pinch_start_dist < 1.0:
		return
	var pts: Array[Vector2] = []
	for p in _touch_positions.values():
		pts.append(p)
	if pts.size() < 2:
		return
	var dist: float = pts[0].distance_to(pts[1])
	var new_zoom: float = clampf(
		_pinch_start_zoom * (dist / _pinch_start_dist),
		_min_zoom(),
		ZOOM_MAX
	)
	var focal := _to_local_screen((pts[0] + pts[1]) * 0.5)
	var map_point := (focal - _pan) / _pinch_start_zoom
	_zoom = new_zoom
	_pan = focal - map_point * _zoom
	_clamp_pan()
	_apply_camera()


func get_view_center_cell() -> Vector2i:
	# Клетка в центре текущего вида камеры
	if size.x < 1.0 or size.y < 1.0:
		return Vector2i.ZERO
	return GridDefs.snap_cell_from_world(_screen_to_world(size * 0.5))


func place_at_view_center(type_id: String) -> bool:
	cancel_placement_mode()
	var center := get_view_center_cell()
	var anchor := GridDefs.block_anchor_for_center(center)
	for cell in _cells_near(anchor, 10):
		if not GridDefs.is_in_bounds(cell.x, cell.y):
			continue
		var uid := GameState.place_block(type_id, cell.x, cell.y)
		if uid != "":
			_spawn_block_node(uid)
			return true
	GameState.log_message.emit("Нет свободного места у центра карты.")
	return false


func _cells_near(origin: Vector2i, max_radius: int) -> Array[Vector2i]:
	# Кольца вокруг origin: сначала центр, потом соседи
	var cells: Array[Vector2i] = []
	for r in range(max_radius + 1):
		if r == 0:
			cells.append(origin)
			continue
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				if maxi(absi(dx), absi(dy)) == r:
					cells.append(origin + Vector2i(dx, dy))
	return cells


func _try_place_at_screen(screen_pos: Vector2) -> void:
	if _selected_type == "":
		return
	var cell := GridDefs.snap_cell_from_world(_screen_to_world(screen_pos))
	if not GridDefs.is_in_bounds(cell.x, cell.y):
		GameState.log_message.emit(
			"Край карты (%d…%d)." % [-GridDefs.GRID_HALF, GridDefs.GRID_HALF - 1]
		)
		return
	var uid := GameState.place_block(_selected_type, cell.x, cell.y)
	if uid != "":
		_spawn_block_node(uid)
		var keep: String = _selected_type if GameState.get_block_stock(_selected_type) > 0 else ""
		_selected_type = keep
		placement_mode_changed.emit(_selected_type)


func enter_placement_mode(type_id: String) -> void:
	if GameState.get_block_stock(type_id) <= 0:
		_selected_type = ""
	else:
		_selected_type = type_id
	placement_mode_changed.emit(_selected_type)


func cancel_placement_mode() -> void:
	_selected_type = ""
	_hide_placement_preview()
	placement_mode_changed.emit("")


func _setup_placement_preview() -> void:
	# Подсветка клетки при установке блока
	_place_preview = ColorRect.new()
	_place_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_place_preview.visible = false
	map_viewport.add_child(_place_preview)
	map_viewport.move_child(_place_preview, 1)


func _update_placement_preview(screen_pos: Vector2) -> void:
	if _selected_type == "":
		_hide_placement_preview()
		return
	var cell := GridDefs.snap_cell_from_world(_screen_to_world(screen_pos))
	_hover_cell = cell
	if not GridDefs.footprint_in_bounds(cell.x, cell.y):
		_hide_placement_preview()
		return
	_place_preview.visible = true
	_place_preview.position = GridDefs.cell_to_pixel(cell.x, cell.y)
	_place_preview.size = GridDefs.block_pixel_size()
	var occupied := not GameState.can_place_block(_selected_type, cell.x, cell.y)
	var accent := BlockDefs.get_block_color(_selected_type)
	if occupied:
		_place_preview.color = Color(1.0, 0.2, 0.35, 0.22)
	else:
		_place_preview.color = Color(accent.r, accent.g, accent.b, 0.16)


func _hide_placement_preview() -> void:
	if _place_preview != null:
		_place_preview.visible = false
	_hover_cell = Vector2i(-1, -1)


func _block_position(gx: int, gy: int) -> Vector2:
	# Якорь gx,gy — левый верхний угол модуля 4×6 клеток
	return GridDefs.cell_to_pixel(gx, gy)


func _on_field_changed() -> void:
	for uid in _block_nodes.keys():
		if not GameState.get_instance(uid).is_valid():
			var node: PlacedBlock = _block_nodes[uid]
			node.queue_free()
			_block_nodes.erase(uid)
	for inst: BlockInstance in GameState.get_placed_blocks():
		var uid: String = inst.uid
		if not _block_nodes.has(uid):
			_spawn_block_node(uid)
		else:
			(_block_nodes[uid] as PlacedBlock).refresh()
	_relayout_blocks()
	_collect_ports()
	_rebuild_wires()


func _relayout_blocks() -> void:
	var sz := PlacedBlock.pixel_size()
	for uid in _block_nodes.keys():
		var block: PlacedBlock = _block_nodes[uid]
		var inst := GameState.get_instance(uid)
		if not inst.is_valid():
			continue
		var gx: int = inst.gx
		var gy: int = inst.gy
		block.custom_minimum_size = sz
		block.size = sz
		block.position = _block_position(gx, gy)


func _spawn_block_node(uid: String) -> void:
	var inst := GameState.get_instance(uid)
	if not inst.is_valid():
		return
	var gx: int = inst.gx
	var gy: int = inst.gy
	var block := PlacedBlock.new()
	var sz := PlacedBlock.pixel_size()
	block.custom_minimum_size = sz
	block.size = sz
	block.position = _block_position(gx, gy)
	block.upgrade_requested.connect(_on_upgrade_requested)
	block.action_requested.connect(_on_block_action)
	blocks_root.add_child(block)
	block.setup(uid, inst.type_id)
	_block_nodes[uid] = block


func _on_upgrade_requested(block: PlacedBlock) -> void:
	GameState.upgrade_instance(block.instance_uid)


func _on_block_action(block: PlacedBlock) -> void:
	GameState.run_block_action(block.instance_uid)


func _collect_ports() -> void:
	_ports.clear()
	for node in _block_nodes.values():
		_gather_ports(node)


func _gather_ports(node: Node) -> void:
	for child in node.get_children():
		if child is ConnectionPort:
			_ports.append(child)
			if not child.port_pressed.is_connected(_on_port_pressed):
				child.port_pressed.connect(_on_port_pressed)
		_gather_ports(child)


func _on_port_pressed(port: ConnectionPort) -> void:
	if port.direction == ConnectionPort.Dir.OUT:
		if GameState.port_has_output_link(port.instance_uid, port.port_id):
			if _pending_out == port:
				GameState.disconnect_output_port(port.instance_uid, port.port_id)
				_clear_pending()
				return
		_pending_out = port
		_start_pending_wire(port)
		_refresh_port_highlights()
		return
	if _pending_out == null:
		GameState.log_message.emit("Сначала выход.")
		return
	GameState.try_connect_ports(
		_pending_out.instance_uid,
		_pending_out.port_id,
		port.instance_uid,
		port.port_id,
	)
	_clear_pending()


func _clear_pending() -> void:
	_pending_out = null
	_stop_pending_wire()
	_refresh_port_highlights()


func _refresh_port_highlights() -> void:
	for port: ConnectionPort in _ports:
		var ok := false
		if _pending_out != null and port.direction == ConnectionPort.Dir.IN:
			ok = GameState.can_connect_ports(
				_pending_out.instance_uid,
				_pending_out.port_id,
				port.instance_uid,
				port.port_id,
			)
		port.set_highlight(port == _pending_out, ok)


func _on_wiring_changed() -> void:
	_clear_pending()
	_rebuild_wires()


func _wire_color_for_port(port: ConnectionPort) -> Color:
	if port.kind == ConnectionPort.Kind.MONEY:
		return MinimalUI.WIRE_MONEY
	return MinimalUI.WIRE_FILE


func _wire_color_for_kind(kind: String) -> Color:
	return MinimalUI.WIRE_MONEY if kind == "money" else MinimalUI.WIRE_FILE


func _start_pending_wire(port: ConnectionPort) -> void:
	_stop_pending_wire()
	_pending_wire = DataWire.new()
	_pending_wire.configure(_wire_color_for_port(port), true, 1.6)
	_pending_wire.set_pending_style()
	wires_root.add_child(_pending_wire)
	_pending_wire.z_index = 10
	_wire_cursor_screen = get_local_mouse_position()
	_update_pending_wire()


func _stop_pending_wire() -> void:
	if _pending_wire != null:
		_pending_wire.queue_free()
		_pending_wire = null


func _rebuild_wires() -> void:
	for wire: DataWire in _wire_nodes:
		wire.queue_free()
	_wire_nodes.clear()
	for link: WireLink in GameState.get_wire_connections():
		var from_p := _find_port(link.from_uid, link.from_port)
		var to_p := _find_port(link.to_uid, link.to_port)
		if from_p == null or to_p == null:
			continue
		var wire := DataWire.new()
		var kind: String = "money" if from_p.kind == ConnectionPort.Kind.MONEY else "file"
		var link_dict := {
			"from_uid": link.from_uid,
			"from_port": link.from_port,
			"to_uid": link.to_uid,
			"to_port": link.to_port,
		}
		wire.configure(_wire_color_for_kind(kind), true, _wire_flow_speed(link_dict))
		wire.set_meta("link", link_dict)
		wires_root.add_child(wire)
		_wire_nodes.append(wire)
	_update_wire_positions()


func _wire_flow_speed(link: Dictionary) -> float:
	# Быстрее, когда по цепочке реально идут данные
	var from_type: String = GameState.get_instance_type(link.get("from_uid", ""))
	if from_type == "downloader" and not GameState.get_download_queue().is_empty():
		return 2.0
	if from_type == "storage" and not GameState.get_upload_queue().is_empty():
		return 2.0
	if from_type == "uploader" and GameState.get_uploader_balance() > 0.0:
		return 2.0
	return 1.1


func _update_wire_positions() -> void:
	for wire: DataWire in _wire_nodes:
		var link: Variant = wire.get_meta("link", null)
		if link == null:
			continue
		var from_p := _find_port(str(link.get("from_uid", "")), str(link.get("from_port", "")))
		var to_p := _find_port(str(link.get("to_uid", "")), str(link.get("to_port", "")))
		if from_p == null or to_p == null:
			continue
		wire.set_endpoints(_port_center(from_p), _port_center(to_p))
	_update_pending_wire()


func _update_pending_wire() -> void:
	if _pending_wire == null or _pending_out == null:
		return
	var from_pos := _port_center(_pending_out)
	var to_pos := _pointer_to_wires_local(_wire_cursor_screen)
	_pending_wire.set_endpoints(from_pos, to_pos)


func _pointer_to_wires_local(screen_pos: Vector2) -> Vector2:
	var global_pos: Vector2 = get_global_transform() * screen_pos
	return wires_root.get_global_transform().affine_inverse() * global_pos


func _find_port(uid: String, port_id: String) -> ConnectionPort:
	for port: ConnectionPort in _ports:
		if port.instance_uid == uid and port.port_id == port_id:
			return port
	return null


func _port_center(port: ConnectionPort) -> Vector2:
	return wires_root.get_global_transform().affine_inverse() * port.get_global_rect().get_center()
