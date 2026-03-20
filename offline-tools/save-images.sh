#!/usr/bin/env bash
###############################################################################
# OpenFMR — save-images.sh  (Offline Deployment Preparation)
# ─────────────────────────────────────────────────────────────────────────────
# Run this script on a machine WITH internet access.
#
# It pulls every public Docker image used across the OpenFMR stack, then
# exports each one as a .tar file into an  offline-images/  directory.
#
# The resulting .tar files can be copied to a USB drive and loaded on an
# air-gapped clinic machine with:
#
#   docker load -i offline-images/<image>.tar
#
# Usage:
#   bash offline-tools/save-images.sh
###############################################################################

set -euo pipefail

# ── Resolve the project root (one level up from this script) ────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# ── Output directory for saved images ────────────────────────────────────────
OUTPUT_DIR="${PROJECT_ROOT}/offline-images"
mkdir -p "${OUTPUT_DIR}"

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

# ── Images to pull & save ────────────────────────────────────────────────────
# Add or remove entries as the stack evolves.  The format is the full
# image reference that you would pass to  docker pull.
IMAGES=(
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
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}   OpenFMR — Offline Image Exporter${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════${NC}"
echo ""
info "Output directory: ${OUTPUT_DIR}"
echo ""

SAVED=0
FAILED=0

for IMAGE in "${IMAGES[@]}"; do
  # Derive a safe filename from the image reference:
  #   "postgres:15"                      → postgres_15.tar
  #   "jembi/openhim-core:latest"        → jembi_openhim-core_latest.tar
  #   "quay.io/keycloak/keycloak:latest" → quay.io_keycloak_keycloak_latest.tar
  SAFE_NAME="${IMAGE//\//_}"    # replace / with _
  SAFE_NAME="${SAFE_NAME//:/_}" # replace : with _
  TAR_FILE="${OUTPUT_DIR}/${SAFE_NAME}.tar"

  # ── Pull the image ─────────────────────────────────────────────────────
  info "Pulling ${IMAGE} …"
  if ! docker pull "${IMAGE}"; then
    fail "Could not pull ${IMAGE} — skipping save."
    ((FAILED++))
    continue
  fi

  # ── Save (export) the image ────────────────────────────────────────────
  info "Saving ${IMAGE} → ${TAR_FILE} …"
  if docker save -o "${TAR_FILE}" "${IMAGE}"; then
    success "${IMAGE}  →  $(du -h "${TAR_FILE}" | cut -f1) saved."
    ((SAVED++))
  else
    fail "Failed to save ${IMAGE}."
    ((FAILED++))
  fi

  echo ""
done

###############################################################################
# Summary
###############################################################################
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo -e "  Saved  : ${GREEN}${SAVED}${NC}"
echo -e "  Failed : ${RED}${FAILED}${NC}"
echo -e "  Output : ${OUTPUT_DIR}"
echo -e "${CYAN}───────────────────────────────────────────────────────${NC}"
echo ""

if [[ ${FAILED} -gt 0 ]]; then
  warn "Some images could not be exported. Check your internet connection."
fi

success "Done.  Copy the ${BOLD}offline-images/${NC} folder to a USB drive."
echo ""
echo -e "  On the target machine, load each image with:"
echo -e "    ${CYAN}for f in offline-images/*.tar; do docker load -i \"\$f\"; done${NC}"
echo ""
