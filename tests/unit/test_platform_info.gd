extends RefCounted
## Unit-тесты определения платформы и распознавания нажатий (без autoload).

const _PlatformInfo := preload("res://scripts/autoload/platform_info.gd")

var case_count := 4


func _make_platform() -> Node:
	var node: Node = _PlatformInfo.new()
	node._refresh()
	return node


func run() -> Array[String]:
	var errors: Array[String] = []
	var pi := _make_platform()
	if pi.touch_target_px() < pi.MIN_TOUCH_TARGET_PX:
		errors.append("touch_target_px не может быть меньше MIN_TOUCH_TARGET_PX")
	if pi.port_hit_size() < pi.PORT_VISUAL_PX:
		errors.append("port_hit_size не может быть меньше визуала порта")
	var mouse := InputEventMouseButton.new()
	mouse.pressed = true
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not pi.is_primary_pointer_press(mouse):
		errors.append("ЛКМ должна считаться основным нажатием")
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	if not pi.is_primary_pointer_press(touch):
		errors.append("ScreenTouch должен считаться основным нажатием")
	var release := InputEventScreenTouch.new()
	release.pressed = false
	if pi.is_primary_pointer_press(release):
		errors.append("отпускание пальца не должно считаться нажатием")
	return errors
