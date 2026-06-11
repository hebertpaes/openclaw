#!/usr/bin/env bash
# Locate the original game's CLAW.REZ in the downloads folder, place it next to
# the binary, and build ASSETS.ZIP. OpenClaw will not start without CLAW.REZ
# (the copyrighted archive from the retail Captain Claw game) in Build_Release.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
require_cmd zip

[ -d "${RELEASE_DIR}" ] \
  || die "Release dir '${RELEASE_DIR}' not found. Build the engine first: ./mac/build.sh"

# --- 1. Find CLAW.REZ ------------------------------------------------------
log_info "Searching for CLAW.REZ ..."
rez=""
if [ -f "${RELEASE_DIR}/CLAW.REZ" ]; then
  rez="${RELEASE_DIR}/CLAW.REZ"
  log_info "CLAW.REZ already present in ${RELEASE_DIR}."
elif [ -d "${DOWNLOADS_DIR}" ]; then
  rez="$(find "${DOWNLOADS_DIR}" -type f -iname 'CLAW.REZ' 2>/dev/null | head -n1 || true)"
  [ -z "${rez}" ] && rez="$(find "${DOWNLOADS_DIR}" -type f -iname '*.rez' 2>/dev/null | head -n1 || true)"
fi

if [ -z "${rez}" ]; then
  log_error "Could not find CLAW.REZ."
  log_error "Place the original game's CLAW.REZ into: ${DOWNLOADS_DIR}"
  log_error "(then re-run this script). It is required and not redistributable."
  exit 1
fi

# --- 2. Place it next to the binary ----------------------------------------
if [ "${rez}" != "${RELEASE_DIR}/CLAW.REZ" ]; then
  log_info "Found: ${rez}"
  log_info "Copying to ${RELEASE_DIR}/CLAW.REZ ..."
  cp -f "${rez}" "${RELEASE_DIR}/CLAW.REZ"
fi
log_ok "CLAW.REZ in place ($(du -h "${RELEASE_DIR}/CLAW.REZ" | cut -f1 | tr -d ' '))."

# --- 3. Build ASSETS.ZIP from the engine's ASSETS folder -------------------
if [ -d "${RELEASE_DIR}/ASSETS" ]; then
  log_info "Packaging ASSETS.ZIP from ${RELEASE_DIR}/ASSETS ..."
  ( cd "${RELEASE_DIR}/ASSETS" && zip -r -q -X "../ASSETS.ZIP" . )
  log_ok "ASSETS.ZIP created ($(du -h "${RELEASE_DIR}/ASSETS.ZIP" | cut -f1 | tr -d ' '))."
else
  log_warn "No ASSETS directory at ${RELEASE_DIR}/ASSETS — skipping ASSETS.ZIP."
fi

log_ok "Assets ready."
