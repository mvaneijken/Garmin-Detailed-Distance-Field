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

    [string[]]$Devices = @('fenix9pro47mm', 'fenix3')
)

$ErrorActionPreference = 'Stop'

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..' '..')).Path
$sdkPath = (Get-Content (Join-Path $env:APPDATA 'Garmin\ConnectIQ\current-sdk.cfg')).Trim()
$compiler = Join-Path $sdkPath 'bin\monkeyc.bat'

if (-not (Test-Path $KeyPath)) {
    throw "Developer key not found: $KeyPath"
}

foreach ($device in $Devices) {
    $outputDirectory = Join-Path $PSScriptRoot "out\$device"
    New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
    $outputFile = Join-Path $outputDirectory 'LAPPROBE.PRG'

    Push-Location $repositoryRoot
    try {
        & $compiler -d $device -f probe.jungle -o $outputFile -y $KeyPath -w
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
Write-Host 'Next: copy LAPPROBE.PRG to GARMIN/APPS on the watch, create an empty GARMIN/APPS/LOGS/LAPPROBE.TXT,'
Write-Host 'add the field to a data screen and run one scenario per activity (docs/LAP-TEST-PROTOCOL.md).'
