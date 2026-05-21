extends PanelContainer
class_name NeonFrame
## Векторная неоновая рамка: отрисовка под дочерними элементами.

var accent: Color = Color(0.0, 0.88, 1.0, 1.0)

var _border_draw: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	bg.set_border_width_all(0)
	bg.set_content_margin_all(4)
	add_theme_stylebox_override("panel", bg)
	_setup_border_layer()


func set_accent(color: Color) -> void:
	accent = color
	if _border_draw != null:
		_border_draw.queue_redraw()


func _setup_border_layer() -> void:
	if _border_draw != null:
		return
	_border_draw = Control.new()
	_border_draw.name = "BorderDraw"
	_border_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_border_draw.z_index = -1
	_border_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_border_draw)
	move_child(_border_draw, 0)
	_border_draw.draw.connect(_draw_border)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED or what == NOTIFICATION_RESIZED:
		if _border_draw != null:
			_border_draw.queue_redraw()


func _viewport_scale() -> float:
	var gs := get_global_transform().get_scale()
	return maxf(0.001, (absf(gs.x) + absf(gs.y)) * 0.5)


func _screen_pixel_thickness() -> float:
	return 1.0 / _viewport_scale()


func _draw_border() -> void:
	if _border_draw == null:
		return
	var rect := Rect2(Vector2.ZERO, _border_draw.size)
	if rect.size.x < 2.0 or rect.size.y < 2.0:
		return
	var px := _screen_pixel_thickness()
	var glow := Color(accent.r, accent.g, accent.b, 0.28)
	var glow2 := Color(accent.r, accent.g, accent.b, 0.14)
	_border_draw.draw_rect(
		rect.grow_individual(px * 2.0, px * 2.0, px * 2.0, px * 2.0),
		glow2
	)
	_border_draw.draw_rect(rect.grow_individual(px, px, px, px), glow)
	_draw_border_rect_on(_border_draw, rect, accent, px)


func _draw_border_rect_on(canvas: Control, rect: Rect2, color: Color, thickness: float) -> void:
	var t := thickness
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	canvas.draw_rect(Rect2(x, y, w, t), color)
	canvas.draw_rect(Rect2(x, y + h - t, w, t), color)
	canvas.draw_rect(Rect2(x, y + t, t, h - t * 2.0), color)
	canvas.draw_rect(Rect2(x + w - t, y + t, t, h - t * 2.0), color)
