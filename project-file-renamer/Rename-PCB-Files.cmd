@echo off
setlocal
title KiCad Project File Renamer
set "KICAD_RENAMER_FILE=%~f0"
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$p=$env:KICAD_RENAMER_FILE;$t=[IO.File]::ReadAllText($p);$m=':__POWERSHELL_BELOW__';Invoke-Expression ($t.Substring($t.LastIndexOf($m)+$m.Length))"
set "EXIT_CODE=%ERRORLEVEL%"
endlocal & exit /b %EXIT_CODE%

:__POWERSHELL_BELOW__
$ErrorActionPreference = 'Stop'
$TargetDirectory = [IO.Path]::GetDirectoryName($p)
$SupportedExtensions = @('.kicad_pcb', '.kicad_prl', '.kicad_pro', '.kicad_sch')

function Write-Rule {
    param([ConsoleColor]$Color = [ConsoleColor]::DarkCyan)
    Write-Host ('  ' + ('-' * 72)) -ForegroundColor $Color
}

function Write-Banner {
    Clear-Host
    Write-Host ''
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor Cyan
    Write-Host '  |                       KiCad Project Renamer                            |' -ForegroundColor Cyan
    Write-Host '  +------------------------------------------------------------------------+' -ForegroundColor Cyan
    Write-Host '  Renames one project set while preserving each KiCad file extension.' -ForegroundColor DarkGray
    Write-Host ''
}

function Write-Status {
    param(
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Kind,
        [string]$Message
    )

    $style = switch ($Kind) {
        'Info'    { @{ Label = 'INFO'; Color = [ConsoleColor]::Cyan } }
        'Success' { @{ Label = ' OK '; Color = [ConsoleColor]::Green } }
        'Warning' { @{ Label = 'WARN'; Color = [ConsoleColor]::Yellow } }
        'Error'   { @{ Label = 'FAIL'; Color = [ConsoleColor]::Red } }
    }

    Write-Host '  [' -NoNewline -ForegroundColor DarkGray
    Write-Host $style.Label -NoNewline -ForegroundColor $style.Color
    Write-Host "] $Message"
}

function Wait-BeforeExit {
    Write-Host ''
    [void](Read-Host '  Press Enter to close')
}

function Get-NameError {
    param([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return 'The project name cannot be empty.'
    }
    if ($Name -ne $Name.Trim()) {
        return 'The project name cannot start or end with spaces.'
    }
    if ($Name.EndsWith('.')) {
        return 'The project name cannot end with a period.'
    }
    if ($Name.IndexOfAny([IO.Path]::GetInvalidFileNameChars()) -ge 0) {
        return 'The project name contains a character Windows does not allow.'
    }
    if ($Name -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])(?:\..*)?$') {
        return 'That project name is reserved by Windows.'
    }
    return $null
}

function Show-Files {
    param([IO.FileInfo[]]$Files)

    Write-Host '  Files found' -ForegroundColor White
    Write-Rule
    foreach ($file in $Files) {
        Write-Host '    * ' -NoNewline -ForegroundColor DarkCyan
        Write-Host $file.Name -ForegroundColor Gray
    }
    Write-Rule
}

function Show-Plan {
    param([object[]]$Plan)

    Write-Host ''
    Write-Host '  Rename preview' -ForegroundColor White
    Write-Rule
    foreach ($item in $Plan) {
        if ($item.Unchanged) {
            Write-Host '    = ' -NoNewline -ForegroundColor DarkGray
            Write-Host $item.OldName -NoNewline -ForegroundColor DarkGray
            Write-Host '  (already named)' -ForegroundColor DarkGray
        }
        else {
            Write-Host '    ' -NoNewline
            Write-Host $item.OldName -NoNewline -ForegroundColor Gray
            Write-Host '  ->  ' -NoNewline -ForegroundColor DarkCyan
            Write-Host $item.NewName -ForegroundColor Green
        }
    }
    Write-Rule
}

function Invoke-SafeRename {
    param([object[]]$Plan)

    $changes = @($Plan | Where-Object { -not $_.Unchanged })
    if ($changes.Count -eq 0) { return 0 }

    $staged = [Collections.Generic.List[object]]::new()
    try {
        # Stage every source first so case-only renames and name swaps are safe.
        foreach ($item in $changes) {
            do {
                $tempName = '.__kicad_rename_{0}.tmp' -f ([guid]::NewGuid().ToString('N'))
                $tempPath = Join-Path $TargetDirectory $tempName
            } while (Test-Path -LiteralPath $tempPath)

            Rename-Item -LiteralPath $item.Source.FullName -NewName $tempName
            $staged.Add([pscustomobject]@{
                OldPath  = $item.Source.FullName
                TempPath = $tempPath
                NewPath  = $item.DestinationPath
                NewName  = $item.NewName
            })
        }

        foreach ($item in $staged) {
            Rename-Item -LiteralPath $item.TempPath -NewName $item.NewName
        }
        return $changes.Count
    }
    catch {
        $originalError = $_.Exception.Message
        foreach ($item in $staged) {
            try {
                if ((Test-Path -LiteralPath $item.TempPath) -and
                    -not (Test-Path -LiteralPath $item.OldPath)) {
                    Rename-Item -LiteralPath $item.TempPath -NewName ([IO.Path]::GetFileName($item.OldPath))
                }
                elseif ((Test-Path -LiteralPath $item.NewPath) -and
                        -not (Test-Path -LiteralPath $item.OldPath)) {
                    Rename-Item -LiteralPath $item.NewPath -NewName ([IO.Path]::GetFileName($item.OldPath))
                }
            }
            catch {
                # Keep restoring the other files even if one restore fails.
            }
        }
        throw "Rename failed: $originalError"
    }
}

