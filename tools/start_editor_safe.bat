@echo off
setlocal
set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

powershell -ExecutionPolicy Bypass -File "tools\start_editor_safe.ps1"
set "EXIT_CODE=%ERRORLEVEL%"

popd
exit /b %EXIT_CODE%
