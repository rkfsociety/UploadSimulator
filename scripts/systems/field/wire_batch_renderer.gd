extends Node2D
class_name WireBatchRenderer
## Массовая отрисовка проводов через RenderingServer (один canvas item).

const BASE_WIDTH := 2.0
const PULSE_WIDTH := 4.0

var _canvas_rid: RID = RID()
var _segments: Array[Dictionary] = []
var _pending: Dictionary = {}
var _visible_rect: Rect2 = Rect2(-1e9, -1e9, 2e9, 2e9)
var _global_flow: float = 0.0
var _needs_animation: bool = false


func _ready() -> void:
	# Создаём отдельный canvas item для пакетной отрисовки линий
	_canvas_rid = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_canvas_rid, get_canvas_item())
	set_process(false)


func _exit_tree() -> void:
	if _canvas_rid.is_valid():
		RenderingServer.free_rid(_canvas_rid)
		_canvas_rid = RID()


func set_visible_rect(rect: Rect2) -> void:
	_visible_rect = rect


func set_segments(segments: Array[Dictionary]) -> void:
	_segments = segments
	_rebuild_animation_flag()
	_draw_batch()


func set_pending(pending: Dictionary) -> void:
	_pending = pending
	set_process(_needs_animation or not _pending.is_empty())
	_draw_batch()


func clear_pending() -> void:
	_pending = {}
	set_process(_needs_animation)
	_draw_batch()


func _rebuild_animation_flag() -> void:
	_needs_animation = false
	for seg: Dictionary in _segments:
		if seg.get("animate", true):
			_needs_animation = true
			return
	set_process(_needs_animation or not _pending.is_empty())


func _process(delta: float) -> void:
	if not _needs_animation and _pending.is_empty():
		set_process(false)
		return
	_global_flow = fmod(_global_flow + delta, 1.0)
	_draw_batch()


func refresh_draw() -> void:
	if _needs_animation:
		return
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
	var from: Vector2 = seg.get("from", Vector2.ZERO)
	var to: Vector2 = seg.get("to", Vector2.ZERO)
	if not _segment_intersects_view(from, to):
		return
	var color: Color = seg.get("color", Color.WHITE)
	var dim := Color(color.r, color.g, color.b, 0.32)
	RenderingServer.canvas_item_add_line(_canvas_rid, from, to, dim, BASE_WIDTH, true)
	if not seg.get("animate", true):
		RenderingServer.canvas_item_add_line(_canvas_rid, from, to, color, PULSE_WIDTH, true)
		return
	var speed: float = seg.get("speed", 1.1)
	var flow := fmod(_global_flow * speed, 1.0)
	var pulse := _pulse_endpoints(from, to, flow)
	RenderingServer.canvas_item_add_line(_canvas_rid, pulse[0], pulse[1], color, PULSE_WIDTH, true)


func _draw_pending() -> void:
	var from: Vector2 = _pending.get("from", Vector2.ZERO)
	var to: Vector2 = _pending.get("to", Vector2.ZERO)
	if not _segment_intersects_view(from, to):
		return
	var color: Color = _pending.get("color", Color.WHITE)
	var dim := Color(color.r, color.g, color.b, 0.22)
	var bright := Color(color.r, color.g, color.b, 0.75)
	RenderingServer.canvas_item_add_line(_canvas_rid, from, to, dim, BASE_WIDTH, true)
	var flow := fmod(_global_flow * 1.6, 1.0)
	var pulse := _pulse_endpoints(from, to, flow)
	RenderingServer.canvas_item_add_line(_canvas_rid, pulse[0], pulse[1], bright, PULSE_WIDTH, true)


func _pulse_endpoints(from: Vector2, to: Vector2, flow: float) -> PackedVector2Array:
	var seg := to - from
	var len := seg.length()
	if len < 1.0:
		return PackedVector2Array([from, to])
	var seg_frac := clampf(16.0 / len, 0.08, 0.35)
	var t0 := flow
	var t1 := minf(t0 + seg_frac, 1.0)
	return PackedVector2Array([from.lerp(to, t0), from.lerp(to, t1)])


func _segment_intersects_view(from: Vector2, to: Vector2) -> bool:
	if _visible_rect.size.x <= 0.0 or _visible_rect.size.y <= 0.0:
		return true
	var seg_rect := Rect2(from, to - from)
	if seg_rect.size.x < 0.0:
		seg_rect.position.x += seg_rect.size.x
		seg_rect.size.x = -seg_rect.size.x
	if seg_rect.size.y < 0.0:
		seg_rect.position.y += seg_rect.size.y
		seg_rect.size.y = -seg_rect.size.y
	return _visible_rect.intersects(seg_rect)
