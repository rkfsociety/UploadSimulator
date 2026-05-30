extends RefCounted
class_name DiamondPickup
## Несобранный кристал ◆ на карте.


var uid: String = ""
var world_pos := Vector2.ZERO
var amount: int = 1


func to_dict() -> Dictionary:
	return {"uid": uid, "wx": world_pos.x, "wy": world_pos.y, "amount": amount}


static func from_dict(raw: Dictionary) -> DiamondPickup:
	var pickup := DiamondPickup.new()
	pickup.uid = str(raw.get("uid", ""))
	pickup.world_pos = Vector2(float(raw.get("wx", 0.0)), float(raw.get("wy", 0.0)))
	pickup.amount = int(raw.get("amount", 1))
	return pickup
