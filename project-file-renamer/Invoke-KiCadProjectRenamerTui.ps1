[CmdletBinding()]
param(
    [string] $InitialDirectory = (Get-Location).Path,
    [switch] $NoAnimation
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:showStartupEffect = $true

$supportedExtensions = @('.kicad_pcb', '.kicad_prl', '.kicad_pro', '.kicad_sch')

function Test-TuiAnimation {
    return (-not $NoAnimation -and -not [Console]::IsInputRedirected -and $env:TERM -ne 'dumb')
}

function Show-StartupSweep {
    if (-not (Test-TuiAnimation)) { return }

    $trackWidth = 24
    $head = [char]0x2588
    $trail = [char]0x2501
    $cursorVisible = $null
    try {
        $cursorVisible = $Host.UI.RawUI.CursorVisible
        $Host.UI.RawUI.CursorVisible = $false
    }
    catch {}

    try {
        foreach ($position in 0..$trackWidth) {
            $line = '  ' + (($trail.ToString() * $position) + $head)
            Write-Host ("`r" + $line.PadRight($trackWidth + 4)) -NoNewline -ForegroundColor DarkRed
            Start-Sleep -Milliseconds 14
        }
        Write-Host ("`r" + (' ' * ($trackWidth + 4)) + "`r") -NoNewline
    }
    finally {
        if ($null -ne $cursorVisible) {
            try { $Host.UI.RawUI.CursorVisible = $cursorVisible } catch {}
        }
    }
}

function Write-Rule {
    param([ConsoleColor] $Color = [ConsoleColor]::DarkRed)
    Write-Host ('  ' + ('-' * 72)) -ForegroundColor $Color
}

function Write-Banner {
    if ($script:showStartupEffect -and (Test-TuiAnimation)) {
        $script:showStartupEffect = $false
        Show-StartupSweep
    }
    Clear-Host
    Write-Host ''
    Write-Host '  KICAD PROJECT RENAMER' -ForegroundColor DarkRed
    Write-Rule
    Write-Host ''
}

function Write-Section {
    param([string] $Title)

    Write-Host ('  ' + $Title.ToUpperInvariant()) -ForegroundColor DarkRed
}

function Write-Status {
    param(
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string] $Kind,
        [string] $Message
    )

    $style = switch ($Kind) {
        'Info'    { @{ Label = 'i'; Color = [ConsoleColor]::DarkRed } }
        'Success' { @{ Label = '+'; Color = [ConsoleColor]::Green } }
        'Warning' { @{ Label = '!'; Color = [ConsoleColor]::Yellow } }
        'Error'   { @{ Label = 'x'; Color = [ConsoleColor]::Red } }
    }

    Write-Host '  [' -NoNewline -ForegroundColor DarkGray
    Write-Host $style.Label -NoNewline -ForegroundColor $style.Color
    Write-Host "] $Message"
}

function Show-TuiEffect {
    param(
        [string] $Label,
        [int] $Frames = 11
    )

    if (-not (Test-TuiAnimation)) {
        Write-Status Info $Label
        return
    }

    $glyphs = @(0x280B, 0x2819, 0x2839, 0x2838, 0x283C, 0x2834, 0x2826, 0x2827, 0x2807, 0x280F) |
        ForEach-Object { [char]$_ }
    $shades = @([char]0x2588, [char]0x2593, [char]0x2592, [char]0x2591)
    $trackWidth = 10
    $cursorVisible = $null
    try {
        $cursorVisible = $Host.UI.RawUI.CursorVisible
        $Host.UI.RawUI.CursorVisible = $false
    }
    catch {}

    try {
        for ($index = 0; $index -lt $Frames; $index++) {
            $cells = @(' ') * $trackWidth
            foreach ($offset in 0..($shades.Count - 1)) {
                $position = $index - $offset
                if ($position -ge 0 -and $position -lt $trackWidth) {
                    $cells[$position] = $shades[$offset]
                }
            }
            $line = "  $($glyphs[$index % $glyphs.Count])  $Label  $(-join $cells)"
            Write-Host ("`r" + $line.PadRight(78)) -NoNewline -ForegroundColor DarkRed
            Start-Sleep -Milliseconds 45
        }
        Write-Host ("`r" + (' ' * 78) + "`r") -NoNewline
    }
    finally {
        if ($null -ne $cursorVisible) {
            try { $Host.UI.RawUI.CursorVisible = $cursorVisible } catch {}
        }
    }
}

