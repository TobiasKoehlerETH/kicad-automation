@echo off
setlocal
title Angst+Pfister KiCad Schematic Style

set "LAUNCHER_DIR=%~dp0"
set "STYLE_SCRIPT=%LAUNCHER_DIR%..\schematic-style\Set-KiCadProjectSchematicStyle.ps1"

if not exist "%STYLE_SCRIPT%" set "STYLE_SCRIPT=C:\Code\kicad-automation\schematic-style\Set-KiCadProjectSchematicStyle.ps1"

if not exist "%STYLE_SCRIPT%" (
    echo.
    echo Could not find Set-KiCadProjectSchematicStyle.ps1.
    echo Keep this launcher in the kicad-automation repository, or update STYLE_SCRIPT in this file.
    echo.
    pause
    exit /b 1
)

set "LOCAL_LOGO=%LAUNCHER_DIR%APlogo_black.png"
if exist "%LOCAL_LOGO%" (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%STYLE_SCRIPT%" -ProjectPath "%LAUNCHER_DIR%" -LogoPath "%LOCAL_LOGO%"
) else (
    powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%STYLE_SCRIPT%" -ProjectPath "%LAUNCHER_DIR%"
)
set "EXIT_CODE=%ERRORLEVEL%"

echo.
if "%EXIT_CODE%"=="0" (
    echo Angst+Pfister schematic style applied to the project in this folder.
) else (
    echo The style was not applied. See the error above.
)
pause
endlocal & exit /b %EXIT_CODE%
