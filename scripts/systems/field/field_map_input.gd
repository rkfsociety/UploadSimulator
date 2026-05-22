extends RefCounted
class_name FieldMapInput
## Ввод мыши и тача: панорама, зум, установка по тапу.

signal placement_finished(type_id: String)

var _host: Control
var _camera: FieldMapCamera
var _placement: FieldMapPlacement
var _wiring: FieldMapWiring

var _drag_pan: bool = false
var _drag_start := Vector2.ZERO
var _pan_at_drag := Vector2.ZERO
var _pointer_down := false
var _pointer_moved := false
var _press_pos := Vector2.ZERO
var _touch_positions: Dictionary = {}
var _pinch_start_dist: float = 0.0
var _pinch_start_zoom: float = 1.0


func _init(
	host: Control,
	camera: FieldMapCamera,
	placement: FieldMapPlacement,
	wiring: FieldMapWiring,
) -> void:
	_host = host
	_camera = camera
	_placement = placement
	_wiring = wiring


func handle_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_pointer_motion(event.position)
	elif event is InputEventMagnifyGesture:
		_camera.zoom_at(1.0 + (event as InputEventMagnifyGesture).factor, event.position)
		_host.accept_event()


func handle_input(event: InputEvent) -> void:
	if not DisplayServer.is_touchscreen_available():
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
	_update_pointer_follow(local_pos)


func _end_pointer(local_pos: Vector2) -> void:
	_update_pointer_follow(local_pos)
	if _pointer_down and _placement.get_selected_type() != "" and not _pointer_moved:
		# Установка только если тап не по HUD (клики по кнопкам забирает UILayer)
		if _is_over_hud(_host.get_global_transform() * local_pos):
			_pointer_down = false
			_pointer_moved = false
			_drag_pan = false
			return
		var next_type: String = _placement.try_place_at_screen(local_pos)
		_placement.set_selected_type(next_type)
		placement_finished.emit(next_type)
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
	if not _pointer_down:
		return
	if not _pointer_moved and local_pos.distance_to(_press_pos) >= FieldMapConstants.DRAG_THRESHOLD:
		_pointer_moved = true
		_drag_pan = true
	if _drag_pan:
		_camera.set_pan(_pan_at_drag + (local_pos - _drag_start))


func _handle_pointer_motion(screen_pos: Vector2) -> void:
	_apply_pan_drag(screen_pos)
	if _drag_pan:
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


## Зоны HUD: не ставить модуль «сквозь» нижнюю панель и угловые кнопки.
func _is_over_hud(screen_pos: Vector2) -> bool:
	var main := _host.get_parent()
	if main == null:
		return false
	var shop: CanvasItem = main.get_node_or_null("ShopMenu") as CanvasItem
	if shop != null and shop.visible:
		var shop_rect := Rect2(shop.get_global_position(), shop.size)
		if shop_rect.has_point(screen_pos):
			return true
	var vp_size := _host.get_viewport().get_visible_rect().size
	if screen_pos.y >= vp_size.y - 96.0:
		return true
	if screen_pos.x >= vp_size.x - 88.0 and screen_pos.y >= vp_size.y - 112.0:
		return true
	return false