function Show-SuccessAnimation {
    param([string] $Title)

    if (-not (Test-TuiAnimation)) {
        Write-Status Success $Title
        return
    }

    $full = [char]0x2588
    $empty = [char]0x2591
    $check = [char]0x2713
    $barWidth = 18
    $cursorVisible = $null
    try {
        $cursorVisible = $Host.UI.RawUI.CursorVisible
        $Host.UI.RawUI.CursorVisible = $false
    }
    catch {}

    try {
        foreach ($filled in 0..$barWidth) {
            $bar = ($full.ToString() * $filled) + ($empty.ToString() * ($barWidth - $filled))
            Write-Host ("`r  $bar".PadRight(78)) -NoNewline -ForegroundColor DarkRed
            Start-Sleep -Milliseconds 24
        }
        Write-Host ("`r" + (' ' * 78) + "`r") -NoNewline
    }
    finally {
        if ($null -ne $cursorVisible) {
            try { $Host.UI.RawUI.CursorVisible = $cursorVisible } catch {}
        }
    }

    Write-Host "  $check  " -NoNewline -ForegroundColor White -BackgroundColor DarkRed
    Write-Host " $Title" -ForegroundColor DarkRed
}

function Read-MenuChoice {
    param([object[]] $Items)

    if ([Console]::IsInputRedirected) {
        return (Read-Host '  Choose an option').Trim()
    }

    $selectedIndex = 0
    $cursorPosition = $Host.UI.RawUI.CursorPosition
    $menuHeight = $Items.Count
    $maximumTop = [Math]::Max(0, $Host.UI.RawUI.BufferSize.Height - $menuHeight - 1)
    if ($cursorPosition.Y -gt $maximumTop) { $cursorPosition.Y = $maximumTop }
    function Write-Menu {
        param([int] $Index)

        $Host.UI.RawUI.CursorPosition = $cursorPosition
        foreach ($menuIndex in 0..($Items.Count - 1)) {
            $line = ("  {0} {1}" -f $(if ($menuIndex -eq $Index) { '>>' } else { '  ' }), $Items[$menuIndex].Label).PadRight(78)
            if ($menuIndex -eq $Index) { Write-Host $line -ForegroundColor White -BackgroundColor DarkRed }
            else { Write-Host $line -ForegroundColor Gray }
        }
    }

    Write-Menu $selectedIndex
    while ($true) {
        $press = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        switch ($press.VirtualKeyCode) {
            38 { $selectedIndex = [Math]::Max(0, $selectedIndex - 1); Write-Menu $selectedIndex }
            40 { $selectedIndex = [Math]::Min($Items.Count - 1, $selectedIndex + 1); Write-Menu $selectedIndex }
            13 { return $Items[$selectedIndex].Value }
            27 { return 'Q' }
        }
    }
}

function Read-ConfirmChoice {
    param([string] $Prompt)

    if ([Console]::IsInputRedirected) {
        return ((Read-Host "  $Prompt [Y]es / [N]o").Trim() -match '^(?i:y|yes)$')
    }

    $selectedIndex = 0
    Write-Host "  $Prompt  (Y/N or arrows)" -ForegroundColor DarkRed
    while ($true) {
        $yes = if ($selectedIndex -eq 0) { '[ Yes ]' } else { '  Yes  ' }
        $no = if ($selectedIndex -eq 1) { '[ No ]' } else { '  No   ' }
        Write-Host ("`r  $yes    $no".PadRight(78)) -NoNewline -ForegroundColor DarkRed
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'LeftArrow' { $selectedIndex = 0 }
            'RightArrow' { $selectedIndex = 1 }
            'Enter' { Write-Host ''; return ($selectedIndex -eq 0) }
            'Escape' { Write-Host ''; return $false }
            'Y' { Write-Host ''; return $true }
            'N' { Write-Host ''; return $false }
        }
    }
}

