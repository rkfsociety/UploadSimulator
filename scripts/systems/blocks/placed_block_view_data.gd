extends RefCounted
class_name PlacedBlockViewData
## Данные для отображения модуля (без привязки к узлам сцены).

var instance_uid: String = ""
var block_type: String = ""
var title: String = ""
var metric: String = ""
var status: String = ""
var accent: Color = Color.WHITE
var action_visible: bool = false
var action_text: String = ""
var action_enabled: bool = false
var progress: float = -1.0
var upgrade_text: String = ""
var upgrade_enabled: bool = false


## Собирает снимок состояния из GameState для uid/type_id.
static func from_instance(uid: String, type_id: String) -> PlacedBlockViewData:
	var data := PlacedBlockViewData.new()
	data.instance_uid = uid
	data.block_type = type_id
	var def: Dictionary = BlockDefs.TYPES.get(type_id, {})
	data.title = str(def.get("name", type_id))
	data.accent = BlockDefs.get_block_color(type_id)
	data.metric = GameState.display.get_block_metric(uid)
	var disp: Dictionary = GameState.display.get_block_display(uid)
	data.status = str(disp.get("status", ""))
	data.action_visible = bool(disp.get("action_visible", false))
	data.action_text = str(disp.get("action_text", "—"))
	data.action_enabled = bool(disp.get("action_enabled", false))
	data.progress = float(disp.get("progress", -1.0))
	var lvl: int = GameState.field.get_instance_level(uid)
	var cost: int = GameState.field.get_instance_upgrade_cost(uid)
	data.upgrade_text = "↑ Ур.%d · $%d" % [lvl + 1, cost]
	data.upgrade_enabled = GameState.field.can_upgrade_instance(uid)
	return data
