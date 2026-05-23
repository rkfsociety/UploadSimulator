extends Resource
class_name GameBalanceConfig
## Настраиваемые лимиты геймплея (редактор Godot или копия в user://).

@export_group("Очереди и задания")
## Сколько заданий скачивания/выгрузки может ждать в очереди одновременно.
@export var max_queue_jobs: int = 5
## Нижняя граница длительности задания (сек), чтобы прогресс не делил на ноль.
@export var min_job_duration_sec: float = 0.05
## Максимальная длительность одного переноса (сек) при генерации размера файла.
@export var max_transfer_job_duration_sec: float = 50.0

@export_group("Скорости передачи")
## Базовая скорость скачивания на 1-м уровне загрузчика (байт/с).
@export var base_download_speed_bps: float = 100.0
## Базовая скорость выгрузки на 1-м уровне аплоудера (байт/с).
@export var base_upload_speed_bps: float = 100.0
## Устаревшая «скорость» в условных МБ/с — только для масштаба байт из старых сохранений.
@export var legacy_speed_mbps: float = 3.5

@export_group("Хранилище и файлы")
## Базовая ёмкость диска (условные КБ до масштабирования BYTE_SIZE_SCALE).
@export var base_storage_legacy_kb: float = 32.0
## Прирост ёмкости хранилища за уровень (условные КБ × BYTE_SIZE_SCALE).
@export var storage_capacity_legacy_kb_per_level: float = 40.0
## Размер «сырого» файла в условных МБ (для совместимости, если понадобится).
@export var raw_file_legacy_mb: float = 18.0
## Минимум свободного места, чтобы разрешить новое скачивание (байт).
@export var min_download_reserve_bytes: float = 96_000.0
## Диапазон размера текстового файла при скачивании (байт).
@export var text_file_bytes_min: float = 400.0
@export var text_file_bytes_max: float = 3_200.0
## Размер файла по умолчанию в хранилище (если не задан явно).
@export var default_stored_file_bytes: float = 1_000.0

@export_group("Экономика")
@export var start_diamonds: int = 5
@export var diamonds_per_upload: int = 1
## Минимальный баланс в сейфе аплоудера для сбора в кассу.
@export var min_collect_balance: float = 0.01
## Числитель дохода за байт до деления на BYTE_SIZE_SCALE (как в старом балансе 0.04/scale).
@export var revenue_legacy_numerator: float = 0.04
## Бонус качества файла за уровень загрузчика.
@export var quality_per_downloader_level: float = 0.08
## Цена улучшения модуля по умолчанию, если в BlockDefs нет своих полей.
@export var default_upgrade_base: float = 30.0
@export var default_upgrade_mult: float = 1.4

@export_group("Тайминги")
## Пауза после выгрузки перед следующим действием (сек).
@export var upload_settle_pause_sec: float = 1.0


# Масштаб байт из старых сохранений в «МБ»
func byte_size_scale() -> float:
	return base_download_speed_bps / maxf(legacy_speed_mbps, 0.001)


func base_storage_bytes() -> float:
	return base_storage_legacy_kb * 1024.0 * byte_size_scale()


func raw_file_bytes() -> float:
	return raw_file_legacy_mb * byte_size_scale()


func revenue_per_byte() -> float:
	return revenue_legacy_numerator / byte_size_scale()
