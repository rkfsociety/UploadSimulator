extends RefCounted
class_name MinimalUI
## Неоновый киберпанк-стиль интерфейса: палитра, кэш StyleBoxFlat и Theme.

const COLORS_PATH := "res://resources/minimal_ui_colors.tres"
# Иконка кнопки магазина в нижнем HUD
const SHOP_HUD_ICON_PATH := "res://assets/icons/shop.svg"

static var _palette: MinimalUIColors
static var _theme: Theme
static var _box_cache: Dictionary = {}
static var _shop_hud_icon: Texture2D


# Короткие имена цветов (читают палитру из .tres)
static var BG_DARK: Color:
	get:
		return colors().bg_dark


static var BG_PANEL: Color:
	get:
		return colors().bg_panel


static var NEON_CYAN: Color:
	get:
		return colors().neon_cyan


static var NEON_MAGENTA: Color:
	get:
		return colors().neon_magenta


static var NEON_PURPLE: Color:
	get:
		return colors().neon_purple


static var NEON_GOLD: Color:
	get:
		return colors().neon_gold


static var TEXT: Color:
	get:
		return colors().text


static var TEXT_DIM: Color:
	get:
		return colors().text_dim


static var WIRE_FILE: Color:
	get:
		return colors().wire_file


static var WIRE_MONEY: Color:
	get:
		return colors().wire_money


static func colors() -> MinimalUIColors:
	if _palette == null:
		_palette = load(COLORS_PATH) as MinimalUIColors
		if _palette == null:
			_palette = MinimalUIColors.new()
	return _palette


static func theme() -> Theme:
	if _theme == null:
		_theme = MinimalUITheme.build()
	return _theme


static func attach_theme(root: Control) -> void:
	root.theme = theme()


static func neon_box(
	bg: Color,
	border: Color,
	glow: bool = true,
	margin: int = 8,
	radius: int = 8,
) -> StyleBoxFlat:
	var key := "%s|%s|%s|%d|%d" % [bg.to_html(false), border.to_html(false), glow, margin, radius]
	if _box_cache.has(key):
		return _box_cache[key]
	var s := _make_neon_box(bg, border, glow, margin, radius)
	_box_cache[key] = s
	return s


static func _make_neon_box(
	bg: Color,
	border: Color,
	glow: bool,
	margin: int,
	radius: int,
) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.set_content_margin_all(margin)
	if glow:
		var glow_a := colors().neon_glow_alpha
		s.shadow_color = Color(border.r, border.g, border.b, glow_a)
		s.shadow_size = 4
	return s


static func flat_btn(normal: Color = Color(), border: Color = Color()) -> StyleBoxFlat:
	var c := colors()
	if normal == Color():
		normal = c.bg_panel
	if border == Color():
		border = c.neon_cyan
	return neon_box(normal, border, true)


# --- Кэшированные пресеты (используются Theme и apply_*) ---

static func cached_action_normal() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_action_normal, c.border_cyan(c.action_border_alpha), true)


static func cached_action_hover() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_action_hover, c.neon_cyan, true)


static func cached_action_pressed() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_action_pressed, c.neon_magenta, true)


static func cached_action_disabled() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_action_disabled, c.text_dim, false)


static func cached_icon_normal() -> StyleBoxFlat:
	return icon_btn()


static func cached_icon_hover() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_icon_hover, c.neon_magenta, true)


static func cached_icon_pressed() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_icon_pressed, c.neon_cyan, true)


static func cached_icon_disabled() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.btn_icon_disabled, c.text_dim, false)


static func cached_progress_background() -> StyleBoxFlat:
	var c := colors()
	var bg := StyleBoxFlat.new()
	bg.bg_color = c.progress_bg
	bg.border_color = c.border_cyan(c.progress_border_alpha)
	bg.set_border_width_all(1)
	bg.corner_radius_top_left = 4
	bg.corner_radius_top_right = 4
	bg.corner_radius_bottom_left = 4
	bg.corner_radius_bottom_right = 4
	var key := "progress_bg"
	if not _box_cache.has(key):
		_box_cache[key] = bg
	return _box_cache[key]


