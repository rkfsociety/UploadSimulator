extends VBoxContainer
class_name NetworkBlockPanel
## Панель модуля «Сеть»: скорости ↓/↑ в стиле неонового HUD.

const COLOR_DOWNLOAD := Color(0.28, 1.0, 0.48)
const COLOR_UPLOAD := Color(0.38, 0.86, 1.0)
const COLOR_DOT_IDLE := Color(0.22, 0.26, 0.34)

var _download_value: Label
var _upload_value: Label
var _download_dot: Panel
var _upload_dot: Panel
var _status_label: Label


func _ready() -> void:
	add_theme_constant_override("separation", 6)
	_add_speed_row(true)
	_add_speed_row(false)
	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status_label.add_theme_font_size_override("font_size", 10)
	_status_label.add_theme_color_override("font_color", MinimalUI.TEXT_DIM)
	add_child(_status_label)


func apply(
	download_bps: float,
	upload_bps: float,
	download_active: bool,
	upload_active: bool,
	status: String,
) -> void:
	_download_value.text = ByteFormat.format_speed_bps_label(download_bps)
	_upload_value.text = ByteFormat.format_speed_bps_label(upload_bps)
	_set_dot(_download_dot, download_active, COLOR_DOWNLOAD)
	_set_dot(_upload_dot, upload_active, COLOR_UPLOAD)
	_status_label.text = status
	_status_label.visible = not status.is_empty()


func _add_speed_row(is_download: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	var accent := COLOR_DOWNLOAD if is_download else COLOR_UPLOAD

	var icon := Label.new()
	icon.text = "↓" if is_download else "↑"
	icon.custom_minimum_size = Vector2(18, 18)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	icon.add_theme_color_override("font_color", accent)

	var title := Label.new()
	title.text = "Загрузка" if is_download else "Выгрузка"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 13)
	title.add_theme_color_override("font_color", MinimalUI.TEXT)

	var value := Label.new()
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_font_size_override("font_size", 13)
	value.add_theme_color_override("font_color", accent.lightened(0.08))

	var dot := _make_dot()

	row.add_child(icon)
	row.add_child(title)
	row.add_child(value)
	row.add_child(dot)
	add_child(row)

	if is_download:
		_download_value = value
		_download_dot = dot
	else:
		_upload_value = value
		_upload_dot = dot


func _make_dot() -> Panel:
	var dot := Panel.new()
	dot.custom_minimum_size = Vector2(10, 10)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_DOT_IDLE
	style.set_corner_radius_all(5)
	dot.add_theme_stylebox_override("panel", style)
	return dot


func _set_dot(dot: Panel, active: bool, accent: Color) -> void:
	var style := StyleBoxFlat.new()
	if active:
		style.bg_color = accent
		style.shadow_color = Color(accent.r, accent.g, accent.b, 0.75)
		style.shadow_size = 4
	else:
		style.bg_color = COLOR_DOT_IDLE
	style.set_corner_radius_all(5)
	dot.add_theme_stylebox_override("panel", style)
