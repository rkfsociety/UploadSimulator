extends RefCounted
class_name GameEnvironmentService
## Улучшения и открытие новых типов модулей за алмазы.

var _data: GameStateData
var _host: Node
var _premium: PremiumCurrencyService


func _init(data: GameStateData, host: Node, premium: PremiumCurrencyService) -> void:
	_data = data
	_host = host
	_premium = premium


func get_upgrade_level(upgrade_id: String) -> int:
	return _data.get_env_upgrade_level(upgrade_id)


func diamond_cost(upgrade_id: String) -> int:
	return EnvironmentUpgradeDefs.diamond_cost_for_level(upgrade_id, get_upgrade_level(upgrade_id))


func can_buy_upgrade(upgrade_id: String) -> bool:
	return check_buy_upgrade(upgrade_id).is_ok()


func check_buy_upgrade(upgrade_id: String) -> GameOperationResult:
	if not EnvironmentUpgradeDefs.UPGRADES.has(upgrade_id):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_UNKNOWN_UPGRADE)
	if EnvironmentUpgradeDefs.is_max_level(upgrade_id, get_upgrade_level(upgrade_id)):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_MAX_LEVEL)
	if not _premium.can_afford(diamond_cost(upgrade_id)):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_INSUFFICIENT_DIAMONDS)
	return GameOperationResult.ok()


func buy_upgrade(upgrade_id: String) -> GameOperationResult:
	var check := check_buy_upgrade(upgrade_id)
	if not check.is_ok():
		return check
	var cost := diamond_cost(upgrade_id)
	if not _premium.try_spend(cost):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_INSUFFICIENT_DIAMONDS)
	var lvl := get_upgrade_level(upgrade_id) + 1
	_data.set_env_upgrade_level(upgrade_id, lvl)
	var name: String = EnvironmentUpgradeDefs.UPGRADES[upgrade_id].get("name", upgrade_id)
	_host.log_message.emit("%s: ур. %d (◆ −%d)" % [name, lvl, cost])
	_host.stats_changed.emit()
	return GameOperationResult.ok()


func is_module_unlocked(type_id: String) -> bool:
	return _data.is_module_type_unlocked(type_id)


func module_unlock_diamond_cost(type_id: String) -> int:
	return BlockDefs.diamond_unlock_cost(type_id)


func can_unlock_module(type_id: String) -> bool:
	return check_unlock_module(type_id).is_ok()


func check_unlock_module(type_id: String) -> GameOperationResult:
	if not BlockDefs.requires_diamond_unlock(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_NOT_LOCKABLE)
	if is_module_unlocked(type_id):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_ALREADY_UNLOCKED)
	if not _premium.can_afford(module_unlock_diamond_cost(type_id)):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_INSUFFICIENT_DIAMONDS)
	return GameOperationResult.ok()


func unlock_module(type_id: String) -> GameOperationResult:
	var check := check_unlock_module(type_id)
	if not check.is_ok():
		return check
	var cost := module_unlock_diamond_cost(type_id)
	if not _premium.try_spend(cost):
		return GameOperationResult.fail(GameOperationResult.Code.ENV_INSUFFICIENT_DIAMONDS)
	_data.unlock_module_type(type_id)
	var name: String = BlockDefs.TYPES.get(type_id, {}).get("name", type_id)
	_host.log_message.emit("Открыт модуль «%s» — теперь в магазине за $ (◆ −%d)" % [name, cost])
	_host.stats_changed.emit()
	return GameOperationResult.ok()


func get_lockable_module_type_ids() -> Array[String]:
	var ids: Array[String] = []
	for type_id in BlockDefs.get_diamond_lockable_type_ids():
		if not is_module_unlocked(type_id):
			ids.append(type_id)
	return ids
