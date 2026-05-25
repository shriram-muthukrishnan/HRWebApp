# CVE Validation Script for Windows (PowerShell)
# Queries GitHub Security Advisories REST API to validate dependencies.
# Supports Maven (Java) and NuGet (.NET) ecosystems.
# Requires PowerShell 5.1+ (built into Windows 10+).
#
# Usage:
#   .\cve.ps1 -Dependencies "org.springframework:spring-core:5.3.9"
#   .\cve.ps1 -Dependencies "Newtonsoft.Json:12.0.3" -Ecosystem nuget
#   .\cve.ps1 -Dependencies "org.springframework:spring-core:5.3.9,log4j:log4j:1.2.17" -OutputFile results.json -Format json
#
# Environment Variables:
#   GITHUB_TOKEN  GitHub Personal Access Token (raises rate limit from 60 to 5000 req/hr)

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Dependencies,

    [ValidateSet('maven', 'nuget')]
    [string]$Ecosystem,

    [string]$OutputFile,

    [ValidateSet('json', 'text', 'markdown')]
    [string]$Format = 'text',

    [string]$GitHubToken
)

$ErrorActionPreference = 'Stop'

# Auto-set GITHUB_TOKEN from gh CLI if not already set
if (-not $env:GITHUB_TOKEN -and (Get-Command 'gh' -ErrorAction SilentlyContinue)) {
    try { $env:GITHUB_TOKEN = & gh auth token 2>$null } catch {}
}

$token = if ($GitHubToken) { $GitHubToken } elseif ($env:GITHUB_TOKEN) { $env:GITHUB_TOKEN } else { $null }

# Auto-detect ecosystem if not specified
if (-not $Ecosystem) {
    $firstDep = ($Dependencies -split ',')[0].Trim()
    $colonCount = ($firstDep.ToCharArray() | Where-Object { $_ -eq ':' }).Count
    if ($colonCount -ge 2) {
        $Ecosystem = 'maven'
    } else {
        $Ecosystem = 'nuget'
    }
    Write-Host "Auto-detected ecosystem: $Ecosystem" -ForegroundColor Yellow
}

# --- Version comparison ---

function Compare-PackageVersion {
    param([string]$V1, [string]$V2)
    # Strip common version suffixes (covers both Maven and NuGet conventions)
    $strip = { param($v) $v -replace '[.\-]?(RELEASE|Final|GA|SNAPSHOT|M\d+|RC\d+|CR\d+|beta\d*|alpha\d*|SP\d+|preview[.\d]*|dev[.\d]*)$', '' }
    $v1c = & $strip $V1
    $v2c = & $strip $V2
    $p1 = $v1c -split '[.\-]'
    $p2 = $v2c -split '[.\-]'
    $max = [Math]::Max($p1.Length, $p2.Length)
    for ($i = 0; $i -lt $max; $i++) {
        $a = if ($i -lt $p1.Length -and $p1[$i] -match '^\d+') { [int]$Matches[0] } else { 0 }
        $b = if ($i -lt $p2.Length -and $p2[$i] -match '^\d+') { [int]$Matches[0] } else { 0 }
        if ($a -lt $b) { return -1 }
        if ($a -gt $b) { return  1 }
    }
    return 0
}

function Test-VersionInRange {
    param([string]$Version, [string]$Range)
    if (-not $Range -or $Range -eq 'null') { return $true }
    foreach ($c in ($Range -split ',')) {
        $c = $c.Trim()
        if ($c -match '^([><=!]+)\s*(.+)$') {
            $op  = $Matches[1]
            $ver = $Matches[2].Trim()
            $cmp = Compare-PackageVersion $Version $ver
            switch ($op) {
                '>='            { if ($cmp -lt 0) { return $false } }
                '>'             { if ($cmp -le 0) { return $false } }
                '<='            { if ($cmp -gt 0) { return $false } }
                '<'             { if ($cmp -ge 0) { return $false } }
                { $_ -in '=','==' } { if ($cmp -ne 0) { return $false } }
            }
        }
    }
    return $true
}

# --- GitHub API ---

function Get-Advisories {
    param([string]$Package)
    $encodedPkg = [System.Uri]::EscapeDataString($Package)
    $url = "https://api.github.com/advisories?affects=$encodedPkg&ecosystem=$Ecosystem&per_page=100&type=reviewed"
    $headers = @{
        'Accept'               = 'application/vnd.github+json'
        'X-GitHub-Api-Version' = '2022-11-28'
    }
    if ($token) { $headers['Authorization'] = "Bearer $token" }

    try {
        $resp = Invoke-RestMethod -Uri $url -Headers $headers -TimeoutSec 30
        if ($null -eq $resp) { return @() }
        if ($resp -isnot [System.Array]) { return @($resp) }
        return $resp
    }
    catch {
        $code = 0
        try { $code = [int]$_.Exception.Response.StatusCode } catch {}
        if ($code -eq 403) {
            Write-Host 'ERROR: GitHub API rate limit exceeded. Set GITHUB_TOKEN for 5000 req/hr.' -ForegroundColor Red
        } else {
            Write-Host "WARNING: HTTP $code for $Package" -ForegroundColor Yellow
        }
        return @()
    }
}

# --- Dependency parsing ---

