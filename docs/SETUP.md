# Запуск на новом ПК

Краткая инструкция после `git clone` — чтобы проект открылся и игра запустилась без ручной донастройки.

## Требования

| Что | Версия |
|-----|--------|
| Godot | **4.6.x** (в проекте указано `4.6`, CI использует **4.6.2**) |
| ОС | Windows / Linux / macOS (редактор Godot) |

Скачать: [godotengine.org/download](https://godotengine.org/download) — сборка **Standard**, не .NET.

## Шаги

1. Клонируй репозиторий:
   ```bash
   git clone https://github.com/rkfsociety/UploadSimulator.git
   cd UploadSimulator
   ```

2. Открой Godot → **Project → Import** → выбери файл `project.godot` в корне папки.

3. Первое открытие: редактор создаст папку `.godot/` и переимпортирует ассеты (`assets/*.import`). Это нормально, подожди завершения импорта.

4. Запуск игры: **F5** (главная сцена `scenes/main.tscn`).

## Запуск из командной строки (Windows)

Двойной клик по **`run_godot.bat`** в корне проекта (редактор Godot).

Удобно положить распакованный Godot **4.6.2** в папку **`Godot/`** в корне репозитория (как у тебя сейчас) — скрипт подхватит его сам. Папка `Godot/` в git не попадает.

Если редактор в другом месте — один раз в cmd:

```bat
set GODOT_EXE=C:\путь\к\Godot_v4.6.2-stable_win64.exe
run_godot.bat
```

Тесты без редактора: **`run_tests.bat`** (нужен `Godot_v4.6.2-stable_win64_console.exe` в той же папке `Godot/`).

Или вручную:

```powershell
& "F:\github\cursor\Godot\Godot_v4.6.2-stable_win64.exe" --path "F:\путь\к\UploadSimulator"
```

Игра (без редактора), если нужно:

```powershell
& "F:\github\cursor\Godot\Godot_v4.6.2-stable_win64.exe" --path "F:\путь\к\UploadSimulator" res://scenes/main.tscn
```

## Что в git, а что появится локально

| В репозитории (нужно для clone) | Только на диске после открытия |
|---------------------------------|------------------------------|
| `project.godot`, `scenes/`, `scripts/` | `.godot/` — кэш редактора |
| `assets/` + `*.import` | |
| `*.gd.uid` рядом со скриптами | |
| `themes/`, `resources/`, `export_presets.cfg` | `build/` — после Export |

## Unit-тесты (опционально)

```bash
godot --headless --path . -s res://tests/test_runner.gd
```

## Помощь через Cursor / агента

Можно попросить агента: «открой проект UploadSimulator в Godot и запусти F5» — укажи путь к папке clone и к `Godot_v4.6.2-stable_win64.exe`, если Godot не в PATH.
