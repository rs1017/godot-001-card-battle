@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

powershell -ExecutionPolicy Bypass -File "tools\run_godot_smoke_safe.ps1" -MaxAttempts 2
set "EXIT_CODE=%ERRORLEVEL%"

popd
exit /b %EXIT_CODE%
