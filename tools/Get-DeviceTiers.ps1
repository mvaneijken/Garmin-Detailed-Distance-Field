#Requires -Version 7.0
<#
.SYNOPSIS
    Classifies every product in manifest.xml into a memory/API tier and writes the result to docs/.
.DESCRIPTION
    Roadmap item 0.3. Reads compiler.json of each manifest product from the local Connect IQ device
    folder (filled by the SDK Manager) and takes:

      - the data field memory limit (appTypes, type datafield),
      - the lowest and highest Connect IQ version over all firmware part numbers.

    Tiers (docs/ANALYSIS.md section 6):

      T0   16 KB data field memory
      T1   32 KB, highest Connect IQ version below 5.0
      T1b  32 KB, highest Connect IQ version 5.0 or higher (new device, old memory budget)
      T2   64 KB and 128 KB
      T3   256 KB

    Two files are written, both without machine specific paths or timestamps so that a re-run on the
    same SDK gives identical output:

      docs/device-tiers.csv          one row per product
      docs/device-tiers.jungle.txt   proposed per-device excludeAnnotations lines

    The jungle lines use feature annotations: t1, t2 and t3 mean "needs at least this tier" (the code
    is left out on lower tiers), t0 marks the no-op twin that only T0 devices keep. With -UpdateJungles
    the lines are written into the marked block of monkey.jungle and probe.jungle (every device line
    repeats the base annotations of its file, because a device line replaces the base line). Run this
    script again after every SDK or device update.
.PARAMETER RepositoryRoot
    The repository root (manifest.xml, .ciq-sdk-version).
.PARAMETER ConnectIQRoot
    The local Connect IQ folder. Defaults to the SDK Manager location for the current OS.
.PARAMETER OutputPath
    The folder the two files are written to.
.EXAMPLE
    ./tools/Get-DeviceTiers.ps1
.EXAMPLE
    ./tools/Get-DeviceTiers.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepositoryRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path,

    [string]$ConnectIQRoot,

    [string]$OutputPath = (Join-Path -Path (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path -ChildPath 'docs'),

    [switch]$UpdateJungles
)

$ErrorActionPreference = 'Stop'

if (-not $ConnectIQRoot) {
    $ConnectIQRoot = if ($IsWindows) {
        Join-Path -Path $env:APPDATA -ChildPath 'Garmin/ConnectIQ'
    }
    elseif ($IsMacOS) {
        Join-Path -Path $HOME -ChildPath 'Library/Application Support/Garmin/ConnectIQ'
    }
    else {
        Join-Path -Path $HOME -ChildPath '.Garmin/ConnectIQ'
    }
}

$DevicesRoot = Join-Path -Path $ConnectIQRoot -ChildPath 'Devices'
if (-not (Test-Path -LiteralPath $DevicesRoot)) {
    throw "No Devices folder in '$ConnectIQRoot'. Download the devices with the SDK Manager first."
}

# Feature annotations that are excluded per tier. An annotation tN means "needs at least tier N".
$ExcludedAnnotationsByTier = @{
    T0  = 't1;t2;t3'
    T1  = 't0;t2;t3'
    T1b = 't0;t2;t3'
    T2  = 't0;t3'
    T3  = 't0'
}

function Get-DeviceTier {
    param(
        [Parameter(Mandatory)]
        [int]$MemoryBytes,

        [Parameter(Mandatory)]
        [version]$MaxConnectIQVersion
    )

    if ($MemoryBytes -le 16384) {
        return 'T0'
    }

    if ($MemoryBytes -le 32768) {
        if ($MaxConnectIQVersion.Major -ge 5) {
            return 'T1b'
        }

        return 'T1'
    }

    if ($MemoryBytes -le 131072) {
        return 'T2'
    }

    return 'T3'
}

