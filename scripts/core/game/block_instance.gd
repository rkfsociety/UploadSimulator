extends RefCounted
class_name BlockInstance
## Экземпляр модуля на поле.

var uid: String = ""
var type_id: String = ""
var gx: int = 0
var gy: int = 0
var level: int = 1


func is_valid() -> bool:
	return uid != ""


static func from_legacy_dict(data: Dictionary) -> BlockInstance:
	var inst := BlockInstance.new()
	inst.uid = str(data.get("uid", ""))
	inst.type_id = str(data.get("type", ""))
	inst.gx = int(data.get("gx", 0))
	inst.gy = int(data.get("gy", 0))
	inst.level = int(data.get("level", 1))
	return inst
