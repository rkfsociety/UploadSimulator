extends Control
## HUD: касса $, алмазы ◆, магазин модулей и улучшений среды.

@onready var money_label: Label = %MoneyLabel
@onready var diamonds_label: Label = %DiamondsLabel
@onready var shop_icon_btn: Button = %ShopIconButton
@onready var shop_icon_tex: TextureRect = %ShopIconTex
@onready var upgrade_shop_btn: Button = %UpgradeShopButton
@onready var map_center_btn: Button = %MapCenterButton
@onready var map_center_tex: TextureRect = %MapCenterIconTex
@onready var shop_menu: Control = %ShopMenu
@onready var upgrade_shop_menu: Control = %UpgradeShopMenu
@onready var field_map: Control = %FieldMap


func _ready() -> void:
	_apply_cyber_theme()
	# Дублируем связи на случай сбоя connection в .tscn
	if not shop_icon_btn.pressed.is_connected(_on_shop_pressed):
		shop_icon_btn.pressed.connect(_on_shop_pressed)
	if not upgrade_shop_btn.pressed.is_connected(_on_upgrade_shop_pressed):
		upgrade_shop_btn.pressed.connect(_on_upgrade_shop_pressed)
	if not map_center_btn.pressed.is_connected(_on_map_center_pressed):
		map_center_btn.pressed.connect(_on_map_center_pressed)
	shop_menu.closed.connect(_refresh)
	upgrade_shop_menu.closed.connect(_refresh)
	GameState.stats_changed.connect(_refresh)
	GameState.placement_requested.connect(_on_placement_requested)
	GameState.block_purchased.connect(_on_block_purchased)
	field_map.placement_mode_changed.connect(_on_placement_mode_changed)
	_refresh()


func _apply_cyber_theme() -> void:
	MinimalUI.attach_theme(self)
	MinimalUI.apply_balance_label(money_label)
	diamonds_label.add_theme_color_override("font_color", MinimalUI.NEON_PURPLE)
	diamonds_label.add_theme_font_size_override("font_size", 22)
	MinimalUI.apply_shop_hud_button(shop_icon_btn, shop_icon_tex)
	shop_icon_btn.tooltip_text = "Магазин модулей ($)"
	MinimalUI.apply_shop_hud_button(upgrade_shop_btn, null)
	upgrade_shop_btn.tooltip_text = "Улучшения среды (◆)"
	MinimalUI.apply_map_center_hud_button(map_center_btn, map_center_tex)
	map_center_btn.tooltip_text = "В центр карты"


func _refresh() -> void:
	money_label.text = "$%.0f" % GameState.access.get_money()
	diamonds_label.text = "◆ %d" % GameState.access.get_diamonds()
	var shop_open := shop_menu.visible
	var upgrade_open := upgrade_shop_menu.visible
	# Не блокируем кнопки disabled — иначе после сбоя видимости магазин «не открывается»
	var dim_shop := Color(0.45, 0.55, 0.75, 0.55) if shop_open else Color.WHITE
	var dim_upg := Color(0.45, 0.55, 0.75, 0.55) if upgrade_open else Color.WHITE
	shop_icon_tex.modulate = dim_shop
	upgrade_shop_btn.modulate = dim_upg


func _on_block_purchased(type_id: String) -> void:
	shop_menu.close()
	upgrade_shop_menu.close()
	if field_map.has_method("place_at_view_center"):
		field_map.place_at_view_center(type_id)


func _on_placement_requested(type_id: String) -> void:
	shop_menu.close()
	upgrade_shop_menu.close()
	if field_map.has_method("enter_placement_mode"):
		field_map.enter_placement_mode(type_id)


func _on_placement_mode_changed(type_id: String) -> void:
	if type_id == "":
		shop_icon_btn.tooltip_text = "Магазин модулей ($)"
	else:
		var name: String = BlockDefs.TYPES.get(type_id, {}).get("name", type_id)
		shop_icon_btn.tooltip_text = "Тап по карте: %s" % name


func _on_shop_pressed() -> void:
	if field_map.has_method("cancel_placement_mode"):
		field_map.cancel_placement_mode()
	upgrade_shop_menu.close()
	shop_menu.open()
	_refresh()


func _on_upgrade_shop_pressed() -> void:
	if field_map.has_method("cancel_placement_mode"):
		field_map.cancel_placement_mode()
	shop_menu.close()
	upgrade_shop_menu.open()
	_refresh()


func _on_map_center_pressed() -> void:
	if field_map.has_method("focus_map_center"):
		field_map.focus_map_center()
