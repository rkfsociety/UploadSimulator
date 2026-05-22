extends RefCounted
class_name GameEnvironmentService
## Покупка улучшений среды за алмазы.

var _data: GameStateData
var _host: Node


func _init(data: GameStateData, host: Node) -> void:
	_data = data
	_host = host


func get_upgrade_level(upgrade_id: String) -> int:
	return _data.get_env_upgrade_level(upgrade_id)


func diamond_cost(upgrade_id: String) -> int:
	return EnvironmentUpgradeDefs.diamond_cost_for_level(
		upgrade_id, get_upgrade_level(upgrade_id)
	)


func can_buy_upgrade(upgrade_id: String) -> bool:
	if not EnvironmentUpgradeDefs.UPGRADES.has(upgrade_id):
		return false
	if EnvironmentUpgradeDefs.is_max_level(upgrade_id, get_upgrade_level(upgrade_id)):
		return false
	return _data.get_diamonds() >= diamond_cost(upgrade_id)


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	var cost := diamond_cost(upgrade_id)
	_data.try_spend_diamonds(cost)
	var lvl := get_upgrade_level(upgrade_id) + 1
	_data.set_env_upgrade_level(upgrade_id, lvl)
	var name: String = EnvironmentUpgradeDefs.UPGRADES[upgrade_id].get("name", upgrade_id)
	_host.log_message.emit("%s: ур. %d (◆ −%d)" % [name, lvl, cost])
	_host.stats_changed.emit()
	return true
