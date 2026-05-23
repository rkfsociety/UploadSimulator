@echo off
setlocal EnableExtensions

rem Upload Simulator — открыть проект в РЕДАКТОРЕ Godot (игра: run_game.bat или F5)
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

rem 1) переменная окружения  2) Godot/ в корне репозитория
set "LOCAL_GODOT=%PROJECT_DIR%\Godot\Godot_v4.6.2-stable_win64.exe"
if not defined GODOT_EXE (
	set "GODOT_EXE=%LOCAL_GODOT%"
)

if not exist "%GODOT_EXE%" (
	echo ERROR: Godot not found:
	echo   %GODOT_EXE%
	echo.
	echo Put Godot 4.6.2 into: %PROJECT_DIR%\Godot\
	echo   or set path:
	echo   set GODOT_EXE=C:\Path\To\Godot_v4.6.2-stable_win64.exe
	echo   run_godot.bat
	echo.
	pause
	exit /b 1
)

echo Project: %PROJECT_DIR%
echo Godot:   %GODOT_EXE%
start "" "%GODOT_EXE%" --path "%PROJECT_DIR%"
endlocal
