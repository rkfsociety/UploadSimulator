extends Control
class_name FieldMapBlockMenu
## Кнопка продажи выбранного модуля: маленький крестик у правого края экрана.

signal sell_requested(uid: String)
signal closed

const DANGER_COLOR := Color(1.0, 0.35, 0.4, 1.0)
const EDGE_MARGIN := 12.0

var _uid: String = ""
var _field_map: Control
var _camera: FieldMapCamera
var _sell_btn: Button


func _init(field_map: Control, camera: FieldMapCamera) -> void:
	_field_map = field_map
	_camera = camera
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	hide()


func is_open() -> bool:
	return visible and _uid != ""


func get_panel_global_rect() -> Rect2:
	if _sell_btn == null or not visible:
		return Rect2()
	return Rect2(_sell_btn.global_position, _sell_btn.size)


func show_for(uid: String) -> void:
	if uid == "":
		hide_menu()
		return
	var inst := GameState.field.get_instance(uid)
	if not inst.is_valid():
		hide_menu()
		return
	_uid = uid
	_sell_btn.disabled = not GameState.field.can_remove_block(uid)
	var refund := GameState.field.get_block_sell_value(uid)
	_sell_btn.tooltip_text = "Продать за $%d" % refund
	show()
	move_to_front()


func hide_menu() -> void:
	if _uid != "":
		_uid = ""
		hide()
		closed.emit()


func refresh_position() -> void:
	# Кнопка закреплена якорем у правого края — пересчёт не нужен.
	pass


func _build_ui() -> void:
	_sell_btn = Button.new()
	_sell_btn.text = "×"
	_sell_btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var side := float(PlatformInfo.touch_target_px())
	_sell_btn.custom_minimum_size = Vector2(side, side)
	_sell_btn.add_theme_stylebox_override(
		"normal", MinimalUI.neon_box(MinimalUI.bg_panel, DANGER_COLOR, true, 6, 8)
	)
	_sell_btn.add_theme_stylebox_override(
		"hover", MinimalUI.neon_box(MinimalUI.bg_panel, DANGER_COLOR, true, 6, 8)
	)
	_sell_btn.add_theme_stylebox_override(
		"pressed", MinimalUI.neon_box(MinimalUI.bg_panel, DANGER_COLOR, true, 6, 8)
	)
	_sell_btn.add_theme_color_override("font_color", DANGER_COLOR)
	_sell_btn.add_theme_font_size_override("font_size", 24)
	_sell_btn.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	_sell_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_sell_btn.grow_vertical = Control.GROW_DIRECTION_BOTH
	_sell_btn.position = Vector2(-side - EDGE_MARGIN, -side * 0.5)
	_sell_btn.pressed.connect(_on_sell_pressed)
	add_child(_sell_btn)


func _on_sell_pressed() -> void:
	if _uid == "":
		return
	sell_requested.emit(_uid)
