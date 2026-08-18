[CmdletBinding()]
param(
    [string] $InitialProjectPath = (Get-Location).Path,
    [string] $InitialLogoPath,
    [string] $InitialAuthorName,
    [string] $InitialTeamName,
    [switch] $NoAnimation
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$script:showStartupEffect = $true

$styleScript = Join-Path $PSScriptRoot 'Set-KiCadProjectSchematicStyle.ps1'
$repositoryLogo = Join-Path (Split-Path -Path $PSScriptRoot -Parent) 'personal\APlogo_black.png'

if (-not (Test-Path -LiteralPath $styleScript -PathType Leaf)) {
    Write-Host "Style script not found: $styleScript" -ForegroundColor Red
    [void](Read-Host 'Press Enter to close')
    exit 1
}

if ([string]::IsNullOrWhiteSpace($InitialLogoPath) -and (Test-Path -LiteralPath $repositoryLogo -PathType Leaf)) {
    $InitialLogoPath = $repositoryLogo
}
if ([string]::IsNullOrWhiteSpace($InitialAuthorName)) {
    $InitialAuthorName = 'Tobias K' + [char]0x00F6 + 'hler'
}
if ([string]::IsNullOrWhiteSpace($InitialTeamName)) {
    $InitialTeamName = 'Sensing Materials Team'
}

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
    Write-Host '  ANGST+PFISTER SCHEMATIC STYLE' -ForegroundColor DarkRed
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

function Show-CompletionExplosion {
    param([string] $Title)

    if (-not (Test-TuiAnimation)) {
        Write-Status Success $Title
        return
    }

    $canvasWidth = 72
    $visibleTitle = $Title
    if ($visibleTitle.Length -gt 42) {
        $visibleTitle = $visibleTitle.Substring(0, 39) + '...'
    }

    $frames = @()
    $frames += ,@(
        '·',
        '·   |   ·',
        '  \  |  /',
        '     ✦',
        "  /  |  \",
        '·   |   ·',
        '·'
    )
    $frames += ,@(
        '·    .    ·',
        ' .   \|/   . ',
        '   ·  |  ·',
        '---   ✦   ---',
        '   ·  |  ·',
        ' .   /|\   . ',
        '·    .    ·'
    )
    $frames += ,@(
        '·  .  ·  .  ·  .  ·',
        ' .  \  |  /  \  |  . ',
        '---   \ | /   ---',
        '      [✦]',
        '---   / | \   ---',
        ' .  /  |  \  /  |  . ',
        '·  .  ·  .  ·  .  ·'
    )
    $frames += ,@(
        '.   ·   .   ·   .   ·',
        ' \  |  / \  |  / \  |',
        '---\ | /---\ | /---',
        "---  ✦  $visibleTitle  ✦  ---",
        '---/ | \---/ | \---',
        ' /  |  \ /  |  \ /  |',
        '.   ·   .   ·   .   ·'
    )
    $frames += ,@(
        '·       .       ·       .',
        '    \   |   /       \   |',
        ' .    \ | /    .    \ | /',
        "      ✦  $visibleTitle  ✦",
        ' .    / | \    .    / | \',
        '    /   |   \       /   |',
        '·       .       ·       .'
    )

    $cursorVisible = $null
    $origin = $null
    try {
        $origin = $Host.UI.RawUI.CursorPosition
        $cursorVisible = $Host.UI.RawUI.CursorVisible
        $Host.UI.RawUI.CursorVisible = $false
    }
    catch {
        Write-Status Success $Title
        return
    }

    try {
        foreach ($frame in $frames) {
            $Host.UI.RawUI.CursorPosition = $origin
            foreach ($line in $frame) {
                $leftPadding = [Math]::Max(0, [int][Math]::Floor(($canvasWidth - $line.Length) / 2))
                Write-Host (((' ' * $leftPadding) + $line).PadRight($canvasWidth)) -ForegroundColor DarkRed
            }
            Start-Sleep -Milliseconds 85
        }

        $Host.UI.RawUI.CursorPosition = $origin
        foreach ($line in $frames[-1]) {
            Write-Host (' ' * $canvasWidth)
        }
        $Host.UI.RawUI.CursorPosition = $origin
        Write-Host "  ✦  $Title  ✦" -ForegroundColor White -BackgroundColor DarkRed
    }
    catch {
        Write-Host ''
        Write-Status Success $Title
    }
    finally {
        if ($null -ne $cursorVisible) {
            try { $Host.UI.RawUI.CursorVisible = $cursorVisible } catch {}
        }
    }

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
        $line = "  $yes    $no"
        Write-Host ("`r" + $line.PadRight(78)) -NoNewline -ForegroundColor DarkRed
        $key = [Console]::ReadKey($true)
        switch ($key.Key) {
            'LeftArrow' { $selectedIndex = 0 }
            'RightArrow' { $selectedIndex = 1 }
            'Enter' {
                Write-Host ''
                return ($selectedIndex -eq 0)
            }
            'Escape' {
                Write-Host ''
                return $false
            }
            'Y' { Write-Host ''; return $true }
            'N' { Write-Host ''; return $false }
        }
    }
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

function Get-ProjectSelection {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = '(not selected)'; ApplyPath = $null; ProjectFile = $null; Message = 'Choose a project folder.' }
    }

    $displayPath = $Path
    try {
        $item = Get-Item -LiteralPath ([IO.Path]::GetFullPath($Path)) -ErrorAction Stop
        $displayPath = $item.FullName
        if (-not $item.PSIsContainer) {
            if ($item.Extension -ine '.kicad_pro') {
                throw 'The selected file is not a .kicad_pro project.'
            }
            return [pscustomobject]@{ IsValid = $true; DisplayPath = $item.FullName; ApplyPath = $item.FullName; ProjectFile = $item.FullName; Message = "Project: $($item.Name)" }
        }

        $projects = @(Get-ChildItem -LiteralPath $item.FullName -File -Filter '*.kicad_pro')
        if ($projects.Count -eq 0) {
            throw 'No .kicad_pro file was found in this folder.'
        }
        if ($projects.Count -gt 1) {
            throw "Found $($projects.Count) .kicad_pro files. Select one project file explicitly."
        }

        return [pscustomobject]@{ IsValid = $true; DisplayPath = $item.FullName; ApplyPath = $item.FullName; ProjectFile = $projects[0].FullName; Message = "Project: $($projects[0].Name)" }
    }
    catch {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = $displayPath; ApplyPath = $null; ProjectFile = $null; Message = $_.Exception.Message }
    }
}