function Wait-BeforeExit {
    Write-Host ''
    [void](Read-Host '  Press Enter to close')
}

function ConvertFrom-UserPath {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }

    $cleanPath = $Path.Trim()
    if ($cleanPath.Length -ge 2) {
        $first = $cleanPath.Substring(0, 1)
        $last = $cleanPath.Substring($cleanPath.Length - 1, 1)
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            $cleanPath = $cleanPath.Substring(1, $cleanPath.Length - 2)
        }
    }

    return [Environment]::ExpandEnvironmentVariables($cleanPath.Trim())
}

function Get-NameError {
    param([string] $Name)

    if ([string]::IsNullOrWhiteSpace($Name)) {
        return 'Choose a new project name.'
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

function Get-DirectorySelection {
    param([string] $Path)

    $emptyFiles = @()
    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject]@{
            IsValid = $false; DisplayPath = '(not selected)'; Directory = $null
            Files = $emptyFiles; Message = 'Choose a folder containing one KiCad project.'
        }
    }

    $displayPath = $Path
    try {
        $item = Get-Item -LiteralPath ([IO.Path]::GetFullPath($Path)) -ErrorAction Stop
        $displayPath = $item.FullName
        if (-not $item.PSIsContainer) {
            throw 'Select a project folder, not a file.'
        }

        $files = @(
            Get-ChildItem -LiteralPath $item.FullName -File |
                Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() } |
                Sort-Object Extension, Name
        )
        if ($files.Count -eq 0) {
            throw 'No supported KiCad project files were found in this folder.'
        }

        $duplicates = @($files | Group-Object { $_.Extension.ToLowerInvariant() } | Where-Object Count -gt 1)
        if ($duplicates.Count -gt 0) {
            $duplicateTypes = ($duplicates.Name | Sort-Object) -join ', '
            throw "More than one file uses the same project extension: $duplicateTypes"
        }

        $baseNames = @($files.BaseName | Sort-Object -Unique)
        if ($baseNames.Count -eq 1) {
            $message = "$($files.Count) file(s) found; current name: $($baseNames[0])"
        }
        else {
            $message = "$($files.Count) file(s) found with mixed base names."
        }

        return [pscustomobject]@{
            IsValid = $true; DisplayPath = $item.FullName; Directory = $item.FullName
            Files = $files; Message = $message
        }
    }
    catch {
        return [pscustomobject]@{
            IsValid = $false; DisplayPath = $displayPath; Directory = $null
            Files = $emptyFiles; Message = $_.Exception.Message
        }
    }
}

function Get-NameSelection {
    param([string] $Name)

    $nameError = Get-NameError $Name
    if ($null -ne $nameError) {
        $displayName = $Name
        if ([string]::IsNullOrWhiteSpace($displayName)) { $displayName = '(not selected)' }
        return [pscustomobject]@{ IsValid = $false; DisplayPath = $displayName; ApplyName = $null; Message = $nameError }
    }

    return [pscustomobject]@{ IsValid = $true; DisplayPath = $Name; ApplyName = $Name; Message = 'Project name is valid.' }
}

