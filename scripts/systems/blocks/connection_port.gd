extends Control
class_name ConnectionPort
## Неоновая ячейка порта блока.

signal port_pressed(port: ConnectionPort)

enum Kind { FILE, MONEY }
enum Dir { IN, OUT }

# Визуальный размер иконки порта (зона нажатия — PlatformInfo.port_hit_size)

var _instance_uid: String = ""
var _block_type: String = ""
var _port_id: String = ""
var _kind: Kind = Kind.FILE
var _direction: Dir = Dir.OUT
# Модульный (центральный) порт: один на модуль, тип данных провод определяет сам.
var _module_level: bool = false

var instance_uid: String:
	get:
		return _instance_uid

var block_type: String:
	get:
		return _block_type

var port_id: String:
	get:
		return _port_id

var kind: Kind:
	get:
		return _kind

var direction: Dir:
	get:
		return _direction

var is_module_level: bool:
	get:
		return _module_level


## Однократная инициализация порта (поля только для чтения снаружи).
func configure(uid: String, type_id: String, p_id: String, p_kind: Kind, p_dir: Dir) -> void:
	_instance_uid = uid
	_block_type = type_id
	_port_id = p_id
	_kind = p_kind
	_direction = p_dir
	_module_level = false
	tooltip_text = _tooltip_text()
	queue_redraw()


## Инициализация единственного (центрального) порта модуля. Тип данных и
## направление выбирает сервис проводов по паре типов модулей при соединении.
func configure_module(uid: String, type_id: String) -> void:
	_instance_uid = uid
	_block_type = type_id
	_port_id = ""
	_module_level = true
	tooltip_text = "%s · разъём" % _block_type
	queue_redraw()


func _ready() -> void:
	# На таче — не меньше 48px, рисуем иконку по центру
	var hit := float(PlatformInfo.port_hit_size())
	custom_minimum_size = Vector2(hit, hit)
	tooltip_text = _tooltip_text()
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if PlatformInfo.is_primary_pointer_press(event):
		port_pressed.emit(self)
		accept_event()


func _draw() -> void:
	var vis_sz := float(PlatformInfo.port_visual_size())
	var vis := Vector2(vis_sz, vis_sz)
	var offset := (size - vis) * 0.5
	draw_set_transform(offset, 0.0, Vector2.ONE)
	if _module_level:
		draw_module_visual(self, vis)
	else:
		draw_port_visual(self, vis, _kind, _direction)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## Нейтральный центральный разъём модуля: кольцо-хаб без привязки к типу данных.
static func draw_module_visual(canvas: CanvasItem, canvas_size: Vector2) -> void:
	var center := canvas_size * 0.5
	var r := 9.0
	var accent := MinimalUI.neon_cyan
	canvas.draw_circle(center, r + 2.0, Color(accent.r, accent.g, accent.b, 0.16))
	canvas.draw_circle(center, r, Color(0.04, 0.07, 0.10, 0.95))
	canvas.draw_arc(center, r, 0, TAU, 48, accent, 2.0)
	canvas.draw_circle(center, 3.0, accent)


static func draw_port_visual(
	canvas: CanvasItem, canvas_size: Vector2, p_kind: Kind, p_direction: Dir
) -> void:
	var center := canvas_size * 0.5
	var r := 9.0
	var fill := _fill_color(p_kind, p_direction)
	var outline := _outline_color(p_kind)
	var glow := _glow_color(p_kind)
	if p_kind == Kind.FILE:
		canvas.draw_circle(center, r + 1.0, Color(glow.r, glow.g, glow.b, 0.18))
	else:
		var gr := Rect2(center.x - r - 1.0, center.y - r - 1.0, (r + 1.0) * 2.0, (r + 1.0) * 2.0)
		canvas.draw_rect(gr, Color(glow.r, glow.g, glow.b, 0.16))
	if p_kind == Kind.FILE:
		if p_direction == Dir.OUT:
			canvas.draw_circle(center, r, fill)
			canvas.draw_arc(center, r, 0, TAU, 64, outline, 1.0)
		else:
			canvas.draw_arc(center, r, 0, TAU, 64, fill, 3.0)
			canvas.draw_arc(center, r - 3.5, 0, TAU, 64, outline, 1.0)
	else:
		if p_direction == Dir.OUT:
			var rect := Rect2(center.x - r, center.y - r, r * 2.0, r * 2.0)
			canvas.draw_rect(rect, fill)
			canvas.draw_rect(rect, outline, false, 1.0)
		else:
			var pts := PackedVector2Array(
				[
					center + Vector2(0, -r),
					center + Vector2(r, 0),
					center + Vector2(0, r),
					center + Vector2(-r, 0),
				]
			)
			canvas.draw_colored_polygon(pts, fill)
			canvas.draw_polyline(pts + PackedVector2Array([pts[0]]), outline, 1.0)


static func _fill_color(p_kind: Kind, p_direction: Dir) -> Color:
	if p_kind == Kind.FILE:
		return (
			Color(0.0, 0.75, 0.95, 0.9) if p_direction == Dir.OUT else Color(0.0, 0.4, 0.55, 0.45)
		)
	return Color(1.0, 0.7, 0.1, 0.95) if p_direction == Dir.OUT else Color(0.6, 0.35, 0.05, 0.5)


static func _outline_color(p_kind: Kind) -> Color:
	if p_kind == Kind.FILE:
		return MinimalUI.neon_cyan
	return MinimalUI.neon_gold


static func _glow_color(p_kind: Kind) -> Color:
	if p_kind == Kind.FILE:
		return MinimalUI.neon_cyan
	return MinimalUI.neon_magenta


func _tooltip_text() -> String:
	var type_name := "Файлы" if _kind == Kind.FILE else "Деньги"
	var dir_name := "выход" if _direction == Dir.OUT else "вход"
	return "%s · %s (%s)" % [_block_type, type_name, dir_name]


func set_highlight(active: bool, valid_target: bool = false) -> void:
	if active:
		modulate = Color(1.4, 1.2, 1.8) if valid_target else Color(1.6, 0.9, 1.4)
	elif valid_target:
		modulate = Color(0.7, 1.3, 1.5)
	else:
		modulate = Color.WHITE
	queue_redraw()