function Get-LogoSelection {
    param([string] $Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = '(not selected)'; ApplyPath = $null; Message = 'Choose a PNG logo.' }
    }

    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        if ($item.PSIsContainer) { throw 'Select a PNG file, not a folder.' }
        if ($item.Extension -ine '.png') { throw 'The selected logo must be a .png file.' }
        return [pscustomobject]@{ IsValid = $true; DisplayPath = $item.FullName; ApplyPath = $item.FullName; Message = "PNG logo: $([Math]::Round($item.Length / 1KB, 1)) KB" }
    }
    catch {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = $Path; ApplyPath = $null; Message = $_.Exception.Message }
    }
}

function Get-TextSelection {
    param(
        [string] $Value,
        [string] $Label
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = '(not selected)'; ApplyPath = $null; Message = "$Label cannot be empty." }
    }
    if ($Value.IndexOfAny(@([char]0, [char]10, [char]13)) -ge 0) {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = $Value; ApplyPath = $null; Message = "$Label must be a single line." }
    }
    if ($Value.Length -gt 80) {
        return [pscustomobject]@{ IsValid = $false; DisplayPath = $Value; ApplyPath = $null; Message = "$Label must be 80 characters or fewer." }
    }

    return [pscustomobject]@{ IsValid = $true; DisplayPath = $Value; ApplyPath = $Value; Message = "$Label is ready." }
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

