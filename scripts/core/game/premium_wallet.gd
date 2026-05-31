extends RefCounted
class_name PremiumWallet
## Хранилище баланса ◆: только число, без правил заработка и покупок.

var _balance: int = 0


func _init(start_balance: int = 0) -> void:
	_balance = GameValueBounds.diamonds(start_balance)


func get_balance() -> int:
	return _balance


func can_afford(cost: int) -> bool:
	return cost > 0 and _balance >= cost


## Списание; вызывается только из PremiumCurrencyService.
func try_spend(cost: int) -> bool:
	var spend := GameValueBounds.diamond_delta(cost)
	if not can_afford(spend):
		return false
	_balance -= spend
	return true


## Начисление; вызывается только из PremiumCurrencyService.
func grant(amount: int) -> void:
	var delta := GameValueBounds.diamond_delta(amount)
	if delta <= 0:
		return
	_balance += delta


## Восстановление баланса из сохранения.
func set_balance(value: int) -> void:
	_balance = GameValueBounds.diamonds(value)
