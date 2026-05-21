extends Node2D
class_name DataWire
## Провод с бегущим импульсом (анимация передачи данных).

var _base: Line2D
var _pulse: Line2D
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _flow: float = 0.0
var _animate: bool = true
var _speed: float = 1.1


func _init() -> void:
	_base = Line2D.new()
	_base.width = 2.0
	_base.antialiased = true
	_base.z_index = 0
	add_child(_base)
	_pulse = Line2D.new()
	_pulse.width = 4.0
	_pulse.antialiased = true
	_pulse.z_index = 1
	add_child(_pulse)


func configure(color: Color, animate: bool = true, speed: float = 1.1) -> void:
	_animate = animate
	_speed = speed
	var dim := Color(color.r, color.g, color.b, 0.32)
	_base.default_color = dim
	_pulse.default_color = color


func set_pending_style() -> void:
	# Пунктирный «натянутый» провод при выборе цели
	_base.default_color.a = 0.22
	_pulse.default_color.a = 0.75
	_speed = 1.6


func set_endpoints(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	_base.points = PackedVector2Array([from, to])
	_update_pulse()


func _process(delta: float) -> void:
	if not _animate:
		_pulse.points = PackedVector2Array([_from, _to])
		return
	_flow = fmod(_flow + delta * _speed, 1.0)
	_update_pulse()


func _update_pulse() -> void:
	var seg := _to - _from
	var len := seg.length()
	if len < 1.0:
		_pulse.points = PackedVector2Array([_from, _to])
		return
	var seg_frac := clampf(16.0 / len, 0.08, 0.35)
	var t0 := _flow
	var t1 := minf(t0 + seg_frac, 1.0)
	_pulse.points = PackedVector2Array([_from.lerp(_to, t0), _from.lerp(_to, t1)])
