extends RefCounted
## Unit-тесты границ числовых значений (GameValueBounds, GameStateData).

var case_count := 12


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_money_bounds(errors)
	_test_speed_and_duration(errors)
	_test_state_setters(errors)
	return errors


func _test_money_bounds(errors: Array[String]) -> void:
	if GameValueBounds.money(-50.0) != 0.0:
		errors.append("money: отрицательное → 0")
	if GameValueBounds.money_delta(-10.0) != 0.0:
		errors.append("money_delta: отрицательное → 0")


func _test_speed_and_duration(errors: Array[String]) -> void:
	if GameValueBounds.speed_bps(0.0) < GameValueBounds.MIN_SPEED_BPS:
		errors.append("speed_bps: ноль поднимается до MIN_SPEED_BPS")
	var dur := GameValueBounds.job_duration(0.0)
	if dur < GameConstants.MIN_JOB_DURATION_SEC:
		errors.append("job_duration: слишком мало")
	if dur > GameConstants.MAX_TRANSFER_JOB_DURATION_SEC:
		errors.append("job_duration: слишком много")
	var from_zero_speed := GameValueBounds.job_duration_from_bytes(1000.0, 0.0)
	var expected_zero := GameValueBounds.job_duration(1000.0 / GameValueBounds.MIN_SPEED_BPS)
	if absf(from_zero_speed - expected_zero) > 0.001:
		errors.append("job_duration_from_bytes: нулевая скорость → MIN_SPEED_BPS")
	var huge := GameValueBounds.job_duration(999_999.0)
	if huge != GameConstants.MAX_TRANSFER_JOB_DURATION_SEC:
		errors.append("job_duration: сверхпотолок обрезается")


func _test_state_setters(errors: Array[String]) -> void:
	var data := GameStateData.new()
	var start_money := data.get_money()
	data.set_money(-100.0)
	if data.get_money() != 0.0:
		errors.append("set_money: отрицательное не сохраняется")
	data.set_money(start_money)
	data.add_money(-500.0)
	if data.get_money() != start_money:
		errors.append("add_money: отрицательное начисление игнорируется")
	data.set_uploader_balance(-20.0)
	if data.get_uploader_balance() != 0.0:
		errors.append("set_uploader_balance: отрицательное → 0")
	if data.try_spend_money(-5.0):
		errors.append("try_spend_money: отрицательная сумма отклоняется")
	var wallet := PremiumWallet.new(GameConstants.START_DIAMONDS)
	var start_diamonds := wallet.get_balance()
	wallet.grant(-100)
	if wallet.get_balance() != start_diamonds:
		errors.append("PremiumWallet.grant: отрицательное начисление игнорируется")
	if wallet.try_spend(-1):
		errors.append("PremiumWallet.try_spend: отрицательная сумма отклоняется")
