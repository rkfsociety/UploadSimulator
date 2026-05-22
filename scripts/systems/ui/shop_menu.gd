extends Control
## Магазин: сетка иконок, детали и покупка по нажатию на иконку.

signal closed

const PANEL_H_COMPACT := -200.0
const PANEL_H_DETAIL := -340.0

@onready var icon_row: HBoxContainer = %ShopIconRow
@onready var detail_panel: VBoxContainer = %ShopDetailPanel
@onready var detail_name: Label = %ShopDetailName
@onready var detail_desc: Label = %ShopDetailDesc
@onready var detail_stock: Label = %ShopDetailStock
@onready var buy_btn: Button = %ShopBuyButton
@onready var place_btn: Button = %ShopPlaceButton
@onready var dim: ColorRect = $Dim
@onready var panel: PanelContainer = $Panel
@onready var shop_title: Label = $Panel/PanelMargin/PanelVBox/ShopHeader/ShopTitle
@onready var close_btn: Button = $Panel/PanelMargin/PanelVBox/ShopHeader/CloseButton

var _selected_type: String = ""
var _icon_buttons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_style_panel()
	_style_detail()
	GameState.stats_changed.connect(_refresh)
	buy_btn.pressed.connect(_on_buy_pressed)
	place_btn.pressed.connect(_on_place_pressed)
	hide()
	_build_icon_grid()


func _style_panel() -> void:
	MinimalUI.attach_theme(self)
	panel.add_theme_stylebox_override("panel", MinimalUI.shop_panel_style())
	shop_title.add_theme_color_override("font_color", MinimalUI.NEON_MAGENTA)
	shop_title.add_theme_font_size_override("font_size", 18)
	MinimalUI.apply_action_button(close_btn)
	close_btn.text = "×"
	close_btn.custom_minimum_size = Vector2(56, 36)
	dim.color = Color(0.01, 0.0, 0.05, 0.82)


func _style_detail() -> void:
	detail_name.add_theme_color_override("font_color", MinimalUI.NEON_CYAN)
	detail_desc.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	detail_stock.add_theme_color_override("font_color", MinimalUI.NEON_PURPLE)
	MinimalUI.apply_action_button(buy_btn)
	MinimalUI.apply_action_button(place_btn)


func open() -> void:
	_selected_type = ""
	_hide_detail()
	show()
	move_to_front()
	_refresh()


func close() -> void:
	hide()
	closed.emit()


func _on_dim_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close()


func _build_icon_grid() -> void:
	for child in icon_row.get_children():
		child.queue_free()
	_icon_buttons.clear()
	for type_id in GameState.field.get_shop_block_types():
		var btn := _make_icon_button(type_id)
		icon_row.add_child(btn)
		_icon_buttons[type_id] = btn
	_update_icon_selection()


func _make_icon_button(type_id: String) -> Button:
	var def: Dictionary = BlockDefs.TYPES[type_id]
	var btn := Button.new()
	btn.toggle_mode = true
	btn.text = str(def.get("icon", "?"))
	btn.tooltip_text = def.get("name", type_id)
	MinimalUI.apply_shop_icon_button(btn)
	btn.pressed.connect(_on_icon_pressed.bind(type_id))
	return btn


func _on_icon_pressed(type_id: String) -> void:
	_selected_type = type_id
	_update_icon_selection()
	_show_detail(type_id)


func _update_icon_selection() -> void:
	for type_id in _icon_buttons.keys():
		var btn: Button = _icon_buttons[type_id]
		var accent := BlockDefs.get_block_color(type_id)
		var selected: bool = type_id == _selected_type
		btn.button_pressed = selected
		btn.add_theme_stylebox_override("normal", MinimalUI.shop_icon_tile_style(accent, selected))
		btn.add_theme_stylebox_override("hover", MinimalUI.shop_icon_tile_style(accent, true))
		btn.add_theme_stylebox_override("pressed", MinimalUI.shop_icon_tile_style(accent, true))
		if selected:
			btn.add_theme_color_override("font_color", accent)
		else:
			btn.add_theme_color_override("font_color", MinimalUI.NEON_CYAN)


func _show_detail(type_id: String) -> void:
	var def: Dictionary = BlockDefs.TYPES.get(type_id, {})
	if def.is_empty():
		_hide_detail()
		return
	detail_panel.visible = true
	panel.offset_top = PANEL_H_DETAIL
	detail_name.text = def.get("name", type_id)
	detail_name.add_theme_color_override("font_color", BlockDefs.get_block_color(type_id))
	var desc_text: String = str(def.get("desc", ""))
	if not GameState.environment.is_module_unlocked(type_id):
		desc_text = "Сначала откройте в магазине ◆ (алмазы)."
	detail_desc.text = desc_text
	var stock: int = GameState.field.get_block_stock(type_id)
	detail_stock.text = "Не поставлен: %d" % stock if stock > 0 else "Купите и поставьте на карту"
	buy_btn.text = "Купить · $%d" % int(def.get("shop_cost", 0))
	buy_btn.disabled = not GameState.field.can_buy_block(type_id)
	place_btn.visible = stock > 0
	place_btn.disabled = stock <= 0


func _hide_detail() -> void:
	detail_panel.visible = false
	panel.offset_top = PANEL_H_COMPACT
	for type_id in _icon_buttons.keys():
		var btn: Button = _icon_buttons[type_id]
		var accent := BlockDefs.get_block_color(type_id)
		btn.button_pressed = false
		btn.add_theme_stylebox_override("normal", MinimalUI.shop_icon_tile_style(accent, false))
		btn.add_theme_stylebox_override("hover", MinimalUI.shop_icon_tile_style(accent, true))
		btn.add_theme_stylebox_override("pressed", MinimalUI.shop_icon_tile_style(accent, true))
		btn.add_theme_color_override("font_color", MinimalUI.NEON_CYAN)


func _on_buy_pressed() -> void:
	if _selected_type == "":
		return
	if GameState.field.buy_block(_selected_type):
		close()


func _on_place_pressed() -> void:
	if _selected_type == "":
		return
	GameState.placement_requested.emit(_selected_type)
	close()


func _refresh() -> void:
	if not visible:
		return
	_build_icon_grid()
	if _selected_type != "":
		_show_detail(_selected_type)
	else:
		_hide_detail()


func _on_close_pressed() -> void:
	close()
