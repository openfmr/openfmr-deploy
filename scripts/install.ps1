<#
.SYNOPSIS
  OpenFMR — install.ps1
  Clones every OpenFMR repository into the root of openfmr-deploy/.

.DESCRIPTION
  The script is idempotent: if a repository directory already exists it is
  skipped with a notice rather than re-cloned.

.EXAMPLE
  .\scripts\install.ps1
#>

$ErrorActionPreference = 'Stop'

# ── Resolve the project root (one level up from this script) ─────────────────
$ScriptDir   = $PSScriptRoot
$ProjectRoot = (Resolve-Path "$ScriptDir\..").Path

# ── Color helpers ────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]    $Msg" -ForegroundColor Green }
function Write-Skip    { param([string]$Msg) Write-Host "[SKIP]  $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg) Write-Host "[FAIL]  $Msg" -ForegroundColor Red }

# ── Repository list ──────────────────────────────────────────────────────────
$Repos = @(
    @{ Name = "openfmr-core";           Url = "https://github.com/openfmr/openfmr-core.git" }
    @{ Name = "openfmr-module-cr";      Url = "https://github.com/openfmr/openfmr-module-cr.git" }
    @{ Name = "openfmr-module-hfr";     Url = "https://github.com/openfmr/openfmr-module-hfr.git" }
    @{ Name = "openfmr-module-ts";      Url = "https://github.com/openfmr/openfmr-module-ts.git" }
    @{ Name = "openfmr-module-shr";     Url = "https://github.com/openfmr/openfmr-module-shr.git" }
    @{ Name = "openfmr-module-lmis";    Url = "https://github.com/openfmr/openfmr-module-lmis.git" }
    @{ Name = "openfmr-admin-ui";       Url = "https://github.com/openfmr/openfmr-admin-ui.git" }
    @{ Name = "openfmr-clinical-ui";    Url = "https://github.com/openfmr/openfmr-clinical-ui.git" }
    @{ Name = "openfmr-operations-ui";  Url = "https://github.com/openfmr/openfmr-operations-ui.git" }
)

# ── Main ─────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   OpenFMR - Repository Installer" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

Write-Info "Project root: $ProjectRoot"
Write-Host ""

$Cloned  = 0
$Skipped = 0
$Failed  = 0

foreach ($Repo in $Repos) {
    $RepoPath = Join-Path $ProjectRoot $Repo.Name

    if (Test-Path -Path $RepoPath -PathType Container) {
        Write-Skip "$($Repo.Name) already exists - skipping."
        $Skipped++
    }
    else {
        Write-Info "Cloning $($Repo.Name) ..."
        try {
            git clone $Repo.Url $RepoPath
            if ($LASTEXITCODE -eq 0) {
                Write-Ok "$($Repo.Name) cloned successfully."
                $Cloned++
            }
            else {
                throw "git clone exited with code $LASTEXITCODE"
            }
        }
        catch {
            Write-Fail "Failed to clone $($Repo.Name) from $($Repo.Url)"
            $Failed++
        }
    }
}

# ── Summary ──────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Cloned : $Cloned"  -ForegroundColor Green
Write-Host "  Skipped: $Skipped" -ForegroundColor Yellow
Write-Host "  Failed : $Failed"  -ForegroundColor Red
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

if ($Failed -gt 0) {
    Write-Fail "Some repositories failed to clone. Check the URLs and your network."
    exit 1
}

Write-Ok "Installation complete.  Run  .\scripts\start.ps1  to bring everything up."
