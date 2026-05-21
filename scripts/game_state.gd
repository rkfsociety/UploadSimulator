extends Node
## Глобальное состояние: поле блоков, провода, студия.

signal stats_changed
signal queue_changed
signal log_message(text: String)
signal wiring_changed
signal field_changed
signal placement_requested(type_id: String)
signal block_purchased(type_id: String)

enum Phase { IDLE, RECORDING, UPLOADING, PUBLISHED }

const PIPELINE_LABEL := "Загрузчик → Хранилище → Аплоудер"
const MONEY_PIPELINE_LABEL := "Аплоудер → Коллектор"
const WIRING_HINT := "Круг = файлы | Квадрат/ромб = деньги"
const BASE_STORAGE_GB := 32.0
const RAW_VIDEO_MB := 18.0

var money: float = float(BlockDefs.starter_kit_cost())
var uploader_balance: float = 0.0
var subscribers: int = 0
var total_views: int = 0
var energy: float = 100.0
var max_energy: float = 100.0

var block_stock := {}
var _recording_studio_uid: String = ""
var placed_blocks: Array[Dictionary] = []
var wire_connections: Array[Dictionary] = []

var phase: Phase = Phase.IDLE
var phase_progress: float = 0.0
var phase_duration: float = 1.0
var recorded_videos: int = 0
var published_videos: int = 0
var download_queue: Array[Dictionary] = []
var stored_files: Array[Dictionary] = []
var upload_queue: Array[Dictionary] = []

var _rng := RandomNumberGenerator.new()
var _uid_counter: int = 0


func _ready() -> void:
	_rng.randomize()


func _process(delta: float) -> void:
	_regen_energy(delta)
	_tick_active_phase(delta)
	_tick_download_queue(delta)
	_tick_upload_queue(delta)


# --- Поле и блоки ---

func make_uid() -> String:
	_uid_counter += 1
	return "blk_%d" % _uid_counter


func get_instance(uid: String) -> Dictionary:
	for inst: Dictionary in placed_blocks:
		if inst.get("uid", "") == uid:
			return inst
	return {}


func get_instance_level(uid: String) -> int:
	return int(get_instance(uid).get("level", 0))


func get_instance_type(uid: String) -> String:
	return str(get_instance(uid).get("type", ""))


func has_block_on_field(type_id: String) -> bool:
	for inst: Dictionary in placed_blocks:
		if inst.get("type", "") == type_id:
			return true
	return false


func get_block_stock(type_id: String) -> int:
	return int(block_stock.get(type_id, 0))


func can_buy_block(type_id: String) -> bool:
	if not BlockDefs.TYPES.has(type_id):
		return false
	return money >= float(BlockDefs.TYPES[type_id]["shop_cost"])


func buy_block(type_id: String) -> bool:
	if not can_buy_block(type_id):
		return false
	var cost: float = float(BlockDefs.TYPES[type_id]["shop_cost"])
	money -= cost
	block_stock[type_id] = int(block_stock.get(type_id, 0)) + 1
	log_message.emit("Куплен «%s»." % BlockDefs.TYPES[type_id]["name"])
	block_purchased.emit(type_id)
	stats_changed.emit()
	field_changed.emit()
	return true


func can_place_block(type_id: String, gx: int, gy: int) -> bool:
	if int(block_stock.get(type_id, 0)) <= 0:
		return false
	if not GridDefs.footprint_in_bounds(gx, gy):
		return false
	for cell in GridDefs.block_footprint_cells(gx, gy):
		if not get_block_at(cell.x, cell.y).is_empty():
			return false
	return true


func get_block_at(gx: int, gy: int) -> Dictionary:
	for inst: Dictionary in placed_blocks:
		var ax: int = int(inst.get("gx", -1))
		var ay: int = int(inst.get("gy", -1))
		if (
			gx >= ax
			and gx < ax + GridDefs.BLOCK_CELLS_W
			and gy >= ay
			and gy < ay + GridDefs.BLOCK_CELLS_H
		):
			return inst
	return {}


