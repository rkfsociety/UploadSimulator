extends Control
class_name PlacedBlock
## Модуль: горизонтальная панель (текст) + полоса улучшения справа.

signal upgrade_requested(block: PlacedBlock)
signal action_requested(block: PlacedBlock)

const BLOCK_GAP := 2.0
const MAIN_CELLS_W := GridDefs.BLOCK_CELLS_W - 1
const UPGRADE_CELLS_W := 1

var instance_uid: String = ""
var block_type: String = ""

var _main_panel: NeonFrame
var _upgrade_panel: NeonFrame
var _title_label: Label
var _metric_label: Label
var _state_label: Label
var _progress_bar: ProgressBar
var _action_btn: Button
var _upgrade_btn: Button
var _left_ports: HBoxContainer
var _right_ports: HBoxContainer


static func pixel_size() -> Vector2:
	return GridDefs.block_pixel_size()


static func _main_panel_size() -> Vector2:
	return Vector2(
		float(MAIN_CELLS_W * GridDefs.CELL_SIZE), float(GridDefs.BLOCK_CELLS_H * GridDefs.CELL_SIZE)
	)


static func _upgrade_panel_size() -> Vector2:
	return Vector2(
		float(UPGRADE_CELLS_W * GridDefs.CELL_SIZE),
		float(GridDefs.BLOCK_CELLS_H * GridDefs.CELL_SIZE)
	)


func setup(uid: String, type_id: String) -> void:
	instance_uid = uid
	block_type = type_id
	if _title_label == null:
		_build_ui()
	_build_ports()
	refresh()


func _build_ui() -> void:
	var sz := pixel_size()
	custom_minimum_size = sz
	size = sz
	clip_contents = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var root_h := HBoxContainer.new()
	root_h.add_theme_constant_override("separation", BLOCK_GAP)
	root_h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(root_h)
	_main_panel = NeonFrame.new()
	_main_panel.custom_minimum_size = _main_panel_size()
	_main_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_panel.set_accent(BlockDefs.get_block_color(block_type))
	root_h.add_child(_main_panel)
	var main_margin := MarginContainer.new()
	main_margin.add_theme_constant_override("margin_left", 10)
	main_margin.add_theme_constant_override("margin_top", 8)
	main_margin.add_theme_constant_override("margin_right", 10)
	main_margin.add_theme_constant_override("margin_bottom", 8)
	_main_panel.add_child(main_margin)
	var main_v := VBoxContainer.new()
	main_v.add_theme_constant_override("separation", 1)
	main_margin.add_child(main_v)
	_title_label = Label.new()
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 14)
	_title_label.clip_text = false
	main_v.add_child(_title_label)
	_metric_label = Label.new()
	_metric_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_metric_label.add_theme_font_size_override("font_size", 12)
	_metric_label.add_theme_color_override("font_color", MinimalUI.TEXT)
	_metric_label.clip_text = false
	main_v.add_child(_metric_label)
	_state_label = Label.new()
	_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_state_label.add_theme_font_size_override("font_size", 11)
	_state_label.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	_state_label.clip_text = false
	main_v.add_child(_state_label)
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(0, 6)
	_progress_bar.max_value = 100.0
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	main_v.add_child(_progress_bar)
	_action_btn = Button.new()
	_action_btn.custom_minimum_size = Vector2(0, 28)
	_action_btn.add_theme_font_size_override("font_size", 11)
	_action_btn.visible = false
	_action_btn.pressed.connect(func(): action_requested.emit(self))
	main_v.add_child(_action_btn)
	var ports_row := HBoxContainer.new()
	ports_row.alignment = BoxContainer.ALIGNMENT_CENTER
	ports_row.add_theme_constant_override("separation", 4)
	main_v.add_child(ports_row)
	_left_ports = HBoxContainer.new()
	_left_ports.add_theme_constant_override("separation", 2)
	ports_row.add_child(_left_ports)
	var port_spacer := Control.new()
	port_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ports_row.add_child(port_spacer)
	_right_ports = HBoxContainer.new()
	_right_ports.add_theme_constant_override("separation", 2)
	ports_row.add_child(_right_ports)
	_upgrade_panel = NeonFrame.new()
	_upgrade_panel.custom_minimum_size = _upgrade_panel_size()
	_upgrade_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	_upgrade_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_upgrade_panel.set_accent(BlockDefs.get_block_color(block_type))
	root_h.add_child(_upgrade_panel)
	_upgrade_btn = Button.new()
	_upgrade_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_upgrade_btn.flat = true
	_upgrade_btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_upgrade_btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_upgrade_btn.pressed.connect(func(): upgrade_requested.emit(self))
	_upgrade_panel.add_child(_upgrade_btn)


func _build_ports() -> void:
	for child in _left_ports.get_children():
		child.queue_free()
	for child in _right_ports.get_children():
		child.queue_free()
	var defs: Dictionary = BlockDefs.PORT_DEFS.get(block_type, {})
	for port_id in defs.keys():
		var def: Dictionary = defs[port_id]
		var port := _make_port(port_id, def)
		if def.get("dir", "") == "in":
			_left_ports.add_child(port)
		else:
			_right_ports.add_child(port)
	if _left_ports.get_child_count() == 0:
		_left_ports.visible = false
	if _right_ports.get_child_count() == 0:
		_right_ports.visible = false


func _make_port(port_id: String, def: Dictionary) -> ConnectionPort:
	var port := ConnectionPort.new()
	port.custom_minimum_size = Vector2(12, 12)
	port.instance_uid = instance_uid
	port.block_type = block_type
	port.port_id = port_id
	port.kind = (
		ConnectionPort.Kind.MONEY if def.get("kind", "") == "money" else ConnectionPort.Kind.FILE
	)
	port.direction = ConnectionPort.Dir.IN if def.get("dir", "") == "in" else ConnectionPort.Dir.OUT
	return port


func refresh() -> void:
	if _title_label == null:
		return
	var sz := pixel_size()
	custom_minimum_size = sz
	size = sz
	var accent := BlockDefs.get_block_color(block_type)
	_main_panel.set_accent(accent)
	_upgrade_panel.set_accent(accent)
	var def: Dictionary = BlockDefs.TYPES.get(block_type, {})
	_title_label.text = str(def.get("name", block_type))
	_title_label.add_theme_color_override("font_color", accent)
	_metric_label.text = GameState.get_block_metric(instance_uid)
	_metric_label.add_theme_color_override("font_color", accent.lightened(0.12))
	var disp: Dictionary = GameState.get_block_display(instance_uid)
	_state_label.text = disp.get("status", "")
	var show_action: bool = disp.get("action_visible", false)
	_action_btn.visible = show_action
	if show_action:
		_action_btn.text = disp.get("action_text", "—")
		_action_btn.disabled = not disp.get("action_enabled", false)
		MinimalUI.apply_action_button(_action_btn)
		_action_btn.add_theme_font_size_override("font_size", 11)
	var prog: float = float(disp.get("progress", -1.0))
	if prog >= 0.0:
		_progress_bar.visible = true
		_progress_bar.value = prog * 100.0
		MinimalUI.apply_progress_bar(_progress_bar, accent)
	else:
		_progress_bar.visible = false
	var lvl: int = GameState.get_instance_level(instance_uid)
	var cost: int = GameState.get_instance_upgrade_cost(instance_uid)
	_upgrade_btn.text = "↑ Ур.%d · $%d" % [lvl + 1, cost]
	_upgrade_btn.disabled = not GameState.can_upgrade_instance(instance_uid)
	MinimalUI.apply_block_upgrade_button(_upgrade_btn, accent)
