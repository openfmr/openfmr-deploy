<#
.SYNOPSIS
  OpenFMR — start.ps1
  Brings up every OpenFMR component in the correct dependency order.

.DESCRIPTION
  1. Creates the shared external Docker network (openfmr_global_net).
  2. Starts openfmr-core (OpenHIM, databases, Keycloak, HAPI FHIR).
  3. Waits for core services to become healthy.
  4. Starts each registry module (CR -> HFR -> TS -> SHR -> LMIS).
  5. Starts the three UI front-ends (Admin, Clinical, Operations).

.EXAMPLE
  .\scripts\start.ps1
#>

$ErrorActionPreference = 'Stop'

# ── Resolve the project root (one level up from this script) ─────────────────
$ScriptDir   = $PSScriptRoot
$ProjectRoot = (Resolve-Path "$ScriptDir\..").Path

# ── Load global environment variables ────────────────────────────────────────
$EnvFile = Join-Path $ProjectRoot ".env.global"
if (-not (Test-Path $EnvFile)) {
    Write-Host "[FATAL]  .env.global not found at $EnvFile" -ForegroundColor Red
    exit 1
}

# ── Color helpers ────────────────────────────────────────────────────────────
function Write-Info    { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok      { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn    { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Fail    { param([string]$Msg) Write-Host "[FAIL]    $Msg" -ForegroundColor Red; exit 1 }
function Write-Header  { param([string]$Msg) Write-Host "`n-- $Msg --`n" -ForegroundColor Cyan }

# ── Configurable wait time (seconds) for core services to stabilise ──────────
$CoreWaitSeconds = if ($env:CORE_WAIT_SECONDS) { [int]$env:CORE_WAIT_SECONDS } else { 30 }

# ── Docker network name (must match .env.global -> OPENFMR_NETWORK) ──────────
$NetworkName = "openfmr_global_net"

###############################################################################
# STEP 1 — Create the shared external Docker network
###############################################################################
Write-Header "Step 1/4 - External Docker Network"

$NetworkExists = docker network inspect $NetworkName 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Warn "Network '$NetworkName' already exists - reusing."
}
else {
    docker network create $NetworkName
    Write-Ok "Created Docker network '$NetworkName'."
}

###############################################################################
# STEP 2 — Start openfmr-core (databases, OpenHIM, Keycloak, HAPI FHIR)
###############################################################################
Write-Header "Step 2/4 - Core Infrastructure (openfmr-core)"

$CoreDir = Join-Path $ProjectRoot "openfmr-core"
if (-not (Test-Path $CoreDir -PathType Container)) {
    Write-Fail "Directory $CoreDir not found. Run .\scripts\install.ps1 first."
}

Write-Info "Starting openfmr-core services ..."
docker compose -f "$CoreDir\docker-compose.yml" --env-file $EnvFile up -d

Write-Info "Waiting ${CoreWaitSeconds}s for core services to become healthy ..."
Start-Sleep -Seconds $CoreWaitSeconds

Write-Ok "openfmr-core is up."

###############################################################################
# STEP 3 — Start registry modules (CR, HFR, TS, SHR, LMIS)
###############################################################################
Write-Header "Step 3/4 - Registry Modules"

$Modules = @(
    @{ Dir = "openfmr-module-cr";   Label = "Client Registry" }
    @{ Dir = "openfmr-module-hfr";  Label = "Health Facility Registry" }
    @{ Dir = "openfmr-module-ts";   Label = "Terminology Service" }
    @{ Dir = "openfmr-module-hwr";  Label = "Health Worker Registry" }
    @{ Dir = "openfmr-module-shr";  Label = "Shared Health Record" }
    @{ Dir = "openfmr-module-lmis"; Label = "Logistics Management" }
)

foreach ($Module in $Modules) {
    $ModulePath = Join-Path $ProjectRoot $Module.Dir

    if (-not (Test-Path $ModulePath -PathType Container)) {
        Write-Warn "$($Module.Label) ($($Module.Dir)) - directory not found, skipping."
        continue
    }

    Write-Info "Starting $($Module.Label) ..."
    docker compose -f "$ModulePath\docker-compose.yml" --env-file $EnvFile up -d --build

    Write-Ok "$($Module.Label) ... [OK]"
}

###############################################################################
# STEP 4 — Start UI front-ends
###############################################################################
Write-Header "Step 4/4 - User Interfaces"

$UIs = @(
    @{ Dir = "openfmr-admin-ui";      Label = "Admin UI" }
    @{ Dir = "openfmr-clinical-ui";   Label = "Clinical UI" }
    @{ Dir = "openfmr-operations-ui"; Label = "Operations UI" }
)

foreach ($UI in $UIs) {
    $UIPath = Join-Path $ProjectRoot $UI.Dir

    if (-not (Test-Path $UIPath -PathType Container)) {
        Write-Warn "$($UI.Label) ($($UI.Dir)) - directory not found, skipping."
        continue
    }

    Write-Info "Starting $($UI.Label) ..."
    docker compose -f "$UIPath\docker-compose.yml" --env-file $EnvFile up -d --build

    Write-Ok "$($UI.Label) ... [OK]"
}

###############################################################################
# Done!
###############################################################################
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Green
Write-Host "   OpenFMR - All services are up!" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  OpenHIM Console  ->  " -NoNewline; Write-Host "http://localhost:9000" -ForegroundColor Cyan
Write-Host "  OpenHIM API      ->  " -NoNewline; Write-Host "https://localhost:8085" -ForegroundColor Cyan
Write-Host "  Keycloak         ->  " -NoNewline; Write-Host "https://localhost:8443" -ForegroundColor Cyan
Write-Host "  HAPI FHIR        ->  " -NoNewline; Write-Host "http://localhost:8080" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Run " -NoNewline; Write-Host ".\scripts\stop.ps1" -ForegroundColor White; Write-Host " to tear everything down."
Write-Host ""
