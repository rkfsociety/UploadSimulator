extends Control
class_name PlacedBlock
## Модуль на поле: сцена placed_block.tscn, данные — PlacedBlockViewData, отрисовка — PlacedBlockView.

signal upgrade_requested(block: PlacedBlock)
signal action_requested(block: PlacedBlock)

const SCENE_PATH := "res://scenes/blocks/placed_block.tscn"
const THEME_PATH := "res://themes/placed_block_theme.tres"

static var _scene_cache: PackedScene
static var _theme_cache: Theme
# Основная панель — почти весь след; снизу полоса улучшения на 1 клетку по высоте
const MAIN_CELLS_W := GridDefs.BLOCK_CELLS_W
const MAIN_CELLS_H := GridDefs.BLOCK_MAIN_CELLS_H
const UPGRADE_CELLS_W := GridDefs.BLOCK_CELLS_W
const UPGRADE_CELLS_H := GridDefs.BLOCK_UPGRADE_CELLS_H

var instance_uid: String = ""
var block_type: String = ""

@onready var _main_panel: NeonFrame = %MainPanel
@onready var _upgrade_panel: NeonFrame = %UpgradePanel
@onready var _title_label: Label = %TitleLabel
@onready var _metric_label: Label = %MetricLabel
@onready var _state_label: Label = %StateLabel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _action_btn: Button = %ActionButton
@onready var _upgrade_btn: Button = %UpgradeButton
@onready var _left_ports: HBoxContainer = %LeftPorts
@onready var _right_ports: HBoxContainer = %RightPorts

var _view: PlacedBlockView


## Размер модуля на карте в пикселях (10×6 клеток, альбом).
static func pixel_size() -> Vector2:
	return GridDefs.block_pixel_size()


static func _main_panel_size() -> Vector2:
	return Vector2(
		float(MAIN_CELLS_W * GridDefs.CELL_SIZE), float(MAIN_CELLS_H * GridDefs.CELL_SIZE)
	)


static func _upgrade_panel_size() -> Vector2:
	return Vector2(
		float(UPGRADE_CELLS_W * GridDefs.CELL_SIZE),
		float(UPGRADE_CELLS_H * GridDefs.CELL_SIZE)
	)


static func get_scene() -> PackedScene:
	# Ленивая загрузка сцены модуля при первом спавне
	if _scene_cache == null:
		_scene_cache = load(SCENE_PATH) as PackedScene
	return _scene_cache


static func get_block_theme() -> Theme:
	# Ленивая загрузка темы UI модуля (не get_theme — конфликт с Control)
	if _theme_cache == null:
		_theme_cache = load(THEME_PATH) as Theme
	return _theme_cache


## Создаёт экземпляр из сцены (вместо PlacedBlock.new()).
static func instantiate_block() -> PlacedBlock:
	return get_scene().instantiate() as PlacedBlock


func _ready() -> void:
	# Тема: отступы, стили; шрифт — векторный SystemFont (см. themes/placed_block_theme.tres)
	if theme == null:
		theme = get_block_theme()
	UiFonts.apply_to_theme(theme, 16, 13, 11)
	_apply_root_layout()
	_view = PlacedBlockView.new(
		_main_panel,
		_upgrade_panel,
		_title_label,
		_metric_label,
		_state_label,
		_progress_bar,
		_action_btn,
		_upgrade_btn,
	)
	_upgrade_btn.pressed.connect(func(): upgrade_requested.emit(self))
	_action_btn.pressed.connect(func(): action_requested.emit(self))


## Привязывает экземпляр к uid и типу, пересобирает порты и обновляет UI.
func setup(uid: String, type_id: String) -> void:
	instance_uid = uid
	block_type = type_id
	_build_ports()
	refresh()


func _apply_root_layout() -> void:
	var sz := pixel_size()
	custom_minimum_size = sz
	size = sz
	_main_panel.custom_minimum_size = _main_panel_size()
	_upgrade_panel.custom_minimum_size = _upgrade_panel_size()


func _build_ports() -> void:
	for child in _left_ports.get_children():
		child.queue_free()
	for child in _right_ports.get_children():
		child.queue_free()
	var defs: Dictionary = BlockDefs.PORT_DEFS.get(block_type, {})
	for port_id in defs.keys():
		var def: Dictionary = defs[port_id]
		var port := _make_port(port_id, def)
		if def.get("dir", "") == "in":
			_left_ports.add_child(port)
		else:
			_right_ports.add_child(port)
	_left_ports.visible = _left_ports.get_child_count() > 0
	_right_ports.visible = _right_ports.get_child_count() > 0


func _make_port(port_id: String, def: Dictionary) -> ConnectionPort:
	var port := ConnectionPort.new()
	port.custom_minimum_size = Vector2(12, 12)
	var p_kind := (
		ConnectionPort.Kind.MONEY if def.get("kind", "") == "money" else ConnectionPort.Kind.FILE
	)
	var p_dir := ConnectionPort.Dir.IN if def.get("dir", "") == "in" else ConnectionPort.Dir.OUT
	port.configure(instance_uid, block_type, port_id, p_kind, p_dir)
	return port


## Перечитывает GameState и применяет PlacedBlockViewData к узлам сцены.
func refresh() -> void:
	if _view == null:
		return
	_apply_root_layout()
	_view.apply(PlacedBlockViewData.from_instance(instance_uid, block_type))
