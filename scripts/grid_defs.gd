extends RefCounted
class_name GridDefs
## Сетка 100×100 клеток; (0, 0) — центр карты.

const CELL_SIZE := 80
const GRID_CELLS := 100
const GRID_HALF := GRID_CELLS / 2


static func is_in_bounds(gx: int, gy: int) -> bool:
	return gx >= -GRID_HALF and gx < GRID_HALF and gy >= -GRID_HALF and gy < GRID_HALF


static func cell_to_pixel(gx: int, gy: int) -> Vector2:
	# Центр клетки (gx, gy) в мировых координатах; (0,0) — центр карты
	var half_cell := float(CELL_SIZE) * 0.5
	return Vector2(gx * CELL_SIZE, gy * CELL_SIZE) - Vector2(half_cell, half_cell)


static func cell_rect(gx: int, gy: int) -> Rect2:
	return Rect2(cell_to_pixel(gx, gy), Vector2(CELL_SIZE, CELL_SIZE))


static func pixel_to_cell(world_px: Vector2) -> Vector2i:
	var half_cell := float(CELL_SIZE) * 0.5
	return Vector2i(
		floori((world_px.x + half_cell) / float(CELL_SIZE)),
		floori((world_px.y + half_cell) / float(CELL_SIZE))
	)


static func snap_cell_from_world(world_px: Vector2) -> Vector2i:
	return pixel_to_cell(world_px)


static func world_bounds_rect() -> Rect2:
	var extent := GRID_HALF * CELL_SIZE
	return Rect2(Vector2(-extent, -extent), Vector2(GRID_CELLS * CELL_SIZE, GRID_CELLS * CELL_SIZE))


static func world_pixel_size() -> Vector2:
	return world_bounds_rect().size


static func world_center_pixel() -> Vector2:
	return Vector2.ZERO


static func get_block_color(type_id: String) -> Color:
	return BlockDefs.TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))
