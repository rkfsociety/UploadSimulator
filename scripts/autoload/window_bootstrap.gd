extends Node
## Фиксированный размер окна на ПК; на мобильных — полноэкран и учёт DPI.

const DESIGN_SIZE := Vector2i(720, 1280)


func _ready() -> void:
	# Откладываем, чтобы корневое Window уже было создано движком
	call_deferred("_apply_window")


func _apply_window() -> void:
	if PlatformInfo.is_mobile_os():
		_apply_mobile_window()
	else:
		_apply_desktop_window()


func _apply_desktop_window() -> void:
	var win := get_tree().root as Window
	if win == null:
		return
	var screen_idx := DisplayServer.window_get_current_screen()
	var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen_idx)
	var max_w: int = usable.size.x
	var max_h: int = usable.size.y
	var target_w: int = DESIGN_SIZE.x
	var target_h: int = DESIGN_SIZE.y
	# Пропорционально уменьшаем, если 720×1280 не влезает (панель задач, малый монитор)
	if target_w > max_w or target_h > max_h:
		var scale: float = minf(
			float(max_w) / float(DESIGN_SIZE.x),
			float(max_h) / float(DESIGN_SIZE.y)
		)
		target_w = maxi(1, int(floor(DESIGN_SIZE.x * scale)))
		target_h = maxi(1, int(floor(DESIGN_SIZE.y * scale)))
	var final_size := Vector2i(target_w, target_h)
	win.size = final_size
	win.min_size = final_size
	win.max_size = final_size
	win.unresizable = true
	# HiDPI на ПК: чёткий UI без смены логического 720×1280
	var dpi_scale := PlatformInfo.get_display_scale()
	if dpi_scale > 1.01:
		win.content_scale_factor = dpi_scale
	# Центр в usable-области, чтобы не уезжало за край
	var pos_x: int = usable.position.x + (usable.size.x - target_w) / 2
	var pos_y: int = usable.position.y + (usable.size.y - target_h) / 2
	win.position = Vector2i(pos_x, pos_y)


func _apply_mobile_window() -> void:
	var win := get_tree().root as Window
	if win == null:
		return
	# Полноэкран; масштаб сцены — stretch canvas_items в project.godot
	win.mode = Window.MODE_FULLSCREEN
	win.borderless = true
	win.unresizable = true
	# Плотность пикселей: content_scale_factor согласует тач и отрисовку UI
	var dpi_scale := PlatformInfo.get_display_scale()
	if dpi_scale > 1.01:
		win.content_scale_factor = dpi_scale
