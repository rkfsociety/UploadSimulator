extends Control
## Векторная сетка в мировых координатах MapViewport; pan/zoom задаёт родитель.

const COL_BG_MAP := Color(0.071, 0.071, 0.071, 1.0)
const COL_LINE_MINOR := Color(0.55, 0.55, 0.55, 0.22)
const COL_LINE_MAJOR := Color(0.65, 0.7, 0.75, 0.42)

var _world_bounds := Rect2()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world_bounds = GridDefs.world_bounds_rect()
	# Покрываем всю карту в тех же координатах, что и модули
	position = _world_bounds.position
	size = _world_bounds.size
	z_index = -10
	queue_redraw()


## Перерисовка после сдвига/масштаба камеры (вызывается из field_map).
func sync_view() -> void:
	queue_redraw()


func _minor_step() -> float:
	return float(GridDefs.CELL_SIZE) / 8.0


func _major_step() -> float:
	return float(GridDefs.CELL_SIZE)


func _map_viewport() -> Control:
	return get_parent() as Control


func _field_map() -> Control:
	var vp := _map_viewport()
	if vp == null:
		return null
	return vp.get_parent() as Control


func _zoom() -> float:
	var vp := _map_viewport()
	if vp == null:
		return 1.0
	return maxf(vp.scale.x, 0.001)


func _visible_world_rect() -> Rect2:
	var vp := _map_viewport()
	var field := _field_map()
	if vp == null or field == null or field.size.x < 1.0:
		return _world_bounds
	var zoom := _zoom()
	var pan := vp.position
	var vs := field.size
	var p0 := (Vector2.ZERO - pan) / zoom
	var p1 := (vs - pan) / zoom
	var rect := Rect2(p0, p1 - p0)
	if rect.size.x < 0.0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	if rect.size.y < 0.0:
		rect.position.y += rect.size.y
		rect.size.y = -rect.size.y
	return rect.intersection(_world_bounds)


func _world_to_local_x(world_x: float) -> float:
	return world_x - _world_bounds.position.x


func _world_to_local_y(world_y: float) -> float:
	return world_y - _world_bounds.position.y


func _snap_local(v: float) -> float:
	return floorf(v) + 0.5


func _draw() -> void:
	if size.x < 1.0 or size.y < 1.0:
		return
	draw_rect(Rect2(Vector2.ZERO, size), COL_BG_MAP)
	var zoom := _zoom()
	var vis := _visible_world_rect()
	var wx0 := _world_bounds.position.x
	var wy0 := _world_bounds.position.y
	var wx1 := wx0 + _world_bounds.size.x
	var wy1 := wy0 + _world_bounds.size.y
	var vis_l0 := _world_to_local_x(maxf(wx0, vis.position.x))
	var vis_l1 := _world_to_local_x(mini(wx1, vis.position.x + vis.size.x))
	var vis_t0 := _world_to_local_y(maxf(wy0, vis.position.y))
	var vis_b1 := _world_to_local_y(mini(wy1, vis.position.y + vis.size.y))
	if vis_l1 - vis_l0 < 1.0 or vis_b1 - vis_t0 < 1.0:
		return
	var clip := Rect2(vis_l0, vis_t0, vis_l1 - vis_l0, vis_b1 - vis_t0)
	var minor := _minor_step()
	if minor * zoom >= 0.75:
		_draw_grid_lines(minor, wx0, wx1, wy0, wy1, vis, clip, COL_LINE_MINOR)
	var major := _major_step()
	if major * zoom >= 1.0:
		_draw_grid_lines(major, wx0, wx1, wy0, wy1, vis, clip, COL_LINE_MAJOR)
	_draw_border(wx0, wx1, wy0, wy1, clip)


func _draw_grid_lines(
	step: float,
	wx0: float,
	wx1: float,
	wy0: float,
	wy1: float,
	vis: Rect2,
	clip: Rect2,
	col: Color,
) -> void:
	var x_start := maxf(wx0, floorf(vis.position.x / step) * step)
	var x_end := mini(wx1, vis.position.x + vis.size.x)
	var y_start := maxf(wy0, floorf(vis.position.y / step) * step)
	var y_end := mini(wy1, vis.position.y + vis.size.y)
	var x := x_start
	while x <= x_end + 0.001:
		_draw_v_local(_snap_local(_world_to_local_x(x)), clip, col)
		x += step
	var y := y_start
	while y <= y_end + 0.001:
		_draw_h_local(_snap_local(_world_to_local_y(y)), clip, col)
		y += step


func _draw_border(wx0: float, wx1: float, wy0: float, wy1: float, clip: Rect2) -> void:
	_draw_v_local(_snap_local(_world_to_local_x(wx0)), clip, COL_LINE_MAJOR)
	_draw_v_local(_snap_local(_world_to_local_x(wx1)), clip, COL_LINE_MAJOR)
	_draw_h_local(_snap_local(_world_to_local_y(wy0)), clip, COL_LINE_MAJOR)
	_draw_h_local(_snap_local(_world_to_local_y(wy1)), clip, COL_LINE_MAJOR)


func _draw_v_local(local_x: float, clip: Rect2, col: Color) -> void:
	if local_x < clip.position.x - 1.0 or local_x > clip.position.x + clip.size.x + 1.0:
		return
	draw_rect(Rect2(local_x - 0.5, clip.position.y, 1.0, clip.size.y), col)


func _draw_h_local(local_y: float, clip: Rect2, col: Color) -> void:
	if local_y < clip.position.y - 1.0 or local_y > clip.position.y + clip.size.y + 1.0:
		return
	draw_rect(Rect2(clip.position.x, local_y - 0.5, clip.size.x, 1.0), col)
