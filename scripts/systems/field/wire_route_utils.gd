extends RefCounted
class_name WireRouteUtils
## Ортогональная трассировка проводов (горизонталь / вертикаль, изгибы 90°).

const SAME_ROW_EPS := 4.0

# A* по решётке полуклетки (CELL_SIZE / 2): порты модулей всегда попадают на её узлы.
const _DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
const _OBSTACLE_INSET := 1.0
const _SEARCH_MARGIN_CELLS := 8
const _MAX_GRID_CELLS := 4000
const _MAX_EXPANSIONS := 6000


## Трассировка провода между центрами модулей (перекрестие). У модуля один порт
## в центре, поэтому путь идёт строго центр→центр ортогонально (L/Z); части линии
## внутри модулей-концов скрыты панелями (рисуем провода под блоками).
## Если переданы `obstacles` (прямоугольники прочих модулей, без концов), путь
## огибает их по решётке полуклетки.
## `from_port_dir`/`to_port_dir` оставлены для совместимости вызовов и не влияют на
## маршрут: направление выхода определяется взаимным положением центров.
static func build_path(
	from: Vector2,
	to: Vector2,
	_from_port_dir: ConnectionPort.Dir = ConnectionPort.Dir.OUT,
	_to_port_dir: ConnectionPort.Dir = ConnectionPort.Dir.IN,
	obstacles: Array[Rect2] = [],
) -> PackedVector2Array:
	var simple := _simple_path(from, from, to, to)

	# Без препятствий или если прямой маршрут их не задевает — используем его.
	if obstacles.is_empty() or not _path_hits_obstacles(simple, obstacles):
		return simple

	# Прямой маршрут задевает чужие модули — огибаем по решётке.
	var routed := _route_around(from, to, obstacles)
	if routed.size() < 2:
		return simple
	var full := PackedVector2Array([from])
	for p: Vector2 in routed:
		full.append(p)
	full.append(to)
	return _dedupe(_simplify_collinear(full))


static func _simple_path(
	from: Vector2, exit: Vector2, enter: Vector2, to: Vector2
) -> PackedVector2Array:
	var inner := _connect_orthogonal(exit, enter)
	var raw := PackedVector2Array([from, exit])
	for p: Vector2 in inner:
		raw.append(p)
	raw.append(enter)
	raw.append(to)
	return _dedupe(raw)


## Обрезает концы ортогонального пути по прямоугольникам модулей-концов, чтобы
## видимая линия начиналась/заканчивалась на КРАЮ модуля (эффект «перекрестия»),
## а не в центре. Пустой Rect2 (size 0) — конец не обрезается (например, курсор).
static func trim_path_to_rects(
	path: PackedVector2Array, from_rect: Rect2, to_rect: Rect2
) -> PackedVector2Array:
	var out := path
	if from_rect.size.x > 0.0 and from_rect.size.y > 0.0:
		out = _trim_start(out, from_rect)
	if to_rect.size.x > 0.0 and to_rect.size.y > 0.0:
		out.reverse()
		out = _trim_start(out, to_rect)
		out.reverse()
	return out


## Отбрасывает участок пути внутри `rect` от начала и ставит точку на границе.
static func _trim_start(path: PackedVector2Array, rect: Rect2) -> PackedVector2Array:
	if path.size() < 2:
		return path
	var i := 0
	while i < path.size() - 1 and rect.has_point(path[i + 1]):
		i += 1
	if i >= path.size() - 1:
		return path  # весь путь внутри модуля — оставляем как есть
	var out := PackedVector2Array()
	if rect.has_point(path[i]):
		out.append(_boundary_point(path[i], path[i + 1], rect))
	else:
		out.append(path[i])
	for j in range(i + 1, path.size()):
		out.append(path[j])
	return out


## Точка пересечения ортогонального отрезка (inside→outside) с границей rect.
static func _boundary_point(inside: Vector2, outside: Vector2, rect: Rect2) -> Vector2:
	if is_zero_approx(inside.y - outside.y):
		# Горизонтальный сегмент — пересекаем вертикальную грань.
		var bx := rect.position.x if outside.x < inside.x else rect.position.x + rect.size.x
		return Vector2(bx, inside.y)
	# Вертикальный сегмент — пересекаем горизонтальную грань.
	var by := rect.position.y if outside.y < inside.y else rect.position.y + rect.size.y
	return Vector2(inside.x, by)


