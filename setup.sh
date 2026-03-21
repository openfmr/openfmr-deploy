#!/usr/bin/env bash
###############################################################################
# OpenFMR — setup.sh
# ─────────────────────────────────────────────────────────────────────────────
# Root orchestrator for the OpenFMR Health Information Exchange.
#
# Logic:
#   - If .env.global EXISTS: Assumes the system is configured and simply
#     executes scripts/start.sh to boot the hospital system.
#   - If .env.global DOES NOT EXIST: Assumes a first-time boot. Spins up
#     the Setup Wizard via Docker Compose to collect facility information
#     and auto-generate secure passwords/secrets.
#
# Usage:
#   bash setup.sh
###############################################################################

set -euo pipefail

# ── Resolve the project root ──────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.global"
SETUP_DIR="${SCRIPT_DIR}/setup-wizard"

# ── Color helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}    $*"; }
success() { echo -e "${GREEN}[OK]      $*${NC}"; }
header()  { echo -e "\n${BOLD}${CYAN}── $* ──${NC}\n"; }

###############################################################################
# Check if system is configured
###############################################################################
if [[ -f "${ENV_FILE}" ]]; then
  header "Booting OpenFMR"
  success "System already configured (.env.global found)."
  info "Starting OpenFMR microservices..."
  
  # Execute the main start script
  bash "${SCRIPT_DIR}/scripts/start.sh"
  
else
  header "OpenFMR First-Time Setup"
  info ".env.global not found. Starting Setup Wizard..."
  
  if [[ ! -d "${SETUP_DIR}" ]]; then
    echo -e "\033[0;31m[FATAL]\033[0m Setup Wizard directory (${SETUP_DIR}) not found."
    exit 1
  fi
  
  cd "${SETUP_DIR}"
  
  info "Building and starting Setup Wizard containers..."
  docker-compose -f docker-compose.setup.yml up -d --build
  
  echo ""
  echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo -e "${GREEN}   Setup Wizard is running!${NC}"
  echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
  echo ""
  echo -e "Please open your browser to: ${CYAN}${BOLD}http://localhost:8888${NC}"
  echo "Complete the setup form to generate your hospital's secure configuration."
  echo ""
  echo -e "${YELLOW}Note:${NC} Once setup is complete, you must return here and re-run:"
  echo -e "      ${BOLD}bash setup.sh${NC}"
  echo ""
fi
