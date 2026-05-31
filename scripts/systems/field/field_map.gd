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
var _diamonds: FieldMapDiamonds
var _map_input: FieldMapInput
var _block_drag: RefCounted
var _block_menu: FieldMapBlockMenu


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
	var diamonds_root := Control.new()
	diamonds_root.name = "DiamondsRoot"
	diamonds_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	diamonds_root.z_index = FieldMapConstants.DIAMONDS_Z_INDEX
	map_content.add_child(diamonds_root)
	_diamonds = FieldMapDiamonds.new(diamonds_root, _camera)
	_block_drag = _BlockDragClass.new(map_content, _camera, _blocks, _placement)
	var ui_layer := get_parent().get_node_or_null("UILayer") as Control
	if ui_layer != null:
		_block_menu = FieldMapBlockMenu.new(self, _camera)
		MinimalUI.attach_theme(_block_menu)
		ui_layer.add_child(_block_menu)
		_block_drag.selection_changed.connect(_on_block_selection_changed)
		_block_menu.sell_requested.connect(_on_block_sell_requested)
	_map_input = FieldMapInput.new(self, _camera, _placement, _wiring, _block_drag, _diamonds)
	if _block_menu != null:
		_map_input.set_block_menu(_block_menu)
	_map_input.placement_finished.connect(_on_placement_finished)

	GameState.field_changed.connect(_on_field_changed)
	GameState.diamond_pickups_changed.connect(_on_diamond_pickups_changed)
	GameState.wiring_changed.connect(_on_wiring_changed)
	GameState.queue_changed.connect(_on_blocks_refresh)
	GameState.blocks_progress_changed.connect(_on_blocks_progress)
	GameState.wire_transfers_changed.connect(_on_wire_transfers_changed)

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
	_diamonds.update_visibility(vis)
	if _block_menu != null and _block_menu.is_open():
		_block_menu.refresh_position()


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
	_diamonds.sync_from_state()
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
	_block_drag.clear_selection()
	placement_mode_changed.emit("")


func _on_block_selection_changed(uid: String) -> void:
	if _block_menu == null:
		return
	if uid == "":
		_block_menu.hide_menu()
	else:
		_block_menu.show_for(uid)


func _on_block_sell_requested(uid: String) -> void:
	_block_drag.clear_selection()
	if _block_menu != null:
		_block_menu.hide_menu()
	GameState.report_operation(GameState.field.sell_block(uid))


## Клетка сетки в центре текущего вида (для внешних вызовов).
func get_view_center_cell() -> Vector2i:
	return _camera.view_center_cell()


func _on_field_changed() -> void:
	# Перенос модуля — не прерываем: relocate сбрасывает drag до emit field_changed.
	if _block_drag.is_dragging():
		return
	# Снимок раскладки ДО пересборки: sync_from_state переставит узлы, поэтому
	# сравнивать позиции после неё бесполезно (они уже совпадут с целевыми).
	var prev_layout := _capture_block_layout()
	_blocks.sync_from_state()
	_diamonds.sync_from_state()
	# Порты и провода — только при изменении набора/раскладки блоков.
	# rebuild_wires (а не update_positions): после загрузки сейва сегментов ещё нет,
	# их надо собрать заново из восстановленных соединений GameState.
	if _block_layout_changed(prev_layout):
		_wiring.collect_ports()
		_wiring.rebuild_wires()
		# Свежезаспавненные блоки раскладывают порты не сразу — уточняем концы проводов кадром позже
		_refresh_wire_positions_deferred()
	_block_drag.sync_selection_visual()


func _on_diamond_pickups_changed() -> void:
	_diamonds.sync_from_state()


## Пересчёт координат проводов после того, как контейнеры портов разложились (следующий кадр).
func _refresh_wire_positions_deferred() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.process_frame
	if not _AsyncSafety.is_node_in_scene(self):
		return
	_wiring.update_positions()


func _on_blocks_refresh() -> void:
	_blocks.refresh_all()


func _on_blocks_progress() -> void:
	_blocks.refresh_uids(GameState.display.get_progress_block_uids())
	_wiring.refresh_tokens()


func _on_wire_transfers_changed() -> void:
	_blocks.refresh_uids(GameState.display.get_progress_block_uids())
	_wiring.refresh_tokens()


func _on_wiring_changed() -> void:
	_wiring.clear_pending()
	_wiring.rebuild_wires()


## Снимок раскладки: uid → позиция узла (до пересборки блоков).
func _capture_block_layout() -> Dictionary:
	var layout := {}
	for uid in _blocks.get_nodes().keys():
		var block: PlacedBlock = _blocks.get_nodes()[uid] as PlacedBlock
		layout[uid] = block.position
	return layout


## Изменился ли набор или позиции блоков относительно снимка (после sync_from_state).
func _block_layout_changed(prev_layout: Dictionary) -> bool:
	var nodes := _blocks.get_nodes()
	if nodes.size() != prev_layout.size():
		return true
	for uid in nodes.keys():
		if not prev_layout.has(uid):
			return true
		var block: PlacedBlock = nodes[uid] as PlacedBlock
		if block.position != prev_layout[uid]:
			return true
	return false


func _on_placement_finished(type_id: String) -> void:
	placement_mode_changed.emit(type_id)
