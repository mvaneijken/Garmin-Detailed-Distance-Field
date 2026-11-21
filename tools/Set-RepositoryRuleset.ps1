#Requires -Version 7.0
<#
.SYNOPSIS
    Applies the repository rulesets in .github/rulesets to the GitHub repository.
.DESCRIPTION
    Branch protection is kept as code: each JSON file in .github/rulesets is the exact body of the
    GitHub REST rulesets API (POST/PUT /repos/{owner}/{repo}/rulesets). This script creates a ruleset
    that does not exist yet and replaces one with the same name.

    It runs with the GitHub CLI (gh) and the caller's own credentials, which need admin rights on the
    repository. No workflow runs it: changing the rules that protect master is a maintainer action.
.PARAMETER Repository
    The repository as owner/name.
.PARAMETER RulesetPath
    The folder that holds the ruleset JSON files.
.EXAMPLE
    ./tools/Set-RepositoryRuleset.ps1 -WhatIf
.EXAMPLE
    ./tools/Set-RepositoryRuleset.ps1 -Repository mvaneijken/Garmin-Detailed-Distance-Field
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidatePattern('^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$')]
    [string]$Repository = 'mvaneijken/Garmin-Detailed-Distance-Field',

    [string]$RulesetPath = (Join-Path -Path $PSScriptRoot -ChildPath '..' -AdditionalChildPath '.github', 'rulesets')
)

$ErrorActionPreference = 'Stop'

if ($null -eq (Get-Command -Name gh -ErrorAction SilentlyContinue)) {
    throw 'The GitHub CLI (gh) is required. Install it and sign in with: gh auth login'
}

$Existing = gh api --paginate "repos/$Repository/rulesets" | ConvertFrom-Json
if ($LASTEXITCODE -ne 0) {
    throw "Could not list the rulesets of '$Repository'. Admin rights on the repository are required."
}

foreach ($File in (Get-ChildItem -Path $RulesetPath -Filter '*.json' -File | Sort-Object -Property Name)) {
    $Ruleset = Get-Content -LiteralPath $File.FullName -Raw | ConvertFrom-Json
    $Current = @($Existing | Where-Object { $_.name -eq $Ruleset.name })

    if ($Current.Count -gt 1) {
        throw "More than one ruleset named '$($Ruleset.name)' exists on '$Repository'; resolve that by hand first."
    }

    if ($Current.Count -eq 1) {
        if ($PSCmdlet.ShouldProcess("$Repository ruleset '$($Ruleset.name)' (id $($Current[0].id))", "Replace from $($File.Name)")) {
            $null = gh api --method PUT "repos/$Repository/rulesets/$($Current[0].id)" --input $File.FullName
            if ($LASTEXITCODE -ne 0) { throw "Replacing ruleset '$($Ruleset.name)' failed." }
            "Replaced ruleset '{0}'." -f $Ruleset.name | Write-Host
        }
    }
    elseif ($PSCmdlet.ShouldProcess("$Repository ruleset '$($Ruleset.name)'", "Create from $($File.Name)")) {
        $null = gh api --method POST "repos/$Repository/rulesets" --input $File.FullName
        if ($LASTEXITCODE -ne 0) { throw "Creating ruleset '$($Ruleset.name)' failed." }
        "Created ruleset '{0}'." -f $Ruleset.name | Write-Host
    }
}
