extends Control
class_name DiamondPickupView
## Кристал ◆ на карте (сбор по тапу через hit-test в FieldMapDiamonds).

var pickup_uid: String = ""
var amount: int = 1

var _pulse: float = 0.0


func setup(uid: String, world_pos: Vector2, gem_amount: int) -> void:
	pickup_uid = uid
	amount = gem_amount
	var half := FieldMapConstants.DIAMOND_PICKUP_SIZE * 0.5
	position = world_pos - Vector2(half, half)
	custom_minimum_size = Vector2(
		FieldMapConstants.DIAMOND_PICKUP_SIZE, FieldMapConstants.DIAMOND_PICKUP_SIZE
	)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func _process(delta: float) -> void:
	_pulse += delta * 3.5
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var glow := 0.65 + 0.35 * sin(_pulse)
	draw_circle(center, 18.0, Color(0.55, 0.2, 1.0, 0.22 * glow))
	draw_circle(center, 11.0, Color(0.78, 0.45, 1.0, 0.85))
	var pts := PackedVector2Array(
		[
			center + Vector2(0.0, -10.0),
			center + Vector2(8.0, 0.0),
			center + Vector2(0.0, 10.0),
			center + Vector2(-8.0, 0.0),
		]
	)
	draw_colored_polygon(pts, Color(0.95, 0.88, 1.0, 0.95))
	if amount > 1:
		var font := ThemeDB.fallback_font
		var fs := 11
		var label := str(amount)
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(
			font,
			center + Vector2(-tw * 0.5, 4.0),
			label,
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			fs,
			Color.WHITE
		)
