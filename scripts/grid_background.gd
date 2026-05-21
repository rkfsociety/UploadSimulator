extends Control
## Векторная сетка: линии строго внутри границ карты, без «гребёнки» на краях.

const COL_BG := Color(0.05, 0.05, 0.06, 1.0)
const COL_BG_MAP := Color(0.071, 0.071, 0.071, 1.0)
const COL_LINE := Color(0.5, 0.5, 0.5, 0.14)

var _viewport_size := Vector2(800, 600)
var _pan := Vector2.ZERO
var _zoom: float = 1.0
var _world_bounds := Rect2(Vector2.ZERO, Vector2(800000, 800000))


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func set_camera(viewport_size: Vector2, pan: Vector2, zoom: float, world_bounds: Rect2) -> void:
	_viewport_size = viewport_size
	_pan = pan
	_zoom = maxf(zoom, 0.001)
	_world_bounds = world_bounds
	size = viewport_size
	queue_redraw()


func _grid_step_world() -> float:
	return float(GridDefs.CELL_SIZE) / 8.0


func _snap_px(v: float) -> float:
	return floorf(v) + 0.5


func _world_to_screen_x(world_x: float) -> float:
	return _pan.x + world_x * _zoom


func _world_to_screen_y(world_y: float) -> float:
	return _pan.y + world_y * _zoom


func _visible_world_rect() -> Rect2:
	var a := (_pan * -1.0) / _zoom
	var b := (_viewport_size - _pan) / _zoom
	return Rect2(a, b - a)


func _grid_clip_rect() -> Rect2:
	# Прямоугольник карты на экране — линии не выходят за него
	var l := _world_to_screen_x(_world_bounds.position.x)
	var t := _world_to_screen_y(_world_bounds.position.y)
	var r := _world_to_screen_x(_world_bounds.position.x + _world_bounds.size.x)
	var b := _world_to_screen_y(_world_bounds.position.y + _world_bounds.size.y)
	var x0 := minf(l, r)
	var y0 := minf(t, b)
	var x1 := maxf(l, r)
	var y1 := maxf(t, b)
	return Rect2(Vector2(x0, y0), Vector2(x1 - x0, y1 - y0)).intersection(
		Rect2(Vector2.ZERO, _viewport_size)
	)


func _draw() -> void:
	if _viewport_size.x < 1.0 or _viewport_size.y < 1.0:
		return
	var clip := _grid_clip_rect()
	if clip.size.x < 1.0 or clip.size.y < 1.0:
		draw_rect(Rect2(Vector2.ZERO, _viewport_size), COL_BG)
		return
	draw_rect(Rect2(Vector2.ZERO, _viewport_size), COL_BG_MAP)
	var step := _grid_step_world()
	if step * _zoom < 0.75:
		return
	var vis := _visible_world_rect()
	var wx0 := _world_bounds.position.x
	var wy0 := _world_bounds.position.y
	var wx1 := _world_bounds.position.x + _world_bounds.size.x
	var wy1 := _world_bounds.position.y + _world_bounds.size.y
	var x_start := maxf(wx0, floorf(vis.position.x / step) * step)
	var x_end := mini(wx1, vis.position.x + vis.size.x)
	var y_start := maxf(wy0, floorf(vis.position.y / step) * step)
	var y_end := mini(wy1, vis.position.y + vis.size.y)
	var x := x_start
	while x <= x_end + 0.001:
		_draw_v_line(_snap_px(_world_to_screen_x(x)), clip)
		x += step
	var y := y_start
	while y <= y_end + 0.001:
		_draw_h_line(_snap_px(_world_to_screen_y(y)), clip)
		y += step
	# Линии по краям карты (совпадают с границей, без пустых полос)
	_draw_v_line(_snap_px(_world_to_screen_x(wx0)), clip)
	_draw_v_line(_snap_px(_world_to_screen_x(wx1)), clip)
	_draw_h_line(_snap_px(_world_to_screen_y(wy0)), clip)
	_draw_h_line(_snap_px(_world_to_screen_y(wy1)), clip)


func _draw_v_line(screen_x: float, clip: Rect2) -> void:
	if screen_x < clip.position.x - 1.0 or screen_x > clip.position.x + clip.size.x + 1.0:
		return
	draw_rect(Rect2(screen_x - 0.5, clip.position.y, 1.0, clip.size.y), COL_LINE)


func _draw_h_line(screen_y: float, clip: Rect2) -> void:
	if screen_y < clip.position.y - 1.0 or screen_y > clip.position.y + clip.size.y + 1.0:
		return
	draw_rect(Rect2(clip.position.x, screen_y - 0.5, clip.size.x, 1.0), COL_LINE)
