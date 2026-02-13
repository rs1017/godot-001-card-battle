@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

set "FEATURE_NAME=%~1"
if "%FEATURE_NAME%"=="" set "FEATURE_NAME=card-battle-core"

set "PROFILE=%~2"
if "%PROFILE%"=="" set "PROFILE=standard"

set "COMPLETE_FLAG=docs/ralph/COMPLETE.flag"

if /I "%PROFILE%"=="quick" (
	call "tools\run_ralph_mode.bat" "%FEATURE_NAME%"
	set "EXIT_CODE=%ERRORLEVEL%"
	popd
	exit /b %EXIT_CODE%
)

if /I "%PROFILE%"=="standard" (
	call "tools\run_ralph_loop.bat" "%FEATURE_NAME%" 10 2 "%COMPLETE_FLAG%"
	set "EXIT_CODE=%ERRORLEVEL%"
	popd
	exit /b %EXIT_CODE%
)

if /I "%PROFILE%"=="deep" (
	call "tools\run_ralph_loop.bat" "%FEATURE_NAME%" 20 3 "%COMPLETE_FLAG%"
	set "EXIT_CODE=%ERRORLEVEL%"
	popd
	exit /b %EXIT_CODE%
)

if /I "%PROFILE%"=="refs" (
	powershell -ExecutionPolicy Bypass -File "tools\reference_ops_agent.ps1" -Feature "%FEATURE_NAME%"
	set "EXIT_CODE=%ERRORLEVEL%"
	popd
	exit /b %EXIT_CODE%
)

if /I "%PROFILE%"=="smoke" (
	call "tools\run_headless_smoke.bat"
	set "EXIT_CODE=%ERRORLEVEL%"
	popd
	exit /b %EXIT_CODE%
)

echo [RALPH] Unknown profile: %PROFILE%
echo Usage: tools\run_ralph_recommended.bat [feature-name] [quick^|standard^|deep^|refs^|smoke]
popd
exit /b 1
