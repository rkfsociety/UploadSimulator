extends Control
class_name ConnectionPort
## Неоновая ячейка порта блока.

signal port_pressed(port: ConnectionPort)

enum Kind { FILE, MONEY }
enum Dir { IN, OUT }

@export var instance_uid: String = ""
@export var block_type: String = ""
@export var port_id: String = ""
@export var kind: Kind = Kind.FILE
@export var direction: Dir = Dir.OUT

const SIZE := Vector2(30, 30)


func _ready() -> void:
	custom_minimum_size = SIZE
	tooltip_text = _tooltip_text()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		port_pressed.emit(self)
		accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		port_pressed.emit(self)
		accept_event()


func _draw() -> void:
	var center := size * 0.5
	var r := 9.0
	var fill := _fill_color()
	var outline := _outline_color()
	var glow := _glow_color()
	# Лёгкое свечение порта (без большой растушёвки)
	if kind == Kind.FILE:
		draw_circle(center, r + 1.0, Color(glow.r, glow.g, glow.b, 0.18))
	else:
		var gr := Rect2(center.x - r - 1.0, center.y - r - 1.0, (r + 1.0) * 2.0, (r + 1.0) * 2.0)
		draw_rect(gr, Color(glow.r, glow.g, glow.b, 0.16))
	if kind == Kind.FILE:
		if direction == Dir.OUT:
			draw_circle(center, r, fill)
			draw_arc(center, r, 0, TAU, 64, outline, 1.0)
		else:
			draw_arc(center, r, 0, TAU, 64, fill, 3.0)
			draw_arc(center, r - 3.5, 0, TAU, 64, outline, 1.0)
	else:
		if direction == Dir.OUT:
			var rect := Rect2(center.x - r, center.y - r, r * 2.0, r * 2.0)
			draw_rect(rect, fill)
			draw_rect(rect, outline, false, 1.0)
		else:
			var pts := PackedVector2Array(
				[
					center + Vector2(0, -r),
					center + Vector2(r, 0),
					center + Vector2(0, r),
					center + Vector2(-r, 0),
				]
			)
			draw_colored_polygon(pts, fill)
			draw_polyline(pts + PackedVector2Array([pts[0]]), outline, 1.0)


func _fill_color() -> Color:
	if kind == Kind.FILE:
		return Color(0.0, 0.75, 0.95, 0.9) if direction == Dir.OUT else Color(0.0, 0.4, 0.55, 0.45)
	return Color(1.0, 0.7, 0.1, 0.95) if direction == Dir.OUT else Color(0.6, 0.35, 0.05, 0.5)


func _outline_color() -> Color:
	if kind == Kind.FILE:
		return MinimalUI.NEON_CYAN
	return MinimalUI.NEON_GOLD


func _glow_color() -> Color:
	if kind == Kind.FILE:
		return MinimalUI.NEON_CYAN
	return MinimalUI.NEON_MAGENTA


func _tooltip_text() -> String:
	var type_name := "Файлы" if kind == Kind.FILE else "Деньги"
	var dir_name := "выход" if direction == Dir.OUT else "вход"
	return "%s · %s (%s)" % [block_type, type_name, dir_name]


func set_highlight(active: bool, valid_target: bool = false) -> void:
	if active:
		modulate = Color(1.4, 1.2, 1.8) if valid_target else Color(1.6, 0.9, 1.4)
	elif valid_target:
		modulate = Color(0.7, 1.3, 1.5)
	else:
		modulate = Color.WHITE
	queue_redraw()
