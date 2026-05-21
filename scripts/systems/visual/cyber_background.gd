extends ColorRect
## Неоновый фон: градиентные блики и лёгкие сканлайны.


func _ready() -> void:
	color = MinimalUI.BG_DARK
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _draw() -> void:
	var sz := size
	if sz.x < 1.0 or sz.y < 1.0:
		return
	# Верхний магентовый ореол
	draw_rect(Rect2(0, 0, sz.x, sz.y * 0.38), Color(0.7, 0.0, 0.9, 0.14))
	# Нижний циановый ореол
	draw_rect(Rect2(0, sz.y * 0.62, sz.x, sz.y * 0.38), Color(0.0, 0.85, 1.0, 0.1))
	# Центральная виньетка
	draw_rect(Rect2(sz.x * 0.1, sz.y * 0.2, sz.x * 0.8, sz.y * 0.55), Color(0.15, 0.05, 0.25, 0.06))
	# Сканлайны
	var y := 0
	while y < int(sz.y):
		draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0, 1, 1, 0.025), 1.0)
		y += 3
