extends RefCounted

var case_count := 5


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_same_row_is_horizontal(errors)
	_test_axis_aligned(errors)
	_test_sample_endpoints(errors)
	_test_avoids_obstacle(errors)
	_test_no_obstacles_keeps_simple(errors)
	return errors


func _test_same_row_is_horizontal(errors: Array[String]) -> void:
	var path := (
		WireRouteUtils
		. build_path(
			Vector2(200, 96),
			Vector2(500, 98),
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
		)
	)
	if path.size() > 5:
		errors.append("wire route: на одной высоте путь должен быть коротким (<=5 точек)")
	var max_y := path[0].y
	var min_y := path[0].y
	for p: Vector2 in path:
		max_y = maxf(max_y, p.y)
		min_y = minf(min_y, p.y)
	if max_y - min_y > WireRouteUtils.SAME_ROW_EPS + 32.0:
		errors.append("wire route: на одной высоте не должно быть длинного вертикального сегмента")


func _test_axis_aligned(errors: Array[String]) -> void:
	var path := (
		WireRouteUtils
		. build_path(
			Vector2(0, 0),
			Vector2(256, 128),
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
		)
	)
	if not WireRouteUtils.is_axis_aligned(path):
		errors.append("wire route: все сегменты должны быть H/V")


func _test_avoids_obstacle(errors: Array[String]) -> void:
	# Модуль ровно на прямой между портами — путь должен его обогнуть.
	var obstacle := Rect2(Vector2(220, 32), Vector2(192, 192))
	var path := (
		WireRouteUtils
		. build_path(
			Vector2(160, 128),
			Vector2(480, 128),
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
			[obstacle] as Array[Rect2],
		)
	)
	if not WireRouteUtils.is_axis_aligned(path):
		errors.append("wire route: обход должен оставаться ортогональным (H/V)")
	var inner := obstacle.grow(-2.0)
	for i in range(path.size() - 1):
		if WireRouteUtils._seg_hits_rect(path[i], path[i + 1], inner):
			errors.append("wire route: путь не должен проходить сквозь модуль")
			break


func _test_no_obstacles_keeps_simple(errors: Array[String]) -> void:
	# Без препятствий результат совпадает с простым маршрутом (регрессия).
	var bare := WireRouteUtils.build_path(
		Vector2(0, 0), Vector2(256, 128), ConnectionPort.Dir.OUT, ConnectionPort.Dir.IN
	)
	var with_empty := (
		WireRouteUtils
		. build_path(
			Vector2(0, 0),
			Vector2(256, 128),
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
			[] as Array[Rect2],
		)
	)
	if bare != with_empty:
		errors.append("wire route: пустой список препятствий не должен менять маршрут")


func _test_sample_endpoints(errors: Array[String]) -> void:
	var path := (
		WireRouteUtils
		. build_path(
			Vector2(100, 50),
			Vector2(400, 200),
			ConnectionPort.Dir.OUT,
			ConnectionPort.Dir.IN,
		)
	)
	var start := WireRouteUtils.sample_path(path, 0.0)
	var end := WireRouteUtils.sample_path(path, 1.0)
	if start.distance_to(path[0]) > 1.0:
		errors.append("wire route: t=0 у начала")
	if end.distance_to(path[path.size() - 1]) > 1.0:
		errors.append("wire route: t=1 у конца")
