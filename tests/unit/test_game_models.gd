extends RefCounted
## Unit-тесты типизированных моделей BlockInstance и WireLink.

var case_count := 8


func run() -> Array[String]:
	var errors: Array[String] = []
	_test_block_instance(errors)
	_test_wire_link(errors)
	return errors


func _test_block_instance(errors: Array[String]) -> void:
	var inst := BlockInstance.create("text_downloader", 2, 3, "blk_1", 1)
	if not inst.is_valid():
		errors.append("BlockInstance.create: is_valid")
	if inst.type_id != "text_downloader" or inst.gx != 2 or inst.gy != 3 or inst.level != 1:
		errors.append("BlockInstance.create: поля")
	var d := inst.to_dict()
	var restored := BlockInstance.from_dict(d)
	if restored.uid != inst.uid or restored.type_id != inst.type_id:
		errors.append("BlockInstance to_dict/from_dict")
	var legacy := BlockInstance.from_legacy_dict({"uid": "x", "type": "text_downloader", "gx": 1, "gy": 0})
	if legacy.type_id != "text_downloader":
		errors.append("BlockInstance.from_legacy_dict type")


func _test_wire_link(errors: Array[String]) -> void:
	var link := WireLink.create("a", "out", "b", "in")
	if not link.is_valid():
		errors.append("WireLink.create: is_valid")
	if not link.matches("a", "out", "b", "in"):
		errors.append("WireLink.matches")
	var d := link.to_dict()
	var restored := WireLink.from_dict(d)
	if not restored.matches("a", "out", "b", "in"):
		errors.append("WireLink to_dict/from_dict")
	var legacy := WireLink.from_legacy_dict(
		{"from_block": "u1", "from_port": "p1", "to_block": "u2", "to_port": "p2"}
	)
	if legacy.from_uid != "u1" or legacy.to_uid != "u2":
		errors.append("WireLink.from_legacy_dict from_block/to_block")
	link.clear()
	if link.is_valid():
		errors.append("WireLink.clear")
