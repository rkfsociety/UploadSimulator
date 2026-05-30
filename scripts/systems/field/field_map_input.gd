extends RefCounted
class_name FieldMapInput
## Ввод мыши и тача: панорама, зум, установка по тапу.

const _BlockDragClass := preload("res://scripts/systems/field/field_map_block_drag.gd")

signal placement_finished(type_id: String)

var _host: Control
var _camera: FieldMapCamera
var _placement: FieldMapPlacement
var _wiring: FieldMapWiring
var _block_drag: RefCounted
var _diamonds: FieldMapDiamonds
var _block_menu: FieldMapBlockMenu = null

var _drag_pan: bool = false
var _drag_start := Vector2.ZERO
var _pan_at_drag := Vector2.ZERO
var _pointer_down := false
var _pointer_moved := false
var _press_pos := Vector2.ZERO
var _touch_positions: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0
# Кэш узлов HUD — find_child на каждый кадр дорогой
var _hud_menus: Array[CanvasItem] = []
var _hud_menus_resolved: bool = false


func _init(
	host: Control,
	camera: FieldMapCamera,
	placement: FieldMapPlacement,
	wiring: FieldMapWiring,
	block_drag: RefCounted,
	diamonds: FieldMapDiamonds,
) -> void:
	_host = host
	_camera = camera
	_placement = placement
	_wiring = wiring
	_block_drag = block_drag
	_diamonds = diamonds


func set_block_menu(menu: FieldMapBlockMenu) -> void:
	_block_menu = menu


func handle_gui_input(event: InputEvent) -> void:
	# На ПК ЛКМ и панорама — в process_frame (опрос мыши), здесь только колесо и СКМ
	if _use_polling_input() and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		var screen_pos := _host.get_global_transform() * mb.position
		if mb.pressed and _is_over_hud(screen_pos):
			return
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion and not _use_polling_input():
		_handle_pointer_motion(event.position)
	elif event is InputEventMagnifyGesture:
		_camera.zoom_at(1.0 + (event as InputEventMagnifyGesture).factor, event.position)
		_host.accept_event()


func handle_input(event: InputEvent) -> void:
	# На ПК мышь обрабатывается в _gui_input; тач здесь только на мобильных ОС
	if not _use_touch_input():
		return
	if _is_over_hud(_screen_pos_from_event(event)):
		return
	if event is InputEventScreenTouch:
		_handle_screen_touch(event as InputEventScreenTouch)
	elif event is InputEventScreenDrag:
		_handle_screen_drag(event as InputEventScreenDrag)


func _handle_mouse_button(mb: InputEventMouseButton) -> void:
	var local_pos := mb.position
	if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
		_camera.zoom_at(FieldMapConstants.ZOOM_WHEEL_STEP, local_pos)
		_host.accept_event()
		return
	if mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		_camera.zoom_at(1.0 / FieldMapConstants.ZOOM_WHEEL_STEP, local_pos)
		_host.accept_event()
		return
	if mb.button_index == MOUSE_BUTTON_RIGHT or mb.button_index == MOUSE_BUTTON_MIDDLE:
		if mb.pressed:
			_begin_pan(local_pos, true)
		else:
			_end_pointer(local_pos)
		_host.accept_event()
		return
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if mb.pressed:
		_begin_pointer(local_pos)
	else:
		_end_pointer(local_pos)
	_host.accept_event()


func _to_local(screen_pos: Vector2) -> Vector2:
	return _host.get_global_transform().affine_inverse() * screen_pos


func _begin_pointer(local_pos: Vector2) -> void:
	_pointer_down = true
	_pointer_moved = false
	_press_pos = local_pos
	_drag_pan = false
	_drag_start = local_pos
	_pan_at_drag = _camera.pan
	_block_drag.on_pointer_down(local_pos)
	_update_pointer_follow(local_pos)


func _end_pointer(local_pos: Vector2) -> void:
	_update_pointer_follow(local_pos)
	if _block_drag.is_dragging():
		_block_drag.finish_drag(local_pos)
	elif _pointer_down and not _pointer_moved:
		if _is_over_hud(_host.get_global_transform() * local_pos):
			_pointer_down = false
			_pointer_moved = false
			_drag_pan = false
			return
		elif _placement.get_selected_type() != "":
			var next_type: String = _placement.try_place_at_screen(local_pos)
			_placement.set_selected_type(next_type)
			placement_finished.emit(next_type)
		elif _diamonds.try_collect_at_screen(local_pos):
			pass
		else:
			_block_drag.handle_tap(local_pos)
	_pointer_down = false
	_pointer_moved = false
	_drag_pan = false


func _begin_pan(local_pos: Vector2, moved: bool) -> void:
	_pointer_down = true
	_pointer_moved = moved
	_drag_pan = true
	_drag_start = local_pos
	_pan_at_drag = _camera.pan


func _apply_pan_drag(local_pos: Vector2) -> void:
	_update_pointer_follow(local_pos)
	_update_drag_state(local_pos)


## Каждый кадр на ПК: опрос ЛКМ — панорама и установка без _gui_input.
func process_frame(host: Control) -> void:
	if not _use_polling_input():
		return
	var vp := host.get_viewport()
	if vp == null:
		return
	var global_mouse := vp.get_mouse_position()
	var local_pos := host.get_local_mouse_position()
	var over_hud := _is_over_hud(global_mouse)
	var lmb := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if _placement.get_selected_type() != "" and not lmb and not _pointer_down:
		_placement.update_preview(local_pos)

	if lmb and not over_hud:
		if not _pointer_down:
			_begin_pointer(local_pos)
		_update_pointer_follow(local_pos)
		_update_drag_state(local_pos)
	elif _pointer_down:
		_end_pointer(local_pos)


