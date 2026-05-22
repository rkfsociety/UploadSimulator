extends Control
## Магазин улучшений среды: покупка за алмазы (◆).

signal closed

var _dim: ColorRect
var _panel: PanelContainer
var _list: VBoxContainer
var _title: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	MinimalUI.attach_theme(self)
	_build_ui()
	hide()
	GameState.stats_changed.connect(_on_stats_changed)


func open() -> void:
	show()
	_refresh()
	move_to_front()


func close() -> void:
	hide()
	closed.emit()


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(0.01, 0.0, 0.06, 0.85)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -380.0
	_panel.add_theme_stylebox_override("panel", MinimalUI.shop_panel_style())
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	_title = Label.new()
	_title.text = "Улучшения среды"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", MinimalUI.NEON_MAGENTA)
	_title.add_theme_font_size_override("font_size", 18)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(56, 36)
	MinimalUI.apply_action_button(close_btn)
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var hint := Label.new()
	hint.text = "Валюта: ◆ алмазы (за выгрузку файлов). Касса $ — только модули на карте."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 260)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _on_stats_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	for upgrade_id in EnvironmentUpgradeDefs.get_upgrade_ids():
		_list.add_child(_make_row(upgrade_id))


func _make_row(upgrade_id: String) -> Control:
	var def: Dictionary = EnvironmentUpgradeDefs.UPGRADES[upgrade_id]
	var lvl: int = GameState.environment.get_upgrade_level(upgrade_id)
	var maxed := EnvironmentUpgradeDefs.is_max_level(upgrade_id, lvl)
	var cost: int = GameState.environment.diamond_cost(upgrade_id)

	var row := PanelContainer.new()
	row.add_theme_stylebox_override("panel", MinimalUI.neon_box(MinimalUI.BG_PANEL, MinimalUI.NEON_PURPLE, false, 8, 6))

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	row.add_child(margin)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	margin.add_child(h)

	var icon := Label.new()
	icon.text = str(def.get("icon", "◆"))
	icon.add_theme_font_size_override("font_size", 22)
	h.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = "%s · ур. %d" % [def.get("name", upgrade_id), lvl]
	name_lbl.add_theme_color_override("font_color", MinimalUI.NEON_CYAN)
	info.add_child(name_lbl)

	var desc := Label.new()
	desc.text = str(def.get("desc", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	desc.add_theme_font_size_override("font_size", 11)
	info.add_child(desc)

	var buy := Button.new()
	buy.custom_minimum_size = Vector2(120, 44)
	MinimalUI.apply_action_button(buy)
	if maxed:
		buy.text = "Макс."
		buy.disabled = true
	else:
		buy.text = "◆ %d" % cost
		buy.disabled = not GameState.environment.can_buy_upgrade(upgrade_id)
		buy.pressed.connect(_on_buy.bind(upgrade_id))
	h.add_child(buy)

	return row


func _on_buy(upgrade_id: String) -> void:
	if GameState.environment.buy_upgrade(upgrade_id):
		_refresh()
