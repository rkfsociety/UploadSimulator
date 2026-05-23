extends RefCounted
class_name FieldMapBlocks
## Визуальные узлы модулей на MapViewport.

var _blocks_root: Control
var _nodes: Dictionary = {}


func _init(blocks_root: Control) -> void:
	_blocks_root = blocks_root


func get_nodes() -> Dictionary:
	return _nodes


func sync_from_state() -> void:
	for uid in _nodes.keys():
		if not GameState.field.get_instance(uid).is_valid():
			(_nodes[uid] as PlacedBlock).queue_free()
			_nodes.erase(uid)
	for inst: BlockInstance in GameState.access.get_placed_blocks():
		if not _nodes.has(inst.uid):
			spawn(inst.uid)
		else:
			(_nodes[inst.uid] as PlacedBlock).refresh()
	_relayout()


func spawn(uid: String) -> void:
	if _nodes.has(uid):
		(_nodes[uid] as PlacedBlock).refresh()
		return
	var inst := GameState.field.get_instance(uid)
	if not inst.is_valid():
		return
	var block := PlacedBlock.instantiate_block()
	var sz := PlacedBlock.pixel_size()
	block.custom_minimum_size = sz
	block.size = sz
	block.position = GridDefs.cell_to_pixel(inst.gx, inst.gy)
	block.upgrade_requested.connect(_on_upgrade_requested)
	block.action_requested.connect(_on_block_action)
	_blocks_root.add_child(block)
	block.setup(uid, inst.type_id)
	_nodes[uid] = block
	block.visible = true
	block.process_mode = Node.PROCESS_MODE_INHERIT


func refresh_all() -> void:
	for uid in _nodes.keys():
		var block: PlacedBlock = _nodes[uid] as PlacedBlock
		if block != null and is_instance_valid(block):
			block.refresh()


## Обновляет только указанные модули (прогресс очереди без обхода всей карты).
func refresh_uids(uids: Array) -> void:
	for uid in uids:
		var block: PlacedBlock = get_block(str(uid))
		if block != null and is_instance_valid(block):
			block.refresh()


func get_block(uid: String) -> PlacedBlock:
	return _nodes.get(uid, null) as PlacedBlock


func _relayout() -> void:
	var sz := PlacedBlock.pixel_size()
	for uid in _nodes.keys():
		var block: PlacedBlock = _nodes[uid]
		var inst := GameState.field.get_instance(uid)
		if not inst.is_valid():
			continue
		block.custom_minimum_size = sz
		block.size = sz
		block.position = GridDefs.cell_to_pixel(inst.gx, inst.gy)


## Скрывает блоки вне вида и отключает для них _process.
func update_visibility(visible_rect: Rect2) -> void:
	for uid in _nodes.keys():
		var block: PlacedBlock = _nodes[uid] as PlacedBlock
		var block_rect := Rect2(block.position, block.size)
		var show := visible_rect.intersects(block_rect)
		if block.visible == show:
			continue
		block.visible = show
		block.process_mode = (
			Node.PROCESS_MODE_INHERIT if show else Node.PROCESS_MODE_DISABLED
		)


func _on_upgrade_requested(block: PlacedBlock) -> void:
	GameState.report_operation(GameState.field.upgrade_instance(block.instance_uid))


func _on_block_action(block: PlacedBlock) -> void:
	GameState.report_operation(GameState.pipeline.run_block_action(block.instance_uid))
