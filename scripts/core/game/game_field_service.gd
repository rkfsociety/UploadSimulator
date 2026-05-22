extends RefCounted
class_name GameFieldService
## Поле: модули, склад, покупка, улучшения.

var _data: GameStateData
var _host: Node


func _init(data: GameStateData, host: Node) -> void:
	_data = data
	_host = host


func make_uid() -> String:
	return _data.next_uid()


func get_instance(uid: String) -> BlockInstance:
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.uid == uid:
			return inst
	return BlockInstance.new()


func get_instance_level(uid: String) -> int:
	var inst := get_instance(uid)
	return inst.level if inst.is_valid() else 0


func get_instance_type(uid: String) -> String:
	return get_instance(uid).type_id


func has_block_on_field(type_id: String) -> bool:
	for inst: BlockInstance in _data.get_placed_blocks():
		if inst.type_id == type_id:
			return true
	return false


func get_block_stock(type_id: String) -> int:
	return _data.get_block_stock(type_id)


func can_buy_block(type_id: String) -> bool:
	if not BlockDefs.TYPES.has(type_id):
		return false
	if not _data.is_module_type_unlocked(type_id):
		return false
	return _data.get_money() >= float(BlockDefs.TYPES[type_id]["shop_cost"])


func buy_block(type_id: String) -> bool:
	if not can_buy_block(type_id):
		return false
	var cost: float = float(BlockDefs.TYPES[type_id]["shop_cost"])
	_data.try_spend_money(cost)
	_data.add_block_stock(type_id, 1)
	_host.log_message.emit("Куплен «%s»." % BlockDefs.TYPES[type_id]["name"])
	_host.block_purchased.emit(type_id)
	_notify_stats_and_field()
	return true


func can_place_block(type_id: String, gx: int, gy: int) -> bool:
	if not _data.is_module_type_unlocked(type_id):
		return false
	if _data.get_block_stock(type_id) <= 0:
		return false
	if not GridDefs.footprint_in_bounds(gx, gy):
		return false
	for cell in GridDefs.block_footprint_cells(gx, gy):
		if get_block_at(cell.x, cell.y).is_valid():
			return false
	return true


func get_block_at(gx: int, gy: int) -> BlockInstance:
	for inst: BlockInstance in _data.get_placed_blocks():
		if (
			gx >= inst.gx
			and gx < inst.gx + GridDefs.BLOCK_CELLS_W
			and gy >= inst.gy
			and gy < inst.gy + GridDefs.BLOCK_CELLS_H
		):
			return inst
	return BlockInstance.new()


func place_block(type_id: String, gx: int, gy: int) -> String:
	if not GridDefs.footprint_in_bounds(gx, gy):
		_host.log_message.emit(
			"За пределами карты (%d…%d)." % [-GridDefs.GRID_HALF, GridDefs.GRID_HALF - 1]
		)
		return ""
	if not can_place_block(type_id, gx, gy):
		return ""
	_data.add_block_stock(type_id, -1)
	var inst := BlockInstance.create(type_id, gx, gy, _data.next_uid(), 1)
	_data.get_placed_blocks().append(inst)
	_host.log_message.emit("%s установлен на поле." % BlockDefs.TYPES[type_id]["name"])
	_notify_stats_and_field()
	return inst.uid


func get_instance_upgrade_cost(uid: String) -> int:
	var inst := get_instance(uid)
	if not inst.is_valid():
		return 0
	return GameBonus.upgrade_cost(inst.type_id, inst.level)


func can_upgrade_instance(uid: String) -> bool:
	return (
		get_instance(uid).is_valid() and _data.get_money() >= float(get_instance_upgrade_cost(uid))
	)


func upgrade_instance(uid: String) -> bool:
	if not can_upgrade_instance(uid):
		return false
	var inst := get_instance(uid)
	var cost := get_instance_upgrade_cost(uid)
	_data.try_spend_money(float(cost))
	inst.level += 1
	_replace_instance(inst)
	var block_name: String = BlockDefs.TYPES.get(inst.type_id, {}).get("name", "")
	_host.log_message.emit("%s улучшен до ур. %d" % [block_name, inst.level])
	_notify_stats_and_field()
	return true


func get_shop_block_types() -> Array[String]:
	var keys: Array[String] = []
	for k in BlockDefs.TYPES.keys():
		if _data.is_module_type_unlocked(k):
			keys.append(k)
	keys.sort()
	return keys


func _replace_instance(inst: BlockInstance) -> void:
	var blocks := _data.get_placed_blocks()
	for i in blocks.size():
		if blocks[i].uid == inst.uid:
			blocks[i] = inst
			return


func _notify_stats_and_field() -> void:
	_host.stats_changed.emit()
	_host.field_changed.emit()
