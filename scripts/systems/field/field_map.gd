extends Control
## Поле карты (лимит 100×100 клеток). Оркестратор: камера, блоки, провода, установка, ввод.

const _BlockDragClass := preload("res://scripts/systems/field/field_map_block_drag.gd")
const _AsyncSafety := preload("res://scripts/core/async_safety.gd")

signal placement_mode_changed(type_id: String)

@onready var map_viewport: Control = $MapViewport
@onready var map_content: Control = $MapViewport/MapContent
@onready var grid_draw: Control = $MapViewport/MapContent/GridDraw
@onready var wires_root: Control = $MapViewport/MapContent/WiresRoot
@onready var blocks_root: Control = $MapViewport/MapContent/BlocksRoot

var _camera: FieldMapCamera
var _blocks: FieldMapBlocks
var _placement: FieldMapPlacement
var _wiring: FieldMapWiring
var _map_input: FieldMapInput
var _block_drag: RefCounted


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# MapViewport — клип на весь экран; pan/zoom только у MapContent (мир 0,0 в центр вида)
	map_viewport.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_viewport.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_viewport.clip_contents = true
	map_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for node in [wires_root, blocks_root]:
		node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Провода поверх блоков, чтобы линии были видны между портами
	wires_root.z_index = FieldMapConstants.WIRES_Z_INDEX
	_camera = FieldMapCamera.new(self, map_content)
	_blocks = FieldMapBlocks.new(blocks_root)
	_placement = FieldMapPlacement.new(map_content, _camera)
	_wiring = FieldMapWiring.new(self, wires_root, _blocks)
	_block_drag = _BlockDragClass.new(map_content, _camera, _blocks, _placement)
	_map_input = FieldMapInput.new(self, _camera, _placement, _wiring, _block_drag)
	_map_input.placement_finished.connect(_on_placement_finished)

	GameState.field_changed.connect(_on_field_changed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	GameState.queue_changed.connect(_on_blocks_refresh)
	GameState.blocks_progress_changed.connect(_on_blocks_progress)

	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	# Карта могла сняться с дерева за кадр ожидания
	if not _AsyncSafety.is_node_in_scene(self):
		return
	_camera.focus_world(GridDefs.world_center_pixel())
	_on_field_changed()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_camera.apply()


func _process(_delta: float) -> void:
	if _map_input != null:
		_map_input.process_frame(self)
	# Сетка — только при сдвиге/зуме камеры, не каждый кадр
	if _camera.consume_view_dirty() and grid_draw.has_method("sync_view"):
		grid_draw.sync_view()
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


## После покупки: автопостановка или режим «тап по карте».
func start_placement_after_buy(type_id: String) -> void:
	place_at_view_center(type_id)


## Ставит модуль в центр текущего вида; ищет свободную клетку вокруг якоря.
func place_at_view_center(type_id: String) -> bool:
	if GameState.field.get_block_stock(type_id) <= 0:
		return false
	_block_drag.clear_selection()
	if _placement.place_at_view_center(type_id, _blocks.spawn):
		cancel_placement_mode()
		_sync_field_visual()
		return true
	enter_placement_mode(type_id)
	return false


func _sync_field_visual() -> void:
	_blocks.sync_from_state()
	_block_drag.sync_selection_visual()
	_wiring.collect_ports()
	_wiring.update_positions()


## Включает режим ручной установки выбранного типа модуля.
func enter_placement_mode(type_id: String) -> void:
	_block_drag.clear_selection()
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
	if _block_drag.is_dragging():
		_block_drag.cancel_drag()
	var prev_uids: Array = _blocks.get_nodes().keys()
	_blocks.sync_from_state()
	var curr_uids: Array = _blocks.get_nodes().keys()
	# Порты и провода — только при изменении набора/раскладки блоков.
	# rebuild_wires (а не update_positions): после загрузки сейва сегментов ещё нет,
	# их надо собрать заново из восстановленных соединений GameState.
	if _blocks_layout_changed(prev_uids, curr_uids):
		_wiring.collect_ports()
		_wiring.rebuild_wires()
	_block_drag.sync_selection_visual()


func _on_blocks_refresh() -> void:
	_blocks.refresh_all()


func _on_blocks_progress() -> void:
	_blocks.refresh_uids(GameState.display.get_progress_block_uids())


func _on_wiring_changed() -> void:
	_wiring.clear_pending()
	_wiring.rebuild_wires()


## Сравнивает uid и позиции блоков до/после sync_from_state.
func _blocks_layout_changed(prev_uids: Array, curr_uids: Array) -> bool:
	if prev_uids.size() != curr_uids.size():
		return true
	for uid in curr_uids:
		if uid not in prev_uids:
			return true
	for uid in curr_uids:
		var inst := GameState.field.get_instance(str(uid))
		if not inst.is_valid():
			continue
		var block: PlacedBlock = _blocks.get_nodes()[uid] as PlacedBlock
		if block.position != GridDefs.cell_to_pixel(inst.gx, inst.gy):
			return true
	return false


func _on_placement_finished(type_id: String) -> void:
	placement_mode_changed.emit(type_id)