function Parse-Dependency {
    param([string]$DepStr)
    $parts = $DepStr -split ':'
    if ($Ecosystem -eq 'maven') {
        if ($parts.Count -lt 3) { return $null }
        return @{
            Package = "$($parts[0]):$($parts[1])"
            Version = $parts[2]
        }
    } else {
        # NuGet: PackageName:version
        if ($parts.Count -lt 2) { return $null }
        return @{
            Package = $parts[0]
            Version = $parts[1]
        }
    }
}

# --- Main scan ---

$scanDate = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss+00:00')
$vulnerabilities = [System.Collections.ArrayList]::new()
$advisoryCache = @{}

Write-Host "Validating CVEs for $Ecosystem dependencies..." -ForegroundColor Yellow

$depList = $Dependencies -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }
$total     = $depList.Count
$processed = 0

foreach ($depStr in $depList) {
    $parsed = Parse-Dependency $depStr
    if (-not $parsed) {
        Write-Host "WARNING: Skipping malformed dependency: $depStr" -ForegroundColor Yellow
        continue
    }
    $package = $parsed.Package
    $version = $parsed.Version
    $processed++

    if (-not $advisoryCache.ContainsKey($package)) {
        Write-Host "  [$processed/$total] Querying $package..." -ForegroundColor Gray
        $advisoryCache[$package] = Get-Advisories $package
        Start-Sleep -Milliseconds 100
    } else {
        Write-Host "  [$processed/$total] $package (cached)" -ForegroundColor Gray
    }

    $advisories = $advisoryCache[$package]
    if (-not $advisories -or $advisories.Count -eq 0) { continue }

    foreach ($adv in $advisories) {
        foreach ($vuln in $adv.vulnerabilities) {
            if ($vuln.package.ecosystem -ne $Ecosystem -or $vuln.package.name -ne $package) { continue }
            $vrange  = $vuln.vulnerable_version_range
            $patched = if ($vuln.first_patched_version) { $vuln.first_patched_version } else { 'none' }

            if (Test-VersionInRange $version $vrange) {
                [void]$vulnerabilities.Add([ordered]@{
                    dependency       = $depStr
                    cve_id           = if ($adv.cve_id)   { $adv.cve_id }   else { 'N/A' }
                    ghsa_id          = if ($adv.ghsa_id)  { $adv.ghsa_id }  else { 'N/A' }
                    severity         = if ($adv.severity)  { $adv.severity }  else { 'unknown' }
                    summary          = if ($adv.summary)   { $adv.summary }   else { 'N/A' }
                    url              = if ($adv.html_url)  { $adv.html_url }  else { '' }
                    vulnerable_range = if ($vrange)        { $vrange }        else { '' }
                    patched_version  = $patched
                })
            }
        }
    }
}

$vulnCount = $vulnerabilities.Count
Write-Host "Scan complete. $processed dependencies checked."

# --- Format output ---

switch ($Format) {
    'json' {
        $report = [ordered]@{
            scan_date                    = $scanDate
            ecosystem                    = $Ecosystem
            total_dependencies_scanned   = $processed
            total_vulnerabilities_found  = $vulnCount
            vulnerabilities              = @($vulnerabilities)
        }
        $output = $report | ConvertTo-Json -Depth 10
    }
    'markdown' {
        $lines = @(
            '# CVE Scan Report', '',
            "- **Date**: $scanDate",
            "- **Ecosystem**: $Ecosystem",
            "- **Dependencies scanned**: $processed",
            "- **Vulnerabilities found**: $vulnCount", ''
        )
        if ($vulnCount -eq 0) {
            $lines += '> No known vulnerabilities found.'
        } else {
            $lines += '| Dependency | CVE | Severity | Summary | Vulnerable Range | Patched Version |'
            $lines += '|---|---|---|---|---|---|'
            foreach ($v in $vulnerabilities) {
                $s = $v.summary -replace '\|', '\|'
                $lines += "| $($v.dependency) | $($v.cve_id) | $($v.severity) | $s | $($v.vulnerable_range) | $($v.patched_version) |"
            }
        }
        $output = $lines -join "`n"
    }
    default {
        $lines = @(
            '======================================',
            "  CVE Scan Report ($Ecosystem)",
            '======================================',
            "Date: $scanDate",
            "Dependencies scanned: $processed",
            "Vulnerabilities found: $vulnCount", ''
        )
        if ($vulnCount -eq 0) {
            $lines += 'No known vulnerabilities found.'
        } else {
            $lines += '--------------------------------------'
            foreach ($v in $vulnerabilities) {
                $lines += ''
                $lines += "  Dependency: $($v.dependency)"
                $lines += "  CVE:        $($v.cve_id)"
                $lines += "  GHSA:       $($v.ghsa_id)"
                $lines += "  Severity:   $($v.severity)"
                $lines += "  Summary:    $($v.summary)"
                $lines += "  Range:      $($v.vulnerable_range)"
                $lines += "  Fix:        Upgrade to $($v.patched_version)"
                $lines += "  URL:        $($v.url)"
                $lines += '--------------------------------------'
            }
        }
        $output = $lines -join "`n"
    }
}

# Write output
if ($OutputFile) {
    [System.IO.File]::WriteAllText($OutputFile, $output, [System.Text.Encoding]::UTF8)
    Write-Host "Results saved to $OutputFile" -ForegroundColor Green
} else {
    Write-Output $output
}

# Exit code
if ($vulnCount -gt 0) {
    Write-Host "WARNING: Found $vulnCount vulnerabilities" -ForegroundColor Yellow
    exit 1
} else {
    Write-Host 'OK: No known CVEs found' -ForegroundColor Green
    exit 0
}
