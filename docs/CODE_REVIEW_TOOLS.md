# Проверка кода и бесплатные AI-инструменты

В репозитории уже настроены **автоматические проверки** (GitHub Actions).  
Ниже — что работает из коробки и что нужно **один раз включить** в настройках GitHub.

## Уже в репозитории (бесплатно)

| Инструмент | Что делает | Где |
|------------|------------|-----|
| **CI** | Godot import, `gdlint`, `gdformat`, Ruff, Semgrep, actionlint | `.github/workflows/ci.yml` |
| **CodeQL** | Поиск уязвимостей в Python (`tools/`) | `.github/workflows/codeql.yml` |
| **Dependabot** | Обновления Actions и pip | `.github/dependabot.yml` |
| **pre-commit** | Локальные хуки перед коммитом | `.pre-commit-config.yaml` |
| **CodeRabbit** | Конфиг AI-ревью PR | `.coderabbit.yaml` |

### Локально перед коммитом

```powershell
pip install -r requirements-dev.txt
pre-commit install
pre-commit run --all-files
```

```powershell
gdlint scripts/
gdformat scripts/
```

---

## AI-ревью PR (бесплатные / freemium)

Установите GitHub App на репозиторий **rkfsociety/UploadSimulator** (или свой fork).

### CodeRabbit

- **Сайт:** https://coderabbit.ai  
- **Установка:** https://github.com/apps/coderabbitai  
- **Конфиг:** `.coderabbit.yaml` (уже в корне)  
- **Тариф:** бесплатный план для OSS и ограниченный для private — см. их pricing  
- **Что даёт:** комментарии к PR, summary, чат по диффу  

### Gemini Code Assist for GitHub

- **Установка:** https://github.com/marketplace/gemini-code-assist  
- **Тариф:** бесплатный tier с лимитами (Google)  
- **Что даёт:** ревью PR, ответы на issues, предложения по коду  

### GitHub Copilot (Pull Request reviews)

- **Нужно:** подписка Copilot (есть бесплатно для студентов / open source maintainers)  
- **Включение:** Settings → Copilot → PR reviews  
- **Что даёт:** AI summary и комментарии к PR  

### Amazon Q Developer (GitHub)

- **Установка:** AWS / GitHub Marketplace integration  
- **Тариф:** free tier с квотами  
- **Что даёт:** ревью и объяснение изменений в PR  

### Snyk

- **Установка:** https://github.com/apps/snyk  
- **Тариф:** бесплатно для open source; для private — лимитированный free  
- **Что даёт:** уязвимости в зависимостях (если появятся npm/pip lock в проекте)  

### Codacy

- **Установка:** https://github.com/apps/codacy  
- **Тариф:** free для public repos  
- **Что даёт:** качество кода, дубликаты, coverage (для поддерживаемых языков)  

### Greptile

- **Сайт:** https://greptile.com  
- **Тариф:** trial / freemium  
- **Что даёт:** AI-обзор всего репозитория и PR  

---

## IDE и редактор (бесплатно)

| Инструмент | Назначение |
|------------|------------|
| **Cursor** | AI-агент, ревью файлов, Bugbot на PR (по плану Cursor) |
| **Godot Editor** | Встроенная проверка GDScript при сохранении |
| **gdtoolkit** | `gdlint` + `gdformat` в терминале |
| **Ruff** | Линт `tools/*.py` |

---

## Рекомендуемый минимум для этого проекта

1. Оставить включёнными **CI + CodeQL + Dependabot** (уже в `.github/`).  
2. Поставить **CodeRabbit** или **Gemini Code Assist** на репозиторий — AI-ревью PR.  
3. Локально: **pre-commit** + Godot перед пушем.  

После push в `master` открой **Actions** на GitHub и убедись, что workflow зелёные.
