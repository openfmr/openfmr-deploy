<#
.SYNOPSIS
  OpenFMR — stop.ps1
  Gracefully tears down every OpenFMR Docker Compose stack in reverse
  dependency order (UIs -> modules -> core).

.DESCRIPTION
  Stops all services. Optionally removes the shared Docker network.

.PARAMETER RemoveNetwork
  If specified, removes the openfmr_global_net Docker network after stopping
  all services.

.EXAMPLE
  .\scripts\stop.ps1
  .\scripts\stop.ps1 -RemoveNetwork
#>

param(
    [switch]$RemoveNetwork
)

$ErrorActionPreference = 'Stop'

# ── Resolve the project root (one level up from this script) ─────────────────
$ScriptDir   = $PSScriptRoot
$ProjectRoot = (Resolve-Path "$ScriptDir\..").Path

# ── Color helpers ────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg) Write-Host "[FAIL]    $Msg" -ForegroundColor Red }
function Write-Header  { param([string]$Msg) Write-Host "`n-- $Msg --`n" -ForegroundColor Cyan }

# ── Directories to stop (reverse startup order) ─────────────────────────────
$Stacks = @(
    @{ Dir = "openfmr-portal-ui";     Label = "Portal Dashboard" }
    @{ Dir = "openfmr-operations-ui"; Label = "Operations UI" }
    @{ Dir = "openfmr-clinical-ui";   Label = "Clinical UI" }
    @{ Dir = "openfmr-admin-ui";      Label = "Admin UI" }
    @{ Dir = "openfmr-module-lmis";   Label = "Logistics Management" }
    @{ Dir = "openfmr-module-shr";    Label = "Shared Health Record" }
    @{ Dir = "openfmr-module-hwr";    Label = "Health Worker Registry" }
    @{ Dir = "openfmr-module-ts";     Label = "Terminology Service" }
    @{ Dir = "openfmr-module-hfr";    Label = "Health Facility Registry" }
    @{ Dir = "openfmr-module-cr";     Label = "Client Registry" }
    @{ Dir = "openfmr-core";          Label = "Core Infrastructure" }
)

$NetworkName = "openfmr_global_net"

###############################################################################
# Tear down each stack
###############################################################################
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Red
Write-Host "   OpenFMR - Stopping All Services" -ForegroundColor Red
Write-Host "=======================================================" -ForegroundColor Red
Write-Host ""

foreach ($Stack in $Stacks) {
    $StackPath = Join-Path $ProjectRoot $Stack.Dir

    if (-not (Test-Path $StackPath -PathType Container)) {
        Write-Warn "$($Stack.Label) ($($Stack.Dir)) - not found, skipping."
        continue
    }

    $ComposeFile = Join-Path $StackPath "docker-compose.yml"
    if (-not (Test-Path $ComposeFile)) {
        Write-Warn "$($Stack.Label) - no docker-compose.yml found, skipping."
        continue
    }

    Write-Info "Stopping $($Stack.Label) ..."
    docker compose -f $ComposeFile down --remove-orphans 2>$null

    if ($LASTEXITCODE -eq 0) {
        Write-Ok "$($Stack.Label) stopped."
    }
    else {
        Write-Fail "$($Stack.Label) - docker compose down returned an error."
    }
}

###############################################################################
# Optionally remove the shared network
###############################################################################
if ($RemoveNetwork) {
    Write-Header "Removing Docker Network"

    $NetworkExists = docker network ls -q -f name="^${NetworkName}$"
    if ($NetworkExists) {
        docker network rm $NetworkName | Out-Null
        Write-Ok "Removed network '$NetworkName'."
    }
    else {
        Write-Warn "Network '$NetworkName' does not exist - nothing to remove."
    }
}
else {
    Write-Info "Network '$NetworkName' was kept. Pass -RemoveNetwork to delete it."
}

###############################################################################
# Done
###############################################################################
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "   OpenFMR - All services stopped." -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
