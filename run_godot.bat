@echo off
rem Запуск Upload Simulator в редакторе Godot 4.6.2
chcp 65001 >nul

set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

rem Путь к Godot (переопредели через переменную окружения GODOT_EXE)
if not defined GODOT_EXE set "GODOT_EXE=F:\github\cursor\Godot\Godot_v4.6.2-stable_win64.exe"

if not exist "%GODOT_EXE%" (
	echo [Ошибка] Godot не найден:
	echo   %GODOT_EXE%
	echo.
	echo Укажи свой путь, например:
	echo   set GODOT_EXE=C:\Tools\Godot_v4.6.2-stable_win64.exe
	echo   run_godot.bat
	echo.
	pause
	exit /b 1
)

echo Проект: %PROJECT_DIR%
echo Godot:  %GODOT_EXE%
start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
