@echo off
setlocal EnableExtensions

rem Сборка релизного APK для Android (без debug-оверлея) без редактора Godot
set "PROJECT_DIR=%~dp0"
if "%PROJECT_DIR:~-1%"=="\" set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

set "LOCAL_GODOT=%PROJECT_DIR%\Godot\Godot_v4.6.2-stable_win64_console.exe"
if not defined GODOT_EXE (
	set "GODOT_EXE=%LOCAL_GODOT%"
)

if not exist "%GODOT_EXE%" (
	echo ERROR: Godot console not found:
	echo   %GODOT_EXE%
	pause
	exit /b 1
)

set "APK_PATH=%PROJECT_DIR%\build\UploadSimulator-release.apk"

rem Подпись релизного APK тем же debug-ключом (для личного теста, не для Google Play)
set "GODOT_ANDROID_KEYSTORE_RELEASE_PATH=%PROJECT_DIR%\Godot\keystores\debug.keystore"
set "GODOT_ANDROID_KEYSTORE_RELEASE_USER=androiddebugkey"
set "GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD=android"

echo Project: %PROJECT_DIR%
echo Godot:   %GODOT_EXE%
echo APK:     %APK_PATH%
echo.

if not exist "%PROJECT_DIR%\.godot" (
	echo First run: importing project...
	"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --import --quit-after 1
	if errorlevel 1 (
		echo ERROR: import failed.
		pause
		exit /b 1
	)
	echo.
)

if not exist "%PROJECT_DIR%\build" mkdir "%PROJECT_DIR%\build"

echo Exporting Android APK (release)...
"%GODOT_EXE%" --headless --path "%PROJECT_DIR%" --export-release "Android" "%APK_PATH%"
if errorlevel 1 (
	echo.
	echo ERROR: export failed. Check SDK/JDK/keystore paths in local editor settings:
	echo   Godot\editor_data\editor_settings-4.6.tres
	pause
	exit /b 1
)

echo.
echo Done: %APK_PATH%
endlocal & exit /b 0
