extends RefCounted
class_name GameSaveService
## Сервис сохранений: снимок состояния через SaveBackend.

var _data: GameStateData
var _premium: PremiumCurrencyService
var _host: Node
var _backend: SaveBackend


func _init(
	data: GameStateData, premium: PremiumCurrencyService, host: Node, backend: SaveBackend
) -> void:
	_data = data
	_premium = premium
	_host = host
	_backend = backend


func set_backend(backend: SaveBackend) -> void:
	_backend = backend


func is_persistent() -> bool:
	return _backend.is_persistent()


func has_save(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	return _backend.has_save(slot_id)


func save(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	var snap := GameSaveSnapshot.capture(_data, _premium)
	if not snap.is_valid():
		return false
	return _backend.write_save(slot_id, snap.to_payload())


func load(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	var payload := _backend.read_save(slot_id)
	if payload.is_empty():
		return false
	var snap := GameSaveSnapshot.from_payload(payload)
	if not snap.apply_to(_data, _premium):
		return false
	_notify_state_restored()
	return true


func delete_save(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	return _backend.delete_save(slot_id)


## Новая игра: стартовое состояние в памяти + удаление слота на диске.
func reset_progress(slot_id: String = SaveConstants.DEFAULT_SLOT) -> bool:
	_data.reset_to_initial()
	_premium.reset()
	var deleted := _backend.delete_save(slot_id)
	_notify_state_restored()
	return deleted


func _notify_state_restored() -> void:
	# UI и поле подписаны на эти сигналы после загрузки/сохранения.
	# Порядок важен: сначала блоки (создаёт узлы и порты), затем провода (рисуются по портам).
	_host.field_changed.emit()
	_host.wiring_changed.emit()
	_host.stats_changed.emit()
	_host.queue_changed.emit()
