@echo off
setlocal

set FEATURE_NAME=%~1
if "%FEATURE_NAME%"=="" set FEATURE_NAME=ralph-1000

set REQUIRED_SUCCESS=%~2
if "%REQUIRED_SUCCESS%"=="" set REQUIRED_SUCCESS=2

set COMPLETE_FLAG=%~3
if "%COMPLETE_FLAG%"=="" set COMPLETE_FLAG=docs/ralph/COMPLETE.flag

powershell -ExecutionPolicy Bypass -File "tools\run_ralph_loop.ps1" ^
  -Feature "%FEATURE_NAME%" ^
  -MaxCycles 1000 ^
  -RequiredSuccessCycles %REQUIRED_SUCCESS% ^
  -CompletionFlag "%COMPLETE_FLAG%" ^
  -SkipMasterPlanGate ^
  -PlanReadinessPath "docs/plans/latest_plan.md" ^
  -StopOnQaComplete 0

exit /b %errorlevel%
