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
var upgrade_visible: bool = true
var use_network_panel: bool = false
var network_download_bps: float = 0.0
var network_upload_bps: float = 0.0
var network_download_active: bool = false
var network_upload_active: bool = false


## Собирает снимок состояния из GameState для uid/type_id.
static func from_instance(uid: String, type_id: String) -> PlacedBlockViewData:
	var data := PlacedBlockViewData.new()
	data.instance_uid = uid
	data.block_type = type_id
	var def: Dictionary = BlockDefs.TYPES.get(type_id, {})
	var lvl: int = GameState.field.get_instance_level(uid)
	var block_name: String = str(def.get("name", type_id))
	if type_id == "network":
		data.title = block_name
		data.use_network_panel = true
		data.network_download_bps = GameState.pipeline.network_download_speed(uid)
		data.network_upload_bps = GameState.pipeline.network_upload_speed(uid)
		var dl_chain: Dictionary = GameState.wiring.get_download_chain()
		var file_chain: Dictionary = GameState.wiring.get_file_chain()
		data.network_download_active = (
			str(dl_chain.get("network", "")) == uid
			and not GameState.access.get_download_queue().is_empty()
		)
		var up_uid := str(file_chain.get("uploader", ""))
		var upload_transfer := GameState.access.get_wire_transfers()
		var upload_active := false
		for transfer: WireFileTransfer in upload_transfer:
			if transfer.purpose == WireFileTransfer.Purpose.TO_NETWORK and transfer.from_uid == up_uid:
				upload_active = true
				break
			if transfer.purpose == WireFileTransfer.Purpose.TO_UPLOADER:
				upload_active = true
				break
		data.network_upload_active = (
			str(file_chain.get("network", "")) == uid
			and (
				upload_active or not GameState.access.get_upload_queue().is_empty()
			)
		)
	else:
		if BlockDefs.is_upgradeable(type_id):
			data.title = "%s · ур. %d" % [block_name, lvl]
		else:
			data.title = block_name
	# Характеристики типа (скорость, ёмкость и т.д.)
	data.accent = BlockDefs.get_block_color(type_id)
	data.metric = GameState.display.get_block_metric(uid)
	var disp: Dictionary = GameState.display.get_block_display(uid)
	# Текущее действие: файл, прогресс, очередь
	data.status = str(disp.get("status", ""))
	data.action_visible = bool(disp.get("action_visible", false))
	data.action_text = str(disp.get("action_text", "—"))
	data.action_enabled = bool(disp.get("action_enabled", false))
	data.progress = float(disp.get("progress", -1.0))
	var cost: int = GameState.field.get_instance_upgrade_cost(uid)
	data.upgrade_visible = BlockDefs.is_upgradeable(type_id)
	if data.upgrade_visible:
		data.upgrade_text = "Улучшить → ур. %d · $%d" % [lvl + 1, cost]
		data.upgrade_enabled = GameState.field.can_upgrade_instance(uid)
	else:
		data.upgrade_text = ""
		data.upgrade_enabled = false
	return data
