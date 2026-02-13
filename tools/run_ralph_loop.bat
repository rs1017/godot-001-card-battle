@echo off
setlocal

set FEATURE_NAME=%~1
if "%FEATURE_NAME%"=="" set FEATURE_NAME=ralph-loop

set MAX_CYCLES=%~2
if "%MAX_CYCLES%"=="" set MAX_CYCLES=10

set REQUIRED_SUCCESS=%~3
if "%REQUIRED_SUCCESS%"=="" set REQUIRED_SUCCESS=2

set COMPLETE_FLAG=%~4
if "%COMPLETE_FLAG%"=="" set COMPLETE_FLAG=docs/ralph/COMPLETE.flag

powershell -ExecutionPolicy Bypass -File "tools\run_ralph_loop.ps1" -Feature "%FEATURE_NAME%" -MaxCycles %MAX_CYCLES% -RequiredSuccessCycles %REQUIRED_SUCCESS% -CompletionFlag "%COMPLETE_FLAG%"
exit /b %errorlevel%
