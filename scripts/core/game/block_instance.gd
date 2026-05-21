extends RefCounted
class_name BlockInstance
## Экземпляр модуля на поле (типизированная модель).


var uid: String = ""
var type_id: String = ""
var gx: int = 0
var gy: int = 0
var level: int = 1


func is_valid() -> bool:
	return uid != ""


static func create(
	type_id: String, gx: int, gy: int, uid: String = "", level: int = 1
) -> BlockInstance:
	var inst := BlockInstance.new()
	inst.uid = uid
	inst.type_id = type_id
	inst.gx = gx
	inst.gy = gy
	inst.level = level
	return inst


func to_dict() -> Dictionary:
	return {
		"uid": uid,
		"type": type_id,
		"gx": gx,
		"gy": gy,
		"level": level,
	}


static func from_dict(data: Dictionary) -> BlockInstance:
	return from_legacy_dict(data)


static func from_legacy_dict(data: Dictionary) -> BlockInstance:
	var inst := BlockInstance.new()
	inst.uid = str(data.get("uid", ""))
	inst.type_id = str(data.get("type", data.get("type_id", "")))
	inst.gx = int(data.get("gx", 0))
	inst.gy = int(data.get("gy", 0))
	inst.level = int(data.get("level", 1))
	return inst
