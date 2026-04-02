<#
.SYNOPSIS
  OpenFMR — setup.ps1
  Root orchestrator for the OpenFMR Health Information Exchange.

.DESCRIPTION
  - If .env.global EXISTS: Assumes the system is configured and simply
    executes scripts\start.ps1 to boot the hospital system.
  - If .env.global DOES NOT EXIST: Assumes a first-time boot. Spins up
    the Setup Wizard via Docker Compose to collect facility information
    and auto-generate secure passwords/secrets.

.EXAMPLE
  .\setup.ps1
#>

$ErrorActionPreference = 'Stop'

# ── Resolve the project root ─────────────────────────────────────────────────
$ScriptDir = $PSScriptRoot
$EnvFile   = Join-Path $ScriptDir ".env.global"
$SetupDir  = Join-Path $ScriptDir "setup-wizard"

# ── Color helpers ────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Header  { param([string]$Msg) Write-Host "`n-- $Msg --`n" -ForegroundColor Cyan }

###############################################################################
# Check if system is configured
###############################################################################
if (Test-Path $EnvFile) {
    Write-Header "Booting OpenFMR"
    Write-Ok "System already configured (.env.global found)."
    Write-Info "Starting OpenFMR microservices..."

    # Execute the main start script
    & "$ScriptDir\scripts\start.ps1"
}
else {
    Write-Header "OpenFMR First-Time Setup"
    Write-Info ".env.global not found. Starting Setup Wizard..."

    if (-not (Test-Path $SetupDir -PathType Container)) {
        Write-Host "[FATAL] Setup Wizard directory ($SetupDir) not found." -ForegroundColor Red
        exit 1
    }

    Write-Info "Building and starting Setup Wizard containers..."
    docker compose -f "$SetupDir\docker-compose.setup.yml" up -d --build

    Write-Host ""
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host "   Setup Wizard is running!" -ForegroundColor Green
    Write-Host "=======================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Please open your browser to: " -NoNewline
    Write-Host "http://localhost:8888" -ForegroundColor Cyan
    Write-Host "Complete the setup form to generate your hospital's secure configuration."
    Write-Host ""
    Write-Host "Note: " -ForegroundColor Yellow -NoNewline
    Write-Host "Once setup is complete, you must return here and re-run:"
    Write-Host "      .\setup.ps1" -ForegroundColor White
    Write-Host ""
}
