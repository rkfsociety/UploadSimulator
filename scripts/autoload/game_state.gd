extends Node
## Фасад глобального состояния: сигналы, тик пайплайна, модули API.

const _AsyncSafety := preload("res://scripts/core/async_safety.gd")

signal stats_changed
signal queue_changed
## Лёгкое обновление UI модулей при прогрессе очереди (без полного field_changed).
signal blocks_progress_changed
signal log_message(text: String)
## Код GameOperationResult.Code и текст — для UI/отладки без разбора лога.
signal operation_failed(code: int, message: String)
signal wiring_changed
signal field_changed
signal placement_requested(type_id: String)
signal block_purchased(type_id: String)

enum Phase { IDLE, SETTLING }

var access: GameStateAccess
var field: GameStateField
var display: GameStateDisplay
var wiring: GameStateWiring
var storage: GameStateStorage
var pipeline: GameStatePipeline
var environment: GameStateEnvironment
var premium: GameStatePremium
var save: GameStateSave

var _data: GameStateData
var _field_svc: GameFieldService
var _wiring_svc: GameWiringService
var _storage_svc: GameStorageService
var _premium_svc: PremiumCurrencyService
var _pipeline_svc: GamePipelineService
var _display_svc: GameDisplayService
var _environment_svc: GameEnvironmentService
var _save_svc: GameSaveService


func _ready() -> void:
	_data = GameStateData.new()
	_premium_svc = PremiumCurrencyService.new(self)
	_field_svc = GameFieldService.new(_data, self)
	_wiring_svc = GameWiringService.new(_data, self, _field_svc)
	_storage_svc = GameStorageService.new(_data, _field_svc)
	_environment_svc = GameEnvironmentService.new(_data, self, _premium_svc)
	_pipeline_svc = GamePipelineService.new(
		_data, self, _field_svc, _wiring_svc, _storage_svc, _premium_svc
	)
	_wiring_svc.bind_pipeline(_pipeline_svc)
	_save_svc = GameSaveService.new(_data, _premium_svc, self, NullSaveBackend.new())
	_display_svc = GameDisplayService.new(_data, _field_svc, _wiring_svc, _storage_svc, _pipeline_svc)
	access = GameStateAccess.new(_data)
	field = GameStateField.new(_field_svc)
	display = GameStateDisplay.new(_display_svc)
	wiring = GameStateWiring.new(_wiring_svc)
	storage = GameStateStorage.new(_storage_svc)
	pipeline = GameStatePipeline.new(_pipeline_svc)
	environment = GameStateEnvironment.new(_environment_svc)
	premium = GameStatePremium.new(_premium_svc)
	save = GameStateSave.new(_save_svc)


func _process(delta: float) -> void:
	_pipeline_svc.tick(delta)


func run_publish_pause(job: FileTransferJob) -> void:
	pipeline.apply_publish(job)
	_finish_publish_pause_async()


func _finish_publish_pause_async() -> void:
	var tree := get_tree()
	if tree == null:
		return
	await tree.create_timer(GameConstants.UPLOAD_SETTLE_PAUSE_SEC).timeout
	# После паузы сцена могла выгрузиться — не трогаем пайплайн на мёртвом узле
	if not _AsyncSafety.is_node_alive(self):
		return
	pipeline.finish_publish_pause()


## Показывает ошибку в логе и шлёт operation_failed; возвращает успех операции.
func report_operation(result: GameOperationResult) -> bool:
	if result.is_ok():
		return true
	var msg := result.get_message()
	if not msg.is_empty():
		log_message.emit(msg)
	operation_failed.emit(result.code, msg)
	return false
