#!/usr/bin/env bash
###############################################################################
# OpenFMR — stop.sh
# ─────────────────────────────────────────────────────────────────────────────
# Gracefully tears down every OpenFMR Docker Compose stack in reverse
# dependency order (UIs → modules → core) and optionally removes the
# shared Docker network.
#
# Usage:
#   bash scripts/stop.sh              # stop all, keep network
#   bash scripts/stop.sh --remove-net # stop all AND remove the network
###############################################################################

set -euo pipefail

# ── Resolve the project root (one level up from this script) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Flags ────────────────────────────────────────────────────────────────────
REMOVE_NETWORK=false
for arg in "$@"; do
  case "${arg}" in
    --remove-net|--remove-network) REMOVE_NETWORK=true ;;
    *) echo "Unknown flag: ${arg}"; exit 1 ;;
  esac
done

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
fail()    { echo -e "${RED}[FAIL]${NC}    $*"; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}\n"; }

# ── Directories to stop (reverse startup order) ─────────────────────────────
STACKS=(
  "openfmr-operations-ui:Operations UI"
  "openfmr-clinical-ui:Clinical UI"
  "openfmr-admin-ui:Admin UI"
  "openfmr-module-lmis:Logistics Management"
  "openfmr-module-shr:Shared Health Record"
  "openfmr-module-hwr:Health Worker Registry"
  "openfmr-module-ts:Terminology Service"
  "openfmr-module-hfr:Health Facility Registry"
  "openfmr-module-cr:Client Registry"
  "openfmr-core:Core Infrastructure"
)

NETWORK_NAME="openfmr_global_net"

###############################################################################
# Tear down each stack
###############################################################################
echo ""
echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
echo -e "${RED}   OpenFMR — Stopping All Services${NC}"
echo -e "${RED}═══════════════════════════════════════════════════════${NC}"
echo ""

for ENTRY in "${STACKS[@]}"; do
  STACK_DIR="${ENTRY%%:*}"
  STACK_LABEL="${ENTRY##*:}"
  STACK_PATH="${PROJECT_ROOT}/${STACK_DIR}"

  if [[ ! -d "${STACK_PATH}" ]]; then
    warn "${STACK_LABEL} (${STACK_DIR}) — not found, skipping."
    continue
  fi

  # Check if a docker-compose.yml exists in the directory
  if [[ ! -f "${STACK_PATH}/docker-compose.yml" ]]; then
    warn "${STACK_LABEL} — no docker-compose.yml found, skipping."
    continue
  fi

  info "Stopping ${STACK_LABEL} …"
  if docker-compose -f "${STACK_PATH}/docker-compose.yml" down --remove-orphans 2>/dev/null; then
    success "${STACK_LABEL} stopped."
  else
    fail "${STACK_LABEL} — docker-compose down returned an error."
  fi
done

###############################################################################
# Optionally remove the shared network
###############################################################################
if [[ "${REMOVE_NETWORK}" == true ]]; then
  header "Removing Docker Network"
  if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
    docker network rm "${NETWORK_NAME}"
    success "Removed network '${NETWORK_NAME}'."
  else
    warn "Network '${NETWORK_NAME}' does not exist — nothing to remove."
  fi
else
  info "Network '${NETWORK_NAME}' was kept. Pass --remove-net to delete it."
fi

###############################################################################
# Done
###############################################################################
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}   OpenFMR — All services stopped.${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
echo ""