$ManifestText = Get-Content -LiteralPath (Join-Path -Path $RepositoryRoot -ChildPath 'manifest.xml') -Raw
$Products = @([regex]::Matches($ManifestText, 'iq:product id="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
if ($Products.Count -eq 0) {
    throw 'No products found in manifest.xml.'
}

$Rows = foreach ($Product in $Products) {
    $CompilerJsonPath = Join-Path -Path $DevicesRoot -ChildPath "$Product/compiler.json"
    if (-not (Test-Path -LiteralPath $CompilerJsonPath)) {
        throw "No compiler.json for '$Product' in '$DevicesRoot'. Download the device with the SDK Manager."
    }

    $Compiler = Get-Content -LiteralPath $CompilerJsonPath -Raw | ConvertFrom-Json
    $DataField = @($Compiler.appTypes | Where-Object { $_.type -eq 'datafield' })
    if ($DataField.Count -ne 1) {
        throw "'$Product' has $($DataField.Count) datafield entries in compiler.json; expected exactly one."
    }

    $Versions = @($Compiler.partNumbers | ForEach-Object { [version]$_.connectIQVersion } | Sort-Object)
    if ($Versions.Count -eq 0) {
        throw "'$Product' has no part numbers with a Connect IQ version."
    }

    $Tier = Get-DeviceTier -MemoryBytes ([int]$DataField[0].memoryLimit) -MaxConnectIQVersion $Versions[-1]

    [pscustomobject][ordered]@{
        Id                   = $Product
        Name                 = $Compiler.displayName
        DataFieldMemoryBytes = [int]$DataField[0].memoryLimit
        MinConnectIQ         = $Versions[0].ToString()
        MaxConnectIQ         = $Versions[-1].ToString()
        Tier                 = $Tier
        ExcludeAnnotations   = $ExcludedAnnotationsByTier[$Tier]
    }
}

$SdkVersion = (Get-Content -LiteralPath (Join-Path -Path $RepositoryRoot -ChildPath '.ciq-sdk-version') -Raw).Trim()

$CsvPath = Join-Path -Path $OutputPath -ChildPath 'device-tiers.csv'
$JunglePath = Join-Path -Path $OutputPath -ChildPath 'device-tiers.jungle.txt'

$JungleLines = @(
    "# Generated by tools/Get-DeviceTiers.ps1 from the device files of SDK $SdkVersion. Do not edit by hand."
    '# The lines in monkey.jungle and probe.jungle are generated from this list (-UpdateJungles) and also hold the base annotations.'
    '# An annotation tN means "needs at least tier N"; t0 marks the no-op twin kept only on T0. Each line lists what that device must leave out.'
)
foreach ($Row in $Rows) {
    $JungleLines += "$($Row.Id).excludeAnnotations = $($Row.ExcludeAnnotations)".TrimEnd()
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Write device-tiers.csv and device-tiers.jungle.txt for $($Rows.Count) products")) {
    $Rows | Export-Csv -LiteralPath $CsvPath -NoTypeInformation -Encoding utf8
    Set-Content -LiteralPath $JunglePath -Value $JungleLines -Encoding utf8
}

function Update-JungleTierBlock {
    # A per-device excludeAnnotations line REPLACES the base line (checked with SDK 9.3.0), so every device line
    # repeats the base annotations of its jungle file, then adds the tier annotations.
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    $Begin = '# BEGIN generated tier lines (tools/Get-DeviceTiers.ps1 -UpdateJungles, do not edit by hand)'
    $End = '# END generated tier lines'
    $Text = (Get-Content -LiteralPath $Path -Raw) -replace "`r`n", "`n"

    $BaseMatch = [regex]::Match($Text, '(?m)^base\.excludeAnnotations\s*=\s*(.*?)\s*$')
    if (-not $BaseMatch.Success) {
        throw "No base.excludeAnnotations line in '$Path'."
    }
    $Base = $BaseMatch.Groups[1].Value

    $Block = @($Begin)
    foreach ($Row in $Rows) {
        $Block += "$($Row.Id).excludeAnnotations = $Base;$($Row.ExcludeAnnotations)".Replace(' = ;', ' = ')
    }
    $Block += $End
    $BlockText = $Block -join "`n"

    $Pattern = '(?s)' + [regex]::Escape($Begin) + '.*?' + [regex]::Escape($End)
    if ($Text -match $Pattern) {
        $Text = [regex]::Replace($Text, $Pattern, { param($Match) $BlockText })
    }
    else {
        $Text = $Text.TrimEnd() + "`n`n" + $BlockText + "`n"
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Write the generated tier lines')) {
        Set-Content -LiteralPath $Path -Value $Text -NoNewline -Encoding utf8
    }
}

if ($UpdateJungles) {
    foreach ($JungleFile in 'monkey.jungle', 'probe.jungle') {
        Update-JungleTierBlock -Path (Join-Path -Path $RepositoryRoot -ChildPath $JungleFile)
    }
}

"{0} products classified (SDK {1})." -f $Rows.Count, $SdkVersion | Write-Output
$Rows | Group-Object -Property Tier | Sort-Object -Property Name | ForEach-Object {
    '  {0,-3} {1,3} devices' -f $_.Name, $_.Count | Write-Output
}
