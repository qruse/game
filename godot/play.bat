@echo off
rem 전투 프로토타입 바로 실행 (더블클릭). Godot 4.7을 winget으로 설치한 경로를 쓴다
set GODOT=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe
if not exist "%GODOT%" (
  echo Godot 4.7을 찾지 못했습니다: %GODOT%
  pause
  exit /b 1
)
start "" "%GODOT%" --path "%~dp0"