static func cached_log_panel() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.panel_log, c.border_purple(c.log_border_alpha), true)


static func cached_shop_panel() -> StyleBoxFlat:
	return shop_panel_style()


static func cached_block_panel() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.panel_block, c.neon_cyan, true)


static func cached_cell_hover() -> StyleBoxFlat:
	return cell_hover_style()


static func icon_btn() -> StyleBoxFlat:
	var c := colors()
	# margin=4 в ключе кэша, чтобы не портить общий neon_box
	return neon_box(c.btn_icon_normal, c.neon_magenta, true, 4, 8)


static func shop_hud_icon() -> Texture2D:
	# Кэш SVG-корзины (preload + load на случай горячей перезагрузки)
	if _shop_hud_icon == null:
		if ResourceLoader.exists(SHOP_HUD_ICON_PATH):
			_shop_hud_icon = load(SHOP_HUD_ICON_PATH) as Texture2D
	return _shop_hud_icon


static func _transparent_button_style() -> StyleBoxEmpty:
	# Пустой стиль — кликабельная область без заливки поверх иконки
	var s := StyleBoxEmpty.new()
	return s


static func apply_icon_button(btn: Button) -> void:
	btn.flat = false
	btn.custom_minimum_size = Vector2(44, 44)
	btn.text = "◈"
	btn.theme_type_variation = &"icon"
	var t := theme()
	btn.add_theme_stylebox_override("normal", t.get_stylebox("normal", &"icon"))
	btn.add_theme_stylebox_override("hover", t.get_stylebox("hover", &"icon"))
	btn.add_theme_stylebox_override("pressed", t.get_stylebox("pressed", &"icon"))
	btn.add_theme_stylebox_override("disabled", t.get_stylebox("disabled", &"icon"))
	btn.add_theme_color_override("font_color", NEON_MAGENTA)
	btn.add_theme_font_size_override("font_size", 20)


static func apply_shop_hud_button(hit_btn: Button, icon_tex: TextureRect) -> void:
	# Иконка — сосед TextureRect; Button только ловит клики (дети Button под фоном)
	var panel: PanelContainer = hit_btn.get_parent().get_parent() as PanelContainer
	var t := theme()
	if panel:
		panel.add_theme_stylebox_override("panel", t.get_stylebox("normal", &"icon"))
	var tex := shop_hud_icon()
	if tex and icon_tex.texture == null:
		icon_tex.texture = tex
	icon_tex.modulate = Color.WHITE
	icon_tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var empty := _transparent_button_style()
	hit_btn.flat = true
	hit_btn.text = ""
	hit_btn.icon = null
	hit_btn.add_theme_stylebox_override("normal", empty)
	hit_btn.add_theme_stylebox_override("hover", empty)
	hit_btn.add_theme_stylebox_override("pressed", empty)
	hit_btn.add_theme_stylebox_override("disabled", empty)
	hit_btn.add_theme_stylebox_override("focus", empty)


static func apply_action_button(btn: Button) -> void:
	btn.flat = false
	btn.custom_minimum_size = Vector2(0, 44)
	btn.theme_type_variation = &"action"
	var t := theme()
	btn.add_theme_stylebox_override("normal", t.get_stylebox("normal", &"action"))
	btn.add_theme_stylebox_override("hover", t.get_stylebox("hover", &"action"))
	btn.add_theme_stylebox_override("pressed", t.get_stylebox("pressed", &"action"))
	btn.add_theme_stylebox_override("disabled", t.get_stylebox("disabled", &"action"))
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_DIM)
	btn.add_theme_font_size_override("font_size", 14)