func _update_drag_state(local_pos: Vector2) -> void:
	if not _pointer_down:
		return
	var drag_thr := PlatformInfo.drag_threshold_px()
	if not _pointer_moved and local_pos.distance_to(_press_pos) >= drag_thr:
		_pointer_moved = true
		_drag_pan = true
		if _block_drag.try_begin_drag(local_pos):
			_drag_pan = false
			_wiring.clear_pending()
	if _block_drag.is_dragging():
		_block_drag.update_drag(local_pos)
		return
	if _drag_pan:
		_camera.set_pan(_pan_at_drag + (local_pos - _drag_start))


func _handle_pointer_motion(screen_pos: Vector2) -> void:
	_apply_pan_drag(screen_pos)
	if _drag_pan or _block_drag.is_dragging():
		_host.accept_event()


func _handle_screen_touch(st: InputEventScreenTouch) -> void:
	if st.pressed:
		_touch_positions[st.index] = st.position
		if _touch_positions.size() == 1:
			_begin_pointer(_to_local(st.position))
		elif _touch_positions.size() >= 2:
			_pointer_down = false
			_drag_pan = false
			_begin_pinch()
	else:
		_touch_positions.erase(st.index)
		if _touch_positions.size() < 2:
			_pinch_start_dist = 0.0
		if _touch_positions.is_empty():
			_end_pointer(_to_local(st.position))
		elif _touch_positions.size() == 1:
			_begin_pointer(_to_local(_touch_positions.values()[0]))


func _handle_screen_drag(sd: InputEventScreenDrag) -> void:
	_touch_positions[sd.index] = sd.position
	if _touch_positions.size() >= 2:
		_update_pinch()
	elif _drag_pan:
		_camera.apply_pan_delta(sd.relative)
		_host.accept_event()
	elif _block_drag.is_dragging():
		_block_drag.update_drag(_to_local(sd.position))
		_host.accept_event()
	else:
		_apply_pan_drag(_to_local(sd.position))


func _begin_pinch() -> void:
	var pts: Array[Vector2] = []
	for p in _touch_positions.values():
		pts.append(p)
	if pts.size() < 2:
		return
	_pinch_start_dist = pts[0].distance_to(pts[1])
	_pinch_start_zoom = _camera.zoom


func _update_pinch() -> void:
	if _pinch_start_dist < FieldMapConstants.MIN_PINCH_DISTANCE:
		return
	var pts: Array[Vector2] = []
	for p in _touch_positions.values():
		pts.append(p)
	if pts.size() < 2:
		return
	var dist: float = pts[0].distance_to(pts[1])
	var focal := _to_local((pts[0] + pts[1]) * 0.5)
	var new_zoom: float = clampf(
		_pinch_start_zoom * (dist / _pinch_start_dist),
		_camera.min_zoom(),
		FieldMapConstants.ZOOM_MAX,
	)
	var map_point := (focal - _camera.pan) / _pinch_start_zoom
	_camera.zoom = new_zoom
	_camera.pan = focal - map_point * _camera.zoom
	_camera.apply()


func _update_pointer_follow(local_pos: Vector2) -> void:
	_wiring.set_cursor_screen(local_pos)
	_placement.update_preview(local_pos)


func _screen_pos_from_event(event: InputEvent) -> Vector2:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).position
	if event is InputEventScreenDrag:
		return (event as InputEventScreenDrag).position
	return Vector2.ZERO


func _ensure_hud_menus_cached() -> void:
	if _hud_menus_resolved:
		return
	_hud_menus_resolved = true
	var main := _host.get_parent()
	if main == null:
		return
	for menu_name in ["ShopMenu", "UpgradeShopMenu"]:
		# Меню в ModalLayer — get_node("ShopMenu") не сработает
		var menu: CanvasItem = main.find_child(menu_name, true, false) as CanvasItem
		if menu != null:
			_hud_menus.append(menu)


## Зоны HUD: не ставить модуль «сквозь» нижнюю панель и угловые кнопки.
func _is_over_hud(screen_pos: Vector2) -> bool:
	_ensure_hud_menus_cached()
	for menu in _hud_menus:
		if menu != null and is_instance_valid(menu) and menu.visible:
			var menu_rect := Rect2(menu.get_global_position(), menu.size)
			if menu_rect.has_point(screen_pos):
				return true
	if _block_menu != null and _block_menu.is_open():
		if _block_menu.get_panel_global_rect().has_point(screen_pos):
			return true
	var vp_size := _host.get_viewport().get_visible_rect().size
	# Нижняя полоса: магазин $ по центру
	if screen_pos.y >= vp_size.y - PlatformInfo.hud_bottom_strip_height():
		return true
	# Правый столбец: «в центр» и магазин ◆ под ним
	if (
		screen_pos.x >= vp_size.x - PlatformInfo.hud_right_column_width()
		and screen_pos.y >= vp_size.y - PlatformInfo.hud_right_column_top_offset()
	):
		return true
	return false


func _use_touch_input() -> bool:
	return PlatformInfo.prefers_touch_input()


func _use_polling_input() -> bool:
	return not PlatformInfo.prefers_touch_input()
