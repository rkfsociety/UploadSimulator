extends RefCounted
class_name FieldMapDiamonds
## Визуальные кристаллы ◆ на карте и сбор по тапу.


var _root: Control
var _camera: FieldMapCamera
var _nodes: Dictionary = {}


func _init(root: Control, camera: FieldMapCamera) -> void:
	_root = root
	_camera = camera


func sync_from_state() -> void:
	for uid in _nodes.keys():
		if _find_pickup(str(uid)) == null:
			(_nodes[uid] as Control).queue_free()
			_nodes.erase(uid)
	for pickup: DiamondPickup in GameState.access.get_diamond_pickups():
		if not _nodes.has(pickup.uid):
			_spawn(pickup)
	_update_positions()


func try_collect_at_screen(screen_local: Vector2) -> bool:
	var world_pos := _camera.screen_to_world(screen_local)
	var collected := GameState.premium.try_collect_at_world(
		world_pos, FieldMapConstants.DIAMOND_PICKUP_HIT_RADIUS
	)
	return collected


func update_visibility(visible_rect: Rect2) -> void:
	for uid in _nodes.keys():
		var node: Control = _nodes[uid]
		var node_rect := Rect2(node.position, node.size)
		var show := visible_rect.intersects(node_rect)
		if node.visible == show:
			continue
		node.visible = show
		node.process_mode = Node.PROCESS_MODE_INHERIT if show else Node.PROCESS_MODE_DISABLED


func _spawn(pickup: DiamondPickup) -> void:
	var view := DiamondPickupView.new()
	view.name = "Diamond_%s" % pickup.uid
	view.z_index = FieldMapConstants.DIAMONDS_Z_INDEX
	_root.add_child(view)
	view.setup(pickup.uid, pickup.world_pos, pickup.amount)
	_nodes[pickup.uid] = view


func _update_positions() -> void:
	for pickup: DiamondPickup in GameState.access.get_diamond_pickups():
		var view: DiamondPickupView = _nodes.get(pickup.uid, null) as DiamondPickupView
		if view != null:
			view.setup(pickup.uid, pickup.world_pos, pickup.amount)


func _find_pickup(uid: String) -> DiamondPickup:
	for pickup: DiamondPickup in GameState.access.get_diamond_pickups():
		if pickup.uid == uid:
			return pickup
	return null
