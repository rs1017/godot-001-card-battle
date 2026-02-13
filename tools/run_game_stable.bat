@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

set "GUI_EXE=Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"
set "CONSOLE_EXE=Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe"
set "LOG_FILE=.tmp\godot-live.log"

if not exist "%GUI_EXE%" (
	echo [FAIL] Missing executable: %GUI_EXE%
	popd
	exit /b 1
)

if not exist "%CONSOLE_EXE%" (
	echo [FAIL] Missing executable: %CONSOLE_EXE%
	popd
	exit /b 1
)

if not exist ".tmp" mkdir ".tmp"

echo [RUN] GUI: %GUI_EXE% --path . --rendering-driver opengl3 --windowed
start "" "%GUI_EXE%" --path . --rendering-driver opengl3 --windowed

echo [RUN] CONSOLE: %CONSOLE_EXE% --path . --rendering-driver opengl3 --windowed --log-file %LOG_FILE%
start "Godot Live Console" cmd /k ""%CONSOLE_EXE%" --path . --rendering-driver opengl3 --windowed --log-file %LOG_FILE%""

popd
exit /b 0
