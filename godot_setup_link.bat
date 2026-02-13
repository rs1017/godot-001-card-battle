@echo off
SET PROJECT_DIRECTORY=%~dp0
pushd %PROJECT_DIRECTORY%

:: ========================================================
:: 1. reference 폴더 링크 (공용 리소스)
:: ========================================================
if exist reference rmdir reference
mklink /d reference ..\reference

:: ========================================================
:: 2. Engine 링크 생성 (핵심!)
:: 긴 엔진 폴더명을 'Engine'이라는 짧은 이름으로 연결합니다.
:: ========================================================
if exist Engine rmdir Engine
mklink /d Engine ..\Godot_v4.5.1-stable_mono_win64

:: ========================================================
:: 3. godot-game (상위 루트) 링크
:: ========================================================
if exist godot-game rmdir godot-game
mklink /d godot-game ..

popd
echo.
echo [설정 완료] 
echo 1. reference  -> ..\reference
echo 2. Engine     -> ..\Godot_v4.5.1-stable_mono_win64
echo 3. godot-game -> ..
pause