static func apply_balance_label(lbl: Label, large: bool = true) -> void:
	lbl.theme_type_variation = &"balance" if large else &"balance_small"
	lbl.add_theme_color_override("font_color", NEON_CYAN)
	lbl.add_theme_font_size_override("font_size", 24 if large else 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func apply_dim_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"dim"
	lbl.add_theme_color_override("font_color", NEON_GOLD)
	lbl.add_theme_font_size_override("font_size", 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT


static func apply_status_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"status"
	lbl.add_theme_color_override("font_color", NEON_MAGENTA)
	lbl.modulate = Color(1, 1, 1, 1)


static func apply_hint_label(lbl: Label) -> void:
	lbl.theme_type_variation = &"hint"
	lbl.add_theme_color_override("font_color", TEXT_DIM)
	lbl.modulate = colors().hint_modulate


static func apply_progress_bar(bar: ProgressBar, fill_color: Color = Color()) -> void:
	if fill_color == Color():
		fill_color = colors().neon_cyan
	bar.add_theme_stylebox_override("background", cached_progress_background())
	bar.add_theme_stylebox_override("fill", progress_fill_style(fill_color))


static func progress_fill_style(fill_color: Color) -> StyleBoxFlat:
	var key := "progress_fill|%s" % fill_color.to_html(false)
	if _box_cache.has(key):
		return _box_cache[key]
	var c := colors()
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	fill.shadow_color = Color(fill_color.r, fill_color.g, fill_color.b, c.progress_fill_glow_alpha)
	fill.shadow_size = 3
	_box_cache[key] = fill
	return fill


static func apply_log_panel(panel: PanelContainer) -> void:
	panel.theme_type_variation = &"log"
	panel.add_theme_stylebox_override("panel", cached_log_panel())


static func block_panel_style() -> StyleBoxFlat:
	return cached_block_panel()


static func block_grid_style() -> StyleBoxFlat:
	return block_neon_frame_style(NEON_CYAN)


static func block_neon_frame_style(accent: Color) -> StyleBoxFlat:
	var c := colors()
	var key := "block_frame|%s" % accent.to_html(false)
	if _box_cache.has(key):
		return _box_cache[key]
	# Тонкая рамка (~2px) и лёгкое свечение без большой растушёвки
	var s := StyleBoxFlat.new()
	var glow := Color(accent.r, accent.g, accent.b, c.frame_glow_alpha)
	s.bg_color = c.panel_block_frame
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
	_box_cache[key] = s
	return s


static func shop_panel_style() -> StyleBoxFlat:
	var key := "shop_panel"
	if _box_cache.has(key):
		return _box_cache[key]
	var c := colors()
	# duplicate: neon_box отдаёт общий кэш, здесь нужна отдельная копия
	var s := neon_box(c.panel_shop, c.neon_magenta, true).duplicate() as StyleBoxFlat
	s.corner_radius_bottom_left = 0
	s.corner_radius_bottom_right = 0
	s.border_width_top = 2
	s.border_color = c.neon_magenta
	s.shadow_size = 8
	s.shadow_color = c.shop_shadow
	_box_cache[key] = s
	return s


static func shop_row_style() -> StyleBoxFlat:
	var c := colors()
	return neon_box(c.panel_shop_row, c.border_cyan(c.shop_row_border_alpha), false)


static func shop_icon_tile_style(accent: Color, selected: bool = false) -> StyleBoxFlat:
	if selected:
		return block_neon_frame_style(accent)
	var c := colors()
	var dim := Color(accent.r, accent.g, accent.b, 0.4)
	return neon_box(c.panel_shop_tile, dim, false)


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
	btn.theme_type_variation = &"shop_icon"
	btn.add_theme_font_size_override("font_size", 28)
	btn.add_theme_color_override("font_color", NEON_CYAN)


static func cell_hover_style() -> StyleBoxFlat:
	var key := "cell_hover"
	if _box_cache.has(key):
		return _box_cache[key]
	var c := colors()
	var s := StyleBoxFlat.new()
	s.bg_color = c.cell_hover_bg
	s.border_color = c.cell_hover_border
	s.set_border_width_all(1)
	_box_cache[key] = s
	return s
