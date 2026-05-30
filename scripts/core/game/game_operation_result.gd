extends RefCounted
class_name GameOperationResult
## Результат операции: код ошибки и текст для UI/лога.

enum Code {
	OK,
	UNKNOWN,
	# Пайплайн файлов и денег
	PIPELINE_NO_CHAIN,
	PIPELINE_NO_MONEY_CHAIN,
	PIPELINE_PHASE_BUSY,
	PIPELINE_DOWNLOAD_QUEUE_FULL,
	PIPELINE_UPLOAD_QUEUE_FULL,
	PIPELINE_NO_STORAGE,
	PIPELINE_NO_FILES,
	PIPELINE_SAFE_EMPTY,
	PIPELINE_WRONG_MODULE,
	FILE_TYPE_UNSUPPORTED,
	# Поле и магазин $
	FIELD_INVALID_MODULE,
	FIELD_MODULE_LOCKED,
	FIELD_INSUFFICIENT_MONEY,
	FIELD_NO_STOCK,
	FIELD_OUT_OF_BOUNDS,
	FIELD_CELL_OCCUPIED,
	FIELD_INVALID_INSTANCE,
	# Провода
	WIRING_INVALID_MODULE,
	WIRING_TYPE_NOT_ALLOWED,
	WIRING_PORT_DIRECTION,
	WIRING_PORT_KIND_MISMATCH,
	WIRING_OUTPUT_BUSY,
	WIRING_INPUT_BUSY,
	# Магазин ◆
	ENV_UNKNOWN_UPGRADE,
	ENV_MAX_LEVEL,
	ENV_INSUFFICIENT_DIAMONDS,
	ENV_ALREADY_UNLOCKED,
	ENV_NOT_LOCKABLE,
}

var code: Code = Code.OK
## Дополнительный текст (перекрывает шаблон из message_for).
var detail: String = ""
## Полезная нагрузка при успехе (например uid модуля).
var value: Variant = null


static func ok(payload: Variant = null) -> GameOperationResult:
	var r := GameOperationResult.new()
	r.code = Code.OK
	r.value = payload
	return r


static func fail(err_code: Code, err_detail: String = "") -> GameOperationResult:
	var r := GameOperationResult.new()
	r.code = err_code
	r.detail = err_detail
	return r


func is_ok() -> bool:
	return code == Code.OK


func get_message() -> String:
	if is_ok():
		return ""
	if not detail.is_empty():
		return detail
	return message_for(code)


static func message_for(err_code: Code) -> String:
	match err_code:
		Code.PIPELINE_NO_CHAIN:
			return "Соедини сеть → Text Downloader → Загрузчик → сеть."
		Code.PIPELINE_NO_MONEY_CHAIN:
			return "Соедини порт денег аплоудера с коллектором."
		Code.PIPELINE_PHASE_BUSY:
			return "Дождись завершения текущей операции."
		Code.PIPELINE_DOWNLOAD_QUEUE_FULL:
			return "Очередь скачивания заполнена."
		Code.PIPELINE_UPLOAD_QUEUE_FULL:
			return "Очередь выгрузки заполнена."
		Code.PIPELINE_NO_STORAGE:
			return "Загрузчик переполнен (лимит 100 файлов)."
		Code.PIPELINE_NO_FILES:
			return "В загрузчике нет файлов для выгрузки."
		Code.PIPELINE_SAFE_EMPTY:
			return "Сейф аплоудера пуст."
		Code.PIPELINE_WRONG_MODULE:
			return "Действие недоступно для этого модуля."
		Code.FILE_TYPE_UNSUPPORTED:
			return "Этот тип файла пока нельзя скачать."
		Code.FIELD_INVALID_MODULE:
			return "Неизвестный тип модуля."
		Code.FIELD_MODULE_LOCKED:
			return "Сначала открой модуль в магазине ◆."
		Code.FIELD_INSUFFICIENT_MONEY:
			return "Недостаточно денег."
		Code.FIELD_NO_STOCK:
			return "Купи модуль в магазине."
		Code.FIELD_OUT_OF_BOUNDS:
			return "За пределами карты."
		Code.FIELD_CELL_OCCUPIED:
			return "Клетка занята."
		Code.FIELD_INVALID_INSTANCE:
			return "Модуль не найден на поле."
		Code.WIRING_INVALID_MODULE:
			return "Неверный порт или модуль."
		Code.WIRING_TYPE_NOT_ALLOWED:
			return "Соединение недоступно."
		Code.WIRING_PORT_DIRECTION:
			return "Соединяй выход (справа) с входом (слева)."
		Code.WIRING_PORT_KIND_MISMATCH:
			return "Разные типы сигнала на портах."
		Code.WIRING_OUTPUT_BUSY:
			return "У выхода уже есть провод."
		Code.WIRING_INPUT_BUSY:
			return "Вход уже занят."
		Code.ENV_UNKNOWN_UPGRADE:
			return "Неизвестное улучшение."
		Code.ENV_MAX_LEVEL:
			return "Достигнут максимальный уровень."
		Code.ENV_INSUFFICIENT_DIAMONDS:
			return "Недостаточно алмазов ◆."
		Code.ENV_ALREADY_UNLOCKED:
			return "Модуль уже открыт."
		Code.ENV_NOT_LOCKABLE:
			return "Этот модуль не открывается за ◆."
		_:
			return "Операция недоступна."


func get_uid() -> String:
	return str(value) if is_ok() else ""
