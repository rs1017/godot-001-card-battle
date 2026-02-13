@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

set "GUI_EXE=Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"
set "LOG_FILE=.tmp\godot-live.log"

if not exist "%GUI_EXE%" (
	echo [FAIL] Missing executable: %GUI_EXE%
	popd
	exit /b 1
)

if not exist ".tmp" mkdir ".tmp"
if exist "%LOG_FILE%" del /f /q "%LOG_FILE%" >nul 2>nul

echo [RUN] GUI: %GUI_EXE% --path . --rendering-driver opengl3 --windowed --log-file %LOG_FILE%
start "" "%GUI_EXE%" --path . --rendering-driver opengl3 --windowed --log-file %LOG_FILE%

echo [RUN] CONSOLE LOG: tail -f %LOG_FILE%
start "Godot Live Console" cmd /k "powershell -NoLogo -NoExit -Command \"Get-Content '%LOG_FILE%' -Wait\""

popd
exit /b 0
