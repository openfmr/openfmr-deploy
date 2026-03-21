#!/usr/bin/env bash
###############################################################################
# OpenFMR — start.sh
# ─────────────────────────────────────────────────────────────────────────────
# Brings up every OpenFMR component in the correct dependency order:
#
#   1. Creates the shared external Docker network (openfmr_global_net).
#   2. Starts openfmr-core (OpenHIM, databases, Keycloak, HAPI FHIR).
#   3. Waits for core services to become healthy.
#   4. Starts each registry module (CR → HFR → TS → SHR → LMIS).
#   5. Starts the three UI front-ends (Admin, Clinical, Operations).
#
# Usage:
#   bash scripts/start.sh          (from the openfmr-deploy directory)
#   bash /absolute/path/start.sh   (from anywhere — script resolves paths)
###############################################################################

set -euo pipefail

# ── Resolve the project root (one level up from this script) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Load global environment variables ────────────────────────────────────────
ENV_FILE="${PROJECT_ROOT}/.env.global"
if [[ ! -f "${ENV_FILE}" ]]; then
  echo -e "\033[0;31m[FATAL]\033[0m  .env.global not found at ${ENV_FILE}"
  exit 1
fi

# ── Color helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]${NC}      $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}    $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; exit 1; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}\n"; }

# ── Configurable wait time (seconds) for core services to stabilise ──────────
CORE_WAIT_SECONDS="${CORE_WAIT_SECONDS:-30}"

# ── Docker network name (must match .env.global → OPENFMR_NETWORK) ──────────
NETWORK_NAME="openfmr_global_net"

###############################################################################
# STEP 1 — Create the shared external Docker network
###############################################################################
header "Step 1/4 · External Docker Network"

if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  warn "Network '${NETWORK_NAME}' already exists — reusing."
else
  docker network create "${NETWORK_NAME}"
  success "Created Docker network '${NETWORK_NAME}'."
fi

###############################################################################
# STEP 2 — Start openfmr-core (databases, OpenHIM, Keycloak, HAPI FHIR)
###############################################################################
header "Step 2/4 · Core Infrastructure (openfmr-core)"

CORE_DIR="${PROJECT_ROOT}/openfmr-core"
if [[ ! -d "${CORE_DIR}" ]]; then
  fail "Directory ${CORE_DIR} not found. Run scripts/install.sh first."
fi

info "Starting openfmr-core services …"
docker-compose -f "${CORE_DIR}/docker-compose.yml" --env-file "${ENV_FILE}" up -d

info "Waiting ${CORE_WAIT_SECONDS}s for core services to become healthy …"
sleep "${CORE_WAIT_SECONDS}"

# ── Optional: poll a health endpoint instead of a fixed sleep ────────────────
# Uncomment the block below if openfmr-core exposes a health-check endpoint.
#
# MAX_RETRIES=20
# RETRY_INTERVAL=5
# for i in $(seq 1 ${MAX_RETRIES}); do
#   if curl -sSf http://localhost:8085/heartbeat >/dev/null 2>&1; then
#     success "OpenHIM API is responding."
#     break
#   fi
#   info "Retry ${i}/${MAX_RETRIES} — waiting for OpenHIM …"
#   sleep ${RETRY_INTERVAL}
# done

success "openfmr-core is up."

###############################################################################
# STEP 3 — Start registry modules (CR, HFR, TS, SHR, LMIS)
###############################################################################
header "Step 3/4 · Registry Modules"

MODULES=(
  "openfmr-module-cr:Client Registry"
  "openfmr-module-hfr:Health Facility Registry"
  "openfmr-module-ts:Terminology Service"
  "openfmr-module-hwr:Health Worker Registry"
  "openfmr-module-shr:Shared Health Record"
  "openfmr-module-lmis:Logistics Management"
)

for ENTRY in "${MODULES[@]}"; do
  MODULE_DIR="${ENTRY%%:*}"          # e.g. openfmr-module-cr
  MODULE_LABEL="${ENTRY##*:}"        # e.g. Client Registry

  MODULE_PATH="${PROJECT_ROOT}/${MODULE_DIR}"

  if [[ ! -d "${MODULE_PATH}" ]]; then
    warn "${MODULE_LABEL} (${MODULE_DIR}) — directory not found, skipping."
    continue
  fi

  info "Starting ${MODULE_LABEL} …"
  docker-compose -f "${MODULE_PATH}/docker-compose.yml" \
    --env-file "${ENV_FILE}" up -d --build

  success "${MODULE_LABEL} … ${GREEN}[OK]${NC}"
done

###############################################################################
# STEP 4 — Start UI front-ends
###############################################################################
header "Step 4/4 · User Interfaces"

UIS=(
  "openfmr-admin-ui:Admin UI"
  "openfmr-clinical-ui:Clinical UI"
  "openfmr-operations-ui:Operations UI"
)

for ENTRY in "${UIS[@]}"; do
  UI_DIR="${ENTRY%%:*}"
  UI_LABEL="${ENTRY##*:}"

  UI_PATH="${PROJECT_ROOT}/${UI_DIR}"

  if [[ ! -d "${UI_PATH}" ]]; then
    warn "${UI_LABEL} (${UI_DIR}) — directory not found, skipping."
    continue
  fi

  info "Starting ${UI_LABEL} …"
  docker-compose -f "${UI_PATH}/docker-compose.yml" \
    --env-file "${ENV_FILE}" up -d --build

  success "${UI_LABEL} … ${GREEN}[OK]${NC}"
done

###############################################################################
# Done!
###############################################################################
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   OpenFMR — All services are up!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
echo -e "  OpenHIM Console  →  ${CYAN}http://localhost:9000${NC}"
echo -e "  OpenHIM API      →  ${CYAN}https://localhost:8085${NC}"
echo -e "  Keycloak         →  ${CYAN}https://localhost:8443${NC}"
echo -e "  HAPI FHIR        →  ${CYAN}http://localhost:8080${NC}"
echo ""
echo -e "  Run ${BOLD}scripts/stop.sh${NC} to tear everything down."
echo ""
