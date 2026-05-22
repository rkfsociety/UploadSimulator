extends RefCounted
class_name GameConstants
## Константы баланса и UI (вместо магических чисел в коде).

const PIPELINE_LABEL := "Загрузчик → Хранилище → Аплоудер"
const MONEY_PIPELINE_LABEL := "Аплоудер → Коллектор"
const WIRING_HINT := "Круг = файлы | Квадрат/ромб = деньги"

# Скорости передачи (байт/с), README: 100 Б/с на 1-м уровне
const BASE_DOWNLOAD_SPEED_BPS := 100.0
const BASE_UPLOAD_SPEED_BPS := 100.0

# Масштаб размеров при переходе с условных «МБ» на байты (длительности очередей сохраняются)
const _LEGACY_SPEED_MBPS := 3.5
const BYTE_SIZE_SCALE := BASE_DOWNLOAD_SPEED_BPS / _LEGACY_SPEED_MBPS

# Ёмкость и файлы (байты)
const BASE_STORAGE_BYTES := 32.0 * 1024.0 * BYTE_SIZE_SCALE
const RAW_FILE_BYTES := 18.0 * BYTE_SIZE_SCALE
const MIN_DOWNLOAD_RESERVE_BYTES := 140.0 * BYTE_SIZE_SCALE
const DOWNLOAD_ASSETS_BYTES_MIN := 35.0 * BYTE_SIZE_SCALE
const DOWNLOAD_ASSETS_BYTES_MAX := 120.0 * BYTE_SIZE_SCALE
const DOWNLOAD_VIDEO_BYTES_MIN := 70.0 * BYTE_SIZE_SCALE
const DOWNLOAD_VIDEO_BYTES_MAX := 200.0 * BYTE_SIZE_SCALE
const DEFAULT_STORED_FILE_BYTES := 100.0 * BYTE_SIZE_SCALE

const START_ENERGY := 100.0
const ENERGY_REGEN_PER_SEC := 6.0
const RECORD_ENERGY_COST := 25.0

const MAX_QUEUE_JOBS := 5
const MIN_COLLECT_BALANCE := 0.01
const MIN_JOB_DURATION_SEC := 0.05

const STUDIO_BASE_DURATION_SEC := 4.0
const QUALITY_PER_DOWNLOADER_LEVEL := 0.08

const PUBLISH_PAUSE_SEC := 1.0
const PUBLISH_VIEWS_MIN := 40
const PUBLISH_VIEWS_MAX := 180
const REVENUE_PER_VIEW := 0.04
const PUBLISH_SUBSCRIBERS_MAX := 3

const DEFAULT_UPGRADE_BASE := 30
const DEFAULT_UPGRADE_MULT := 1.4
