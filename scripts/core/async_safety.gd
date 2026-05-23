extends RefCounted
## Проверки валидности узлов и дерева сцены после await (подключать через preload).


## Узел не освобождён и не стоит в очереди на удаление.
static func is_node_alive(node: Node) -> bool:
	return node != null and is_instance_valid(node) and not node.is_queued_for_deletion()


## Узел жив и всё ещё в дереве сцены (можно вызывать методы UI/сцены).
static func is_node_in_scene(node: Node) -> bool:
	return is_node_alive(node) and node.is_inside_tree()


## SceneTree пригоден после await (выход из игры, смена главного цикла).
static func is_scene_tree_alive(tree: SceneTree) -> bool:
	return tree != null and is_instance_valid(tree)