function Get-PlanSelection {
    param(
        [object] $DirectorySelection,
        [object] $NameSelection
    )

    if (-not $DirectorySelection.IsValid -or -not $NameSelection.IsValid) {
        return [pscustomobject]@{ IsValid = $false; Plan = @(); Message = 'Complete the folder and project name first.' }
    }

    $plan = @(
        foreach ($file in $DirectorySelection.Files) {
            $newName = $NameSelection.ApplyName + $file.Extension.ToLowerInvariant()
            [pscustomobject]@{
                Source = $file
                OldName = $file.Name
                NewName = $newName
                DestinationPath = Join-Path $DirectorySelection.Directory $newName
                Unchanged = $file.Name -ceq $newName
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
        $names = ($conflicts.NewName | Sort-Object) -join ', '
        return [pscustomobject]@{ IsValid = $false; Plan = $plan; Message = "Would overwrite existing file(s): $names" }
    }

    return [pscustomobject]@{ IsValid = $true; Plan = $plan; Message = 'Rename plan is safe.' }
}

function Get-KiCadSelection {
    $running = @(Get-Process -Name 'kicad', 'eeschema', 'pcbnew' -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) {
        return [pscustomobject]@{ IsValid = $true; Message = 'KiCad is closed.' }
    }

    $names = ($running.ProcessName | Sort-Object -Unique) -join ', '
    return [pscustomobject]@{ IsValid = $false; Message = "Close KiCad before renaming (running: $names)." }
}

function Write-Selection {
    param(
        [string] $Key,
        [string] $Label,
        [object] $Selection
    )

    try { $width = [Math]::Max(78, [Console]::WindowWidth - 2) } catch { $width = 78 }
    $value = if ($Selection.IsValid) { $Selection.DisplayPath } else { $Selection.Message }
    $valueWidth = [Math]::Max(20, $width - 25)
    if ($Selection.IsValid) {
        $value = Get-FittedText $value $valueWidth
    }
    elseif ($value.Length -gt $valueWidth) {
        $value = $value.Substring(0, $valueWidth - 3) + '...'
    }
    Write-Host ("  [{0}] " -f $Key) -NoNewline -ForegroundColor DarkRed
    Write-Host ("{0,-18}" -f $Label) -NoNewline -ForegroundColor Gray
    Write-Host $value -ForegroundColor $(if ($Selection.IsValid) { [ConsoleColor]::Gray } else { [ConsoleColor]::Yellow })
}

function Show-Plan {
    param([object[]] $Plan)

    foreach ($item in $Plan) {
        if ($item.Unchanged) {
            Write-Host '    = ' -NoNewline -ForegroundColor DarkGray
            Write-Host $item.OldName -NoNewline -ForegroundColor DarkGray
            Write-Host '  (already named)' -ForegroundColor DarkGray
        }
        else {
            Write-Host '    ' -NoNewline
            Write-Host $item.OldName -NoNewline -ForegroundColor Gray
            Write-Host '  ->  ' -NoNewline -ForegroundColor DarkRed
            Write-Host $item.NewName -ForegroundColor Green
        }
    }
}

function Read-NewPath {
    param(
        [string] $Prompt,
        [string] $CurrentPath
    )

    Write-Host ''
    Write-Host '  Enter, paste, or drop a path; blank keeps current.' -ForegroundColor DarkGray
    $newPath = Read-Host "  $Prompt"
    if ([string]::IsNullOrWhiteSpace($newPath)) { return $CurrentPath }
    return ConvertFrom-UserPath $newPath
}

function Get-BrowserStartDirectory {
    param([string] $Path)

    try {
        if (-not [string]::IsNullOrWhiteSpace($Path)) {
            $item = Get-Item -LiteralPath ([IO.Path]::GetFullPath($Path)) -ErrorAction Stop
            if ($item.PSIsContainer) { return $item.FullName }
            return $item.Directory.FullName
        }
    }
    catch {}

    return (Get-Location).Path
}

function Get-FolderBrowserEntries {
    param(
        [string] $Directory,
        [switch] $Drives
    )

    $entries = @()
    if ($Drives) {
        foreach ($drive in @(Get-PSDrive -PSProvider FileSystem | Sort-Object Name)) {
            $entries += [pscustomobject]@{ Kind = 'Drive'; Name = "[$($drive.Name):]"; Path = $drive.Root }
        }
        return $entries
    }

    $directoryItem = Get-Item -LiteralPath $Directory -ErrorAction Stop
    if ((Get-DirectorySelection $directoryItem.FullName).IsValid) {
        $entries += [pscustomobject]@{ Kind = 'Select'; Name = '[Select this folder]'; Path = $directoryItem.FullName }
    }
    if ($null -ne $directoryItem.Parent) {
        $entries += [pscustomobject]@{ Kind = 'Parent'; Name = '[..]'; Path = $directoryItem.Parent.FullName }
    }
    else {
        $entries += [pscustomobject]@{ Kind = 'Drives'; Name = '[Computer / drives]'; Path = $null }
    }

    foreach ($folder in @(Get-ChildItem -LiteralPath $directoryItem.FullName -Directory -Force -ErrorAction Stop | Sort-Object Name)) {
        $entries += [pscustomobject]@{ Kind = 'Directory'; Name = "[$($folder.Name)]"; Path = $folder.FullName }
    }

    return $entries
}

function Get-FittedText {
    param(
        [string] $Text,
        [int] $Width
    )

    if ($null -eq $Text) { return '' }
    if ($Width -lt 4 -or $Text.Length -le $Width) { return $Text }
    return ('...' + $Text.Substring($Text.Length - ($Width - 3)))
}

function Show-FolderBrowser {
    param([string] $InitialPath)

    $currentDirectory = Get-BrowserStartDirectory $InitialPath
    $selectedIndex = 0
    $showDrives = $false
    $browserNotice = $null

    while ($true) {
        try {
            $entries = @(Get-FolderBrowserEntries -Directory $currentDirectory -Drives:$showDrives)
        }
        catch {
            $browserNotice = $_.Exception.Message
            $parent = Split-Path -Path $currentDirectory -Parent
            if ([string]::IsNullOrWhiteSpace($parent)) { $showDrives = $true }
            else { $currentDirectory = $parent }
            $selectedIndex = 0
            continue
        }

        if ($entries.Count -eq 0) { $selectedIndex = 0 }
        elseif ($selectedIndex -ge $entries.Count) { $selectedIndex = $entries.Count - 1 }
        elseif ($selectedIndex -lt 0) { $selectedIndex = 0 }

        try { $consoleWidth = [Math]::Max(60, [Console]::WindowWidth) } catch { $consoleWidth = 80 }
        try { $visibleRows = [Math]::Max(5, [Console]::WindowHeight - 17) } catch { $visibleRows = 12 }
        $visibleRows = [Math]::Min(18, $visibleRows)
        $firstIndex = if ($selectedIndex -ge $visibleRows) { $selectedIndex - $visibleRows + 1 } else { 0 }
        $lastIndex = [Math]::Min($entries.Count - 1, $firstIndex + $visibleRows - 1)

        Write-Banner
        Write-Host '  Choose a KiCad project folder' -ForegroundColor DarkRed
        $displayLocation = if ($showDrives) { 'Computer / drives' } else { Get-FittedText $currentDirectory ($consoleWidth - 4) }
        Write-Host "  $displayLocation" -ForegroundColor Gray
        if (-not $showDrives) {
            $currentSelection = Get-DirectorySelection $currentDirectory
            if ($currentSelection.IsValid) {
                Write-Status Success $currentSelection.Message
            }
            else {
                Write-Status Warning $currentSelection.Message
            }
        }
        Write-Rule

        if ($entries.Count -eq 0) {
            Write-Host '  No filesystem drives are available.' -ForegroundColor DarkGray
        }
        else {
            for ($index = $firstIndex; $index -le $lastIndex; $index++) {
                $entry = $entries[$index]
                $prefix = if ($index -eq $selectedIndex) { '  > ' } else { '    ' }
                $text = $prefix + (Get-FittedText $entry.Name ($consoleWidth - 6))
                if ($index -eq $selectedIndex) {
                    Write-Host $text.PadRight($consoleWidth) -ForegroundColor White -BackgroundColor DarkRed
                }
                else {
                    Write-Host $text -ForegroundColor Gray
                }
            }
        }

        Write-Rule
        Write-Host '  Up/Down move  |  Enter open  |  Backspace up' -ForegroundColor DarkRed
        Write-Host '  S select  |  G path  |  D drives  |  Esc cancel' -ForegroundColor DarkRed
        if (-not [string]::IsNullOrWhiteSpace($browserNotice)) {
            Write-Status Warning $browserNotice
        }

        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'UpArrow' {
                if ($entries.Count -gt 0) { $selectedIndex = ($selectedIndex - 1 + $entries.Count) % $entries.Count }
            }
            'DownArrow' {
                if ($entries.Count -gt 0) { $selectedIndex = ($selectedIndex + 1) % $entries.Count }
            }
            'PageUp' { $selectedIndex = [Math]::Max(0, $selectedIndex - $visibleRows) }
            'PageDown' { $selectedIndex = [Math]::Min([Math]::Max(0, $entries.Count - 1), $selectedIndex + $visibleRows) }
            'Home' { $selectedIndex = 0 }
            'End' { $selectedIndex = [Math]::Max(0, $entries.Count - 1) }
            'D' {
                $showDrives = $true
                $selectedIndex = 0
                $browserNotice = $null
            }
            'Backspace' {
                if ($showDrives) { continue }
                $parent = (Get-Item -LiteralPath $currentDirectory).Parent
                if ($null -eq $parent) {
                    $showDrives = $true
                    $browserNotice = $null
                }
                else {
                    $currentDirectory = $parent.FullName
                    $selectedIndex = 0
                    $browserNotice = $null
                }
            }
            'S' {
                if ($showDrives) { continue }
                $folderSelection = Get-DirectorySelection $currentDirectory
                if ($folderSelection.IsValid) { return $currentDirectory }
                $browserNotice = $folderSelection.Message
            }
            'G' {
                $typedPath = Read-NewPath 'Go to folder' $currentDirectory
                try {
                    $typedItem = Get-Item -LiteralPath $typedPath -ErrorAction Stop
                    if (-not $typedItem.PSIsContainer) { throw 'Select a project folder, not a file.' }
                    $currentDirectory = $typedItem.FullName
                    $showDrives = $false
                    $selectedIndex = 0
                    $browserNotice = $null
                }
                catch { $browserNotice = $_.Exception.Message }
            }
            'Enter' {
                if ($entries.Count -eq 0) { continue }
                $entry = $entries[$selectedIndex]
                switch ($entry.Kind) {
                    'Select' {
                        return $entry.Path
                    }
                    'Drive' {
                        $currentDirectory = $entry.Path
                        $showDrives = $false
                    }
                    'Drives' { $showDrives = $true }
                    default {
                        $currentDirectory = $entry.Path
                        $showDrives = $false
                    }
                }
                $selectedIndex = 0
                $browserNotice = $null
            }
            'Escape' { return $null }
        }
    }
}

function Read-NewName {
    param([string] $CurrentName)

    Write-Host ''
    if (-not [string]::IsNullOrWhiteSpace($CurrentName)) {
        Write-Host '  Blank keeps current.' -ForegroundColor DarkGray
    }
    $newName = Read-Host '  New project name'
    if ([string]::IsNullOrEmpty($newName) -and -not [string]::IsNullOrWhiteSpace($CurrentName)) {
        return $CurrentName
    }
    return $newName
}

function Invoke-SafeRename {
    param(
        [object[]] $Plan,
        [string] $Directory
    )

    $changes = @($Plan | Where-Object { -not $_.Unchanged })
    if ($changes.Count -eq 0) { return 0 }

    $staged = [Collections.Generic.List[object]]::new()
    try {
        foreach ($item in $changes) {
            do {
                $tempName = '.__kicad_rename_{0}.tmp' -f ([guid]::NewGuid().ToString('N'))
                $tempPath = Join-Path $Directory $tempName
            } while (Test-Path -LiteralPath $tempPath)

            Rename-Item -LiteralPath $item.Source.FullName -NewName $tempName
            $staged.Add([pscustomobject]@{
                OldPath = $item.Source.FullName
                TempPath = $tempPath
                NewPath = $item.DestinationPath
                NewName = $item.NewName
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
                if ((Test-Path -LiteralPath $item.TempPath) -and -not (Test-Path -LiteralPath $item.OldPath)) {
                    Rename-Item -LiteralPath $item.TempPath -NewName ([IO.Path]::GetFileName($item.OldPath))
                }
                elseif ((Test-Path -LiteralPath $item.NewPath) -and -not (Test-Path -LiteralPath $item.OldPath)) {
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

try { $Host.UI.RawUI.WindowTitle = 'KiCad Project Renamer' } catch {}

$directoryPath = ConvertFrom-UserPath $InitialDirectory
$newBaseName = ''
$noticeKind = 'Info'
$noticeMessage = $null

while ($true) {
    $directory = Get-DirectorySelection $directoryPath
    $name = Get-NameSelection $newBaseName
    $plan = Get-PlanSelection $directory $name
    $kiCad = Get-KiCadSelection
    $isReady = $directory.IsValid -and $name.IsValid -and $plan.IsValid -and $kiCad.IsValid

    Write-Banner
    Write-Section 'Inputs'
    Write-Selection 'D' 'Project folder' $directory
    Write-Selection 'N' 'New name' $name

    if ($directory.IsValid -and $name.IsValid) {
        Write-Host ''
        Write-Section 'Preview'
        Show-Plan $plan.Plan
        if (-not $plan.IsValid) {
            Write-Status Error $plan.Message
        }
    }

    Write-Host ''
    if ($kiCad.IsValid) {
        Write-Status Success $kiCad.Message
    }
    else {
        Write-Status Warning $kiCad.Message
    }
    if (-not [string]::IsNullOrWhiteSpace($noticeMessage)) {
        Write-Status $noticeKind $noticeMessage
    }
    Write-Host ''

    $renameLabel = if ($isReady) { 'Review & rename' } else { 'Rename (not ready)' }
    $choice = Read-MenuChoice -Items @(
        [pscustomobject]@{ Label = 'Project folder'; Value = 'D' }
        [pscustomobject]@{ Label = 'New name'; Value = 'N' }
        [pscustomobject]@{ Label = $renameLabel; Value = 'R' }
        [pscustomobject]@{ Label = 'Quit'; Value = 'Q' }
    )
    switch -Regex ($choice) {
        '^(?i:d)$' {
            $newDirectoryPath = Show-FolderBrowser -InitialPath $directoryPath
            if ($null -ne $newDirectoryPath) {
                $directoryPath = $newDirectoryPath
                $noticeKind = 'Info'
                $noticeMessage = 'Project folder selection updated.'
            }
            else {
                $noticeKind = 'Info'
                $noticeMessage = 'Project folder selection unchanged.'
            }
            continue
        }
        '^(?i:n)$' {
            $newBaseName = Read-NewName $newBaseName
            $noticeKind = 'Info'
            $noticeMessage = 'Project name updated.'
            continue
        }
        '^(?i:q|quit|exit)$' {
            Write-Host ''
            Write-Status Info 'No files were changed.'
            exit 0
        }
        '^(?i:r)$' {
            if (-not $isReady) {
                $noticeKind = 'Error'
                if (-not $kiCad.IsValid) {
                    $noticeMessage = $kiCad.Message
                }
                elseif (-not $plan.IsValid -and $directory.IsValid -and $name.IsValid) {
                    $noticeMessage = $plan.Message
                }
                else {
                    $noticeMessage = 'Complete the folder and new project name before renaming.'
                }
                continue
            }

            Write-Banner
            Write-Section 'Review'
            Write-Host '  Folder: ' -NoNewline -ForegroundColor DarkGray
            Write-Host $directory.Directory -ForegroundColor White
            Write-Host ''
            Show-Plan $plan.Plan
            Write-Rule
            Write-Status Info 'Staged with rollback.'
            Write-Host ''
            if (-not (Read-ConfirmChoice 'Rename these files?')) {
                $noticeKind = 'Info'
                $noticeMessage = 'Rename cancelled; no files were changed.'
                continue
            }

            Write-Host ''
            try {
                Show-TuiEffect 'Preparing staged rename'
                $count = Invoke-SafeRename -Plan $plan.Plan -Directory $directory.Directory
                if ($count -eq 0) {
                    Write-Status Info 'Names already match.'
                }
                else {
                    Show-SuccessAnimation "$count project file(s) renamed"
                }
                Wait-BeforeExit
                exit 0
            }
            catch {
                Write-Status Error $_.Exception.Message
                Write-Host '  Any files that could be restored were returned to their original names.' -ForegroundColor DarkGray
                Wait-BeforeExit
                exit 1
            }
        }
        default {
            $noticeKind = 'Warning'
            $noticeMessage = 'Unknown choice. Enter D, N, R, or Q.'
            continue
        }
    }
}
