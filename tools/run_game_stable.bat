@echo off
setlocal

set "PROJECT_DIR=%~dp0.."
pushd "%PROJECT_DIR%"

set "EXE=Engine\Godot_v4.5.1-stable_mono_win64\Godot_v4.5.1-stable_mono_win64_console.exe"
if not exist "%EXE%" (
	echo [FAIL] Missing executable: %EXE%
	popd
	exit /b 1
)

echo [RUN] %EXE% --path . --rendering-driver opengl3
start "" "%EXE%" --path . --rendering-driver opengl3

popd
exit /b 0
