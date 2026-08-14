[CmdletBinding()]
param(
    [Parameter(Mandatory, Position = 0)]
    [string[]] $ProjectPath,

    [string] $LogoPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'personal\APlogo_black.png')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-JsonFile {
    param(
        [Parameter(Mandatory)] [object] $Value,
        [Parameter(Mandatory)] [string] $Path
    )

    $json = $Value | ConvertTo-Json -Depth 100
    $temporaryPath = "$Path.tmp"
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($temporaryPath, $json + [Environment]::NewLine, $utf8WithoutBom)
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Set-JsonProperty {
    param(
        [Parameter(Mandatory)] [object] $Object,
        [Parameter(Mandatory)] [string] $Name,
        [Parameter(Mandatory)] $Value
    )

    $Object | Add-Member -MemberType NoteProperty -Name $Name -Value $Value -Force
}

function Resolve-ProjectFile {
    param([Parameter(Mandatory)] [string] $Path)

    $resolvedPath = Resolve-Path -LiteralPath $Path
    $item = Get-Item -LiteralPath $resolvedPath
    if (-not $item.PSIsContainer) {
        if ($item.Extension -ne '.kicad_pro') {
            throw "Expected a .kicad_pro file: $Path"
        }
        return $item
    }

    $projects = @(Get-ChildItem -LiteralPath $item.FullName -File -Filter '*.kicad_pro')
    if ($projects.Count -ne 1) {
        throw "Expected exactly one .kicad_pro file in $($item.FullName); found $($projects.Count). Pass the project file explicitly."
    }
    return $projects[0]
}

function New-WorksheetFile {
    param(
        [Parameter(Mandatory)] [string] $TemplatePath,
        [Parameter(Mandatory)] [string] $ImagePath,
        [Parameter(Mandatory)] [string] $DestinationPath
    )

    $template = Get-Content -LiteralPath $TemplatePath -Raw -Encoding UTF8
    $base64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($ImagePath))
    $chunks = for ($offset = 0; $offset -lt $base64.Length; $offset += 76) {
        $length = [Math]::Min(76, $base64.Length - $offset)
        "`t`t`t`"$($base64.Substring($offset, $length))`""
    }
    $worksheet = $template.Replace('__LOGO_DATA__', ($chunks -join [Environment]::NewLine))
    $utf8WithoutBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($DestinationPath, $worksheet, $utf8WithoutBom)
}

$runningKiCad = Get-Process -Name 'kicad', 'eeschema', 'pl_editor' -ErrorAction SilentlyContinue
if ($runningKiCad) {
    $processNames = ($runningKiCad.ProcessName | Sort-Object -Unique) -join ', '
    throw "Close KiCad before changing a project. Running process(es): $processNames"
}

if (-not (Test-Path -LiteralPath $LogoPath -PathType Leaf)) {
    throw "Logo not found: $LogoPath"
}

$worksheetTemplate = Join-Path $PSScriptRoot 'Company-Schematic.kicad_wks.in'
if (-not (Test-Path -LiteralPath $worksheetTemplate -PathType Leaf)) {
    throw "Worksheet template not found: $worksheetTemplate"
}

$timeStamp = Get-Date -Format 'yyyyMMdd-HHmmss'
foreach ($path in $ProjectPath) {
    $projectFile = Resolve-ProjectFile -Path $path
    $projectDirectory = $projectFile.DirectoryName
    $worksheetPath = Join-Path $projectDirectory 'Company-Schematic.kicad_wks'

    Copy-Item -LiteralPath $projectFile.FullName -Destination "$($projectFile.FullName).$timeStamp.bak"
    if (Test-Path -LiteralPath $worksheetPath -PathType Leaf) {
        Copy-Item -LiteralPath $worksheetPath -Destination "$worksheetPath.$timeStamp.bak"
    }

    New-WorksheetFile -TemplatePath $worksheetTemplate -ImagePath $LogoPath -DestinationPath $worksheetPath

    $project = Get-Content -LiteralPath $projectFile.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
    if (-not ($project.PSObject.Properties.Name -contains 'schematic')) {
        Set-JsonProperty -Object $project -Name 'schematic' -Value ([PSCustomObject]@{})
    }
    Set-JsonProperty -Object $project.schematic -Name 'page_layout_descr_file' -Value '${KIPRJMOD}/Company-Schematic.kicad_wks'
    Write-JsonFile -Value $project -Path $projectFile.FullName

    Write-Host "Styled project: $($projectFile.FullName)"
    Write-Host "Worksheet: $worksheetPath"
    Write-Host "Backup: $($projectFile.FullName).$timeStamp.bak"
}
