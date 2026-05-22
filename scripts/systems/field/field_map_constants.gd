extends RefCounted
class_name FieldMapConstants
## Константы поля карты (камера, ввод, провода, превью).

const ZOOM_MIN := 0.2
# Максимальное приближение: иначе Control масштабируется растром и текст «сыпется»
const ZOOM_MAX := 1.6
const ZOOM_WHEEL_STEP := 1.12
const DRAG_THRESHOLD := 6.0
const PAN_CLAMP_MARGIN := 0.0
const MIN_ZOOM_EPSILON := 0.001
const MIN_PINCH_DISTANCE := 1.0

const PLACE_SEARCH_RADIUS := 10
const VISIBLE_WORLD_GROW_CELLS := 1

const WIRES_Z_INDEX := 5
const PENDING_WIRE_Z_INDEX := 10
const WIRE_FLOW_IDLE := 1.1
const WIRE_FLOW_ACTIVE := 2.0
const WIRE_PENDING_THICKNESS := 1.6

const PREVIEW_VALID_ALPHA := 0.16
const PREVIEW_OCCUPIED_COLOR := Color(1.0, 0.2, 0.35, 0.22)
