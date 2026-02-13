@echo off
cd /d "%~dp0"

echo ============================================
echo Current directory: %cd%
echo ============================================
echo.

:: 1. reference
echo [1] reference
if exist reference (
    del /f /q reference 2>nul
    rmdir reference 2>nul
)
mklink /d reference ..\reference
echo.

:: 2. Engine
echo [2] Engine
if exist Engine (
    del /f /q Engine 2>nul
    rmdir Engine 2>nul
)
mklink /d Engine ..\Godot_v4.5.1-stable_mono_win64
echo.

:: 3. godot-game
echo [3] godot-game
if exist godot-game (
    del /f /q godot-game 2>nul
    rmdir godot-game 2>nul
)
mklink /d godot-game ..
echo.

echo ============================================
echo [VERIFY]
dir /al 2>nul | findstr "<"
echo ============================================
pause