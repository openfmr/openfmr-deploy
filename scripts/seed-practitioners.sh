#!/bin/bash
# =============================================================================
# OpenFMR — Practitioner Seeding Script
# =============================================================================
# This script POSTs Practitioner resources to the central HAPI FHIR server.
# These resources correspond to the users defined in Keycloak and are
# required for the UI to display correct names (via the fhirUser claim).
# =============================================================================

FHIR_URL="http://localhost:8091/fhir"

echo "[INFO] Seeding Practitioners to $FHIR_URL ..."

# 1. Dr. Ankit Sharma
cat <<EOF | curl -X PUT -H "Content-Type: application/fhir+json" -d @- "$FHIR_URL/Practitioner/dr-sharma"
{
  "resourceType": "Practitioner",
  "id": "dr-sharma",
  "identifier": [{ "system": "http://openfmr.org/practitioner-id", "value": "ANKIT123" }],
  "name": [{ "use": "official", "family": "Sharma", "given": ["Ankit"] }]
}
EOF

# 2. Nurse Sita Acharya
cat <<EOF | curl -X PUT -H "Content-Type: application/fhir+json" -d @- "$FHIR_URL/Practitioner/nurse-acharya"
{
  "resourceType": "Practitioner",
  "id": "nurse-acharya",
  "identifier": [{ "system": "http://openfmr.org/practitioner-id", "value": "SITA456" }],
  "name": [{ "use": "official", "family": "Acharya", "given": ["Sita"] }]
}
EOF

# 3. Admin User
cat <<EOF | curl -X PUT -H "Content-Type: application/fhir+json" -d @- "$FHIR_URL/Practitioner/admin-user"
{
  "resourceType": "Practitioner",
  "id": "admin-user",
  "identifier": [{ "system": "http://openfmr.org/practitioner-id", "value": "ADMIN789" }],
  "name": [{ "use": "official", "family": "User", "given": ["Admin"] }]
}
EOF

echo -e "\n[OK] Seeding complete!"
