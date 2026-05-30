extends RefCounted
class_name GameFieldService
## Поле: модули, склад, покупка, улучшения.

var _data: GameStateData
var _host: Node
var _wiring: GameWiringService = null


func _init(data: GameStateData, host: Node) -> void:
	_data = data
	_host = host


func bind_wiring(wiring: GameWiringService) -> void:
	_wiring = wiring


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


func owned_singleton_count(type_id: String) -> int:
	var count := _data.get_block_stock(type_id)
	if has_block_on_field(type_id):
		count += 1
	return count


func check_singleton_limit(type_id: String) -> GameOperationResult:
	if not BlockDefs.is_singleton_type(type_id):
		return GameOperationResult.ok()
	if owned_singleton_count(type_id) <= 0:
		return GameOperationResult.ok()
	var block_name: String = BlockDefs.TYPES.get(type_id, {}).get("name", type_id)
	return GameOperationResult.fail(
		GameOperationResult.Code.FIELD_SINGLETON_LIMIT,
		"«%s» может быть только один — снимите с поля или поставьте со склада."
		% block_name,
	)


func get_block_stock(type_id: String) -> int:
	return _data.get_block_stock(type_id)


func can_buy_block(type_id: String) -> bool:
	return check_buy_block(type_id).is_ok()


func check_buy_block(type_id: String) -> GameOperationResult:
	if not BlockDefs.TYPES.has(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_MODULE)
	var singleton := check_singleton_limit(type_id)
	if not singleton.is_ok():
		return singleton
	if not _data.is_module_type_unlocked(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_MODULE_LOCKED)
	if _data.get_money() < float(BlockDefs.TYPES[type_id]["shop_cost"]):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INSUFFICIENT_MONEY)
	return GameOperationResult.ok()


func buy_block(type_id: String) -> GameOperationResult:
	var check := check_buy_block(type_id)
	if not check.is_ok():
		return check
	var cost: float = float(BlockDefs.TYPES[type_id]["shop_cost"])
	_data.try_spend_money(cost)
	_data.add_block_stock(type_id, 1)
	_host.log_message.emit("Куплен «%s»." % BlockDefs.TYPES[type_id]["name"])
	_host.block_purchased.emit(type_id)
	_notify_stats_and_field()
	return GameOperationResult.ok()


func can_place_block(type_id: String, gx: int, gy: int) -> bool:
	return check_place_block(type_id, gx, gy).is_ok()


func check_place_block(type_id: String, gx: int, gy: int) -> GameOperationResult:
	if not BlockDefs.TYPES.has(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_MODULE)
	if BlockDefs.is_singleton_type(type_id) and has_block_on_field(type_id):
		return check_singleton_limit(type_id)
	if not _data.is_module_type_unlocked(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_MODULE_LOCKED)
	if _data.get_block_stock(type_id) <= 0:
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_NO_STOCK)
	if not GridDefs.footprint_in_bounds(gx, gy, type_id):
		return GameOperationResult.fail(
			GameOperationResult.Code.FIELD_OUT_OF_BOUNDS,
			"За пределами карты (%d…%d)."
			% [-GridDefs.GRID_HALF, GridDefs.GRID_HALF - 1]
		)
	for cell in GridDefs.block_footprint_cells(gx, gy, type_id):
		if get_block_at(cell.x, cell.y).is_valid():
			return GameOperationResult.fail(GameOperationResult.Code.FIELD_CELL_OCCUPIED)
	return GameOperationResult.ok()


func get_block_at(gx: int, gy: int) -> BlockInstance:
	for inst: BlockInstance in _data.get_placed_blocks():
		var c := GridDefs.block_cells(inst.type_id)
		if (
			gx >= inst.gx
			and gx < inst.gx + c.x
			and gy >= inst.gy
			and gy < inst.gy + c.y
		):
			return inst
	return BlockInstance.new()


func can_relocate_block(uid: String, gx: int, gy: int) -> bool:
	return check_relocate_block(uid, gx, gy).is_ok()


