extends RefCounted
class_name GameStateField
## Поле: модули, склад, покупка, улучшения.

var _svc: GameFieldService


func _init(svc: GameFieldService) -> void:
	_svc = svc


func make_uid() -> String:
	return _svc.make_uid()


func get_instance(uid: String) -> BlockInstance:
	return _svc.get_instance(uid)


func get_instance_level(uid: String) -> int:
	return _svc.get_instance_level(uid)


func get_instance_type(uid: String) -> String:
	return _svc.get_instance_type(uid)


func has_block_on_field(type_id: String) -> bool:
	return _svc.has_block_on_field(type_id)


func get_block_stock(type_id: String) -> int:
	return _svc.get_block_stock(type_id)


func can_buy_block(type_id: String) -> bool:
	return _svc.can_buy_block(type_id)


func check_buy_block(type_id: String) -> GameOperationResult:
	return _svc.check_buy_block(type_id)


func buy_block(type_id: String) -> GameOperationResult:
	return _svc.buy_block(type_id)


func can_place_block(type_id: String, gx: int, gy: int) -> bool:
	return _svc.can_place_block(type_id, gx, gy)


func check_place_block(type_id: String, gx: int, gy: int) -> GameOperationResult:
	return _svc.check_place_block(type_id, gx, gy)


func place_block(type_id: String, gx: int, gy: int) -> GameOperationResult:
	return _svc.place_block(type_id, gx, gy)


func get_block_at(gx: int, gy: int) -> BlockInstance:
	return _svc.get_block_at(gx, gy)


func can_relocate_block(uid: String, gx: int, gy: int) -> bool:
	return _svc.can_relocate_block(uid, gx, gy)


func check_relocate_block(uid: String, gx: int, gy: int) -> GameOperationResult:
	return _svc.check_relocate_block(uid, gx, gy)


func relocate_block(uid: String, gx: int, gy: int) -> GameOperationResult:
	return _svc.relocate_block(uid, gx, gy)


func can_remove_block(uid: String) -> bool:
	return _svc.can_remove_block(uid)


func check_remove_block(uid: String) -> GameOperationResult:
	return _svc.check_remove_block(uid)


func remove_block(uid: String) -> GameOperationResult:
	return _svc.remove_block(uid)


func get_block_sell_value(uid: String) -> int:
	return _svc.get_block_sell_value(uid)


func sell_block(uid: String) -> GameOperationResult:
	return _svc.sell_block(uid)


func get_instance_upgrade_cost(uid: String) -> int:
	return _svc.get_instance_upgrade_cost(uid)


func can_upgrade_instance(uid: String) -> bool:
	return _svc.can_upgrade_instance(uid)


func check_upgrade_instance(uid: String) -> GameOperationResult:
	return _svc.check_upgrade_instance(uid)


func upgrade_instance(uid: String) -> GameOperationResult:
	return _svc.upgrade_instance(uid)


func get_shop_block_types() -> Array[String]:
	return _svc.get_shop_block_types()
