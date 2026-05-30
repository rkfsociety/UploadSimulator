extends Node2D
class_name WireFileTokenLayer
## Маркер файла (кружок) на проводе во время передачи.

const TOKEN_RADIUS := 9.0
const TOKEN_BORDER := 1.6

var _segments: Array[Dictionary] = []


func set_segments(segments: Array[Dictionary]) -> void:
	_segments = segments
	_sync_process()


func refresh() -> void:
	_sync_process()
	queue_redraw()


func _sync_process() -> void:
	set_process(_has_active_motion())


func _process(_delta: float) -> void:
	if _has_active_motion():
		queue_redraw()
	else:
		set_process(false)


func _has_active_motion() -> bool:
	if not GameState.access.get_download_queue().is_empty():
		return true
	return not GameState.access.get_wire_transfers().is_empty()


func _draw() -> void:
	var chain := GameState.wiring.get_download_chain()
	if not chain.is_empty() and not GameState.access.get_download_queue().is_empty():
		var job: FileTransferJob = GameState.access.get_download_queue()[0]
		_draw_token(
			str(chain.get("network", "")),
			"net_out",
			str(chain.get("downloader", "")),
			"net_in",
			job.progress,
			job.file_type_id,
		)
	for transfer: WireFileTransfer in GameState.access.get_wire_transfers():
		_draw_token(
			transfer.from_uid,
			transfer.from_port,
			transfer.to_uid,
			transfer.to_port,
			transfer.progress,
			transfer.file_type_id,
		)


func _draw_token(
	from_uid: String,
	from_port: String,
	to_uid: String,
	to_port: String,
	progress: float,
	file_type_id: String,
) -> void:
	var endpoints := _find_endpoints(from_uid, from_port, to_uid, to_port)
	if endpoints.is_empty():
		return
	var from: Vector2 = endpoints[0]
	var to: Vector2 = endpoints[1]
	var pos := from.lerp(to, clampf(progress, 0.0, 1.0))
	var fill := MinimalUI.WIRE_FILE
	fill.a = 0.95
	draw_circle(pos, TOKEN_RADIUS, fill)
	draw_arc(pos, TOKEN_RADIUS, 0.0, TAU, 24, Color(1.0, 1.0, 1.0, 0.85), TOKEN_BORDER, true)
	var label := FileDefs.get_type_icon_char(file_type_id)
	var font := ThemeDB.fallback_font
	var font_size := 11
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	draw_string(
		font,
		pos - text_size * 0.5 + Vector2(0.0, text_size.y * 0.82),
		label,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color(0.08, 0.12, 0.18, 1.0),
	)


func _find_endpoints(
	from_uid: String,
	from_port: String,
	to_uid: String,
	to_port: String,
) -> PackedVector2Array:
	for seg: Dictionary in _segments:
		var link: Variant = seg.get("link", null)
		if link is not WireLink:
			continue
		var wire: WireLink = link
		if not wire.matches(from_uid, from_port, to_uid, to_port):
			continue
		return PackedVector2Array([seg.get("from", Vector2.ZERO), seg.get("to", Vector2.ZERO)])
	return PackedVector2Array()
