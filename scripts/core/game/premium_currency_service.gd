extends RefCounted
class_name PremiumCurrencyService
## Единая точка заработка и трат алмазов (отдельно от кассы $ и сейфа аплоудера).

enum Source {
	UPLOAD, ## за выгрузку файла
	QUEST, ## будущие квесты и награды
	ADMIN, ## отладка / читы
}

var _wallet: PremiumWallet
var _host: Node


func _init(host: Node, start_balance: int = GameConstants.START_DIAMONDS) -> void:
	_host = host
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


## Награда за успешную выгрузку (см. GameConstants.DIAMONDS_PER_UPLOAD).
func grant_upload_reward() -> int:
	return grant(GameConstants.DIAMONDS_PER_UPLOAD, Source.UPLOAD)


func export_save_dict() -> Dictionary:
	return {"diamonds": get_balance()}


func import_save_dict(payload: Dictionary) -> void:
	_wallet.set_balance(int(payload.get("diamonds", GameConstants.START_DIAMONDS)))
