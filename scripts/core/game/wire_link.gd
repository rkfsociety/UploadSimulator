extends RefCounted
class_name WireLink
## Соединение двух портов на поле.

var from_uid: String = ""
var from_port: String = ""
var to_uid: String = ""
var to_port: String = ""


static func from_legacy_dict(data: Dictionary) -> WireLink:
	var link := WireLink.new()
	link.from_uid = str(data.get("from_uid", ""))
	link.from_port = str(data.get("from_port", ""))
	link.to_uid = str(data.get("to_uid", ""))
	link.to_port = str(data.get("to_port", ""))
	return link
