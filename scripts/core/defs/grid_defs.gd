extends RefCounted
class_name GridDefs
## Сетка 100×100 клеток; (0, 0) — центр карты.

# Клетка сетки: модуль 10×6 клеток ≈ прежний размер в пикселях (6×4 при 80px)
const CELL_SIZE := 48
const GRID_CELLS := 100
const GRID_HALF := GRID_CELLS / 2
# Единый след модуля на поле: альбомная ориентация, в пределах 8×5 … 20×20
const BLOCK_CELLS_W := 10
const BLOCK_CELLS_H := 6
const BLOCK_UPGRADE_CELLS_H := 1
const BLOCK_MAIN_CELLS_H := BLOCK_CELLS_H - BLOCK_UPGRADE_CELLS_H


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


static func block_pixel_size() -> Vector2:
	# Размер модуля на карте: 10×6 клеток (горизонтально)
	return Vector2(BLOCK_CELLS_W * CELL_SIZE, BLOCK_CELLS_H * CELL_SIZE)


static func block_footprint_cells(gx: int, gy: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for dx in range(BLOCK_CELLS_W):
		for dy in range(BLOCK_CELLS_H):
			cells.append(Vector2i(gx + dx, gy + dy))
	return cells


static func footprint_in_bounds(gx: int, gy: int) -> bool:
	for cell in block_footprint_cells(gx, gy):
		if not is_in_bounds(cell.x, cell.y):
			return false
	return true


static func block_anchor_for_center(center: Vector2i) -> Vector2i:
	# Якорь (левый верх) так, чтобы блок был по центру клетки center
	return center - Vector2i(BLOCK_CELLS_W / 2, BLOCK_CELLS_H / 2)


static func world_bounds_rect() -> Rect2:
	var extent := GRID_HALF * CELL_SIZE
	return Rect2(Vector2(-extent, -extent), Vector2(GRID_CELLS * CELL_SIZE, GRID_CELLS * CELL_SIZE))


static func world_pixel_size() -> Vector2:
	return world_bounds_rect().size


static func world_center_pixel() -> Vector2:
	return Vector2.ZERO


static func get_block_color(type_id: String) -> Color:
	return BlockDefs.TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))