function Get-KiCadSelection {
    $running = @(Get-Process -Name 'kicad', 'eeschema', 'pl_editor' -ErrorAction SilentlyContinue)
    if ($running.Count -eq 0) {
        return [pscustomobject]@{ IsValid = $true; Message = 'KiCad is closed.' }
    }

    $names = ($running.ProcessName | Sort-Object -Unique) -join ', '
    return [pscustomobject]@{ IsValid = $false; Message = "Close KiCad before applying (running: $names)." }
}

function Write-SummaryRow {
    param(
        [string] $Label,
        [string] $Value,
        [ConsoleColor] $Color = [ConsoleColor]::White
    )

    Write-Host ("  {0,-10}" -f ($Label + ':')) -NoNewline -ForegroundColor DarkGray
    Write-Host $Value -ForegroundColor $Color
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

function Get-BrowserEntries {
    param(
        [string] $Directory,
        [ValidateSet('Project', 'Logo')]
        [string] $Mode,
        [switch] $Drives
    )

    $entries = @()
    if ($Drives) {
        foreach ($drive in @(Get-PSDrive -PSProvider FileSystem | Sort-Object Name)) {
            $entries += [pscustomobject]@{
                Kind = 'Drive'
                Name = "[$($drive.Name):]"
                Path = $drive.Root
            }
        }
        return $entries
    }

    $directoryItem = Get-Item -LiteralPath $Directory -ErrorAction Stop
    if ($Mode -eq 'Project' -and (Get-ProjectSelection $directoryItem.FullName).IsValid) {
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

    $extension = if ($Mode -eq 'Project') { '.kicad_pro' } else { '.png' }
    foreach ($file in @(Get-ChildItem -LiteralPath $directoryItem.FullName -File -Force -ErrorAction Stop | Where-Object { $_.Extension -ieq $extension } | Sort-Object Name)) {
        $entries += [pscustomobject]@{ Kind = 'File'; Name = $file.Name; Path = $file.FullName }
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

function Show-FileBrowser {
    param(
        [ValidateSet('Project', 'Logo')]
        [string] $Mode,
        [string] $InitialPath
    )

    $title = if ($Mode -eq 'Project') { 'Choose a KiCad project' } else { 'Choose a company logo' }
    $fileHint = if ($Mode -eq 'Project') { '.kicad_pro files' } else { '.png files' }
    $currentDirectory = Get-BrowserStartDirectory $InitialPath
    $selectedIndex = 0
    $showDrives = $false
    $browserNotice = $null

    while ($true) {
        try {
            $entries = @(Get-BrowserEntries -Directory $currentDirectory -Mode $Mode -Drives:$showDrives)
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
        try { $visibleRows = [Math]::Max(5, [Console]::WindowHeight - 16) } catch { $visibleRows = 12 }
        $visibleRows = [Math]::Min(18, $visibleRows)
        $firstIndex = if ($selectedIndex -ge $visibleRows) { $selectedIndex - $visibleRows + 1 } else { 0 }
        $lastIndex = [Math]::Min($entries.Count - 1, $firstIndex + $visibleRows - 1)

        Write-Banner
        Write-Host "  $title" -ForegroundColor DarkRed
        $displayLocation = if ($showDrives) { 'Computer / drives' } else { Get-FittedText $currentDirectory ($consoleWidth - 4) }
        Write-Host "  $displayLocation" -ForegroundColor Gray
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
                    $color = if ($entry.Kind -eq 'File') { [ConsoleColor]::White } else { [ConsoleColor]::Gray }
                    Write-Host $text -ForegroundColor $color
                }
            }
        }

        Write-Rule
        Write-Host '  Up/Down move  |  Enter open  |  Backspace up' -ForegroundColor DarkRed
        if ($Mode -eq 'Project') {
            Write-Host '  S select  |  G path  |  D drives  |  Esc cancel' -ForegroundColor DarkRed
        }
        else {
            Write-Host '  G path  |  D drives  |  Esc cancel' -ForegroundColor DarkRed
        }
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
                if ($Mode -eq 'Project') {
                    $folderSelection = Get-ProjectSelection $currentDirectory
                    if ($folderSelection.IsValid) { return $currentDirectory }
                    $browserNotice = $folderSelection.Message
                }
            }
            'G' {
                $typedPath = Read-NewPath 'Go to path' $currentDirectory
                try {
                    $typedItem = Get-Item -LiteralPath $typedPath -ErrorAction Stop
                    if ($typedItem.PSIsContainer) {
                        $currentDirectory = $typedItem.FullName
                        $showDrives = $false
                        $selectedIndex = 0
                        $browserNotice = $null
                    }
                    elseif (($Mode -eq 'Project' -and $typedItem.Extension -ieq '.kicad_pro') -or ($Mode -eq 'Logo' -and $typedItem.Extension -ieq '.png')) {
                        return $typedItem.FullName
                    }
                    else {
                        $browserNotice = "Choose one of the visible $fileHint."
                    }
                }
                catch { $browserNotice = $_.Exception.Message }
            }
            'Enter' {
                if ($entries.Count -eq 0) { continue }
                $entry = $entries[$selectedIndex]
                switch ($entry.Kind) {
                    'File' { return $entry.Path }
                    'Select' { return $entry.Path }
                    'Drive' {
                        $currentDirectory = $entry.Path
                        $showDrives = $false
                        $selectedIndex = 0
                        $browserNotice = $null
                    }
                    'Drives' {
                        $showDrives = $true
                        $selectedIndex = 0
                        $browserNotice = $null
                    }
                    default {
                        $currentDirectory = $entry.Path
                        $showDrives = $false
                        $selectedIndex = 0
                        $browserNotice = $null
                    }
                }
            }
            'Escape' { return $null }
        }
    }
}

