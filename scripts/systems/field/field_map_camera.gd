extends RefCounted
class_name FieldMapCamera
## Камера карты: pan, zoom, синхронизация сетки и MapViewport.

var _host: Control
var _map_viewport: Control
var _grid_draw: Control

var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO


func _init(host: Control, map_viewport: Control, grid_draw: Control) -> void:
	_host = host
	_map_viewport = map_viewport
	_grid_draw = grid_draw


## Размер области FieldMap на экране.
func view_size() -> Vector2:
	return _host.size


## Переводит экранные координаты FieldMap в мировые пиксели карты.
func screen_to_world(screen: Vector2) -> Vector2:
	return (screen - pan) / zoom


## Мировой прямоугольник, попадающий в текущий вид (с запасом по краям).
func visible_world_rect() -> Rect2:
	var p0 := screen_to_world(Vector2.ZERO)
	var p1 := screen_to_world(view_size())
	var rect := Rect2(p0, p1 - p0)
	if rect.size.x < 0.0:
		rect.position.x += rect.size.x
		rect.size.x = -rect.size.x
	if rect.size.y < 0.0:
		rect.position.y += rect.size.y
		rect.size.y = -rect.size.y
	var grow := float(FieldMapConstants.VISIBLE_WORLD_GROW_CELLS * GridDefs.CELL_SIZE)
	return rect.grow_individual(grow, grow, grow, grow)


## Клетка сетки в центре текущего вида.
func view_center_cell() -> Vector2i:
	if _host.size.x < 1.0 or _host.size.y < 1.0:
		return Vector2i.ZERO
	return GridDefs.snap_cell_from_world(screen_to_world(_host.size * 0.5))


## Центрирует камеру на мировой точке.
func focus_world(world_px: Vector2) -> void:
	if _host.size.x < 1.0 or _host.size.y < 1.0:
		return
	pan = _host.size * 0.5 - world_px * zoom
	apply()


## Масштаб с фиксацией точки под курсором.
func zoom_at(factor: float, screen_pos: Vector2) -> void:
	var old_zoom := zoom
	zoom = clampf(zoom * factor, FieldMapConstants.ZOOM_MIN, FieldMapConstants.ZOOM_MAX)
	if is_equal_approx(old_zoom, zoom):
		return
	var map_point := (screen_pos - pan) / old_zoom
	pan = screen_pos - map_point * zoom
	apply()


## Сдвиг pan с ограничением границ карты.
func apply_pan_delta(delta: Vector2) -> void:
	pan += delta
	apply()


## Установить pan напрямую (после перетаскивания).
func set_pan(value: Vector2) -> void:
	pan = value
	apply()


## Применить текущие zoom/pan к viewport и сетке.
func apply() -> void:
	if _map_viewport == null or not _host.is_node_ready():
		return
	_clamp_pan()
	_map_viewport.scale = Vector2.ONE * zoom
	_map_viewport.position = pan
	_sync_grid()


func _clamp_pan() -> void:
	if _host.size.x < 1.0 or _host.size.y < 1.0:
		return
	var bounds := GridDefs.world_bounds_rect()
	var margin := FieldMapConstants.PAN_CLAMP_MARGIN
	pan.x = _clamp_axis(
		pan.x, _host.size.x, zoom, margin, bounds.position.x, bounds.position.x + bounds.size.x
	)
	pan.y = _clamp_axis(
		pan.y, _host.size.y, zoom, margin, bounds.position.y, bounds.position.y + bounds.size.y
	)


## Обновить сетку без изменения zoom/pan (каждый кадр).
func sync_grid() -> void:
	_sync_grid()


func _sync_grid() -> void:
	if _grid_draw == null or not _grid_draw.has_method("set_camera"):
		return
	_grid_draw.set_camera(_host.size, pan, zoom, GridDefs.world_bounds_rect())


func _clamp_axis(
	value: float,
	view_size: float,
	zoom_level: float,
	margin: float,
	world_min: float,
	world_max: float,
) -> float:
	var span := world_max - world_min
	var span_screen := span * zoom_level
	if span_screen <= view_size:
		var center_w := (world_min + world_max) * 0.5
		return view_size * 0.5 - center_w * zoom_level
	var m := margin / maxf(zoom_level, FieldMapConstants.MIN_ZOOM_EPSILON)
	var lo := view_size - (world_max - m) * zoom_level
	var hi := -(world_min + m) * zoom_level
	if lo > hi:
		return (lo + hi) * 0.5
	return clampf(value, lo, hi)
