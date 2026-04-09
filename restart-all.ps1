<#
.SYNOPSIS
  OpenFMR — restart-all.ps1
  Stops all OpenFMR modules and restarts them in dependency order.

.EXAMPLE
  .\restart-all.ps1
#>

$ErrorActionPreference = 'Stop'

$ScriptDir   = $PSScriptRoot
$ProjectRoot = $ScriptDir
$EnvFile     = Join-Path $ProjectRoot ".env.global"

$ModuleDirs = @(
    "openfmr-portal-ui"
    "openfmr-operations-ui"
    "openfmr-clinical-ui"
    "openfmr-admin-ui"
    "openfmr-core"
    "openfmr-module-cr"
    "openfmr-module-hfr"
    "openfmr-module-lmis"
    "openfmr-module-hwr"
    "openfmr-module-ts"
    "openfmr-module-shr"
)

# ── Stop all ─────────────────────────────────────────────────────────────────
Write-Host "Stopping all OpenFMR modules..." -ForegroundColor Yellow

foreach ($Dir in $ModuleDirs) {
    $DirPath = Join-Path $ProjectRoot $Dir
    if (Test-Path $DirPath -PathType Container) {
        Write-Host "Stopping $Dir..." -ForegroundColor Cyan
        docker compose -f "$DirPath\docker-compose.yml" down 2>$null
    }
}

# ── Start Core ───────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "Step 1: Starting OpenFMR Core..." -ForegroundColor Green

$CorePath = Join-Path $ProjectRoot "openfmr-core"
docker compose -f "$CorePath\docker-compose.yml" --env-file "$CorePath\.env.example" up -d
Write-Host "Waiting 45s for core to stabilize..." -ForegroundColor Yellow
Start-Sleep -Seconds 45

# ── Start Modules ────────────────────────────────────────────────────────────
$RestModules = @(
    "openfmr-module-cr"
    "openfmr-module-hfr"
    "openfmr-module-lmis"
    "openfmr-module-hwr"
    "openfmr-module-ts"
    "openfmr-module-shr"
    "openfmr-admin-ui"
    "openfmr-clinical-ui"
    "openfmr-operations-ui"
    "openfmr-portal-ui"
)

foreach ($Dir in $RestModules) {
    $DirPath = Join-Path $ProjectRoot $Dir
    if (Test-Path $DirPath -PathType Container) {
        Write-Host "Step: Starting $Dir..." -ForegroundColor Green
        docker compose -f "$DirPath\docker-compose.yml" --env-file $EnvFile up -d
        Write-Host "Waiting 60s for $Dir to stabilize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 60
    }
}

# ── Status ───────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "All modules started. Checking status..." -ForegroundColor Green
docker ps --format "{{.Names}}: {{.Status}}"
