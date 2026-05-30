extends Node
## Платформа, плотность экрана и минимальные зоны нажатия для сенсорного ввода.

# Логический viewport проекта (совпадает с project.godot)
const DESIGN_VIEWPORT := Vector2i(720, 1280)
# Рекомендация Material / Apple HIG: ~48 dp
const MIN_TOUCH_TARGET_PX := 48
# Визуальный размер порта на карте (отрисовка)
const PORT_VISUAL_PX := 30

# Зоны HUD в координатах дизайн-viewport (для field_map_input)
const HUD_BOTTOM_STRIP_PX := 96.0
const HUD_RIGHT_COLUMN_W_PX := 88.0
const HUD_RIGHT_COLUMN_TOP_PX := 148.0

var _mobile_os: bool = false
var _touch_primary: bool = false
var _display_scale: float = 1.0


func _ready() -> void:
	_refresh()


## Пересчитывает флаги (можно вызвать после смены экрана).
func refresh() -> void:
	_refresh()


func _refresh() -> void:
	var os_name := OS.get_name()
	_mobile_os = os_name in ["Android", "iOS"]
	_touch_primary = _mobile_os or DisplayServer.is_touchscreen_available()
	_display_scale = _read_display_scale()


func _read_display_scale() -> float:
	var screen_idx := DisplayServer.window_get_current_screen()
	var scale := DisplayServer.screen_get_scale(screen_idx)
	if scale < 1.0:
		scale = 1.0
	return clampf(scale, 1.0, 3.0)


func is_mobile_os() -> bool:
	return _mobile_os


func prefers_touch_input() -> bool:
	return _touch_primary


func get_display_scale() -> float:
	return _display_scale


## Минимальная сторона интерактивного элемента в логических пикселях viewport.
func touch_target_px() -> int:
	var base := MIN_TOUCH_TARGET_PX
	if _mobile_os:
		base = maxi(base, int(ceil(float(MIN_TOUCH_TARGET_PX) * 1.1)))
	var scaled := int(ceil(float(base) / _display_scale))
	return maxi(MIN_TOUCH_TARGET_PX, scaled)


func port_hit_size() -> int:
	if prefers_touch_input():
		return maxi(PORT_VISUAL_PX, touch_target_px())
	# На ПК — компактная зона нажатия, чтобы порты не перекрывали текст модуля
	return PORT_VISUAL_PX + 4


func port_visual_size() -> int:
	return PORT_VISUAL_PX


## Порог сдвига пальца до «перетаскивания» (чуть выше на таче).
func drag_threshold_px() -> float:
	if prefers_touch_input():
		return 8.0
	return 6.0


func hud_bottom_strip_height() -> float:
	if _mobile_os:
		return HUD_BOTTOM_STRIP_PX + 8.0
	return HUD_BOTTOM_STRIP_PX


func hud_right_column_width() -> float:
	if _mobile_os:
		return HUD_RIGHT_COLUMN_W_PX + 8.0
	return HUD_RIGHT_COLUMN_W_PX


func hud_right_column_top_offset() -> float:
	if _mobile_os:
		return HUD_RIGHT_COLUMN_TOP_PX + 12.0
	return HUD_RIGHT_COLUMN_TOP_PX


## Основное нажатие: ЛКМ или палец.
func is_primary_pointer_press(event: InputEvent) -> bool:
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		return mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT
	return false


## Расширяет custom_minimum_size до touch_target (сохраняя больший размер).
func ensure_touch_minimum(control: Control, min_w: int = -1, min_h: int = -1) -> void:
	var touch := touch_target_px()
	var w := touch if min_w < 0 else maxi(min_w, touch)
	var h := touch if min_h < 0 else maxi(min_h, touch)
	var cur := control.custom_minimum_size
	control.custom_minimum_size = Vector2(maxi(int(cur.x), w), maxi(int(cur.y), h))


func apply_action_button_touch(btn: Button) -> void:
	ensure_touch_minimum(btn, -1, touch_target_px())


func apply_mobile_hud(main_ui: Control) -> void:
	if not _mobile_os:
		return
	var shop_hud: Control = main_ui.find_child("ShopHud", true, false) as Control
	if shop_hud:
		ensure_touch_minimum(shop_hud, touch_target_px() + 8, touch_target_px() + 8)
	var center_hud: Control = main_ui.find_child("MapCenterHud", true, false) as Control
	if center_hud:
		ensure_touch_minimum(center_hud, touch_target_px(), touch_target_px())
	var upgrade_hud: Control = main_ui.find_child("UpgradeShopHud", true, false) as Control
	if upgrade_hud:
		ensure_touch_minimum(upgrade_hud, touch_target_px() + 8, touch_target_px() + 8)
