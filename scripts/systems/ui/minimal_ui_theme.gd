extends RefCounted
class_name MinimalUITheme
## Собирает Theme для HUD и магазина из кэша MinimalUI.


static func build() -> Theme:
	var c := MinimalUI.colors()
	var theme := Theme.new()
	UiFonts.apply_to_theme(theme, 24, 14, 12)
	# Кнопка действия
	theme.set_stylebox("normal", &"action", MinimalUI.cached_action_normal())
	theme.set_stylebox("hover", &"action", MinimalUI.cached_action_hover())
	theme.set_stylebox("pressed", &"action", MinimalUI.cached_action_pressed())
	theme.set_stylebox("disabled", &"action", MinimalUI.cached_action_disabled())
	theme.set_color("font_color", &"action", c.text)
	theme.set_color("font_disabled_color", &"action", c.text_dim)
	theme.set_font_size("font_size", &"action", 14)
	# Иконка-кнопка
	theme.set_stylebox("normal", &"icon", MinimalUI.cached_icon_normal())
	theme.set_stylebox("hover", &"icon", MinimalUI.cached_icon_hover())
	theme.set_stylebox("pressed", &"icon", MinimalUI.cached_icon_pressed())
	theme.set_stylebox("disabled", &"icon", MinimalUI.cached_icon_disabled())
	theme.set_color("font_color", &"icon", c.neon_magenta)
	theme.set_font_size("font_size", &"icon", 20)
	# Баланс
	theme.set_color("font_color", &"balance", c.neon_cyan)
	theme.set_font_size("font_size", &"balance", 24)
	theme.set_font_size("font_size", &"balance_small", 12)
	# Подписи
	theme.set_color("font_color", &"dim", c.neon_gold)
	theme.set_font_size("font_size", &"dim", 12)
	theme.set_color("font_color", &"status", c.neon_magenta)
	theme.set_color("font_color", &"hint", c.text_dim)
	# Прогресс-бар (заливка с акцентом задаётся отдельно)
	theme.set_stylebox("background", "ProgressBar", MinimalUI.cached_progress_background())
	# Панели
	theme.set_stylebox("panel", &"log", MinimalUI.cached_log_panel())
	theme.set_stylebox("panel", &"shop", MinimalUI.cached_shop_panel())
	# Магазин: плитка иконки
	theme.set_font_size("font_size", &"shop_icon", 28)
	theme.set_color("font_color", &"shop_icon", c.neon_cyan)
	return theme
