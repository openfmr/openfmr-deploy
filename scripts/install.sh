#!/usr/bin/env bash
###############################################################################
# OpenFMR — install.sh
# ─────────────────────────────────────────────────────────────────────────────
# Clones every OpenFMR repository into the root of openfmr-deploy/.
#
# Usage:
#   bash scripts/install.sh          (from the openfmr-deploy directory)
#   bash /absolute/path/install.sh   (from anywhere — script resolves paths)
#
# The script is idempotent: if a repository directory already exists it is
# skipped with a notice rather than re-cloned.
###############################################################################

set -euo pipefail

# ── Resolve the project root (one level up from this script) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Color helpers ────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[SKIP]${NC}  $*"; }
fail()    { echo -e "${RED}[FAIL]${NC}  $*"; }

# ── Repository list ─────────────────────────────────────────────────────────
# Replace "YourOrg" with your actual GitHub organization or user.
REPOS=(
  "openfmr-core:https://github.com/openfmr/openfmr-core.git"
  "openfmr-module-cr:https://github.com/openfmr/openfmr-module-cr.git"
  "openfmr-module-hfr:https://github.com/openfmr/openfmr-module-hfr.git"
  "openfmr-module-ts:https://github.com/openfmr/openfmr-module-ts.git"
  "openfmr-module-shr:https://github.com/openfmr/openfmr-module-shr.git"
  "openfmr-module-lmis:https://github.com/openfmr/openfmr-module-lmis.git"
  "openfmr-admin-ui:https://github.com/openfmr/openfmr-admin-ui.git"
  "openfmr-clinical-ui:https://github.com/openfmr/openfmr-clinical-ui.git"
  "openfmr-operations-ui:https://github.com/openfmr/openfmr-operations-ui.git"
)

# ── Main ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   OpenFMR — Repository Installer${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""

cd "${PROJECT_ROOT}"
info "Project root: ${PROJECT_ROOT}"
echo ""

CLONED=0
SKIPPED=0
FAILED=0

for ENTRY in "${REPOS[@]}"; do
  REPO_NAME="${ENTRY%%:*}"
  REPO_URL="${ENTRY#*:}"

  if [[ -d "${PROJECT_ROOT}/${REPO_NAME}" ]]; then
    warn "${REPO_NAME} already exists — skipping."
    ((SKIPPED++))
  else
    info "Cloning ${REPO_NAME} ..."
    if git clone "${REPO_URL}" "${PROJECT_ROOT}/${REPO_NAME}"; then
      success "${REPO_NAME} cloned successfully."
      ((CLONED++))
    else
      fail "Failed to clone ${REPO_NAME} from ${REPO_URL}"
      ((FAILED++))
    fi
  fi
done

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo -e "  Cloned : ${GREEN}${CLONED}${NC}"
echo -e "  Skipped: ${YELLOW}${SKIPPED}${NC}"
echo -e "  Failed : ${RED}${FAILED}${NC}"
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo ""

if [[ ${FAILED} -gt 0 ]]; then
  fail "Some repositories failed to clone. Check the URLs and your network."
  exit 1
fi

success "Installation complete.  Run  scripts/start.sh  to bring everything up."
