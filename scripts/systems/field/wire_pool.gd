extends RefCounted
class_name WirePool
## Пул словарей сегментов проводов (переиспользование при rebuild_wires).


static var _segment_pool: Array[Dictionary] = []
static var _link_pool: Array[Dictionary] = []


static func release_segments(segments: Array) -> void:
	for seg: Dictionary in segments:
		_recycle_segment(seg)


static func acquire_segment() -> Dictionary:
	if _segment_pool.is_empty():
		return {}
	var seg: Dictionary = _segment_pool.pop_back()
	seg.clear()
	return seg


static func acquire_link() -> Dictionary:
	if _link_pool.is_empty():
		return {}
	var link: Dictionary = _link_pool.pop_back()
	link.clear()
	return link


static func _recycle_segment(seg: Dictionary) -> void:
	var link: Variant = seg.get("link", null)
	if link is Dictionary:
		var link_dict: Dictionary = link
		link_dict.clear()
		_link_pool.append(link_dict)
	seg.clear()
	_segment_pool.append(seg)