function Read-NewText {
    param(
        [string] $Prompt,
        [string] $CurrentValue
    )

    Write-Host ''
    Write-Host '  Blank keeps current.' -ForegroundColor DarkGray
    $newValue = Read-Host "  $Prompt"
    if ([string]::IsNullOrWhiteSpace($newValue)) { return $CurrentValue }
    return $newValue.Trim()
}

try { $Host.UI.RawUI.WindowTitle = 'Angst+Pfister KiCad Schematic Style' } catch {}

$projectPath = ConvertFrom-UserPath $InitialProjectPath
$logoPath = ConvertFrom-UserPath $InitialLogoPath
$authorName = $InitialAuthorName
$teamName = $InitialTeamName
$noticeKind = 'Info'
$noticeMessage = $null

while ($true) {
    $project = Get-ProjectSelection $projectPath
    $logo = Get-LogoSelection $logoPath
    $author = Get-TextSelection $authorName 'Author name'
    $team = Get-TextSelection $teamName 'Team name'
    $kiCad = Get-KiCadSelection
    $isReady = $project.IsValid -and $logo.IsValid -and $author.IsValid -and $team.IsValid -and $kiCad.IsValid

    Write-Banner
    Write-Section 'Inputs'
    Write-Selection 'P' 'Project' $project
    Write-Selection 'L' 'Logo' $logo
    Write-Selection 'N' 'Author' $author
    Write-Selection 'T' 'Team' $team
    Write-Host '  Profile            Angst+Pfister / Group Engineering' -ForegroundColor DarkGray
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

    $applyLabel = if ($isReady) { 'Review & apply' } else { 'Apply (not ready)' }
    $choice = Read-MenuChoice -Items @(
        [pscustomobject]@{ Label = 'Project'; Value = 'P' }
        [pscustomobject]@{ Label = 'Logo'; Value = 'L' }
        [pscustomobject]@{ Label = 'Author'; Value = 'N' }
        [pscustomobject]@{ Label = 'Team'; Value = 'T' }
        [pscustomobject]@{ Label = $applyLabel; Value = 'A' }
        [pscustomobject]@{ Label = 'Quit'; Value = 'Q' }
    )
    switch -Regex ($choice) {
        '^(?i:p)$' {
            $newProjectPath = Show-FileBrowser -Mode Project -InitialPath $projectPath
            if ($null -ne $newProjectPath) {
                $projectPath = $newProjectPath
                $noticeKind = 'Info'
                $noticeMessage = 'Project selection updated.'
            }
            else {
                $noticeKind = 'Info'
                $noticeMessage = 'Project selection unchanged.'
            }
            continue
        }
        '^(?i:l)$' {
            $newLogoPath = Show-FileBrowser -Mode Logo -InitialPath $logoPath
            if ($null -ne $newLogoPath) {
                $logoPath = $newLogoPath
                $noticeKind = 'Info'
                $noticeMessage = 'Logo selection updated.'
            }
            else {
                $noticeKind = 'Info'
                $noticeMessage = 'Logo selection unchanged.'
            }
            continue
        }
        '^(?i:n)$' {
            $authorName = Read-NewText 'Author name' $authorName
            $noticeKind = 'Info'
            $noticeMessage = 'Author name updated.'
            continue
        }
        '^(?i:t)$' {
            $teamName = Read-NewText 'Team name' $teamName
            $noticeKind = 'Info'
            $noticeMessage = 'Team name updated.'
            continue
        }
        '^(?i:q|quit|exit)$' {
            Write-Host ''
            Write-Status Info 'No files were changed.'
            exit 0
        }
        '^(?i:a)$' {
            if (-not $isReady) {
                $noticeKind = 'Error'
                if (-not $kiCad.IsValid) {
                    $noticeMessage = $kiCad.Message
                }
                else {
                    $noticeMessage = 'Complete every field with a valid value before applying.'
                }
                continue
            }

            Write-Banner
            Write-Section 'Review'
            Write-SummaryRow 'Project' $project.ProjectFile
            Write-SummaryRow 'Profile' 'Angst+Pfister / Group Engineering'
            Write-SummaryRow 'Logo' $logo.ApplyPath
            Write-SummaryRow 'Author' $author.ApplyPath
            Write-SummaryRow 'Team' $team.ApplyPath
            Write-SummaryRow 'Date' (Get-Date -Format 'yyyy-MM-dd')
            Write-Rule
            Write-Status Info 'Backup created first.'
            Write-Host ''
            if (-not (Read-ConfirmChoice 'Apply this setup?')) {
                $noticeKind = 'Info'
                $noticeMessage = 'Apply cancelled; no files were changed.'
                continue
            }

            Write-Host ''
            try {
                Show-TuiEffect 'Preparing safe worksheet update'
                Show-TuiEffect 'Embedding logo and title-block values'
                & $styleScript -ProjectPath $project.ApplyPath -LogoPath $logo.ApplyPath -AuthorName $author.ApplyPath -TeamName $team.ApplyPath
                Write-Host ''
                Show-CompletionExplosion 'Schematic style applied'
                [void](Read-Host '  Press Enter to close')
                exit 0
            }
            catch {
                Write-Host ''
                Write-Status Error $_.Exception.Message
                [void](Read-Host '  Press Enter to return to the menu')
                $noticeKind = 'Error'
                $noticeMessage = 'The style was not applied. Correct the issue and try again.'
                continue
            }
        }
        default {
            $noticeKind = 'Warning'
            $noticeMessage = 'Unknown choice. Enter P, L, N, T, A, or Q.'
            continue
        }
    }
}
