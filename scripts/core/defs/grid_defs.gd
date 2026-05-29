extends RefCounted
class_name GridDefs
## Сетка 100×100 клеток; (0, 0) — центр карты.

# Клетка сетки крупнее — текст модулей читается без «лесенки» при умеренном зуме
const CELL_SIZE := 64
const GRID_CELLS := 100
const GRID_HALF := GRID_CELLS / 2
# Размер следа модуля задаётся отдельно для каждого типа в BlockDefs (cells_w/cells_h).
# Нижняя полоса улучшения — 1 клетка по высоте у всех типов.
const BLOCK_UPGRADE_CELLS_H := 1


## Размер следа модуля данного типа в клетках (ширина, высота).
static func block_cells(type_id: String) -> Vector2i:
	return BlockDefs.cells_size(type_id)


static func is_in_bounds(gx: int, gy: int) -> bool:
	return gx >= -GRID_HALF and gx < GRID_HALF and gy >= -GRID_HALF and gy < GRID_HALF


static func cell_to_pixel(gx: int, gy: int) -> Vector2:
	# Левый-верхний угол клетки (gx, gy) — точно на линии сетки (кратно CELL_SIZE)
	return Vector2(gx * CELL_SIZE, gy * CELL_SIZE)


static func cell_rect(gx: int, gy: int) -> Rect2:
	return Rect2(cell_to_pixel(gx, gy), Vector2(CELL_SIZE, CELL_SIZE))


static func pixel_to_cell(world_px: Vector2) -> Vector2i:
	return Vector2i(
		floori(world_px.x / float(CELL_SIZE)),
		floori(world_px.y / float(CELL_SIZE))
	)


static func snap_cell_from_world(world_px: Vector2) -> Vector2i:
	return pixel_to_cell(world_px)


static func block_pixel_size(type_id: String) -> Vector2:
	# Размер модуля на карте в пикселях (свой для каждого типа)
	var c := block_cells(type_id)
	return Vector2(c.x * CELL_SIZE, c.y * CELL_SIZE)


static func block_footprint_cells(gx: int, gy: int, type_id: String) -> Array[Vector2i]:
	var c := block_cells(type_id)
	var cells: Array[Vector2i] = []
	for dx in range(c.x):
		for dy in range(c.y):
			cells.append(Vector2i(gx + dx, gy + dy))
	return cells


static func footprint_in_bounds(gx: int, gy: int, type_id: String) -> bool:
	for cell in block_footprint_cells(gx, gy, type_id):
		if not is_in_bounds(cell.x, cell.y):
			return false
	return true


static func block_anchor_for_center(center: Vector2i, type_id: String) -> Vector2i:
	# Якорь (левый верх) так, чтобы блок был по центру клетки center
	var c := block_cells(type_id)
	return center - Vector2i(c.x / 2, c.y / 2)


static func world_bounds_rect() -> Rect2:
	var extent := GRID_HALF * CELL_SIZE
	return Rect2(Vector2(-extent, -extent), Vector2(GRID_CELLS * CELL_SIZE, GRID_CELLS * CELL_SIZE))


static func world_pixel_size() -> Vector2:
	return world_bounds_rect().size


static func world_center_pixel() -> Vector2:
	return Vector2.ZERO


static func get_block_color(type_id: String) -> Color:
	return BlockDefs.TYPES.get(type_id, {}).get("color", Color(0.0, 0.88, 1.0, 1.0))
