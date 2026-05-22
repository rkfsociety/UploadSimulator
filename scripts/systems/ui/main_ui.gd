extends Control
## Минимальный HUD: баланс сверху справа, магазин снизу по центру.

@onready var money_label: Label = %MoneyLabel
@onready var shop_icon_btn: Button = %ShopIconButton
@onready var map_center_btn: Button = %MapCenterButton
@onready var shop_menu: Control = %ShopMenu
@onready var field_map: Control = %FieldMap


func _ready() -> void:
	_apply_cyber_theme()
	# Дублируем связь на случай устаревшего пути в .tscn
	if not shop_icon_btn.pressed.is_connected(_on_shop_pressed):
		shop_icon_btn.pressed.connect(_on_shop_pressed)
	shop_menu.closed.connect(_refresh)
	GameState.stats_changed.connect(_refresh)
	GameState.placement_requested.connect(_on_placement_requested)
	GameState.block_purchased.connect(_on_block_purchased)
	field_map.placement_mode_changed.connect(_on_placement_mode_changed)
	_refresh()


func _apply_cyber_theme() -> void:
	MinimalUI.attach_theme(self)
	MinimalUI.apply_balance_label(money_label)
	MinimalUI.apply_shop_hud_button(shop_icon_btn)
	shop_icon_btn.tooltip_text = "Магазин"
	MinimalUI.apply_map_center_hud_button(map_center_btn)
	map_center_btn.tooltip_text = "В центр карты"


func _refresh() -> void:
	money_label.text = "$%.0f" % GameState.access.get_money()
	shop_icon_btn.disabled = shop_menu.visible
	# Затемнение иконки, когда магазин уже открыт
	var icon_tex: TextureRect = shop_icon_btn.get_node_or_null("ShopHudIcon") as TextureRect
	if icon_tex:
		icon_tex.modulate = Color(0.45, 0.55, 0.75, 0.55) if shop_icon_btn.disabled else Color.WHITE


func _on_block_purchased(type_id: String) -> void:
	shop_menu.close()
	if field_map.has_method("place_at_view_center"):
		field_map.place_at_view_center(type_id)


func _on_placement_requested(type_id: String) -> void:
	shop_menu.close()
	if field_map.has_method("enter_placement_mode"):
		field_map.enter_placement_mode(type_id)


func _on_placement_mode_changed(type_id: String) -> void:
	if type_id == "":
		shop_icon_btn.tooltip_text = "Магазин"
	else:
		var name: String = BlockDefs.TYPES.get(type_id, {}).get("name", type_id)
		shop_icon_btn.tooltip_text = "Тап по карте: %s" % name


func _on_shop_pressed() -> void:
	if field_map.has_method("cancel_placement_mode"):
		field_map.cancel_placement_mode()
	shop_menu.open()
	_refresh()


func _on_map_center_pressed() -> void:
	if field_map.has_method("focus_map_center"):
		field_map.focus_map_center()
