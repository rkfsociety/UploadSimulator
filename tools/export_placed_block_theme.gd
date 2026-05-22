extends SceneTree
## Однократный экспорт темы модуля в .tres (запуск: godot --headless -s tools/export_placed_block_theme.gd).

const _ThemeBuilder = preload("res://scripts/systems/blocks/placed_block_theme.gd")


func _init() -> void:
	var theme: Theme = _ThemeBuilder.build()
	var err := ResourceSaver.save(theme, "res://themes/placed_block_theme.tres")
	if err != OK:
		push_error("Не удалось сохранить тему: %s" % error_string(err))
		quit(1)
		return
	print("Сохранено: res://themes/placed_block_theme.tres")
	quit()
