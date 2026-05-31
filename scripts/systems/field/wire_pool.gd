extends RefCounted
class_name WirePool
## Пул сегментов проводов (переиспользование при rebuild_wires).

static var _segment_pool: Array[Dictionary] = []
static var _link_pool: Array[WireLink] = []


static func release_segments(segments: Array) -> void:
	for seg: Dictionary in segments:
		_recycle_segment(seg)


static func acquire_segment() -> Dictionary:
	if _segment_pool.is_empty():
		return {}
	var seg: Dictionary = _segment_pool.pop_back()
	seg.clear()
	return seg


static func acquire_link() -> WireLink:
	if _link_pool.is_empty():
		return WireLink.new()
	var link: WireLink = _link_pool.pop_back()
	link.clear()
	return link


static func _recycle_segment(seg: Dictionary) -> void:
	var link: Variant = seg.get("link", null)
	if link is WireLink:
		_recycle_link(link as WireLink)
	seg.clear()
	_segment_pool.append(seg)


static func _recycle_link(link: WireLink) -> void:
	link.clear()
	_link_pool.append(link)
