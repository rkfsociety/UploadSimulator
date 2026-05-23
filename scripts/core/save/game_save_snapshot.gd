extends RefCounted
class_name GameSaveSnapshot
## Снимок прогресса: сериализация и восстановление GameStateData.


static func capture(data: GameStateData, premium: PremiumCurrencyService) -> GameSaveSnapshot:
	var snap := GameSaveSnapshot.new()
	var payload := data.export_save_dict()
	payload.merge(premium.export_save_dict())
	snap._payload = payload
	return snap


static func from_payload(payload: Dictionary) -> GameSaveSnapshot:
	var snap := GameSaveSnapshot.new()
	snap._payload = payload.duplicate(true)
	return snap


var _payload: Dictionary = {}


func is_valid() -> bool:
	if _payload.is_empty():
		return false
	var version: int = int(_payload.get("format_version", 0))
	return version == SaveConstants.FORMAT_VERSION


func to_payload() -> Dictionary:
	return _payload.duplicate(true)


func apply_to(data: GameStateData, premium: PremiumCurrencyService) -> bool:
	if not is_valid():
		return false
	data.import_save_dict(_payload)
	premium.import_save_dict(_payload)
	return true
