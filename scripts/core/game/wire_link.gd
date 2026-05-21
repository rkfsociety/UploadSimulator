extends RefCounted
class_name WireLink
## Соединение двух портов на поле (типизированная модель).


var from_uid: String = ""
var from_port: String = ""
var to_uid: String = ""
var to_port: String = ""


func is_valid() -> bool:
	return from_uid != "" and from_port != "" and to_uid != "" and to_port != ""


func matches(from_u: String, from_p: String, to_u: String, to_p: String) -> bool:
	return from_uid == from_u and from_port == from_p and to_uid == to_u and to_port == to_p


func clear() -> void:
	from_uid = ""
	from_port = ""
	to_uid = ""
	to_port = ""


func copy_from(other: WireLink) -> void:
	from_uid = other.from_uid
	from_port = other.from_port
	to_uid = other.to_uid
	to_port = other.to_port


static func create(from_u: String, from_p: String, to_u: String, to_p: String) -> WireLink:
	var link := WireLink.new()
	link.from_uid = from_u
	link.from_port = from_p
	link.to_uid = to_u
	link.to_port = to_p
	return link


func to_dict() -> Dictionary:
	return {
		"from_uid": from_uid,
		"from_port": from_port,
		"to_uid": to_uid,
		"to_port": to_port,
	}


static func from_dict(data: Dictionary) -> WireLink:
	return from_legacy_dict(data)


static func from_legacy_dict(data: Dictionary) -> WireLink:
	var link := WireLink.new()
	link.from_uid = str(data.get("from_uid", data.get("from_block", "")))
	link.from_port = str(data.get("from_port", ""))
	link.to_uid = str(data.get("to_uid", data.get("to_block", "")))
	link.to_port = str(data.get("to_port", ""))
	return link
