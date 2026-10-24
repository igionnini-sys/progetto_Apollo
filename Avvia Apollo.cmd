@echo off
cd /d "%~dp0"
if exist ".tools\godot\Godot_v4.6.1-stable_win64.exe" (
  start "Apollo" ".tools\godot\Godot_v4.6.1-stable_win64.exe" --path "%~dp0."
  exit /b
)
where godot >nul 2>nul
if not errorlevel 1 (
  start "Apollo" godot --path "%~dp0."
  exit /b
)
echo Installa Godot 4.6.1 e importa project.godot. Leggi README.md.
pause
