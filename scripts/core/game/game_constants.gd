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
# Размер файла при скачивании: случайный, но не больше speed_bps × множитель (≈ 50 с на линии)
const DOWNLOAD_SIZE_SPEED_MULTIPLIER := 50.0
# Текстовые файлы — небольшие (абсолютный потолок ниже cap по скорости)
const TEXT_FILE_BYTES_MIN := 400.0
const TEXT_FILE_BYTES_MAX := 3_200.0
const MIN_DOWNLOAD_RESERVE_BYTES := TEXT_FILE_BYTES_MAX
const DEFAULT_STORED_FILE_BYTES := 1_000.0

const MAX_QUEUE_JOBS := 5
const MIN_COLLECT_BALANCE := 0.01
const MIN_JOB_DURATION_SEC := 0.05

const QUALITY_PER_DOWNLOADER_LEVEL := 0.08

# Пауза после выгрузки; доход — от объёма файла (байты), не от «просмотров»
const UPLOAD_SETTLE_PAUSE_SEC := 1.0
const REVENUE_PER_BYTE := 0.04 / BYTE_SIZE_SCALE

const DEFAULT_UPGRADE_BASE := 30
const DEFAULT_UPGRADE_MULT := 1.4
