#Requires -Version 7.0
<#
.SYNOPSIS
    Builds the private Connect IQ toolchain image for CI and pins it in .ciq-toolchain-image.
.DESCRIPTION
    Garmin requires a login (with 2FA) to download device files, which CI cannot do headless.
    This script is run by the maintainer on their own machine instead:

      1. Checks that the local Connect IQ folder (filled by the SDK Manager) has device files for
         every product in manifest.xml.
      2. Looks up the Linux SDK for .ciq-sdk-version in Garmin's public SDK index, downloads it once
         to compute its SHA-256 (the Docker build verifies the same bytes).
      3. Builds tools/toolchain/Dockerfile with the device files and simulator fonts.
      4. Pushes the image to ghcr.io (private package) and writes the digest-pinned reference to
         .ciq-toolchain-image. Commit that file through a pull request.

    The image contains no credentials or signing keys.
.PARAMETER ConnectIQRoot
    The local Connect IQ folder. Defaults to the SDK Manager location for the current OS.
.PARAMETER ImageName
    Image repository on ghcr.io.
.PARAMETER NoPush
    Build only; do not push and do not update .ciq-toolchain-image.
.EXAMPLE
    gh auth refresh -h github.com -s write:packages
    ./tools/toolchain/Publish-CiqToolchainImage.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepositoryRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../..')).Path,

    [string]$ConnectIQRoot,

    [ValidatePattern('^ghcr\.io/[a-z0-9_.-]+/[a-z0-9_.-]+$')]
    [string]$ImageName = 'ghcr.io/mvaneijken/ciq-toolchain',

    [switch]$NoPush
)

$ErrorActionPreference = 'Stop'

function Assert-NativeSuccess {
    # Call native commands directly and run this right after. A wrapper that forwards the arguments
    # (an advanced function with ValueFromRemainingArguments) lets PowerShell bind single-dash
    # arguments such as '-q' or '-t' to its own common parameters and drop them silently.
    param(
        [Parameter(Mandatory)]
        [string]$Description
    )

    if ($LASTEXITCODE -ne 0) { throw "'$Description' failed with exit code $LASTEXITCODE." }
}

foreach ($Tool in 'docker', 'gh') {
    if ($null -eq (Get-Command -Name $Tool -ErrorAction SilentlyContinue)) { throw "'$Tool' is required." }
}

if (-not $ConnectIQRoot) {
    $ConnectIQRoot = if ($IsWindows) { Join-Path -Path $env:APPDATA -ChildPath 'Garmin/ConnectIQ' }
    elseif ($IsMacOS) { Join-Path -Path $HOME -ChildPath 'Library/Application Support/Garmin/ConnectIQ' }
    else { Join-Path -Path $HOME -ChildPath '.Garmin/ConnectIQ' }
}
$DevicesRoot = Join-Path -Path $ConnectIQRoot -ChildPath 'Devices'
$FontsRoot = Join-Path -Path $ConnectIQRoot -ChildPath 'Fonts'
if (-not (Test-Path -LiteralPath $DevicesRoot)) { throw "No Devices folder in '$ConnectIQRoot'. Download the devices with the SDK Manager first." }

# --- 1. Device files for every manifest product -------------------------------------------------
# Same extraction as tools/ci/build.sh, so the image and the CI check agree on the product list.
$ManifestText = Get-Content -LiteralPath (Join-Path -Path $RepositoryRoot -ChildPath 'manifest.xml') -Raw
$Products = @([regex]::Matches($ManifestText, 'iq:product id="([^"]+)"') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique)
if ($Products.Count -eq 0) { throw 'No products found in manifest.xml.' }
$Missing = @($Products | Where-Object { -not (Test-Path -LiteralPath (Join-Path -Path $DevicesRoot -ChildPath $_)) })
if ($Missing.Count -gt 0) {
    throw "Missing device files for $($Missing.Count) product(s): $($Missing -join ', '). Download them in the SDK Manager."
}
"Device files present for all $($Products.Count) products." | Write-Host
if (-not (Test-Path -LiteralPath $FontsRoot)) {
    Write-Warning "No Fonts folder in '$ConnectIQRoot': the simulator (unit tests) will not have its fonts."
}

