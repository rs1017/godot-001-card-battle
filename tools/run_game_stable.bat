@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

set "GUI_EXE=Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64.exe"
set "LOG_DIR=docs\qa\bug_reports"
set "LOG_FILE=%LOG_DIR%\godot-live.log"
set "ERROR_LOG=%LOG_DIR%\godot-errors.log"
set "WINDOW_RES=1600x900"
set "WINDOW_POS=120,60"

if not exist "%GUI_EXE%" (
	echo [FAIL] Missing executable: %GUI_EXE%
	popd
	exit /b 1
)

if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
if exist "%LOG_FILE%" del /f /q "%LOG_FILE%" >nul 2>nul
if exist "%ERROR_LOG%" del /f /q "%ERROR_LOG%" >nul 2>nul

echo [RUN] GUI: %GUI_EXE% --path . --rendering-driver opengl3 --windowed --resolution %WINDOW_RES% --position %WINDOW_POS% --log-file %LOG_FILE%
start "" "%GUI_EXE%" --path . --rendering-driver opengl3 --windowed --resolution %WINDOW_RES% --position %WINDOW_POS% --log-file %LOG_FILE%

echo [RUN] CONSOLE LOG: live game log stream from %LOG_FILE%
start "Godot Live Console" powershell -NoLogo -NoExit -Command "Write-Host '[LIVE GAME LOG]' -ForegroundColor Cyan; Write-Host '[ERROR LOG] %ERROR_LOG%' -ForegroundColor Yellow; while (-not (Test-Path '%LOG_FILE%')) { Start-Sleep -Milliseconds 200 }; Get-Content '%LOG_FILE%' -Tail 80 -Wait | ForEach-Object { $_; if ($_ -like 'ERROR:*') { Add-Content -Path '%ERROR_LOG%' -Value $_ } }"

popd
exit /b 0