func check_relocate_block(uid: String, gx: int, gy: int) -> GameOperationResult:
	var inst := get_instance(uid)
	if not inst.is_valid():
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_INSTANCE)
	if not GridDefs.footprint_in_bounds(gx, gy, inst.type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_OUT_OF_BOUNDS)
	for cell in GridDefs.block_footprint_cells(gx, gy, inst.type_id):
		var other := get_block_at(cell.x, cell.y)
		if other.is_valid() and other.uid != uid:
			return GameOperationResult.fail(GameOperationResult.Code.FIELD_CELL_OCCUPIED)
	return GameOperationResult.ok()


func relocate_block(uid: String, gx: int, gy: int) -> GameOperationResult:
	var check := check_relocate_block(uid, gx, gy)
	if not check.is_ok():
		return check
	var inst := get_instance(uid)
	if inst.gx == gx and inst.gy == gy:
		return GameOperationResult.ok()
	inst.gx = gx
	inst.gy = gy
	_replace_instance(inst)
	_notify_stats_and_field()
	return GameOperationResult.ok()


func place_block(type_id: String, gx: int, gy: int) -> GameOperationResult:
	var check := check_place_block(type_id, gx, gy)
	if not check.is_ok():
		return check
	_data.add_block_stock(type_id, -1)
	var inst := BlockInstance.create(type_id, gx, gy, _data.next_uid(), 1)
	_data.get_placed_blocks().append(inst)
	_host.log_message.emit("%s установлен на поле." % BlockDefs.TYPES[type_id]["name"])
	_notify_stats_and_field()
	return GameOperationResult.ok(inst.uid)


func get_instance_upgrade_cost(uid: String) -> int:
	var inst := get_instance(uid)
	if not inst.is_valid():
		return 0
	return GameBonus.upgrade_cost(inst.type_id, inst.level)


func can_upgrade_instance(uid: String) -> bool:
	return check_upgrade_instance(uid).is_ok()


func check_upgrade_instance(uid: String) -> GameOperationResult:
	var inst := get_instance(uid)
	if not inst.is_valid():
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_INSTANCE)
	if not BlockDefs.is_upgradeable(inst.type_id):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_MODULE, "Улучшение недоступно.")
	if _data.get_money() < float(get_instance_upgrade_cost(uid)):
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INSUFFICIENT_MONEY)
	return GameOperationResult.ok()


func upgrade_instance(uid: String) -> GameOperationResult:
	var check := check_upgrade_instance(uid)
	if not check.is_ok():
		return check
	var inst := get_instance(uid)
	var cost := get_instance_upgrade_cost(uid)
	_data.try_spend_money(float(cost))
	inst.level += 1
	_replace_instance(inst)
	var block_name: String = BlockDefs.TYPES.get(inst.type_id, {}).get("name", "")
	_host.log_message.emit("%s улучшен до ур. %d" % [block_name, inst.level])
	_notify_stats_and_field()
	return GameOperationResult.ok()


func can_remove_block(uid: String) -> bool:
	return check_remove_block(uid).is_ok()


func check_remove_block(uid: String) -> GameOperationResult:
	var inst := get_instance(uid)
	if not inst.is_valid():
		return GameOperationResult.fail(GameOperationResult.Code.FIELD_INVALID_INSTANCE)
	if _data.get_phase() == GameStateData.Phase.SETTLING:
		return GameOperationResult.fail(GameOperationResult.Code.PIPELINE_PHASE_BUSY)
	return GameOperationResult.ok()


func remove_block(uid: String) -> GameOperationResult:
	var check := check_remove_block(uid)
	if not check.is_ok():
		return check
	var inst := get_instance(uid)
	var type_id := inst.type_id
	if _wiring != null:
		_wiring.disconnect_all_for_module(uid)
	_data.purge_module_activity(uid)
	var blocks := _data.get_placed_blocks()
	for i in range(blocks.size() - 1, -1, -1):
		if blocks[i].uid == uid:
			blocks.remove_at(i)
			break
	_data.add_block_stock(type_id, 1)
	var block_name: String = BlockDefs.TYPES.get(type_id, {}).get("name", type_id)
	_host.log_message.emit("«%s» снят с поля — снова в складе." % block_name)
	if _host.has_signal("wire_transfers_changed"):
		_host.wire_transfers_changed.emit()
	_notify_stats_and_field()
	return GameOperationResult.ok()


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
