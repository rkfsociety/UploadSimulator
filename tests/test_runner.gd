extends SceneTree
## Headless-раннер unit-тестов: godot --headless -s res://tests/test_runner.gd

const _SUITES: Array[Script] = [
	preload("res://tests/unit/test_game_bonus.gd"),
	preload("res://tests/unit/test_block_defs.gd"),
	preload("res://tests/unit/test_game_state_data.gd"),
	preload("res://tests/unit/test_game_models.gd"),
	preload("res://tests/unit/test_game_wiring.gd"),
	preload("res://tests/unit/test_game_collect.gd"),
	preload("res://tests/unit/test_file_size.gd"),
	preload("res://tests/unit/test_file_types.gd"),
	preload("res://tests/unit/test_module_unlock.gd"),
	preload("res://tests/unit/test_field_relocate.gd"),
]


func _init() -> void:
	var failed := 0
	var passed := 0
	for suite_script: Script in _SUITES:
		var suite: RefCounted = suite_script.new() as RefCounted
		if suite == null or not suite.has_method("run"):
			push_error("Некорректный тестовый набор: %s" % suite_script.resource_path)
			failed += 1
			continue
		var errors: Array = suite.run()
		for err: Variant in errors:
			push_error(str(err))
			failed += 1
		var case_count: int = suite.get("case_count") if suite.get("case_count") != null else 0
		if case_count > 0:
			passed += case_count - errors.size()
		else:
			passed += 1 if errors.is_empty() else 0
	print("Tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