func place_block(type_id: String, gx: int, gy: int) -> String:
	if not GridDefs.footprint_in_bounds(gx, gy):
		log_message.emit(
			"За пределами карты (%d…%d)." % [-GridDefs.GRID_HALF, GridDefs.GRID_HALF - 1]
		)
		return ""
	if not can_place_block(type_id, gx, gy):
		return ""
	block_stock[type_id] = int(block_stock.get(type_id, 0)) - 1
	var uid := make_uid()
	placed_blocks.append({"uid": uid, "type": type_id, "gx": gx, "gy": gy, "level": 1})
	log_message.emit("%s установлен на поле." % BlockDefs.TYPES[type_id]["name"])
	field_changed.emit()
	stats_changed.emit()
	return uid


func get_instance_upgrade_cost(uid: String) -> int:
	var inst := get_instance(uid)
	if inst.is_empty():
		return 0
	var type_id: String = inst.get("type", "")
	var def: Dictionary = BlockDefs.TYPES.get(type_id, {})
	var lvl: int = int(inst.get("level", 1))
	return int(round(float(def.get("upgrade_base", 30)) * pow(float(def.get("upgrade_mult", 1.4)), float(lvl))))


func can_upgrade_instance(uid: String) -> bool:
	return not get_instance(uid).is_empty() and money >= float(get_instance_upgrade_cost(uid))


func upgrade_instance(uid: String) -> bool:
	if not can_upgrade_instance(uid):
		return false
	var inst := get_instance(uid)
	var cost := get_instance_upgrade_cost(uid)
	money -= float(cost)
	inst["level"] = int(inst.get("level", 1)) + 1
	for i in placed_blocks.size():
		if placed_blocks[i].get("uid", "") == uid:
			placed_blocks[i] = inst
			break
	var name: String = BlockDefs.TYPES.get(inst.get("type", ""), {}).get("name", "")
	log_message.emit("%s улучшен до ур. %d" % [name, inst["level"]])
	stats_changed.emit()
	field_changed.emit()
	return true


func get_instance_status_line(uid: String) -> String:
	return str(get_block_display(uid).get("status", ""))


func get_block_metric(uid: String) -> String:
	var inst := get_instance(uid)
	if inst.is_empty():
		return ""
	var type_id: String = inst.get("type", "")
	var lvl: int = maxi(1, get_instance_level(uid))
	match type_id:
		"studio":
			var bonus: float = float(lvl) * float(BlockDefs.TYPES["studio"]["effect_per_level"])
			return "%.1f с · запись" % (4.0 / (1.0 + bonus))
		"downloader":
			return "%.1f МБ/с" % _download_speed_for(uid)
		"storage":
			return "%.0f ГБ диск" % (_storage_capacity_for(uid) / 1024.0)
		"uploader":
			return "%.1f МБ/с" % _upload_speed_for(uid)
		"collector":
			return "+%.0f%% к кассе" % (_collector_bonus_for(uid) * 100.0)
	return ""


func get_block_display(uid: String) -> Dictionary:
	var inst := get_instance(uid)
	var empty := {
		"status": "",
		"action_text": "",
		"action_enabled": false,
		"action_visible": false,
		"progress": -1.0,
	}
	if inst.is_empty():
		return empty
	var type_id: String = inst.get("type", "")
	var chain_file := get_file_chain()
	var chain_money := get_money_chain()
	match type_id:
		"studio":
			empty["action_text"] = "Записать"
			empty["action_visible"] = true
			empty["action_enabled"] = can_record_at(uid)
			if phase == Phase.RECORDING and _recording_studio_uid == uid:
				empty["status"] = "Запись %d%%" % int(phase_progress * 100.0)
				empty["progress"] = phase_progress
				empty["action_enabled"] = false
			elif recorded_videos > 0:
				empty["status"] = "Готово: %d рол." % recorded_videos
			else:
				empty["status"] = "Энергия %.0f" % energy
		"downloader":
			empty["action_text"] = "На диск"
			empty["action_visible"] = not chain_file.is_empty()
			empty["action_enabled"] = can_download_at(uid)
			if not download_queue.is_empty() and chain_file.get("downloader", "") == uid:
				var job: Dictionary = download_queue[0]
				empty["status"] = "Качает %d%%" % int(float(job.get("progress", 0.0)) * 100.0)
				empty["progress"] = float(job.get("progress", 0.0))
				empty["action_enabled"] = false
			elif recorded_videos > 0:
				empty["status"] = "В очереди: %d" % recorded_videos
			else:
				empty["status"] = "Ждёт запись"
		"storage":
			var cap := _storage_capacity_for(uid) / 1024.0
			var used_pct := 0.0
			if get_storage_capacity_mb() > 0.0:
				used_pct = get_storage_used_mb() / get_storage_capacity_mb() * 100.0
			empty["status"] = "Диск %.0f%% · %d файл." % [used_pct, stored_files.size()]
			if download_queue.size() > 0:
				empty["status"] = "Принимает файл..."
				empty["progress"] = float(download_queue[0].get("progress", 0.0))
		"uploader":
			empty["action_text"] = "В сеть"
			empty["action_visible"] = not chain_file.is_empty()
			empty["action_enabled"] = can_upload_at(uid)
			if not upload_queue.is_empty() and chain_file.get("uploader", "") == uid:
				var job: Dictionary = upload_queue[0]
				empty["status"] = "Грузит %d%%" % int(float(job.get("progress", 0.0)) * 100.0)
				empty["progress"] = float(job.get("progress", 0.0))
				empty["action_enabled"] = false
			else:
				empty["status"] = "Сейф $%.0f" % uploader_balance
		"collector":
			empty["action_text"] = "В кассу"
			empty["action_visible"] = not chain_money.is_empty()
			empty["action_enabled"] = can_collect_at(uid)
			empty["status"] = "Бонус +%.0f%%" % (_collector_bonus_for(uid) * 100.0)
	return empty


