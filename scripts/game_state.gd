extends Node
## Фасад глобального состояния: делегирует сервисам по зонам ответственности.

signal stats_changed
signal queue_changed
signal log_message(text: String)
signal wiring_changed
signal field_changed
signal placement_requested(type_id: String)
signal block_purchased(type_id: String)

enum Phase { IDLE, RECORDING, UPLOADING, PUBLISHED }

var _data: GameStateData
var _field: GameFieldService
var _wiring: GameWiringService
var _storage: GameStorageService
var _pipeline: GamePipelineService
var _display: GameDisplayService


func _ready() -> void:
	_data = GameStateData.new()
	_field = GameFieldService.new(_data, self)
	_wiring = GameWiringService.new(_data, self, _field)
	_storage = GameStorageService.new(_data, _field)
	_pipeline = GamePipelineService.new(_data, self, _field, _wiring, _storage)
	_display = GameDisplayService.new(_data, _field, _wiring, _storage, _pipeline)


func _process(delta: float) -> void:
	_pipeline.tick(delta)


# --- Доступ к состоянию (инкапсуляция) ---

func get_money() -> float:
	return _data.get_money()


func get_uploader_balance() -> float:
	return _data.get_uploader_balance()


func get_placed_blocks() -> Array[BlockInstance]:
	return _data.get_placed_blocks()


func get_wire_connections() -> Array[WireLink]:
	return _data.get_wire_connections()


func get_download_queue() -> Array[FileTransferJob]:
	return _data.get_download_queue()


func get_upload_queue() -> Array[FileTransferJob]:
	return _data.get_upload_queue()


func get_phase() -> Phase:
	return _data.get_phase() as int as Phase


# --- Поле и блоки ---

func make_uid() -> String:
	return _field.make_uid()


func get_instance(uid: String) -> BlockInstance:
	return _field.get_instance(uid)


func get_instance_level(uid: String) -> int:
	return _field.get_instance_level(uid)


func get_instance_type(uid: String) -> String:
	return _field.get_instance_type(uid)


func has_block_on_field(type_id: String) -> bool:
	return _field.has_block_on_field(type_id)


func get_block_stock(type_id: String) -> int:
	return _field.get_block_stock(type_id)


func can_buy_block(type_id: String) -> bool:
	return _field.can_buy_block(type_id)


func buy_block(type_id: String) -> bool:
	return _field.buy_block(type_id)


func can_place_block(type_id: String, gx: int, gy: int) -> bool:
	return _field.can_place_block(type_id, gx, gy)


func get_block_at(gx: int, gy: int) -> BlockInstance:
	return _field.get_block_at(gx, gy)


func place_block(type_id: String, gx: int, gy: int) -> String:
	return _field.place_block(type_id, gx, gy)


func get_instance_upgrade_cost(uid: String) -> int:
	return _field.get_instance_upgrade_cost(uid)


func can_upgrade_instance(uid: String) -> bool:
	return _field.can_upgrade_instance(uid)


func upgrade_instance(uid: String) -> bool:
	return _field.upgrade_instance(uid)


func get_instance_status_line(uid: String) -> String:
	return _display.get_instance_status_line(uid)


func get_block_metric(uid: String) -> String:
	return _display.get_block_metric(uid)


func get_block_display(uid: String) -> Dictionary:
	return _display.get_block_display(uid)


func get_shop_block_types() -> Array[String]:
	return _field.get_shop_block_types()


# --- Провода ---

func is_wired(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	return _wiring.is_wired(from_uid, from_port, to_uid, to_port)


func can_connect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	return _wiring.can_connect_ports(from_uid, from_port, to_uid, to_port)


func port_has_output_link(uid: String, port_id: String) -> bool:
	return _wiring.port_has_output_link(uid, port_id)


func port_has_input_link(uid: String, port_id: String) -> bool:
	return _wiring.port_has_input_link(uid, port_id)


func try_connect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> bool:
	return _wiring.try_connect_ports(from_uid, from_port, to_uid, to_port)


func disconnect_output_port(uid: String, port_id: String) -> void:
	_wiring.disconnect_output_port(uid, port_id)


func disconnect_ports(from_uid: String, from_port: String, to_uid: String, to_port: String) -> void:
	_wiring.disconnect_ports(from_uid, from_port, to_uid, to_port)


func get_file_chain() -> Dictionary:
	return _wiring.get_file_chain()


func get_money_chain() -> Dictionary:
	return _wiring.get_money_chain()


# --- Хранилище ---

func get_storage_capacity_mb() -> float:
	return _storage.get_storage_capacity_mb()


func get_storage_used_mb() -> float:
	return _storage.get_storage_used_mb()


func has_storage_space(for_mb: float) -> bool:
	return _storage.has_storage_space(for_mb)


func get_storage_free_mb() -> float:
	return _storage.get_storage_free_mb()


# --- Пайплайн ---

func can_record() -> bool:
	return _pipeline.can_record()


func can_record_at(uid: String) -> bool:
	return _pipeline.can_record_at(uid)


func can_download_at(uid: String) -> bool:
	return _pipeline.can_download_at(uid)


func can_upload_at(uid: String) -> bool:
	return _pipeline.can_upload_at(uid)


func can_collect_at(uid: String) -> bool:
	return _pipeline.can_collect_at(uid)


func can_enqueue_download() -> bool:
	return _pipeline.can_enqueue_download()


func can_enqueue_upload() -> bool:
	return _pipeline.can_enqueue_upload()


func can_collect_money() -> bool:
	return _pipeline.can_collect_money()


func collect_money() -> bool:
	return _pipeline.collect_money()


func start_recording_at(uid: String) -> bool:
	return _pipeline.start_recording_at(uid)


func run_block_action(uid: String) -> bool:
	return _pipeline.run_block_action(uid)


func enqueue_download() -> bool:
	return _pipeline.enqueue_download()


func enqueue_upload() -> bool:
	return _pipeline.enqueue_upload()


func get_phase_label() -> String:
	return _pipeline.get_phase_label()


# --- Константы UI (прокси) ---

func get_pipeline_label() -> String:
	return GameConstants.PIPELINE_LABEL


func get_money_pipeline_label() -> String:
	return GameConstants.MONEY_PIPELINE_LABEL


func get_wiring_hint() -> String:
	return GameConstants.WIRING_HINT


func run_publish_pause(job: FileTransferJob) -> void:
	_pipeline.apply_publish(job)
	_finish_publish_pause_async()


func _finish_publish_pause_async() -> void:
	await get_tree().create_timer(GameConstants.PUBLISH_PAUSE_SEC).timeout
	_pipeline.finish_publish_pause()
