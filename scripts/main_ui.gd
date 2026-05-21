extends Control
## Минимальный HUD: баланс сверху справа, магазин снизу по центру.

@onready var money_label: Label = %MoneyLabel
@onready var shop_icon_btn: Button = %ShopIconButton
@onready var shop_menu: Control = %ShopMenu
@onready var field_map: Control = %FieldMap


func _ready() -> void:
	_apply_cyber_theme()
	shop_menu.closed.connect(_refresh)
	GameState.stats_changed.connect(_refresh)
	GameState.placement_requested.connect(_on_placement_requested)
	field_map.placement_mode_changed.connect(_on_placement_mode_changed)
	_refresh()


func _apply_cyber_theme() -> void:
	MinimalUI.apply_balance_label(money_label)
	MinimalUI.apply_icon_button(shop_icon_btn)
	shop_icon_btn.tooltip_text = "Магазин"


func _refresh() -> void:
	money_label.text = "$%.0f" % GameState.money
	shop_icon_btn.disabled = shop_menu.visible


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
