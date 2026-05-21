extends Node
## Фасад глобального состояния: сигналы, тик пайплайна, модули API.

signal stats_changed
signal queue_changed
signal log_message(text: String)
signal wiring_changed
signal field_changed
signal placement_requested(type_id: String)
signal block_purchased(type_id: String)

enum Phase { IDLE, RECORDING, UPLOADING, PUBLISHED }

var access: GameStateAccess
var field: GameStateField
var display: GameStateDisplay
var wiring: GameStateWiring
var storage: GameStateStorage
var pipeline: GameStatePipeline

var _data: GameStateData
var _field_svc: GameFieldService
var _wiring_svc: GameWiringService
var _storage_svc: GameStorageService
var _pipeline_svc: GamePipelineService
var _display_svc: GameDisplayService


func _ready() -> void:
	_data = GameStateData.new()
	_field_svc = GameFieldService.new(_data, self)
	_wiring_svc = GameWiringService.new(_data, self, _field_svc)
	_storage_svc = GameStorageService.new(_data, _field_svc)
	_pipeline_svc = GamePipelineService.new(_data, self, _field_svc, _wiring_svc, _storage_svc)
	_display_svc = GameDisplayService.new(_data, _field_svc, _wiring_svc, _storage_svc, _pipeline_svc)
	access = GameStateAccess.new(_data)
	field = GameStateField.new(_field_svc)
	display = GameStateDisplay.new(_display_svc)
	wiring = GameStateWiring.new(_wiring_svc)
	storage = GameStateStorage.new(_storage_svc)
	pipeline = GameStatePipeline.new(_pipeline_svc)


func _process(delta: float) -> void:
	_pipeline_svc.tick(delta)


func run_publish_pause(job: FileTransferJob) -> void:
	pipeline.apply_publish(job)
	_finish_publish_pause_async()


func _finish_publish_pause_async() -> void:
	await get_tree().create_timer(GameConstants.PUBLISH_PAUSE_SEC).timeout
	pipeline.finish_publish_pause()
