extends RefCounted
class_name FieldMapPlacement
## Режим установки модулей: превью и постановка на сетку.

var _map_viewport: Control
var _camera: FieldMapCamera
var _preview: ColorRect
var _selected_type: String = ""
var hover_cell: Vector2i = Vector2i(-1, -1)


func _init(map_viewport: Control, camera: FieldMapCamera) -> void:
	_map_viewport = map_viewport
	_camera = camera
	_setup_preview()


func get_selected_type() -> String:
	return _selected_type


func set_selected_type(type_id: String) -> void:
	_selected_type = type_id
	if type_id == "":
		hide_preview()


func update_preview(screen_pos: Vector2) -> void:
	if _selected_type == "":
		hide_preview()
		return
	var cell := GridDefs.snap_cell_from_world(_camera.screen_to_world(screen_pos))
	hover_cell = cell
	if not GridDefs.footprint_in_bounds(cell.x, cell.y, _selected_type):
		hide_preview()
		return
	_preview.visible = true
	_preview.position = GridDefs.cell_to_pixel(cell.x, cell.y)
	_preview.size = GridDefs.block_pixel_size(_selected_type)
	var occupied := not GameState.field.can_place_block(_selected_type, cell.x, cell.y)
	var accent := BlockDefs.get_block_color(_selected_type)
	if occupied:
		_preview.color = FieldMapConstants.PREVIEW_OCCUPIED_COLOR
	else:
		_preview.color = Color(accent.r, accent.g, accent.b, FieldMapConstants.PREVIEW_VALID_ALPHA)


func hide_preview() -> void:
	if _preview != null:
		_preview.visible = false
	hover_cell = Vector2i(-1, -1)


## Пытается поставить модуль в клетку под экранной точкой. Возвращает новый type_id для режима (или "").
func try_place_at_screen(screen_pos: Vector2) -> String:
	if _selected_type == "":
		return ""
	var cell := GridDefs.snap_cell_from_world(_camera.screen_to_world(screen_pos))
	if not GridDefs.is_in_bounds(cell.x, cell.y):
		GameState.log_message.emit(
			"Край карты (%d…%d)." % [-GridDefs.GRID_HALF, GridDefs.GRID_HALF - 1]
		)
		return _selected_type
	var place := GameState.field.place_block(_selected_type, cell.x, cell.y)
	if not place.is_ok():
		GameState.report_operation(place)
		return _selected_type
	var uid := place.get_uid()
	if GameState.field.get_block_stock(_selected_type) > 0:
		return _selected_type
	return ""


## Ставит модуль в центр вида; ищет свободное место вокруг якоря.
func place_at_view_center(type_id: String, spawn_block: Callable) -> bool:
	set_selected_type("")
	var center := _camera.view_center_cell()
	var anchor := GridDefs.block_anchor_for_center(center, type_id)
	for cell in _cells_near(anchor, FieldMapConstants.PLACE_SEARCH_RADIUS):
		if not GridDefs.is_in_bounds(cell.x, cell.y):
			continue
		var place := GameState.field.place_block(type_id, cell.x, cell.y)
		if place.is_ok():
			var uid := place.get_uid()
			spawn_block.call(uid)
			return true
	GameState.log_message.emit("Нет свободного места у центра карты.")
	return false


func _setup_preview() -> void:
	_preview = ColorRect.new()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.visible = false
	_map_viewport.add_child(_preview)
	_map_viewport.move_child(_preview, 1)


func _cells_near(origin: Vector2i, max_radius: int) -> Array[Vector2i]:
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