try { $Host.UI.RawUI.WindowTitle = 'KiCad Project File Renamer' } catch {}

Write-Banner
Write-Host '  Folder: ' -NoNewline -ForegroundColor DarkGray
Write-Host $TargetDirectory -ForegroundColor White
Write-Host '  Types:  ' -NoNewline -ForegroundColor DarkGray
Write-Host ($SupportedExtensions -join ', ') -ForegroundColor White
Write-Host ''

try {
    $files = @(
        Get-ChildItem -LiteralPath $TargetDirectory -File |
            Where-Object { $SupportedExtensions -contains $_.Extension.ToLowerInvariant() } |
            Sort-Object Extension, Name
    )
}
catch {
    Write-Status Error "Could not scan the folder: $($_.Exception.Message)"
    Wait-BeforeExit
    exit 1
}

if ($files.Count -eq 0) {
    Write-Status Warning 'No supported KiCad files were found in this folder.'
    Wait-BeforeExit
    exit 0
}

$duplicates = @($files | Group-Object { $_.Extension.ToLowerInvariant() } | Where-Object Count -gt 1)
if ($duplicates.Count -gt 0) {
    Write-Status Error 'More than one file has the same supported extension.'
    Write-Host ''
    foreach ($group in $duplicates) {
        Write-Host "  $($group.Name):" -ForegroundColor Yellow
        foreach ($file in $group.Group) {
            Write-Host "    * $($file.Name)" -ForegroundColor Gray
        }
    }
    Write-Host ''
    Write-Host '  Move unrelated project files elsewhere, then run this tool again.' -ForegroundColor DarkGray
    Wait-BeforeExit
    exit 1
}

Show-Files $files

while ($true) {
    Write-Host ''
    $newBaseName = Read-Host '  Enter the new project name (blank cancels)'
    if ([string]::IsNullOrEmpty($newBaseName)) {
        Write-Status Info 'No files were changed.'
        Wait-BeforeExit
        exit 0
    }

    $nameError = Get-NameError $newBaseName
    if ($null -ne $nameError) {
        Write-Status Error $nameError
        continue
    }

    $plan = @(
        foreach ($file in $files) {
            $newName = $newBaseName + $file.Extension.ToLowerInvariant()
            [pscustomobject]@{
                Source          = $file
                OldName         = $file.Name
                NewName         = $newName
                DestinationPath = Join-Path $TargetDirectory $newName
                Unchanged       = $file.Name -ceq $newName
            }
        }
    )

    $sourcePaths = @($plan | ForEach-Object { $_.Source.FullName })
    $conflicts = @(
        $plan | Where-Object {
            (Test-Path -LiteralPath $_.DestinationPath) -and
            ($sourcePaths -notcontains $_.DestinationPath)
        }
    )

    if ($conflicts.Count -gt 0) {
        Write-Status Error 'A destination file already exists and would be overwritten:'
        foreach ($conflict in $conflicts) {
            Write-Host "    * $($conflict.NewName)" -ForegroundColor Yellow
        }
        Write-Host '  Choose a different project name.' -ForegroundColor DarkGray
        continue
    }

    Show-Plan $plan
    $answer = (Read-Host '  Apply changes? [Y]es / [N]ew name / [Q]uit').Trim()

    if ($answer -match '^(?i:y|yes)$') {
        try {
            $count = Invoke-SafeRename $plan
            Write-Host ''
            if ($count -eq 0) {
                Write-Status Info 'Every file already had the requested name.'
            }
            else {
                Write-Status Success "$count file(s) renamed successfully."
            }
            Wait-BeforeExit
            exit 0
        }
        catch {
            Write-Host ''
            Write-Status Error $_.Exception.Message
            Write-Host '  Any files that could be restored were returned to their original names.' -ForegroundColor DarkGray
            Wait-BeforeExit
            exit 1
        }
    }

    if ($answer -match '^(?i:q|quit)$') {
        Write-Status Info 'No files were changed.'
        Wait-BeforeExit
        exit 0
    }

    Write-Status Info 'Enter another project name.'
}
