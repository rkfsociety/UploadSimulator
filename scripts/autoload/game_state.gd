extends Node
## Фасад глобального состояния: сигналы, тик пайплайна, модули API.

const _AsyncSafety := preload("res://scripts/core/async_safety.gd")

## Периодическое автосохранение на случай некорректного завершения (краш, kill).
const AUTOSAVE_INTERVAL_SEC := 30.0

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

var _autosave_accum: float = 0.0


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
	_save_svc = GameSaveService.new(_data, _premium_svc, self, FileSaveBackend.new())
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
	# Сохраняем прогресс при закрытии окна / сворачивании — обрабатываем сами в _notification
	get_tree().auto_accept_quit = false
	_load_on_start()


## Автозагрузка слота по умолчанию при старте (если есть). UI читает состояние в своих _ready.
func _load_on_start() -> void:
	if save.has_save():
		save.load()


func _process(delta: float) -> void:
	_pipeline_svc.tick(delta)
	_autosave_accum += delta
	if _autosave_accum >= AUTOSAVE_INTERVAL_SEC:
		_autosave_accum = 0.0
		_autosave()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_WM_GO_BACK_REQUEST:
			_autosave()
			get_tree().quit()
		NOTIFICATION_APPLICATION_PAUSED:
			# Android: уход в фон — сохраняем сразу
			_autosave()


func _autosave() -> void:
	if _save_svc != null and _save_svc.is_persistent():
		_save_svc.save()


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
