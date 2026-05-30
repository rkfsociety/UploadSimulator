extends RefCounted
class_name FieldMapCamera
## Камера карты: pan, zoom на MapContent; размер вида — FieldMap.

var _host: Control
var _map_content: Control

var zoom: float = 1.0
var pan: Vector2 = Vector2.ZERO
var _view_dirty: bool = true


func _init(host: Control, map_content: Control) -> void:
	_host = host
	_map_content = map_content


## Размер области FieldMap на экране.
func view_size() -> Vector2:
	return _host.size


## Переводит экранные координаты FieldMap в мировые пиксели карты.
func screen_to_world(screen: Vector2) -> Vector2:
	return (screen - pan) / zoom


## Мировые пиксели карты → координаты FieldMap на экране.
func world_to_screen(world: Vector2) -> Vector2:
	return world * zoom + pan


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
	zoom = clampf(zoom * factor, min_zoom(), FieldMapConstants.ZOOM_MAX)
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


## Минимальный зум: карта заполняет экран, пустоты за краями не видно.
func min_zoom() -> float:
	var bounds := GridDefs.world_bounds_rect()
	var vs := view_size()
	if vs.x < 1.0 or vs.y < 1.0:
		return FieldMapConstants.ZOOM_MIN
	var cover := maxf(vs.x / bounds.size.x, vs.y / bounds.size.y)
	return maxf(cover, FieldMapConstants.ZOOM_MIN)


## Применить текущие zoom/pan к viewport и сетке.
func apply() -> void:
	if _map_content == null or not _host.is_node_ready():
		return
	_clamp_zoom()
	_clamp_pan()
	_map_content.scale = Vector2.ONE * zoom
	_map_content.position = pan
	_view_dirty = true


## Сбрасывает флаг: pan/zoom изменились с прошлого кадра (для перерисовки сетки).
func consume_view_dirty() -> bool:
	var dirty := _view_dirty
	_view_dirty = false
	return dirty


func _clamp_zoom() -> void:
	zoom = clampf(zoom, min_zoom(), FieldMapConstants.ZOOM_MAX)


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


func _clamp_axis(
	value: float,
	view_size: float,
	zoom_level: float,
	margin: float,
	world_min: float,
	world_max: float,
) -> float:
	# Экран (0…view) показывает только мир [world_min, world_max] — без пустоты за картой
	var lo := view_size - world_max * zoom_level - margin
	var hi := -world_min * zoom_level + margin
	if lo > hi:
		return (lo + hi) * 0.5
	return clampf(value, lo, hi)
