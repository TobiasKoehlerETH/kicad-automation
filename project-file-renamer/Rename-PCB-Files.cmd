@echo off
setlocal
title KiCad Project Renamer

set "LAUNCHER_DIR=%~dp0"
set "PROJECT_DIR=%LAUNCHER_DIR%."
set "TUI_SCRIPT=%LAUNCHER_DIR%Invoke-KiCadProjectRenamerTui.ps1"

if not exist "%TUI_SCRIPT%" set "TUI_SCRIPT=C:\Code\kicad-automation\project-file-renamer\Invoke-KiCadProjectRenamerTui.ps1"

if not exist "%TUI_SCRIPT%" (
    echo.
    echo Could not find Invoke-KiCadProjectRenamerTui.ps1.
    echo Keep this launcher in the kicad-automation repository, or update TUI_SCRIPT in this file.
    echo.
    pause
    exit /b 1
)

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%TUI_SCRIPT%" -InitialDirectory "%PROJECT_DIR%"
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%
