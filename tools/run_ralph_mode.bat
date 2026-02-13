@echo off
setlocal

set FEATURE_NAME=%~1
if "%FEATURE_NAME%"=="" set FEATURE_NAME=ralph-default

powershell -ExecutionPolicy Bypass -File "tools\reference_ops_agent.ps1" -Feature "%FEATURE_NAME%"
if errorlevel 1 (
	echo [RALPH] workflow failed
	exit /b 1
)

call "tools\run_headless_smoke.bat"
if errorlevel 1 (
	echo [RALPH] smoke test failed
	exit /b 1
)

echo [RALPH] completed successfully
exit /b 0
