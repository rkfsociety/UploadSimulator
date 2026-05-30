extends RefCounted

var case_count := 2


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_axis_aligned(errors)
	_test_sample_endpoints(errors)
	return errors


func _test_axis_aligned(errors: Array[String]) -> void:
	var path := WireRouteUtils.build_path(
		Vector2(0, 0),
		Vector2(256, 128),
		ConnectionPort.Dir.OUT,
		ConnectionPort.Dir.IN,
	)
	if not WireRouteUtils.is_axis_aligned(path):
		errors.append("wire route: все сегменты должны быть H/V")


func _test_sample_endpoints(errors: Array[String]) -> void:
	var path := WireRouteUtils.build_path(
		Vector2(100, 50),
		Vector2(400, 200),
		ConnectionPort.Dir.OUT,
		ConnectionPort.Dir.IN,
	)
	var start := WireRouteUtils.sample_path(path, 0.0)
	var end := WireRouteUtils.sample_path(path, 1.0)
	if start.distance_to(path[0]) > 1.0:
		errors.append("wire route: t=0 у начала")
	if end.distance_to(path[path.size() - 1]) > 1.0:
		errors.append("wire route: t=1 у конца")
