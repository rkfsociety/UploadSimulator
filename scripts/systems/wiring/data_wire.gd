extends Node2D
class_name DataWire
## Провод с бегущим импульсом (анимация передачи данных).

const _ANIM_NAME := &"flow"

var _base: Line2D
var _pulse: Line2D
var _anim_player: AnimationPlayer
var _screen_notifier: VisibleOnScreenNotifier2D
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _animate: bool = true
var _speed: float = 1.1
var _on_screen: bool = true
var _flow: float = 0.0

## Позиция импульса вдоль провода (0..1), двигается через AnimationPlayer.
var flow: float:
	set(value):
		_flow = value
		_update_pulse()
	get:
		return _flow


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
	_setup_screen_notifier()
	_setup_animation_player()


func configure(color: Color, animate: bool = true, speed: float = 1.1) -> void:
	_animate = animate
	_speed = speed
	var dim := Color(color.r, color.g, color.b, 0.32)
	_base.default_color = dim
	_pulse.default_color = color
	_apply_anim_speed()
	_sync_animation_state()


func set_pending_style() -> void:
	# Пунктирный «натянутый» провод при выборе цели
	_base.default_color.a = 0.22
	_pulse.default_color.a = 0.75
	_speed = 1.6


func set_endpoints(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	_base.points = PackedVector2Array([from, to])
	_update_visibility_rect()
	_update_pulse()
	_sync_animation_state()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		_sync_animation_state()


func _setup_screen_notifier() -> void:
	_screen_notifier = VisibleOnScreenNotifier2D.new()
	add_child(_screen_notifier)
	_screen_notifier.screen_entered.connect(_on_screen_entered)
	_screen_notifier.screen_exited.connect(_on_screen_exited)


func _setup_animation_player() -> void:
	var anim := Animation.new()
	anim.length = 1.0
	anim.loop_mode = Animation.LOOP_LINEAR
	var track_idx := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, NodePath("flow"))
	anim.track_insert_key(track_idx, 0.0, 0.0)
	anim.track_insert_key(track_idx, 1.0, 1.0)
	anim.value_track_set_interpolation_type(track_idx, Animation.INTERPOLATION_LINEAR)

	var lib := AnimationLibrary.new()
	lib.add_animation(_ANIM_NAME, anim)

	_anim_player = AnimationPlayer.new()
	add_child(_anim_player)
	_anim_player.root_node = NodePath("..")
	_anim_player.add_animation_library(&"", lib)
	_apply_anim_speed()


func _apply_anim_speed() -> void:
	if _anim_player == null:
		return
	var anim := _anim_player.get_animation(_ANIM_NAME)
	if anim == null:
		return
	anim.length = 1.0 / maxf(_speed, 0.05)


func _update_visibility_rect() -> void:
	var min_p := _from.min(_to)
	var max_p := _from.max(_to)
	var pad := 12.0
	_screen_notifier.rect = Rect2(min_p - Vector2(pad, pad), max_p - min_p + Vector2(pad * 2.0, pad * 2.0))


func _on_screen_entered() -> void:
	_on_screen = true
	_sync_animation_state()


func _on_screen_exited() -> void:
	_on_screen = false
	_sync_animation_state()


func _sync_animation_state() -> void:
	if _anim_player == null:
		return
	var active := _animate and is_visible_in_tree() and _on_screen
	if not active:
		if _anim_player.is_playing():
			_anim_player.stop()
		if not _animate:
			_pulse.points = PackedVector2Array([_from, _to])
		return
	if not _anim_player.is_playing():
		_anim_player.play(_ANIM_NAME)


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
