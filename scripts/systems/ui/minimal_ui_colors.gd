extends Resource
class_name MinimalUIColors
## Палитра киберпанк-интерфейса; правки в res://resources/minimal_ui_colors.tres.

@export_group("Фон")
@export var bg_dark: Color = Color(0.04, 0.02, 0.09, 1)
@export var bg_panel: Color = Color(0.07, 0.04, 0.14, 0.92)

@export_group("Неон")
@export var neon_cyan: Color = Color(0.0, 0.95, 1.0, 1)
@export var neon_magenta: Color = Color(1.0, 0.12, 0.85, 1)
@export var neon_purple: Color = Color(0.62, 0.2, 1.0, 1)
@export var neon_gold: Color = Color(1.0, 0.82, 0.2, 1)

@export_group("Текст")
@export var text: Color = Color(0.88, 0.96, 1.0, 1)
@export var text_dim: Color = Color(0.45, 0.55, 0.75, 1)
@export var hint_modulate: Color = Color(0.7, 0.85, 1.0, 1)

@export_group("Провода")
@export var wire_file: Color = Color(0.2, 0.95, 1.0, 1)
@export var wire_money: Color = Color(1.0, 0.75, 0.15, 1)

@export_group("Кнопки")
@export var btn_icon_normal: Color = Color(0.1, 0.05, 0.18, 1)
@export var btn_icon_hover: Color = Color(0.14, 0.06, 0.22, 1)
@export var btn_icon_pressed: Color = Color(0.18, 0.08, 0.28, 1)
@export var btn_icon_disabled: Color = Color(0.06, 0.03, 0.1, 1)
@export var btn_action_normal: Color = Color(0.08, 0.05, 0.16, 1)
@export var btn_action_hover: Color = Color(0.12, 0.07, 0.22, 1)
@export var btn_action_pressed: Color = Color(0.15, 0.08, 0.28, 1)
@export var btn_action_disabled: Color = Color(0.05, 0.03, 0.09, 1)
@export var action_border_alpha: float = 0.55

@export_group("Панели")
@export var panel_log: Color = Color(0.05, 0.03, 0.1, 0.85)
@export var panel_block: Color = Color(0.08, 0.04, 0.16, 0.95)
@export var panel_shop: Color = Color(0.06, 0.03, 0.12, 0.98)
@export var panel_shop_row: Color = Color(0.09, 0.05, 0.18, 1)
@export var panel_shop_tile: Color = Color(0.05, 0.03, 0.08, 1)
@export var panel_block_frame: Color = Color(0.0, 0.0, 0.0, 0.9)
@export var log_border_alpha: float = 0.5
@export var shop_row_border_alpha: float = 0.4
@export var shop_shadow: Color = Color(1.0, 0.1, 0.8, 0.35)

@export_group("Прочее")
@export var progress_bg: Color = Color(0.05, 0.03, 0.12, 1)
@export var progress_border_alpha: float = 0.35
@export var cell_hover_bg: Color = Color(0.0, 0.85, 1.0, 0.12)
@export var cell_hover_border: Color = Color(0.0, 0.95, 1.0, 0.55)
@export var frame_glow_alpha: float = 0.38
@export var neon_glow_alpha: float = 0.45
@export var progress_fill_glow_alpha: float = 0.6


func border_cyan(alpha: float = 1.0) -> Color:
	return Color(neon_cyan.r, neon_cyan.g, neon_cyan.b, alpha)


func border_purple(alpha: float = 1.0) -> Color:
	return Color(neon_purple.r, neon_purple.g, neon_purple.b, alpha)
