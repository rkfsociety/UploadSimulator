extends Control
class_name PlacedBlock
## Модуль на поле: сцена placed_block.tscn, данные — PlacedBlockViewData, отрисовка — PlacedBlockView.

signal upgrade_requested(block: PlacedBlock)
signal action_requested(block: PlacedBlock)

const SCENE_PATH := "res://scenes/blocks/placed_block.tscn"
const THEME_PATH := "res://themes/placed_block_theme.tres"
const NetworkBlockPanelType = preload("res://scripts/systems/blocks/network_block_panel.gd")

static var _scene_cache: PackedScene
static var _theme_cache: Theme

var instance_uid: String = ""
var block_type: String = ""

@onready var _main_panel: NeonFrame = %MainPanel
@onready var _upgrade_panel: NeonFrame = %UpgradePanel
@onready var _title_label: Label = %TitleLabel
@onready var _metric_label: Label = %MetricLabel
@onready var _network_panel: NetworkBlockPanelType = %NetworkPanel
@onready var _progress_bar: ProgressBar = %ProgressBar
@onready var _action_btn: Button = %ActionButton
@onready var _upgrade_btn: Button = %UpgradeButton
@onready var _ports_center: CenterContainer = %PortsCenter

var _view: PlacedBlockView


## Размер модуля на карте в пикселях (свой для каждого типа; "" — значение по умолчанию).
static func pixel_size(type_id: String = "") -> Vector2:
	return GridDefs.block_pixel_size(type_id)


func _uses_upgrade_strip() -> bool:
	return BlockDefs.is_upgradeable(block_type)


func _main_panel_size() -> Vector2:
	var c := GridDefs.block_cells(block_type)
	var upgrade_cells := GridDefs.BLOCK_UPGRADE_CELLS_H if _uses_upgrade_strip() else 0
	return Vector2(
		float(c.x * GridDefs.CELL_SIZE),
		float((c.y - upgrade_cells) * GridDefs.CELL_SIZE),
	)


func _upgrade_panel_size() -> Vector2:
	if not _uses_upgrade_strip():
		return Vector2.ZERO
	var c := GridDefs.block_cells(block_type)
	return Vector2(
		float(c.x * GridDefs.CELL_SIZE),
		float(GridDefs.BLOCK_UPGRADE_CELLS_H * GridDefs.CELL_SIZE),
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
		_network_panel,
		_progress_bar,
		_action_btn,
		_upgrade_btn,
	)
	_upgrade_btn.pressed.connect(func(): upgrade_requested.emit(self))
	_action_btn.pressed.connect(func(): action_requested.emit(self))
	# Кнопка действия на модуле — не ниже touch target на мобильных
	PlatformInfo.apply_action_button_touch(_action_btn)


## Привязывает экземпляр к uid и типу, пересобирает порты и обновляет UI.
func setup(uid: String, type_id: String) -> void:
	instance_uid = uid
	block_type = type_id
	_build_ports()
	refresh()


func _apply_root_layout() -> void:
	var sz := pixel_size(block_type)
	custom_minimum_size = sz
	size = sz
	_main_panel.custom_minimum_size = _main_panel_size()
	var up_sz := _upgrade_panel_size()
	_upgrade_panel.custom_minimum_size = up_sz
	_upgrade_panel.visible = _uses_upgrade_strip()


func _build_ports() -> void:
	# Один центральный разъём на модуль. Какой тип данных и в какую сторону передавать —
	# сервис проводов решает по паре типов модулей при соединении (resolve_wire_ports).
	for child in _ports_center.get_children():
		child.queue_free()
	# Модуль без портов в defs (если такой появится) центральный разъём не получает.
	if BlockDefs.PORT_DEFS.get(block_type, {}).is_empty():
		_ports_center.visible = false
		return
	var port := ConnectionPort.new()
	# Зона нажатия порта — не меньше touch target (визуал остаётся 30px)
	var hit := float(PlatformInfo.port_hit_size())
	port.custom_minimum_size = Vector2(hit, hit)
	port.configure_module(instance_uid, block_type)
	_ports_center.add_child(port)
	_ports_center.visible = true


## Перечитывает GameState и применяет PlacedBlockViewData к узлам сцены.
func refresh() -> void:
	if _view == null:
		return
	_apply_root_layout()
	_view.apply(PlacedBlockViewData.from_instance(instance_uid, block_type))


## Подсветка выбранного модуля на карте (рамка NeonFrame).
func set_map_selected(on: bool) -> void:
	if _main_panel != null:
		_main_panel.set_map_selected(on)
	if _upgrade_panel != null:
		_upgrade_panel.set_map_selected(on)
