extends RefCounted
class_name WireRouteUtils
## Ортогональная трассировка проводов (горизонталь / вертикаль, изгибы 90°).

const STUB_CELLS := 0.5


static func build_path(
	from: Vector2,
	to: Vector2,
	from_port_dir: ConnectionPort.Dir,
	to_port_dir: ConnectionPort.Dir,
) -> PackedVector2Array:
	var stub := float(GridDefs.CELL_SIZE) * STUB_CELLS
	var exit := _exit_from_port(from, from_port_dir, stub)
	var enter := _approach_to_port(to, to_port_dir, stub)
	var inner := _connect_orthogonal(exit, enter)
	var raw := PackedVector2Array([from, exit])
	for p: Vector2 in inner:
		raw.append(p)
	raw.append(enter)
	raw.append(to)
	return _dedupe(raw)


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


static func _exit_from_port(center: Vector2, port_dir: ConnectionPort.Dir, stub: float) -> Vector2:
	if port_dir == ConnectionPort.Dir.OUT:
		return center + Vector2(stub, 0.0)
	return center + Vector2(-stub, 0.0)


static func _approach_to_port(center: Vector2, port_dir: ConnectionPort.Dir, stub: float) -> Vector2:
	if port_dir == ConnectionPort.Dir.IN:
		return center + Vector2(-stub, 0.0)
	return center + Vector2(stub, 0.0)


static func _connect_orthogonal(a: Vector2, b: Vector2) -> Array[Vector2]:
	var ax := _snap_grid(a.x)
	var ay := _snap_grid(a.y)
	var bx := _snap_grid(b.x)
	var by := _snap_grid(b.y)
	if is_zero_approx(ax - bx):
		return []
	if is_zero_approx(ay - by):
		return []
	var mid_x := _snap_grid((ax + bx) * 0.5)
	return [Vector2(mid_x, ay), Vector2(mid_x, by)]


static func _snap_grid(v: float) -> float:
	return roundf(v / float(GridDefs.CELL_SIZE)) * float(GridDefs.CELL_SIZE)


static func _dedupe(points: PackedVector2Array) -> PackedVector2Array:
	if points.is_empty():
		return points
	var out := PackedVector2Array([points[0]])
	for i in range(1, points.size()):
		if points[i].distance_squared_to(out[out.size() - 1]) > 0.25:
			out.append(points[i])
	return out
