extends RefCounted
class_name MinimalUI
## Неоновый киберпанк-стиль интерфейса.

const BG_DARK := Color(0.04, 0.02, 0.09, 1)
const BG_PANEL := Color(0.07, 0.04, 0.14, 0.92)
const NEON_CYAN := Color(0.0, 0.95, 1.0, 1)
const NEON_MAGENTA := Color(1.0, 0.12, 0.85, 1)
const NEON_PURPLE := Color(0.62, 0.2, 1.0, 1)
const NEON_GOLD := Color(1.0, 0.82, 0.2, 1)
const TEXT := Color(0.88, 0.96, 1.0, 1)
const TEXT_DIM := Color(0.45, 0.55, 0.75, 1)
const WIRE_FILE := Color(0.2, 0.95, 1.0, 1)
const WIRE_MONEY := Color(1.0, 0.75, 0.15, 1)


static func neon_box(bg: Color, border: Color, glow: bool = true) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = 8
	s.corner_radius_top_right = 8
	s.corner_radius_bottom_left = 8
	s.corner_radius_bottom_right = 8
	s.set_content_margin_all(8)
	if glow:
		s.shadow_color = Color(border.r, border.g, border.b, 0.45)
		s.shadow_size = 4
	return s


static func flat_btn(normal: Color = BG_PANEL, border: Color = NEON_CYAN) -> StyleBoxFlat:
	return neon_box(normal, border, true)


static func icon_btn() -> StyleBoxFlat:
	var s := neon_box(Color(0.1, 0.05, 0.18, 1), NEON_MAGENTA, true)
	s.set_content_margin_all(4)
	return s


static func apply_icon_button(btn: Button) -> void:
	btn.flat = false
	btn.custom_minimum_size = Vector2(44, 44)
	btn.text = "◈"
	btn.add_theme_stylebox_override("normal", icon_btn())
	btn.add_theme_stylebox_override("hover", neon_box(Color(0.14, 0.06, 0.22, 1), NEON_MAGENTA, true))
	btn.add_theme_stylebox_override("pressed", neon_box(Color(0.18, 0.08, 0.28, 1), NEON_CYAN, true))
	btn.add_theme_stylebox_override("disabled", neon_box(Color(0.06, 0.03, 0.1, 1), TEXT_DIM, false))
	btn.add_theme_color_override("font_color", NEON_MAGENTA)
	btn.add_theme_font_size_override("font_size", 20)


static func apply_action_button(btn: Button) -> void:
	btn.flat = false
	btn.custom_minimum_size = Vector2(0, 44)
	var n := neon_box(Color(0.08, 0.05, 0.16, 1), Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, 0.55), true)
	var h := neon_box(Color(0.12, 0.07, 0.22, 1), NEON_CYAN, true)
	btn.add_theme_stylebox_override("normal", n)
	btn.add_theme_stylebox_override("hover", h)
	btn.add_theme_stylebox_override("pressed", neon_box(Color(0.15, 0.08, 0.28, 1), NEON_MAGENTA, true))
	btn.add_theme_stylebox_override("disabled", neon_box(Color(0.05, 0.03, 0.09, 1), TEXT_DIM, false))
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 14)


static func apply_balance_label(lbl: Label, large: bool = true) -> void:
	lbl.add_theme_color_override("font_color", NEON_CYAN)
	lbl.add_theme_font_size_override("font_size", 24 if large else 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func apply_dim_label(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", NEON_GOLD)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func apply_status_label(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", NEON_MAGENTA)
	lbl.modulate = Color(1, 1, 1, 1)


static func apply_hint_label(lbl: Label) -> void:
	lbl.add_theme_color_override("font_color", TEXT_DIM)
	lbl.modulate = Color(0.7, 0.85, 1, 1)


static func apply_progress_bar(bar: ProgressBar, fill_color: Color = NEON_CYAN) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.05, 0.03, 0.12, 1)
	bg.border_color = Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, 0.35)
	bg.set_border_width_all(1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	fill.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, 0.6)
	fill.shadow_size = 3
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


static func apply_log_panel(panel: PanelContainer) -> void:
	panel.add_theme_stylebox_override("panel", neon_box(Color(0.05, 0.03, 0.1, 0.85), Color(NEON_PURPLE.r, NEON_PURPLE.g, NEON_PURPLE.b, 0.5), true))


static func block_panel_style() -> StyleBoxFlat:
	return neon_box(Color(0.08, 0.04, 0.16, 0.95), NEON_CYAN, true)


static func block_grid_style() -> StyleBoxFlat:
	return block_neon_frame_style(NEON_CYAN)


static func block_neon_frame_style(accent: Color) -> StyleBoxFlat:
	# Тонкая рамка (~2px) и лёгкое свечение без большой растушёвки
	var s := StyleBoxFlat.new()
	var glow := Color(accent.r, accent.g, accent.b, 0.38)
	s.bg_color = Color(0.0, 0.0, 0.0, 0.9)
	s.border_color = accent
	s.set_border_width_all(1)
	s.corner_radius_top_left = 3
	s.corner_radius_top_right = 3
	s.corner_radius_bottom_left = 3
	s.corner_radius_bottom_right = 3
	s.set_content_margin_all(4)
	s.shadow_color = glow
	s.shadow_size = 2
	s.expand_margin_left = 2
	s.expand_margin_top = 2
	s.expand_margin_right = 2
	s.expand_margin_bottom = 2
	return s


static func shop_panel_style() -> StyleBoxFlat:
	var s := neon_box(Color(0.06, 0.03, 0.12, 0.98), NEON_MAGENTA, true)
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.border_width_top = 2
	s.border_color = NEON_MAGENTA
	s.shadow_size = 8
	s.shadow_color = Color(1.0, 0.1, 0.8, 0.35)
	return s


static func shop_row_style() -> StyleBoxFlat:
	return neon_box(Color(0.09, 0.05, 0.18, 1), Color(NEON_CYAN.r, NEON_CYAN.g, NEON_CYAN.b, 0.4), false)


static func shop_icon_tile_style(accent: Color, selected: bool = false) -> StyleBoxFlat:
	if selected:
		return block_neon_frame_style(accent)
	var dim := Color(accent.r, accent.g, accent.b, 0.4)
	return neon_box(Color(0.05, 0.03, 0.08, 1), dim, false)


static func apply_block_upgrade_button(btn: Button, accent: Color) -> void:
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_color_override("font_color", accent)
	btn.add_theme_color_override("font_hover_color", accent.lightened(0.2))
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 12)


static func apply_shop_icon_button(btn: Button) -> void:
	btn.flat = false
	btn.custom_minimum_size = Vector2(68, 68)
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", NEON_CYAN)


static func cell_hover_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.0, 0.85, 1.0, 0.12)
	s.border_color = Color(0.0, 0.95, 1.0, 0.55)
	s.set_border_width_all(1)
	return s
