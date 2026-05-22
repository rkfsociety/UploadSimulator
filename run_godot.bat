@echo off
setlocal EnableExtensions

rem Upload Simulator - open project in Godot editor
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

if not defined GODOT_EXE (
	set "GODOT_EXE=F:\github\cursor\Godot\Godot_v4.6.2-stable_win64.exe"
)

if not exist "%GODOT_EXE%" (
	echo ERROR: Godot not found:
	echo   %GODOT_EXE%
	echo.
	echo Set custom path, then run again:
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
