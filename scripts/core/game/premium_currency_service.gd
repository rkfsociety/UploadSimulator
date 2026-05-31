extends RefCounted
class_name PremiumCurrencyService
## Единая точка заработка и трат алмазов (отдельно от кассы $ и сейфа аплоудера).

enum Source {
	UPLOAD,  ## за выгрузку файла
	QUEST,  ## будущие квесты и награды
	ADMIN,  ## отладка / читы
}

var _wallet: PremiumWallet
var _data: GameStateData
var _host: Node


func _init(
	host: Node, data: GameStateData, start_balance: int = GameConstants.START_DIAMONDS
) -> void:
	_host = host
	_data = data
	_wallet = PremiumWallet.new(start_balance)


func get_balance() -> int:
	return _wallet.get_balance()


## Сброс к стартовому балансу алмазов (новая игра). Без эмита — хост уведомит после reset.
func reset() -> void:
	_wallet.set_balance(GameConstants.START_DIAMONDS)


func can_afford(cost: int) -> bool:
	return _wallet.can_afford(cost)


func try_spend(cost: int) -> bool:
	if not _wallet.try_spend(cost):
		return false
	_host.stats_changed.emit()
	return true


func grant(amount: int, _source: Source = Source.ADMIN) -> int:
	if amount <= 0:
		return 0
	_wallet.grant(amount)
	_host.stats_changed.emit()
	return amount


## Кристал ◆ на карте после выгрузки (баланс не меняется до сбора).
func spawn_upload_pickup(world_pos: Vector2) -> int:
	var amount := GameConstants.DIAMONDS_PER_UPLOAD
	if amount <= 0:
		return 0
	if _data.add_diamond_pickup(world_pos, amount) == "":
		return 0
	if _host.has_signal("diamond_pickups_changed"):
		_host.diamond_pickups_changed.emit()
	return amount


## Сбор кристалла по координатам карты; возвращает начисленное количество ◆.
func try_collect_pickup_at(world_pos: Vector2, radius: float) -> int:
	var uid := _data.find_diamond_pickup_at(world_pos, radius)
	if uid == "":
		return 0
	var amount := _data.take_diamond_pickup(uid)
	if amount <= 0:
		return 0
	grant(amount, Source.UPLOAD)
	if _host.has_signal("diamond_pickups_changed"):
		_host.diamond_pickups_changed.emit()
	_host.log_message.emit("Собрано ◆%d" % amount)
	return amount


func export_save_dict() -> Dictionary:
	return {"diamonds": get_balance()}


func import_save_dict(payload: Dictionary) -> void:
	_wallet.set_balance(int(payload.get("diamonds", GameConstants.START_DIAMONDS)))
