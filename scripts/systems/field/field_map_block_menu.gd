extends Control
class_name FieldMapBlockMenu
## Мини-меню выбранного модуля на карте.

signal remove_requested(uid: String)
signal closed

const DANGER_COLOR := Color(1.0, 0.35, 0.4, 1.0)

var _uid: String = ""
var _field_map: Control
var _camera: FieldMapCamera
var _panel: PanelContainer
var _title: Label
var _hint: Label
var _remove_btn: Button


func _init(field_map: Control, camera: FieldMapCamera) -> void:
	_field_map = field_map
	_camera = camera
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()
	hide()


func is_open() -> bool:
	return visible and _uid != ""


func get_panel_global_rect() -> Rect2:
	if _panel == null or not visible:
		return Rect2()
	return Rect2(_panel.global_position, _panel.size)


func show_for(uid: String) -> void:
	if uid == "":
		hide_menu()
		return
	_uid = uid
	var inst := GameState.field.get_instance(uid)
	if not inst.is_valid():
		hide_menu()
		return
	var def: Dictionary = BlockDefs.TYPES.get(inst.type_id, {})
	_title.text = str(def.get("name", inst.type_id))
	_hint.text = "Перетащите модуль для перемещения"
	_remove_btn.disabled = not GameState.field.can_remove_block(uid)
	_update_position()
	show()
	move_to_front()


func hide_menu() -> void:
	if _uid != "":
		_uid = ""
		hide()
		closed.emit()


func refresh_position() -> void:
	if is_open():
		_update_position()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.add_theme_stylebox_override(
		"panel", MinimalUI.neon_box(MinimalUI.bg_panel, MinimalUI.neon_cyan, true, 10, 8)
	)
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_title = Label.new()
	_title.add_theme_color_override("font_color", MinimalUI.text)
	_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_title)

	_hint = Label.new()
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 180.0
	_hint.add_theme_color_override("font_color", MinimalUI.text_dim)
	_hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(_hint)

	_remove_btn = Button.new()
	_remove_btn.text = "Снять с поля"
	MinimalUI.apply_action_button(_remove_btn)
	PlatformInfo.ensure_touch_minimum(_remove_btn, PlatformInfo.touch_target_px(), 40)
	_remove_btn.add_theme_color_override("font_color", DANGER_COLOR)
	_remove_btn.pressed.connect(_on_remove_pressed)
	vbox.add_child(_remove_btn)


func _on_remove_pressed() -> void:
	if _uid == "":
		return
	remove_requested.emit(_uid)


func _update_position() -> void:
	var inst := GameState.field.get_instance(_uid)
	if not inst.is_valid():
		return
	var origin := GridDefs.cell_to_pixel(inst.gx, inst.gy)
	var sz := GridDefs.block_pixel_size(inst.type_id)
	var anchor := origin + Vector2(sz.x * 0.5, 0.0)
	var map_local := _camera.world_to_screen(anchor)
	var global_anchor := _field_map.get_global_transform() * map_local
	var parent := get_parent() as Control
	if parent == null:
		return
	var local_anchor := parent.get_global_transform().affine_inverse() * global_anchor
	var panel_size := _panel.get_combined_minimum_size()
	position = local_anchor - Vector2(panel_size.x * 0.5, panel_size.y + 10.0)
	position.x = clampf(position.x, 8.0, parent.size.x - panel_size.x - 8.0)
	position.y = clampf(position.y, 8.0, parent.size.y - panel_size.y - 8.0)
