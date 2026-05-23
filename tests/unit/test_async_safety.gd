extends RefCounted
## Unit-тесты AsyncSafety (проверки после await).

const _AsyncSafety := preload("res://scripts/core/async_safety.gd")

var case_count: int = 0


func run() -> Array:
	var errors: Array = []
	case_count = 0
	_assert(errors, not _AsyncSafety.is_node_alive(null), "null не живой")
	_assert(errors, _AsyncSafety.is_scene_tree_alive(null) == false, "null tree")
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		_assert(errors, _AsyncSafety.is_scene_tree_alive(tree), "текущий SceneTree жив")
		var n := Node.new()
		_assert(errors, not _AsyncSafety.is_node_in_scene(n), "узел вне дерева")
		n.free()
	return errors


func _assert(errors: Array, cond: bool, msg: String) -> void:
	case_count += 1
	if not cond:
		errors.append("AsyncSafety: %s" % msg)
