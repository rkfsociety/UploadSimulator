extends RefCounted
## Unit-тесты стартового состояния GameStateData.

var case_count := 1


func run() -> Array[String]:
	var errors: Array[String] = []
	var expected := float(BlockDefs.starter_kit_cost())
	var data := GameStateData.new()
	if data.get_money() != expected:
		errors.append("стартовая касса должна быть %.0f, получено %.0f" % [expected, data.get_money()])
	return errors
