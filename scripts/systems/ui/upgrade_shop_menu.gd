extends Control
## Магазин ◆: открытие новых типов модулей и улучшения среды.

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
	_panel.offset_top = -420.0
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
	_title.text = "Магазин среды"
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_color_override("font_color", MinimalUI.NEON_MAGENTA)
	_title.add_theme_font_size_override("font_size", 18)
	header.add_child(_title)

	var close_btn := Button.new()
	close_btn.text = "×"
	MinimalUI.apply_action_button(close_btn)
	PlatformInfo.ensure_touch_minimum(close_btn, 56, PlatformInfo.touch_target_px())
	close_btn.pressed.connect(close)
	header.add_child(close_btn)

	var hint := Label.new()
	hint.text = (
		'◆ алмазы: сначала откройте новый тип модуля здесь, затем купите его за $ в магазине корзины. '
		+ 'Ниже — улучшения каналов и диска.'
	)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 11)
	vbox.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 300)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)


func _on_dim_input(event: InputEvent) -> void:
	if PlatformInfo.is_primary_pointer_press(event):
		close()


func _on_stats_changed() -> void:
	if visible:
		_refresh()


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	_append_module_unlock_section()
	_append_env_upgrade_section()


func _append_module_unlock_section() -> void:
	_list.add_child(_make_section_title("Новые модули"))
	var lockable := GameState.environment.get_lockable_module_type_ids()
	if lockable.is_empty():
		var empty := Label.new()
		empty.text = "Пока все модули открыты. Новые типы добавятся сюда в обновлениях."
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
		empty.add_theme_font_size_override("font_size", 11)
		_list.add_child(empty)
		return
	for type_id in lockable:
		_list.add_child(_make_module_unlock_row(type_id))


func _append_env_upgrade_section() -> void:
	_list.add_child(_make_section_title("Улучшения среды"))
	for upgrade_id in EnvironmentUpgradeDefs.get_upgrade_ids():
		_list.add_child(_make_env_upgrade_row(upgrade_id))


func _make_section_title(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", MinimalUI.NEON_GOLD)
	lbl.add_theme_font_size_override("font_size", 13)
	return lbl


func _make_module_unlock_row(type_id: String) -> Control:
	var def: Dictionary = BlockDefs.TYPES[type_id]
	var cost: int = GameState.environment.module_unlock_diamond_cost(type_id)
	return _make_row(
		str(def.get("icon", "?")),
		def.get("name", type_id),
		'Откроет покупку в магазине $ - %s' % def.get("desc", ""),
		"Открыть",
		cost,
		GameState.environment.can_unlock_module(type_id),
		_on_unlock_module.bind(type_id),
		BlockDefs.get_block_color(type_id),
	)


func _make_env_upgrade_row(upgrade_id: String) -> Control:
	var def: Dictionary = EnvironmentUpgradeDefs.UPGRADES[upgrade_id]
	var lvl: int = GameState.environment.get_upgrade_level(upgrade_id)
	var maxed := EnvironmentUpgradeDefs.is_max_level(upgrade_id, lvl)
	var cost: int = GameState.environment.diamond_cost(upgrade_id)
	var btn_text := "Макс." if maxed else "◆ %d" % cost
	return _make_row(
		str(def.get("icon", "◆")),
		"%s · ур. %d" % [def.get("name", upgrade_id), lvl],
		str(def.get("desc", "")),
		btn_text,
		cost,
		not maxed and GameState.environment.can_buy_upgrade(upgrade_id),
		_on_buy_upgrade.bind(upgrade_id),
		MinimalUI.NEON_PURPLE,
	)


func _make_row(
	icon_text: String,
	title_text: String,
	desc_text: String,
	btn_label: String,
	_cost: int,
	can_buy: bool,
	on_pressed: Callable,
	accent: Color,
) -> Control:
	var row := PanelContainer.new()
	row.add_theme_stylebox_override(
		"panel", MinimalUI.neon_box(MinimalUI.BG_PANEL, accent, false, 8, 6)
	)

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
	icon.text = icon_text
	icon.add_theme_font_size_override("font_size", 22)
	h.add_child(icon)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = title_text
	name_lbl.add_theme_color_override("font_color", accent)
	info.add_child(name_lbl)

	var desc := Label.new()
	desc.text = desc_text
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	desc.add_theme_font_size_override("font_size", 11)
	info.add_child(desc)

	var buy := Button.new()
	MinimalUI.apply_action_button(buy)
	PlatformInfo.ensure_touch_minimum(buy, 120, PlatformInfo.touch_target_px())
	buy.text = btn_label
	buy.disabled = not can_buy
	buy.pressed.connect(on_pressed)
	h.add_child(buy)

	return row


func _on_unlock_module(type_id: String) -> void:
	if GameState.report_operation(GameState.environment.unlock_module(type_id)):
		_refresh()


func _on_buy_upgrade(upgrade_id: String) -> void:
	if GameState.report_operation(GameState.environment.buy_upgrade(upgrade_id)):
		_refresh()
