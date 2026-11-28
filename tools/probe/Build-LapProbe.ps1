<#
.SYNOPSIS
    Builds the lap probe (roadmap 0.5) for one or more devices.

.DESCRIPTION
    Compiles the data field with probe.jungle, which switches on the (:probe) code of source/Probe.mc, as a debug
    build. The result is tools/probe/out/<device>/LAPPROBE.PRG. The file name matters: the watch writes the
    log to GARMIN/APPS/LOGS/LAPPROBE.TXT, so create that empty file before the run (see docs/LAP-TEST-PROTOCOL.md).
    A throwaway developer key is enough for a sideload; the store key is not needed and must not be used.

.PARAMETER Devices
    Connect IQ device ids, for example fenix3 or fenix9pro47mm.

.PARAMETER Spike
    Builds the Stryd spike (roadmap 3.1, docs/STRYD-SPIKE.md) instead of the lap probe: spike.jungle, the Ant
    permission in tools/probe/manifest-spike.xml (regenerated from manifest.xml here), output LAPSPIKE.PRG (the
    log is GARMIN/APPS/LOGS/LAPSPIKE.TXT). Use a device with Connect IQ 2.4.0 or higher (not fenix 3).

.PARAMETER KeyPath
    Path of a developer key in DER format (see the notes below to create a throwaway key).

.EXAMPLE
    .\tools\probe\Build-LapProbe.ps1 -KeyPath C:\keys\throwaway.der -Devices fenix9pro47mm, fenix3

.NOTES
    Throwaway key: openssl genrsa -out key.pem 4096
                   openssl pkcs8 -topk8 -inform PEM -outform DER -in key.pem -out throwaway.der -nocrypt
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [string]$KeyPath,

    [string[]]$Devices = @('fenix9pro47mm', 'fenix3'),

    [switch]$Spike
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$sdkPath = (Get-Content (Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg')).Trim()
$compiler = Join-Path $sdkPath 'bin\monkeyc.bat'

if (-not (Test-Path $KeyPath)) {
    throw "Developer key not found: $KeyPath"
}

$jungleFile = 'probe.jungle'
$programName = 'LAPPROBE.PRG'
if ($Spike) {
    $jungleFile = 'spike.jungle'
    $programName = 'LAPSPIKE.PRG'
    # The spike needs the Ant permission: the same manifest as the app, with that permission added.
    $spikeManifest = (Get-Content (Join-Path $repositoryRoot 'manifest.xml') -Raw).Replace(
        '<iq:permissions/>',
        "<iq:permissions>`n            <iq:uses-permission id=`"Ant`"/>`n        </iq:permissions>"
    )
    Set-Content -Path (Join-Path $PSScriptRoot 'manifest-spike.xml') -Value $spikeManifest -NoNewline
}

foreach ($device in $Devices) {
    $outputDirectory = Join-Path $PSScriptRoot "out\$device"
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    $outputFile = Join-Path $outputDirectory $programName

    Push-Location $repositoryRoot
    try {
        & $compiler -d $device -f $jungleFile -o $outputFile -y $KeyPath -w
        if ($LASTEXITCODE -ne 0) {
            throw "monkeyc failed for $device (exit code $LASTEXITCODE)"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host "Built $outputFile"
}

Write-Host ''
Write-Host "Next: copy $programName to GARMIN/APPS on the watch, create an empty GARMIN/APPS/LOGS/$([System.IO.Path]::GetFileNameWithoutExtension($programName)).TXT,"
Write-Host 'add the field to a data screen and run one scenario per activity (docs/LAP-TEST-PROTOCOL.md).'
