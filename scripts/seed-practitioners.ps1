<#
.SYNOPSIS
  OpenFMR — seed-practitioners.ps1
  Seeds Practitioner resources into the central HAPI FHIR server.

.DESCRIPTION
  POSTs Practitioner resources that correspond to the users defined in
  Keycloak. These are required for the UI to display correct names
  (via the fhirUser claim).

.EXAMPLE
  .\scripts\seed-practitioners.ps1
#>

$ErrorActionPreference = 'Stop'

$FhirUrl = "http://localhost:8091/fhir"

Write-Host "[INFO] Seeding Practitioners to $FhirUrl ..." -ForegroundColor Cyan

$ContentType = "application/fhir+json"

# ── 1. Dr. Ankit Sharma ──────────────────────────────────────────────────────
$DrSharma = @{
    resourceType = "Practitioner"
    id           = "dr-sharma"
    identifier   = @(
        @{ system = "http://openfmr.org/practitioner-id"; value = "ANKIT123" }
    )
    name         = @(
        @{ use = "official"; family = "Sharma"; given = @("Ankit") }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$FhirUrl/Practitioner/dr-sharma" `
        -Method Put -ContentType $ContentType -Body $DrSharma
    Write-Host "[OK]   Dr. Ankit Sharma seeded." -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Dr. Ankit Sharma: $_" -ForegroundColor Red
}

# ── 2. Nurse Sita Acharya ────────────────────────────────────────────────────
$NurseAcharya = @{
    resourceType = "Practitioner"
    id           = "nurse-acharya"
    identifier   = @(
        @{ system = "http://openfmr.org/practitioner-id"; value = "SITA456" }
    )
    name         = @(
        @{ use = "official"; family = "Acharya"; given = @("Sita") }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$FhirUrl/Practitioner/nurse-acharya" `
        -Method Put -ContentType $ContentType -Body $NurseAcharya
    Write-Host "[OK]   Nurse Sita Acharya seeded." -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Nurse Sita Acharya: $_" -ForegroundColor Red
}

# ── 3. Admin User ────────────────────────────────────────────────────────────
$AdminUser = @{
    resourceType = "Practitioner"
    id           = "admin-user"
    identifier   = @(
        @{ system = "http://openfmr.org/practitioner-id"; value = "ADMIN789" }
    )
    name         = @(
        @{ use = "official"; family = "User"; given = @("Admin") }
    )
} | ConvertTo-Json -Depth 5

try {
    Invoke-RestMethod -Uri "$FhirUrl/Practitioner/admin-user" `
        -Method Put -ContentType $ContentType -Body $AdminUser
    Write-Host "[OK]   Admin User seeded." -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Admin User: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "[OK] Seeding complete!" -ForegroundColor Green
