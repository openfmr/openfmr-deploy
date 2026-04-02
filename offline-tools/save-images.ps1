<#
.SYNOPSIS
  OpenFMR — save-images.ps1  (Offline Deployment Preparation)

.DESCRIPTION
  Run this script on a machine WITH internet access.

  It pulls every public Docker image used across the OpenFMR stack, then
  exports each one as a .tar file into an offline-images/ directory.

  The resulting .tar files can be copied to a USB drive and loaded on an
  air-gapped clinic machine with:

    Get-ChildItem offline-images\*.tar | ForEach-Object { docker load -i $_.FullName }

.EXAMPLE
  .\offline-tools\save-images.ps1
#>

$ErrorActionPreference = 'Stop'

# ── Resolve the project root (one level up from this script) ─────────────────
$ScriptDir   = $PSScriptRoot
$ProjectRoot = (Resolve-Path "$ScriptDir\..").Path

# ── Output directory for saved images ────────────────────────────────────────
$OutputDir = Join-Path $ProjectRoot "offline-images"
if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

# ── Color helpers ────────────────────────────────────────────────────────────
function Write-Info { param([string]$Msg) Write-Host "[INFO]    $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "[OK]      $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "[WARN]    $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "[FAIL]    $Msg" -ForegroundColor Red }

# ── Images to pull & save ────────────────────────────────────────────────────
$Images = @(
    "postgres:15"
    "hapiproject/hapi:latest"
    "jembi/openhim-core:latest"
    "jembi/openhim-console:latest"
    "mongo:4.4"
    "quay.io/keycloak/keycloak:latest"
    "nginx:alpine"
    "python:3.11-slim"
)

###############################################################################
# Main
###############################################################################
Write-Host ""
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   OpenFMR - Offline Image Exporter" -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""
Write-Info "Output directory: $OutputDir"
Write-Host ""

$Saved  = 0
$Failed = 0

foreach ($Image in $Images) {
    # Derive a safe filename from the image reference
    $SafeName = $Image -replace '[/:]', '_'
    $TarFile  = Join-Path $OutputDir "$SafeName.tar"

    # ── Pull the image ───────────────────────────────────────────────────
    Write-Info "Pulling $Image ..."
    docker pull $Image
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Could not pull $Image - skipping save."
        $Failed++
        continue
    }

    # ── Save (export) the image ──────────────────────────────────────────
    Write-Info "Saving $Image -> $TarFile ..."
    docker save -o $TarFile $Image
    if ($LASTEXITCODE -eq 0) {
        $SizeMB = "{0:N2} MB" -f ((Get-Item $TarFile).Length / 1MB)
        Write-Ok "$Image  ->  $SizeMB saved."
        $Saved++
    }
    else {
        Write-Fail "Failed to save $Image."
        $Failed++
    }

    Write-Host ""
}

###############################################################################
# Summary
###############################################################################
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Saved  : $Saved"  -ForegroundColor Green
Write-Host "  Failed : $Failed" -ForegroundColor Red
Write-Host "  Output : $OutputDir" -ForegroundColor White
Write-Host "-------------------------------------------------------" -ForegroundColor Cyan
Write-Host ""

if ($Failed -gt 0) {
    Write-Warn "Some images could not be exported. Check your internet connection."
}

Write-Ok "Done.  Copy the offline-images\ folder to a USB drive."
Write-Host ""
Write-Host "  On the target machine, load each image with:" -ForegroundColor White
Write-Host "    Get-ChildItem offline-images\*.tar | ForEach-Object { docker load -i `$_.FullName }" -ForegroundColor Cyan
Write-Host ""
