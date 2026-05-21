extends RefCounted
class_name PlacedBlockTheme
## Стили модуля на поле; собирает Theme для themes/placed_block_theme.tres.


static func build() -> Theme:
	var c := MinimalUI.colors()
	var theme := Theme.new()
	# Отступы основной панели
	theme.set_constant("margin_left", "MarginContainer", 10)
	theme.set_constant("margin_top", "MarginContainer", 8)
	theme.set_constant("margin_right", "MarginContainer", 10)
	theme.set_constant("margin_bottom", "MarginContainer", 8)
	# Расстояния между колонками и портами
	theme.set_constant("separation", "HBoxContainer", 2)
	theme.set_constant("separation", "VBoxContainer", 1)
	# Заголовок модуля
	theme.set_font_size("font_size", &"title", 14)
	theme.set_color("font_color", &"title", c.text)
	# Метрика
	theme.set_font_size("font_size", &"metric", 12)
	theme.set_color("font_color", &"metric", c.text)
	# Статус
	theme.set_font_size("font_size", &"state", 11)
	theme.set_color("font_color", &"state", c.text_dim)
	# Кнопка действия (кэш MinimalUI)
	theme.set_stylebox("normal", "Button", MinimalUI.cached_action_normal())
	theme.set_stylebox("hover", "Button", MinimalUI.cached_action_hover())
	theme.set_stylebox("pressed", "Button", MinimalUI.cached_action_pressed())
	theme.set_stylebox("disabled", "Button", MinimalUI.cached_action_disabled())
	theme.set_color("font_color", "Button", c.text)
	theme.set_color("font_disabled_color", "Button", c.text_dim)
	theme.set_font_size("font_size", &"action", 11)
	theme.set_stylebox("normal", &"action", MinimalUI.cached_action_normal())
	theme.set_stylebox("hover", &"action", MinimalUI.cached_action_hover())
	# Кнопка улучшения (плоская, цвет акцента задаётся во view)
	theme.set_font_size("font_size", &"upgrade", 12)
	theme.set_color("font_color", &"upgrade", c.text)
	theme.set_color("font_hover_color", &"upgrade", c.text)
	theme.set_color("font_pressed_color", &"upgrade", Color.WHITE)
	theme.set_color("font_disabled_color", &"upgrade", c.text_dim)
	# Прогресс-бар (фон; заливка с акцентом — в PlacedBlockView)
	theme.set_stylebox("background", "ProgressBar", MinimalUI.cached_progress_background())
	theme.set_constant("custom_minimum_size", "ProgressBar", 6)
	return theme
