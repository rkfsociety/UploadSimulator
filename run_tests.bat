@echo off
setlocal EnableExtensions

rem Прогон тестов Godot (headless)
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

set "LOCAL_GODOT=%PROJECT_DIR%\Godot\Godot_v4.6.2-stable_win64_console.exe"
if not defined GODOT_EXE (
	set "GODOT_EXE=%LOCAL_GODOT%"
)

if not exist "%GODOT_EXE%" (
	echo ERROR: Godot console not found:
	echo   %GODOT_EXE%
	exit /b 1
)

echo Project: %PROJECT_DIR%
echo Godot:   %GODOT_EXE%
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" -s res://tests/test_runner.gd
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
