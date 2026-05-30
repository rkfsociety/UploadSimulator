extends RefCounted
class_name GameConstants
## Фасад лимитов геймплея: значения из GameBalanceConfig (ресурс + опциональный user://).

# Preload убирает циклическую зависимость class_name при _static_init
const _BalanceConfig := preload("res://scripts/core/game/game_balance_config.gd")

const PIPELINE_LABEL := "Сеть → Text Downloader → Аплоудер → Сеть"
const MONEY_PIPELINE_LABEL := "Аплоудер → Коллектор"
const WIRING_HINT := "Круг = файлы и канал | Квадрат/ромб = деньги"

const CONFIG_RESOURCE := "res://resources/game_balance.tres"
const USER_CONFIG_PATH := "user://game_balance.tres"

# Заполняются в _static_init из game_balance.tres (или user://game_balance.tres)
static var BASE_DOWNLOAD_SPEED_BPS: float
static var BASE_UPLOAD_SPEED_BPS: float
static var BYTE_SIZE_SCALE: float
static var BASE_STORAGE_FILES: int
static var STORAGE_FILES_PER_LEVEL: int
static var RAW_FILE_BYTES: float
static var DOWNLOAD_SIZE_SPEED_MULTIPLIER: float
static var TEXT_FILE_BYTES_MIN: float
static var TEXT_FILE_BYTES_MAX: float
static var START_DIAMONDS: int
static var DIAMONDS_PER_UPLOAD: int
static var DEFAULT_STORED_FILE_BYTES: float
static var MAX_QUEUE_JOBS: int
static var MIN_COLLECT_BALANCE: float
static var MIN_JOB_DURATION_SEC: float
static var QUALITY_PER_DOWNLOADER_LEVEL: float
static var UPLOAD_SETTLE_PAUSE_SEC: float
static var REVENUE_PER_BYTE: float
static var DEFAULT_UPGRADE_BASE: float
static var DEFAULT_UPGRADE_MULT: float
static var MAX_TRANSFER_JOB_DURATION_SEC: float

static var _balance: Resource


static func _static_init() -> void:
	_apply_config(_load_balance_config())


# Загрузка: user:// переопределяет ресурс из репозитория
static func _load_balance_config() -> Resource:
	if FileAccess.file_exists(USER_CONFIG_PATH):
		var user_cfg: Variant = ResourceLoader.load(USER_CONFIG_PATH)
		if user_cfg != null and user_cfg.get_script() == _BalanceConfig:
			return user_cfg as Resource
		push_warning("GameConstants: %s не GameBalanceConfig, берём дефолт из репозитория." % USER_CONFIG_PATH)
	if ResourceLoader.exists(CONFIG_RESOURCE):
		var base_cfg: Variant = load(CONFIG_RESOURCE)
		if base_cfg != null and base_cfg.get_script() == _BalanceConfig:
			return base_cfg as Resource
	push_warning("GameConstants: не найден %s, встроенные значения по умолчанию." % CONFIG_RESOURCE)
	return _BalanceConfig.new()


static func _apply_config(cfg: Resource) -> void:
	_balance = cfg
	BASE_DOWNLOAD_SPEED_BPS = cfg.base_download_speed_bps
	BASE_UPLOAD_SPEED_BPS = cfg.base_upload_speed_bps
	BYTE_SIZE_SCALE = cfg.byte_size_scale()
	BASE_STORAGE_FILES = cfg.base_storage_files
	STORAGE_FILES_PER_LEVEL = cfg.storage_files_per_level
	RAW_FILE_BYTES = cfg.raw_file_bytes()
	MAX_TRANSFER_JOB_DURATION_SEC = cfg.max_transfer_job_duration_sec
	DOWNLOAD_SIZE_SPEED_MULTIPLIER = MAX_TRANSFER_JOB_DURATION_SEC
	TEXT_FILE_BYTES_MIN = cfg.text_file_bytes_min
	TEXT_FILE_BYTES_MAX = cfg.text_file_bytes_max
	START_DIAMONDS = cfg.start_diamonds
	DIAMONDS_PER_UPLOAD = cfg.diamonds_per_upload
	DEFAULT_STORED_FILE_BYTES = cfg.default_stored_file_bytes
	MAX_QUEUE_JOBS = cfg.max_queue_jobs
	MIN_COLLECT_BALANCE = cfg.min_collect_balance
	MIN_JOB_DURATION_SEC = cfg.min_job_duration_sec
	QUALITY_PER_DOWNLOADER_LEVEL = cfg.quality_per_downloader_level
	UPLOAD_SETTLE_PAUSE_SEC = cfg.upload_settle_pause_sec
	REVENUE_PER_BYTE = cfg.revenue_per_byte()
	DEFAULT_UPGRADE_BASE = cfg.default_upgrade_base
	DEFAULT_UPGRADE_MULT = cfg.default_upgrade_mult
	FileDefs.sync_limits_from_balance()
	BlockDefs.sync_limits_from_balance()


## Текущий ресурс баланса (для отладки и тестов).
static func get_balance_config() -> Resource:
	return _balance


## Перечитать конфиг с диска (после правки user://game_balance.tres).
static func reload_balance_config() -> void:
	_apply_config(_load_balance_config())
