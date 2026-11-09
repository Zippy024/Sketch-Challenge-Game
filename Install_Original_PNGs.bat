@echo off
setlocal
chcp 65001 >nul
set "ROOT=%~dp0"
if "%~1"=="" (
 echo Drag the Godot project folder containing project.godot onto this BAT file.
 pause
 exit /b 1
)
set "PROJECT=%~f1"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%Install_Original_PNGs.ps1" -SourceFolder "%ROOT%Original_PNG" -ProjectFolder "%PROJECT%"
if errorlevel 1 (echo Installation FAILED. Files not modified if validation failed.) else (echo Original PNGs installed. Open Godot and test Stage 3.)
pause
