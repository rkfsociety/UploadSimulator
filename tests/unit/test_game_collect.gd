extends RefCounted
## Сбор денег: сейф аплоудера → касса через коллектор.

var case_count := 1


func run() -> Array[String]:
	var errors: Array[String] = []
	var data := GameStateData.new()
	data.set_uploader_balance(100.0)
	data.set_money(50.0)
	var bonus := GameBonus.effect_at_level("collector", 1)
	var payout := 100.0 * (1.0 + bonus)
	data.set_uploader_balance(0.0)
	data.add_money(payout)
	if not is_equal_approx(data.get_uploader_balance(), 0.0):
		errors.append("после сбора сейф аплоудера должен быть 0")
	if not is_equal_approx(data.get_money(), 50.0 + payout):
		errors.append("касса должна увеличиться на payout с бонусом коллектора")
	return errors