# --- 2. Linux SDK from the public index -----------------------------------------------------------
$SdkVersion = (Get-Content -LiteralPath (Join-Path -Path $RepositoryRoot -ChildPath '.ciq-sdk-version') -Raw).Trim()
$Sdks = Invoke-RestMethod -Uri 'https://developer.garmin.com/downloads/connect-iq/sdks/sdks.json'
$Sdk = @($Sdks | Where-Object { $_.version -eq $SdkVersion })
if ($Sdk.Count -ne 1 -or -not $Sdk[0].linux) { throw "SDK $SdkVersion (Linux) not found in Garmin's SDK index." }
$SdkFileName = $Sdk[0].linux

$Staging = Join-Path -Path ([IO.Path]::GetTempPath()) -ChildPath "ciq-toolchain-$([guid]::NewGuid().ToString('N'))"
New-Item -Path $Staging -ItemType Directory | Out-Null
try {
    $SdkZip = Join-Path -Path $Staging -ChildPath 'sdk.zip'
    Invoke-WebRequest -Uri "https://developer.garmin.com/downloads/connect-iq/sdks/$SdkFileName" -OutFile $SdkZip
    $SdkSha256 = (Get-FileHash -LiteralPath $SdkZip -Algorithm SHA256).Hash.ToLowerInvariant()
    Remove-Item -LiteralPath $SdkZip
    "SDK $SdkVersion : $SdkFileName (sha256 $SdkSha256)" | Write-Host

    # --- 3. Build context: only the devices this project uses, plus fonts -------------------------
    $ContextDevices = Join-Path -Path $Staging -ChildPath 'ConnectIQ/Devices'
    New-Item -Path $ContextDevices -ItemType Directory -Force | Out-Null
    foreach ($Product in $Products) {
        Copy-Item -LiteralPath (Join-Path -Path $DevicesRoot -ChildPath $Product) -Destination $ContextDevices -Recurse
    }
    if (Test-Path -LiteralPath $FontsRoot) {
        Copy-Item -LiteralPath $FontsRoot -Destination (Join-Path -Path $Staging -ChildPath 'ConnectIQ') -Recurse
    }

    $Tag = '{0}:{1}-{2:yyyyMMddHHmm}' -f $ImageName, $SdkVersion, (Get-Date).ToUniversalTime()
    docker build `
        --file (Join-Path -Path $PSScriptRoot -ChildPath 'Dockerfile') `
        --build-arg "SDK_VERSION=$SdkVersion" `
        --build-arg "SDK_FILENAME=$SdkFileName" `
        --build-arg "SDK_SHA256=$SdkSha256" `
        --tag $Tag `
        $Staging
    Assert-NativeSuccess -Description 'docker build'

    if ($NoPush) {
        "Built $Tag (not pushed)." | Write-Host
        return
    }

    # --- 4. Push and pin ------------------------------------------------------------------------
    if ($PSCmdlet.ShouldProcess($Tag, 'Push to ghcr.io and pin in .ciq-toolchain-image')) {
        $Owner = $ImageName.Split('/')[1]
        gh auth token | docker login ghcr.io --username $Owner --password-stdin
        if ($LASTEXITCODE -ne 0) { throw 'docker login ghcr.io failed. Run: gh auth refresh -h github.com -s write:packages' }
        docker push $Tag
        Assert-NativeSuccess -Description 'docker push'
        $Digest = (docker inspect --format '{{index .RepoDigests 0}}' $Tag).Trim()
        if ($Digest -notmatch '^ghcr\.io/.+@sha256:[0-9a-f]{64}$') { throw "Unexpected digest reference '$Digest'." }

        $PinFile = Join-Path -Path $RepositoryRoot -ChildPath '.ciq-toolchain-image'
        $Content = @(
            '# Toolchain image used by CI, pinned by digest. Written by tools/toolchain/Publish-CiqToolchainImage.ps1.'
            "# Built $((Get-Date).ToUniversalTime().ToString('u')) from SDK $SdkVersion ($SdkFileName), $($Products.Count) devices; tag $Tag"
            $Digest
        )
        [IO.File]::WriteAllLines($PinFile, [string[]]$Content)
        @(
            "Pushed and pinned: $Digest"
            'Next:'
            '  1. First time only: package settings on GitHub > Manage Actions access > add this repository (Read).'
            '  2. Commit .ciq-toolchain-image through a pull request and comment /validate.'
        ) | Write-Host
    }
}
finally {
    Remove-Item -LiteralPath $Staging -Recurse -Force -ErrorAction SilentlyContinue
}
