extends RefCounted
class_name FieldMapBlockDrag
## Выделение и перетаскивание уже установленных модулей на карте.

signal selection_changed(uid: String)

var _map_content: Control
var _camera: FieldMapCamera
var _blocks: FieldMapBlocks
var _placement: FieldMapPlacement

var _selected_uid: String = ""
var _press_uid: String = ""
var _drag_uid: String = ""
var _dragging: bool = false
var _hover_cell := Vector2i(-1, -1)
var _ghost: ColorRect


func _init(
	map_content: Control,
	camera: FieldMapCamera,
	blocks: FieldMapBlocks,
	placement: FieldMapPlacement,
) -> void:
	_map_content = map_content
	_camera = camera
	_blocks = blocks
	_placement = placement
	_setup_ghost()


func get_selected_uid() -> String:
	return _selected_uid


func is_dragging() -> bool:
	return _dragging


func clear_selection() -> void:
	_set_selected("")


func on_pointer_down(local_pos: Vector2) -> void:
	_press_uid = _pick_uid_at_screen(local_pos)
	_drag_uid = ""
	_dragging = false
	_hide_ghost()


func try_begin_drag(local_pos: Vector2) -> bool:
	if _placement.get_selected_type() != "":
		return false
	# Модуль под курсором — перенос; пустое место — панорама камеры.
	if _press_uid == "":
		return false
	if _press_uid != _selected_uid:
		_set_selected(_press_uid)
	_drag_uid = _press_uid
	_dragging = true
	_set_selected(_drag_uid)
	update_drag(local_pos)
	return true


func update_drag(local_pos: Vector2) -> void:
	if not _dragging or _drag_uid == "":
		return
	var inst := GameState.field.get_instance(_drag_uid)
	var cell := GridDefs.snap_cell_from_world(_camera.screen_to_world(local_pos))
	_hover_cell = cell
	if not GridDefs.footprint_in_bounds(cell.x, cell.y, inst.type_id):
		_hide_ghost()
		return
	_ghost.visible = true
	_ghost.position = GridDefs.cell_to_pixel(cell.x, cell.y)
	_ghost.size = GridDefs.block_pixel_size(inst.type_id)
	var accent := BlockDefs.get_block_color(inst.type_id) if inst.is_valid() else Color.WHITE
	if GameState.field.can_relocate_block(_drag_uid, cell.x, cell.y):
		_ghost.color = Color(accent.r, accent.g, accent.b, FieldMapConstants.PREVIEW_VALID_ALPHA)
	else:
		_ghost.color = FieldMapConstants.PREVIEW_OCCUPIED_COLOR


func finish_drag(local_pos: Vector2) -> void:
	if not _dragging:
		return
	update_drag(local_pos)
	var drag_uid := _drag_uid
	var target_cell := _hover_cell
	var drag_type := GameState.field.get_instance(drag_uid).type_id
	_dragging = false
	_drag_uid = ""
	_hide_ghost()
	if (
		drag_uid != ""
		and GridDefs.footprint_in_bounds(target_cell.x, target_cell.y, drag_type)
		and GameState.field.can_relocate_block(drag_uid, target_cell.x, target_cell.y)
	):
		GameState.field.relocate_block(drag_uid, target_cell.x, target_cell.y)


## Сброс перетаскивания без переноса (например после field_changed).
func cancel_drag() -> void:
	_dragging = false
	_drag_uid = ""
	_hide_ghost()


func handle_tap(local_pos: Vector2) -> void:
	if _placement.get_selected_type() != "":
		return
	var uid := _pick_uid_at_screen(local_pos)
	_set_selected(uid)


func sync_selection_visual() -> void:
	for uid in _blocks.get_nodes().keys():
		var block: PlacedBlock = _blocks.get_nodes()[uid] as PlacedBlock
		block.set_map_selected(uid == _selected_uid)


func _set_selected(uid: String) -> void:
	if _selected_uid == uid:
		return
	_selected_uid = uid
	sync_selection_visual()
	selection_changed.emit(uid)


func _pick_uid_at_screen(local_pos: Vector2) -> String:
	var world := _camera.screen_to_world(local_pos)
	var cell := GridDefs.pixel_to_cell(world)
	var inst := GameState.field.get_block_at(cell.x, cell.y)
	if inst.is_valid():
		return inst.uid
	return ""


func _setup_ghost() -> void:
	_ghost = ColorRect.new()
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost.visible = false
	_map_content.add_child(_ghost)
	_map_content.move_child(_ghost, 2)


func _hide_ghost() -> void:
	_hover_cell = Vector2i(-1, -1)
	if _ghost != null:
		_ghost.visible = false