# --- Провода (по uid экземпляров на поле) ---

func is_wired(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	for link: Dictionary in wire_connections:
		if (
			link.get("from_uid", "") == from_uid
			and link.get("from_port", "") == from_port
			and link.get("to_uid", "") == to_uid
			and link.get("to_port", "") == to_port
		):
			return true
	return false


func _instance_types(from_uid: String, from_port: String, to_uid: String, to_port: String) -> Array:
	return [
		get_instance_type(from_uid),
		from_port,
		get_instance_type(to_uid),
		to_port,
	]


func can_connect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	var types := _instance_types(from_uid, from_port, to_uid, to_port)
	if types[0] == "" or types[2] == "":
		return false
	if not _is_allowed_edge(types[0], types[1], types[2], types[3]):
		return false
	var from_def: Dictionary = BlockDefs.PORT_DEFS.get(types[0], {}).get(from_port, {})
	var to_def: Dictionary = BlockDefs.PORT_DEFS.get(types[2], {}).get(to_port, {})
	if from_def.is_empty() or to_def.is_empty():
		return false
	if from_def.get("dir", "") != "out" or to_def.get("dir", "") != "in":
		return false
	if from_def.get("kind", "") != to_def.get("kind", ""):
		return false
	if port_has_output_link(from_uid, from_port):
		return false
	if port_has_input_link(to_uid, to_port):
		return false
	return true


func _is_allowed_edge(from_type: String, from_port: String, to_type: String, to_port: String) -> bool:
	for edge in BlockDefs.ALLOWED_WIRES:
		if edge[0] == from_type and edge[1] == from_port and edge[2] == to_type and edge[3] == to_port:
			return true
	return false


func port_has_output_link(uid: String, port_id: String) -> bool:
	for link: Dictionary in wire_connections:
		if link.get("from_uid", "") == uid and link.get("from_port", "") == port_id:
			return true
	return false


func port_has_input_link(uid: String, port_id: String) -> bool:
	for link: Dictionary in wire_connections:
		if link.get("to_uid", "") == uid and link.get("to_port", "") == port_id:
			return true
	return false


func try_connect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	if is_wired(from_uid, from_port, to_uid, to_port):
		disconnect_ports(from_uid, from_port, to_uid, to_port)
		log_message.emit("Провод снят.")
		wiring_changed.emit()
		return true
	if not can_connect_ports(from_uid, from_port, to_uid, to_port):
		log_message.emit(_connection_error(get_instance_type(from_uid), get_instance_type(to_uid)))
		return false
	wire_connections.append({
		"from_uid": from_uid,
		"from_port": from_port,
		"to_uid": to_uid,
		"to_port": to_port,
	})
	log_message.emit("Соединено: %s → %s" % [_type_name(from_uid), _type_name(to_uid)])
	wiring_changed.emit()
	return true


func disconnect_output_port(uid: String, port_id: String) -> void:
	for i in range(wire_connections.size() - 1, -1, -1):
		if wire_connections[i].get("from_uid", "") == uid and wire_connections[i].get("from_port", "") == port_id:
			wire_connections.remove_at(i)
	wiring_changed.emit()


func disconnect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> void:
	for i in range(wire_connections.size() - 1, -1, -1):
		var link: Dictionary = wire_connections[i]
		if (
			link.get("from_uid", "") == from_uid
			and link.get("from_port", "") == from_port
			and link.get("to_uid", "") == to_uid
			and link.get("to_port", "") == to_port
		):
			wire_connections.remove_at(i)


func _connection_error(from_type: String, to_type: String) -> String:
	if from_type == "downloader" and to_type == "uploader":
		return "Нельзя напрямую: загрузчик → аплоудер. Нужно хранилище."
	if from_type == "downloader" and to_type == "collector":
		return "Нельзя: загрузчик → коллектор."
	if from_type == "storage" and to_type == "collector":
		return "Нельзя: хранилище → коллектор."
	return "Соединение недоступно."


func _find_wired_pair(from_type: String, from_port: String, to_type: String, to_port: String) -> Dictionary:
	for link: Dictionary in wire_connections:
		var fu: String = link.get("from_uid", "")
		var tu: String = link.get("to_uid", "")
		if (
			get_instance_type(fu) == from_type
			and link.get("from_port", "") == from_port
			and get_instance_type(tu) == to_type
			and link.get("to_port", "") == to_port
		):
			return {"from_uid": fu, "to_uid": tu}
	return {}


func get_file_chain() -> Dictionary:
	var a := _find_wired_pair("downloader", "file_out", "storage", "file_in")
	if a.is_empty():
		return {}
	var b := _find_wired_pair("storage", "file_out", "uploader", "file_in")
	if b.is_empty() or b.get("from_uid", "") != a.get("to_uid", ""):
		return {}
	return {"downloader": a.get("from_uid", ""), "storage": a.get("to_uid", ""), "uploader": b.get("to_uid", "")}


func get_money_chain() -> Dictionary:
	return _find_wired_pair("uploader", "money_out", "collector", "money_in")


func _type_name(uid: String) -> String:
	return BlockDefs.TYPES.get(get_instance_type(uid), {}).get("name", uid)


# --- Магазин блоков ---

func get_shop_block_types() -> Array[String]:
	var keys: Array[String] = []
	for k in BlockDefs.TYPES.keys():
		keys.append(k)
	keys.sort()
	return keys


# --- Хранилище (сумма всех storage на поле) ---

func get_storage_capacity_mb() -> float:
	var total_gb := 0.0
	for inst: Dictionary in placed_blocks:
		if inst.get("type", "") == "storage":
			total_gb += _storage_capacity_for(inst.get("uid", "")) / 1024.0
	if total_gb <= 0.0:
		return 0.0
	return total_gb * 1024.0


func _storage_capacity_for(uid: String) -> float:
	var lvl: int = maxi(1, get_instance_level(uid))
	var extra: float = float(lvl - 1) * float(BlockDefs.TYPES["storage"]["capacity_gb_per_level"])
	return (BASE_STORAGE_GB + extra) * 1024.0


func get_storage_used_mb() -> float:
	var used := 0.0
	used += float(recorded_videos) * RAW_VIDEO_MB
	for job: Dictionary in download_queue:
		used += float(job.get("size_mb", 0.0))
	for item: Dictionary in stored_files:
		used += float(item.get("size_mb", 0.0))
	for job: Dictionary in upload_queue:
		used += float(job.get("size_mb", 0.0))
	return used


func has_storage_space(for_mb: float) -> bool:
	return get_storage_capacity_mb() > 0.0 and get_storage_free_mb() >= for_mb


func get_storage_free_mb() -> float:
	return maxf(0.0, get_storage_capacity_mb() - get_storage_used_mb())


func _download_speed_for(uid: String) -> float:
	var lvl: int = maxi(1, get_instance_level(uid))
	var bonus: float = float(lvl) * float(BlockDefs.TYPES["downloader"]["effect_per_level"])
	return 3.5 * (1.0 + bonus)


func _upload_speed_for(uid: String) -> float:
	var lvl: int = maxi(1, get_instance_level(uid))
	var bonus: float = float(lvl) * float(BlockDefs.TYPES["uploader"]["effect_per_level"])
	return 4.0 * (1.0 + bonus)


func _collector_bonus_for(uid: String) -> float:
	var lvl: int = maxi(1, get_instance_level(uid))
	return float(lvl) * float(BlockDefs.TYPES["collector"]["effect_per_level"])


# --- Игровой цикл ---

func _regen_energy(delta: float) -> void:
	if phase == Phase.RECORDING:
		return
	if energy < max_energy:
		energy = minf(energy + 6.0 * delta, max_energy)
		stats_changed.emit()


func can_record() -> bool:
	return phase == Phase.IDLE and has_block_on_field("studio") and _any_studio_can_record()


func _any_studio_can_record() -> bool:
	for inst: Dictionary in placed_blocks:
		if inst.get("type", "") == "studio" and can_record_at(inst.get("uid", "")):
			return true
	return false


func can_record_at(uid: String) -> bool:
	if get_instance_type(uid) != "studio" or phase != Phase.IDLE:
		return false
	return (
		energy >= 25.0
		and download_queue.size() < 5
		and upload_queue.size() < 5
		and has_storage_space(RAW_VIDEO_MB)
	)


func can_download_at(uid: String) -> bool:
	var chain := get_file_chain()
	return can_enqueue_download() and chain.get("downloader", "") == uid


func can_upload_at(uid: String) -> bool:
	var chain := get_file_chain()
	return can_enqueue_upload() and chain.get("uploader", "") == uid


func can_collect_at(uid: String) -> bool:
	var chain := get_money_chain()
	return can_collect_money() and chain.get("to_uid", "") == uid


func can_enqueue_download() -> bool:
	var chain := get_file_chain()
	if phase != Phase.IDLE or chain.is_empty() or recorded_videos <= 0:
		return false
	if download_queue.size() >= 5:
		return false
	return has_storage_space(140.0)


func can_enqueue_upload() -> bool:
	var chain := get_file_chain()
	return (
		phase == Phase.IDLE
		and not chain.is_empty()
		and stored_files.size() > 0
		and upload_queue.size() < 5
	)


func can_collect_money() -> bool:
	var chain := get_money_chain()
	return phase == Phase.IDLE and not chain.is_empty() and uploader_balance >= 0.01


func collect_money() -> bool:
	if not can_collect_money():
		return false
	var chain := get_money_chain()
	var uid: String = chain.get("to_uid", "")
	var bonus: float = _collector_bonus_for(uid)
	var payout: float = uploader_balance * (1.0 + bonus)
	uploader_balance = 0.0
	money += payout
	log_message.emit("Коллектор: $%.0f → касса" % payout)
	field_changed.emit()
	stats_changed.emit()
	return true


func start_recording_at(uid: String) -> bool:
	if not can_record_at(uid):
		return false
	energy -= 25.0
	_recording_studio_uid = uid
	phase = Phase.RECORDING
	phase_progress = 0.0
	var lvl: int = maxi(1, get_instance_level(uid))
	var bonus: float = float(lvl) * float(BlockDefs.TYPES["studio"]["effect_per_level"])
	phase_duration = 4.0 / (1.0 + bonus)
	stats_changed.emit()
	field_changed.emit()
	log_message.emit("Студия: запись...")
	return true


func run_block_action(uid: String) -> bool:
	match get_instance_type(uid):
		"studio":
			return start_recording_at(uid)
		"downloader":
			return enqueue_download()
		"uploader":
			return enqueue_upload()
		"collector":
			return collect_money()
	return false


func enqueue_download() -> bool:
	if not can_enqueue_download():
		return false
	var chain := get_file_chain()
	var dl_uid: String = chain.get("downloader", "")
	recorded_videos -= 1
	var title := _random_title()
	var quality := 1.0 + float(get_instance_level(dl_uid)) * 0.08
	var assets_mb := _rng.randf_range(35.0, 120.0)
	var video_mb := _rng.randf_range(70.0, 200.0) * quality
	var total_mb := assets_mb + video_mb
	if not has_storage_space(total_mb - RAW_VIDEO_MB):
		recorded_videos += 1
		log_message.emit("Мало места на диске.")
		stats_changed.emit()
		return false
	var duration := assets_mb / _download_speed_for(dl_uid)
	download_queue.append({
		"title": title,
		"quality": quality,
		"size_mb": total_mb,
		"duration": duration,
		"progress": 0.0,
	})
	queue_changed.emit()
	field_changed.emit()
	log_message.emit("Скачивание «%s»..." % title)
	stats_changed.emit()
	return true


func enqueue_upload() -> bool:
	if not can_enqueue_upload():
		return false
	var chain := get_file_chain()
	var up_uid: String = chain.get("uploader", "")
	var item: Dictionary = stored_files.pop_front()
	var size_mb: float = float(item.get("size_mb", 100.0))
	upload_queue.append({
		"quality": float(item.get("quality", 1.0)),
		"size_mb": size_mb,
		"duration": size_mb / _upload_speed_for(up_uid),
		"progress": 0.0,
		"title": item.get("title", "Ролик"),
	})
	queue_changed.emit()
	field_changed.emit()
	log_message.emit("Выгрузка «%s»..." % item.get("title", "???"))
	stats_changed.emit()
	return true


func get_phase_label() -> String:
	match phase:
		Phase.RECORDING:
			return "Запись"
		Phase.PUBLISHED:
			return "Опубликовано"
		_:
			if not download_queue.is_empty():
				return "Скачивание"
			if not upload_queue.is_empty():
				return "Выгрузка"
			return "Свободен"


func _tick_active_phase(delta: float) -> void:
	if phase == Phase.IDLE or phase == Phase.PUBLISHED:
		return
	phase_progress += delta / maxf(phase_duration, 0.05)
	stats_changed.emit()
	field_changed.emit()
	if phase_progress < 1.0:
		return
	phase_progress = 1.0
	if phase == Phase.RECORDING:
		recorded_videos += 1
		phase = Phase.IDLE
		phase_progress = 0.0
		_recording_studio_uid = ""
		field_changed.emit()
		log_message.emit("Ролик записан → загрузчик «На диск»")


func _tick_download_queue(delta: float) -> void:
	if phase != Phase.IDLE or download_queue.is_empty():
		return
	var job: Dictionary = download_queue[0]
	job["progress"] = float(job.get("progress", 0.0)) + delta / maxf(float(job["duration"]), 0.05)
	download_queue[0] = job
	queue_changed.emit()
	field_changed.emit()
	if float(job["progress"]) >= 1.0:
		download_queue.pop_front()
		stored_files.append({
			"title": job.get("title", ""),
			"quality": float(job.get("quality", 1.0)),
			"size_mb": float(job.get("size_mb", 0.0)),
		})
		field_changed.emit()
		stats_changed.emit()


func _tick_upload_queue(delta: float) -> void:
	if phase != Phase.IDLE or upload_queue.is_empty():
		return
	var job: Dictionary = upload_queue[0]
	job["progress"] = float(job.get("progress", 0.0)) + delta / maxf(float(job["duration"]), 0.05)
	upload_queue[0] = job
	queue_changed.emit()
	field_changed.emit()
	if float(job["progress"]) >= 1.0:
		upload_queue.pop_front()
		field_changed.emit()
		_publish_video(job)


func _publish_video(job: Dictionary) -> void:
	published_videos += 1
	var views := int(round(_rng.randi_range(40, 180) * float(job.get("quality", 1.0))))
	var revenue := views * 0.04
	subscribers += _rng.randi_range(0, 3)
	total_views += views
	uploader_balance += revenue
	phase = Phase.PUBLISHED
	log_message.emit("«%s» +$%.1f в аплоудер" % [job.get("title", ""), revenue])
	await get_tree().create_timer(1.0).timeout
	phase = Phase.IDLE
	field_changed.emit()
	stats_changed.emit()


func _random_title() -> String:
	var topics := ["Обзор", "Гайд", "Влог", "Стрим"]
	var things := ["игры", "патча", "сетапа", "мода"]
	return "%s %s" % [topics[_rng.randi_range(0, topics.size() - 1)], things[_rng.randi_range(0, things.size() - 1)]]


func _format_number(value: int) -> String:
	if value >= 1000:
		return "%.1fK" % (float(value) / 1000.0)
	return str(value)