static func sample_path(points: PackedVector2Array, t: float) -> Vector2:
	if points.is_empty():
		return Vector2.ZERO
	if points.size() == 1:
		return points[0]
	var clamped := clampf(t, 0.0, 1.0)
	var total := 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
	if total < 0.001:
		return points[0]
	var target := clamped * total
	var walked := 0.0
	for i in range(points.size() - 1):
		var seg_len := points[i].distance_to(points[i + 1])
		if walked + seg_len >= target:
			var local_t := (target - walked) / seg_len
			return points[i].lerp(points[i + 1], local_t)
		walked += seg_len
	return points[points.size() - 1]


static func path_bounds(points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2()
	var min_p := points[0]
	var max_p := points[0]
	for p: Vector2 in points:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	return Rect2(min_p, max_p - min_p)


static func is_axis_aligned(points: PackedVector2Array) -> bool:
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		if not is_zero_approx(a.x - b.x) and not is_zero_approx(a.y - b.y):
			return false
	return true


static func _connect_orthogonal(a: Vector2, b: Vector2) -> Array[Vector2]:
	if is_zero_approx(a.x - b.x) or is_zero_approx(a.y - b.y):
		return []
	# Слева направо: один изгиб 90° (горизонталь → вертикаль у входа).
	if b.x >= a.x:
		return [Vector2(b.x, a.y)]
	# Справа налево: Z-образный канал с вертикалью по сетке между модулями.
	var mid_x := _snap_grid((a.x + b.x) * 0.5)
	if is_zero_approx(mid_x - a.x) or is_zero_approx(mid_x - b.x):
		return [Vector2(b.x, a.y)]
	return [Vector2(mid_x, a.y), Vector2(mid_x, b.y)]


static func _snap_grid(v: float) -> float:
	return roundf(v / float(GridDefs.CELL_SIZE)) * float(GridDefs.CELL_SIZE)


## --- Обход препятствий ---


static func _path_hits_obstacles(points: PackedVector2Array, obstacles: Array[Rect2]) -> bool:
	for i in range(points.size() - 1):
		for ob: Rect2 in obstacles:
			if _seg_hits_rect(points[i], points[i + 1], ob.grow(-_OBSTACLE_INSET)):
				return true
	return false


## A* по решётке полуклетки между точками выхода и входа (узлы попадают на сетку).
static func _route_around(
	start: Vector2, goal: Vector2, obstacles: Array[Rect2]
) -> PackedVector2Array:
	var step := float(GridDefs.CELL_SIZE) * 0.5
	var margin := step * float(_SEARCH_MARGIN_CELLS)
	var region := Rect2(start.min(goal), (goal - start).abs())
	for ob: Rect2 in obstacles:
		if region.grow(margin).intersects(ob):
			region = region.merge(ob)
	region = region.grow(margin)
	var origin := Vector2(
		floorf(region.position.x / step) * step, floorf(region.position.y / step) * step
	)
	var nx := int(ceilf(region.size.x / step)) + 2
	var ny := int(ceilf(region.size.y / step)) + 2
	if nx <= 0 or ny <= 0 or nx * ny > _MAX_GRID_CELLS:
		return PackedVector2Array()
	var s := _to_cell(start, origin, step)
	var g := _to_cell(goal, origin, step)
	if _cell_blocked(s, origin, step, obstacles) or _cell_blocked(g, origin, step, obstacles):
		return PackedVector2Array()
	return _astar(s, g, origin, step, nx, ny, obstacles)


static func _astar(
	s: Vector2i,
	g: Vector2i,
	origin: Vector2,
	step: float,
	nx: int,
	ny: int,
	obstacles: Array[Rect2],
) -> PackedVector2Array:
	var turn_cost := step * 0.5
	var start_key := _state_key(s, -1, nx)
	var open: Dictionary = {start_key: true}
	var g_score: Dictionary = {start_key: 0.0}
	var f_score: Dictionary = {start_key: float(_manhattan(s, g)) * step}
	var came: Dictionary = {}
	var cell_of: Dictionary = {start_key: s}
	var dir_of: Dictionary = {start_key: -1}
	var expansions := 0
	while not open.is_empty() and expansions < _MAX_EXPANSIONS:
		expansions += 1
		var cur_key := _pop_lowest(open, f_score)
		var cur: Vector2i = cell_of[cur_key]
		if cur == g:
			return _reconstruct(came, cell_of, cur_key, origin, step)
		var cur_dir: int = dir_of[cur_key]
		var cur_g: float = g_score[cur_key]
		for i in range(_DIRS.size()):
			var nc: Vector2i = cur + _DIRS[i]
			if nc.x < 0 or nc.y < 0 or nc.x >= nx or nc.y >= ny:
				continue
			if _cell_blocked(nc, origin, step, obstacles):
				continue
			if _edge_blocked(cur, nc, origin, step, obstacles):
				continue
			var turn := turn_cost if (cur_dir != -1 and cur_dir != i) else 0.0
			var tentative := cur_g + step + turn
			var nkey := _state_key(nc, i, nx)
			if tentative < float(g_score.get(nkey, INF)):
				came[nkey] = cur_key
				cell_of[nkey] = nc
				dir_of[nkey] = i
				g_score[nkey] = tentative
				f_score[nkey] = tentative + float(_manhattan(nc, g)) * step
				open[nkey] = true
	return PackedVector2Array()


static func _reconstruct(
	came: Dictionary, cell_of: Dictionary, goal_key: int, origin: Vector2, step: float
) -> PackedVector2Array:
	var cells: Array[Vector2i] = []
	var key: int = goal_key
	while true:
		cells.append(cell_of[key])
		if not came.has(key):
			break
		key = came[key]
	cells.reverse()
	var out := PackedVector2Array()
	for c: Vector2i in cells:
		out.append(_cell_pos(c, origin, step))
	return out


static func _pop_lowest(open: Dictionary, f_score: Dictionary) -> int:
	var best_key: int = -1
	var best_f := INF
	for key: int in open:
		var f: float = f_score.get(key, INF)
		if f < best_f:
			best_f = f
			best_key = key
	open.erase(best_key)
	return best_key


static func _state_key(cell: Vector2i, dir: int, nx: int) -> int:
	return ((cell.y * nx) + cell.x) * 5 + (dir + 1)


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _to_cell(p: Vector2, origin: Vector2, step: float) -> Vector2i:
	return Vector2i(roundi((p.x - origin.x) / step), roundi((p.y - origin.y) / step))


static func _cell_pos(c: Vector2i, origin: Vector2, step: float) -> Vector2:
	return origin + Vector2(float(c.x) * step, float(c.y) * step)


static func _cell_blocked(
	c: Vector2i, origin: Vector2, step: float, obstacles: Array[Rect2]
) -> bool:
	var p := _cell_pos(c, origin, step)
	for ob: Rect2 in obstacles:
		if ob.grow(-_OBSTACLE_INSET).has_point(p):
			return true
	return false


static func _edge_blocked(
	a: Vector2i, b: Vector2i, origin: Vector2, step: float, obstacles: Array[Rect2]
) -> bool:
	var mid := (_cell_pos(a, origin, step) + _cell_pos(b, origin, step)) * 0.5
	for ob: Rect2 in obstacles:
		if ob.grow(-_OBSTACLE_INSET).has_point(mid):
			return true
	return false


## Пересечение отрезка с прямоугольником (Лианг–Барски): true, если отрезок заходит внутрь.
static func _seg_hits_rect(a: Vector2, b: Vector2, r: Rect2) -> bool:
	if r.size.x <= 0.0 or r.size.y <= 0.0:
		return false
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	var p := [-d.x, d.x, -d.y, d.y]
	var q := [
		a.x - r.position.x,
		r.position.x + r.size.x - a.x,
		a.y - r.position.y,
		r.position.y + r.size.y - a.y
	]
	for i in range(4):
		if is_zero_approx(p[i]):
			if q[i] < 0.0:
				return false
			continue
		var t: float = q[i] / p[i]
		if p[i] < 0.0:
			t0 = maxf(t0, t)
		else:
			t1 = minf(t1, t)
		if t0 > t1:
			return false
	return true


static func _simplify_collinear(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() < 3:
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size() - 1):
		var prev := out[out.size() - 1]
		var cur := points[i]
		var nxt := points[i + 1]
		var collinear_x := is_zero_approx(prev.x - cur.x) and is_zero_approx(cur.x - nxt.x)
		var collinear_y := is_zero_approx(prev.y - cur.y) and is_zero_approx(cur.y - nxt.y)
		if collinear_x or collinear_y:
			continue
		out.append(cur)
	out.append(points[points.size() - 1])
	return out


static func _dedupe(points: PackedVector2Array) -> PackedVector2Array:
	if points.is_empty():
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		if points[i].distance_squared_to(out[out.size() - 1]) > 0.25:
			out.append(points[i])
	return out
