extends Node2D
class_name WireBatchRenderer
## Массовая отрисовка проводов через RenderingServer (ортогональные линии).

const BASE_WIDTH := 2.0

var _canvas_rid: RID = RID()
var _segments: Array[Dictionary] = []
var _pending: Dictionary = {}
var _visible_rect: Rect2 = Rect2(-1e9, -1e9, 2e9, 2e9)


func _ready() -> void:
	_canvas_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_canvas_rid, get_canvas_item())


func _exit_tree() -> void:
	if _canvas_rid.is_valid():
		RenderingServer.free_rid(_canvas_rid)
		_canvas_rid = RID()


func set_visible_rect(rect: Rect2) -> void:
	_visible_rect = rect


func set_segments(segments: Array[Dictionary]) -> void:
	_segments = segments
	_draw_batch()


func set_pending(pending: Dictionary) -> void:
	_pending = pending
	_draw_batch()


func clear_pending() -> void:
	_pending = {}
	_draw_batch()


func refresh_draw() -> void:
	_draw_batch()


func _draw_batch() -> void:
	if not _canvas_rid.is_valid():
		return
	RenderingServer.canvas_item_clear(_canvas_rid)
	for seg: Dictionary in _segments:
		_draw_segment(seg)
	if not _pending.is_empty():
		_draw_pending()


func _draw_segment(seg: Dictionary) -> void:
	var path: PackedVector2Array = _segment_path(seg)
	if path.size() < 2:
		return
	if not _path_intersects_view(path):
		return
	var color: Color = seg.get("color", Color.WHITE)
	var dim := Color(color.r, color.g, color.b, 0.32)
	_draw_polyline(path, dim)


func _draw_pending() -> void:
	var path: PackedVector2Array = _segment_path(_pending)
	if path.size() < 2:
		return
	if not _path_intersects_view(path):
		return
	var color: Color = _pending.get("color", Color.WHITE)
	var dim := Color(color.r, color.g, color.b, 0.22)
	_draw_polyline(path, dim)


func _segment_path(seg: Dictionary) -> PackedVector2Array:
	var path: Variant = seg.get("path", null)
	if path is PackedVector2Array and (path as PackedVector2Array).size() >= 2:
		return path as PackedVector2Array
	var from: Vector2 = seg.get("from", Vector2.ZERO)
	var to: Vector2 = seg.get("to", Vector2.ZERO)
	return PackedVector2Array([from, to])


func _draw_polyline(points: PackedVector2Array, color: Color) -> void:
	for i in range(points.size() - 1):
		RenderingServer.canvas_item_add_line(
			_canvas_rid, points[i], points[i + 1], color, BASE_WIDTH, true
		)


func _path_intersects_view(path: PackedVector2Array) -> bool:
	if _visible_rect.size.x <= 0.0 or _visible_rect.size.y <= 0.0:
		return true
	var bounds := WireRouteUtils.path_bounds(path)
	var pad := 12.0
	bounds = bounds.grow(pad)
	return _visible_rect.intersects(bounds)
