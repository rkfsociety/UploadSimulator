# Добавление нового модуля

Цепочка для игрока:

1. **Магазин ◆** — открыть тип модуля за алмазы (`diamond_unlock_cost`).
2. **Магазин $ (корзина)** — купить экземпляр за кассу (`shop_cost`), поставить на карту.
3. Провода и улучшения уровня модуля — как у остальных блоков.

## Шаги в коде

1. Добавить тип в `BlockDefs.TYPES`:
   - `unlocked_at_start: false`
   - `diamond_unlock_cost: <цена в ◆>`
   - `shop_cost`, порты, `ALLOWED_WIRES`, баланс как у соседних модулей.
2. Стартовый набор (`starter_kit_types`) не трогать — только модули с `unlocked_at_start: true`.
3. При необходимости — метрики в `GameDisplayService` и действие в `GamePipelineService.run_block_action`.

Пример полей:

```gdscript
"vpn_gateway": {
    "name": "VPN-шлюз",
    "icon": "🔒",
    "unlocked_at_start": false,
    "diamond_unlock_cost": 12,
    "shop_cost": 95,
    # ... ports, upgrade_base, ...
},
```

После этого тип появится в разделе **«Новые модули»** магазина ◆ и, после открытия, в магазине модулей за $.
