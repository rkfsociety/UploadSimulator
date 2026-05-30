extends RefCounted
## Перемещение установленного модуля на свободную клетку.

var case_count := 2


func run() -> Array[String]:
	var errors: Array[String] = []
	var host := _TestHost.new()
	var data := GameStateData.new()
	var field := GameFieldService.new(data, host)
	data.add_block_stock("uploader", 1)
	var place := field.place_block("uploader", 0, 0)
	if not place.is_ok():
		errors.append("place_block uploader")
		return errors
	var uid := place.get_uid()
	if not field.can_relocate_block(uid, 12, 0):
		errors.append("can_relocate на свободную клетку")
	if field.relocate_block(uid, 12, 0):
		var inst := field.get_instance(uid)
		if inst.gx != 12 or inst.gy != 0:
			errors.append("координаты после relocate")
	else:
		errors.append("relocate_block")
	data.add_block_stock("text_downloader", 1)
	var place_dl := field.place_block("text_downloader", 24, 0)
	if not place_dl.is_ok():
		errors.append("place_block text_downloader")
		return errors
	if field.can_relocate_block(uid, 24, 0):
		errors.append("relocate в занятую клетку должен быть запрещён")
	return errors


class _TestHost:
	extends Node

	signal log_message(text: String)
	signal wiring_changed
	signal field_changed
	signal stats_changed
	signal block_purchased(type_id: String)
	signal placement_requested(type_id: String)
	signal queue_changed
