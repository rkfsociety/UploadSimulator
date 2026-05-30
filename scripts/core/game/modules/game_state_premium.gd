extends RefCounted
class_name GameStatePremium
## Публичный API премиум-валюты (◆) для UI и отладки.


var _svc: PremiumCurrencyService


func _init(svc: PremiumCurrencyService) -> void:
	_svc = svc


func get_balance() -> int:
	return _svc.get_balance()


func can_afford(cost: int) -> bool:
	return _svc.can_afford(cost)


func try_collect_at_world(world_pos: Vector2, radius: float = FieldMapConstants.DIAMOND_PICKUP_HIT_RADIUS) -> int:
	return _svc.try_collect_pickup_at(world_pos, radius)
