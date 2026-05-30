extends RefCounted
class_name PlacedBlockView
## Представление: применяет PlacedBlockViewData к узлам сцены.

var _main_panel: NeonFrame
var _upgrade_panel: NeonFrame
var _title_label: Label
var _metric_label: Label
var _network_panel: NetworkBlockPanel
var _progress_bar: ProgressBar
var _action_btn: Button
var _upgrade_btn: Button


func _init(
	main_panel: NeonFrame,
	upgrade_panel: NeonFrame,
	title_label: Label,
	metric_label: Label,
	network_panel: NetworkBlockPanel,
	progress_bar: ProgressBar,
	action_btn: Button,
	upgrade_btn: Button,
) -> void:
	_main_panel = main_panel
	_upgrade_panel = upgrade_panel
	_title_label = title_label
	_metric_label = metric_label
	_network_panel = network_panel
	_progress_bar = progress_bar
	_action_btn = action_btn
	_upgrade_btn = upgrade_btn


## Применяет снимок данных к узлам сцены (без обращения к GameState).
func apply(data: PlacedBlockViewData) -> void:
	var accent := data.accent
	var upgrade_accent := MinimalUI.NEON_MAGENTA if data.use_network_panel else accent
	_main_panel.set_accent(accent)
	_upgrade_panel.set_accent(upgrade_accent)
	_title_label.text = data.title
	if data.use_network_panel:
		_title_label.add_theme_font_size_override("font_size", 20)
		_title_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		_title_label.add_theme_font_size_override("font_size", 16)
		_title_label.add_theme_color_override("font_color", accent)
	if data.use_network_panel and _network_panel != null:
		_network_panel.visible = true
		_metric_label.visible = false
		_network_panel.apply(
			data.network_download_bps,
			data.network_upload_bps,
			data.network_download_active,
			data.network_upload_active,
			data.status,
		)
	else:
		if _network_panel != null:
			_network_panel.visible = false
		_metric_label.visible = true
		_metric_label.text = data.metric
		_metric_label.add_theme_color_override("font_color", accent.lightened(0.12))
	_action_btn.visible = data.action_visible
	if data.action_visible:
		_action_btn.text = data.action_text
		_action_btn.disabled = not data.action_enabled
	if data.progress >= 0.0:
		_progress_bar.visible = true
		_progress_bar.value = data.progress * 100.0
		_apply_progress_fill(accent)
	else:
		_progress_bar.visible = false
	_upgrade_btn.text = data.upgrade_text
	_upgrade_btn.disabled = not data.upgrade_enabled
	_apply_upgrade_colors(upgrade_accent, data.use_network_panel)


## Заливка прогресса зависит от акцента типа модуля.
func _apply_progress_fill(accent: Color) -> void:
	_progress_bar.add_theme_stylebox_override("fill", MinimalUI.progress_fill_style(accent))


## Цвета кнопки улучшения привязаны к акценту блока.
func _apply_upgrade_colors(accent: Color, network_style: bool) -> void:
	_upgrade_btn.flat = true
	_upgrade_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_upgrade_btn.add_theme_color_override("font_color", accent)
	_upgrade_btn.add_theme_color_override("font_hover_color", accent.lightened(0.2))
	_upgrade_btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	if network_style:
		_upgrade_btn.add_theme_font_size_override("font_size", 15)
