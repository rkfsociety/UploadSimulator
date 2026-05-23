extends CanvasLayer
## Отладочный оверлей: FPS и ключевые метрики GameState. Переключение — F3.

const TOGGLE_KEY := KEY_F3

var _panel: PanelContainer
var _label: Label
var _visible_debug := OS.is_debug_build()
# Не собирать строки статистики каждый кадр — достаточно ~6 раз/с
var _stats_accum: float = 0.0
const STATS_REFRESH_SEC := 0.15


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_overlay_visible(_visible_debug)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode == TOGGLE_KEY:
			_visible_debug = not _visible_debug
			_set_overlay_visible(_visible_debug)
			get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if not _visible_debug or _label == null or not _game_state_ready():
		return
	_stats_accum += delta
	if _stats_accum < STATS_REFRESH_SEC:
		return
	_stats_accum = 0.0
	_label.text = _build_stats_text()


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	_panel.add_child(margin)

	_label = Label.new()
	_label.add_theme_font_override("font", UiFonts.default_font())
	_label.add_theme_font_size_override("font_size", 11)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(_label)

	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(8, 56)


func _set_overlay_visible(show_overlay: bool) -> void:
	if _panel:
		_panel.visible = show_overlay


func _game_state_ready() -> bool:
	# Headless-тесты: autoload может быть не инициализирован — не спамим ошибками
	var gs := get_tree().root.get_node_or_null("GameState")
	return gs != null and gs.get("access") != null


func _build_stats_text() -> String:
	if not _game_state_ready():
		return "[DEBUG] GameState недоступен"
	var fps := Engine.get_frames_per_second()
	var phase := GameState.access.get_phase()
	var lines: PackedStringArray = PackedStringArray([
		"[DEBUG] F3 — скрыть",
		"FPS: %.0f" % fps,
		"Касса: $%.0f | Аплоудер: $%.2f"
		% [GameState.access.get_money(), GameState.access.get_uploader_balance()],
		"Фаза: %s | %s" % [phase, GameState.pipeline.get_phase_label()],
		"Очереди ↓%d ↑%d | Модули: %d | Провода: %d"
		% [
			GameState.access.get_download_queue().size(),
			GameState.access.get_upload_queue().size(),
			GameState.access.get_placed_blocks().size(),
			GameState.access.get_wire_connections().size(),
		],
		"Диск: %s / %s"
		% [
			ByteFormat.format_bytes(GameState.storage.get_storage_used_bytes()),
			ByteFormat.format_bytes(GameState.storage.get_storage_capacity_bytes()),
		],
	])
	return "\n".join(lines)
