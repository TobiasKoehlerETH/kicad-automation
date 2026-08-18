@echo off
setlocal
title Angst+Pfister KiCad Schematic Style

rem Self-contained package generated from the schematic-style PowerShell sources.
set "KICAD_PACKAGE_FILE=%~f0"
set "KICAD_PROJECT_PATH=%~dp0."
if not "%~1"=="" set "KICAD_PROJECT_PATH=%~1"

set "KICAD_LOGO_PATH="
if exist "%~dp0APlogo_black.png" set "KICAD_LOGO_PATH=%~dp0APlogo_black.png"
if not "%~2"=="" set "KICAD_LOGO_PATH=%~2"

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$raw=[IO.File]::ReadAllText($env:KICAD_PACKAGE_FILE);$start='#<'+'PSSCRIPT>';$end='#</'+'PSSCRIPT>';$parts=$raw -split $start,2;if($parts.Count-ne 2){throw 'Embedded PowerShell payload not found.'};$body=($parts[1]-split $end,2)[0];&([scriptblock]::Create($body))"
set "EXIT_CODE=%ERRORLEVEL%"
set "KICAD_PACKAGE_FILE="
set "KICAD_PROJECT_PATH="
set "KICAD_LOGO_PATH="
endlocal & exit /b %EXIT_CODE%

#<PSSCRIPT>
$ErrorActionPreference = 'Stop'
$exitCode = 1
$tempRoot = $null

try {
    $packagePath = $env:KICAD_PACKAGE_FILE
    $packageText = [IO.File]::ReadAllText($packagePath)
    $payloadStart = '#<' + 'PAYLOAD>'
    $payloadEnd = '#</' + 'PAYLOAD>'
    $payloadParts = $packageText -split $payloadStart, 2
    if ($payloadParts.Count -ne 2) {
        throw 'Embedded application payload not found.'
    }

    $payload = (($payloadParts[1] -split $payloadEnd, 2)[0] -replace '[^A-Za-z0-9+/=]', '')
    $archiveBytes = [Convert]::FromBase64String($payload)
    $tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('kicad-style-' + [guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $tempRoot)

    $archivePath = Join-Path $tempRoot 'application.zip'
    [IO.File]::WriteAllBytes($archivePath, $archiveBytes)
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [IO.Compression.ZipFile]::ExtractToDirectory($archivePath, $tempRoot)
    Remove-Item -LiteralPath $archivePath -Force

    $tuiPath = Join-Path $tempRoot 'Invoke-KiCadSchematicStyleTui.ps1'
    $arguments = @(
        '-NoLogo',
        '-NoProfile',
        '-ExecutionPolicy', 'Bypass',
        '-File', $tuiPath,
        '-InitialProjectPath', $env:KICAD_PROJECT_PATH
    )
    if (-not [string]::IsNullOrWhiteSpace($env:KICAD_LOGO_PATH)) {
        $arguments += @('-InitialLogoPath', $env:KICAD_LOGO_PATH)
    }

    & powershell.exe @arguments
    $exitCode = $LASTEXITCODE
}
catch {
    Write-Host ''
    Write-Host ('Package error: ' + $_.Exception.Message) -ForegroundColor Red
    if (-not [Console]::IsInputRedirected) {
        [void](Read-Host 'Press Enter to close')
    }
    $exitCode = 1
}
finally {
    if ($null -ne $tempRoot -and (Test-Path -LiteralPath $tempRoot -PathType Container)) {
        $tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\') + '\'
        $resolvedRoot = [IO.Path]::GetFullPath($tempRoot)
        $leaf = Split-Path -Path $resolvedRoot -Leaf
        if ($resolvedRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase) -and $leaf -like 'kicad-style-*') {
            Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
        }
    }
}

exit $exitCode
#</PSSCRIPT>
#<PAYLOAD>
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
#</PAYLOAD>
