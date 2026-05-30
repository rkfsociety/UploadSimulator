# Добавление нового модуля

Цепочка для игрока:

1. **Магазин ◆** — открыть тип модуля за алмазы (`diamond_unlock_cost`).
2. **Магазин $ (корзина)** — купить экземпляр за кассу (`shop_cost`), поставить на карту.
3. Провода и улучшения уровня модуля — как у остальных блоков.

## Шаги в коде

1. Создать файл `scripts/core/defs/modules/<type_id>_module.gd` по образцу соседних модулей:
   - `TYPE_ID`, `build()` — поля модуля (`shop_cost`, порты, `cells_w` / `cells_h`…)
   - `wire_pairs()` — исходящие соединения `[["from_type", "to_type"], …]`
   - `in_starter_kit()` — `true`, если тип в базовом наборе
   - для загрузчиков — `file_type_id` (см. `FileDefs`)
2. Добавить preload в `_MODULE_SCRIPTS` в `block_defs.gd`.
3. При необходимости — метрики в `GameDisplayService` и поведение в `GamePipelineService`.

Пример нового модуля — `scripts/core/defs/modules/text_downloader_module.gd`.

Для модулей с `unlocked_at_start: false` укажите `diamond_unlock_cost` и `in_starter_kit() -> false`.
