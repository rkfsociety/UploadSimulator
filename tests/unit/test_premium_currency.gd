extends RefCounted
## Unit-тесты изолированной премиум-валюты (◆).


var case_count := 4


func run() -> Array[String]:
	var errors: Array[String] = []
	var host := _TestHost.new()
	var premium := PremiumCurrencyService.new(host, GameConstants.START_DIAMONDS)

	if premium.get_balance() != GameConstants.START_DIAMONDS:
		errors.append(
			"стартовый баланс ◆ должен быть %d, получено %d"
			% [GameConstants.START_DIAMONDS, premium.get_balance()]
		)

	var granted := premium.grant_upload_reward()
	if granted != GameConstants.DIAMONDS_PER_UPLOAD:
		errors.append("grant_upload_reward должен вернуть %d" % GameConstants.DIAMONDS_PER_UPLOAD)
	var expected_after_grant := GameConstants.START_DIAMONDS + GameConstants.DIAMONDS_PER_UPLOAD
	if premium.get_balance() != expected_after_grant:
		errors.append("после награды за выгрузку баланс ◆ должен быть %d" % expected_after_grant)

	if not premium.try_spend(1):
		errors.append("try_spend(1) должен пройти при достаточном балансе")
	if premium.get_balance() != expected_after_grant - 1:
		errors.append("баланс ◆ после списания 1")

	if premium.try_spend(999_999):
		errors.append("try_spend на большую сумму должен вернуть false")

	var payload := premium.export_save_dict()
	payload["diamonds"] = 42
	premium.import_save_dict(payload)
	if premium.get_balance() != 42:
		errors.append("import_save_dict должен восстановить баланс 42")

	host.free()
	return errors


class _TestHost:
	extends Node

	signal stats_changed
