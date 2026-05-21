extends Control
## Поле карты (лимит 100×100 клеток). Оркестратор: камера, блоки, провода, установка, ввод.

signal placement_mode_changed(type_id: String)

@onready var map_viewport: Control = $MapViewport
@onready var grid_draw: Control = $GridDraw
@onready var wires_root: Control = $MapViewport/WiresRoot
@onready var blocks_root: Control = $MapViewport/BlocksRoot

var _camera: FieldMapCamera
var _blocks: FieldMapBlocks
var _placement: FieldMapPlacement
var _wiring: FieldMapWiring
var _map_input: FieldMapInput


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	map_viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_viewport.clip_contents = true
	for node in [wires_root, blocks_root]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Провода поверх блоков, чтобы линии были видны между портами
	wires_root.z_index = FieldMapConstants.WIRES_Z_INDEX
	grid_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_camera = FieldMapCamera.new(self, map_viewport, grid_draw)
	_blocks = FieldMapBlocks.new(blocks_root)
	_placement = FieldMapPlacement.new(map_viewport, _camera)
	_wiring = FieldMapWiring.new(self, wires_root, _blocks)
	_map_input = FieldMapInput.new(self, _camera, _placement, _wiring)
	_map_input.placement_finished.connect(_on_placement_finished)

	GameState.field_changed.connect(_on_field_changed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	GameState.stats_changed.connect(_on_field_changed)
	GameState.queue_changed.connect(_on_field_changed)

	await get_tree().process_frame
	_camera.focus_world(GridDefs.world_center_pixel())
	_on_field_changed()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_camera.apply()


func _process(_delta: float) -> void:
	_camera.sync_grid()
	var vis := _camera.visible_world_rect()
	_blocks.update_visibility(vis)
	_wiring.set_visible_rect(vis)


func _gui_input(event: InputEvent) -> void:
	_map_input.handle_gui_input(event)


func _input(event: InputEvent) -> void:
	_map_input.handle_input(event)


## Перемещает камеру в центр карты (мировые координаты 0, 0).
func focus_map_center() -> void:
	_camera.focus_world(GridDefs.world_center_pixel())


## Ставит модуль в центр текущего вида; ищет свободную клетку вокруг якоря.
func place_at_view_center(type_id: String) -> bool:
	return _placement.place_at_view_center(type_id, _blocks.spawn)


## Включает режим ручной установки выбранного типа модуля.
func enter_placement_mode(type_id: String) -> void:
	_placement.set_selected_type(type_id)
	placement_mode_changed.emit(type_id)


## Отменяет режим установки и сбрасывает незавершённое соединение провода.
func cancel_placement_mode() -> void:
	_placement.set_selected_type("")
	_wiring.clear_pending()
	placement_mode_changed.emit("")


## Клетка сетки в центре текущего вида (для внешних вызовов).
func get_view_center_cell() -> Vector2i:
	return _camera.view_center_cell()


func _on_field_changed() -> void:
	_blocks.sync_from_state()
	_wiring.collect_ports()
	_wiring.rebuild_wires()


func _on_wiring_changed() -> void:
	_wiring.clear_pending()
	_wiring.rebuild_wires()


func _on_placement_finished(type_id: String) -> void:
	placement_mode_changed.emit(type_id)
