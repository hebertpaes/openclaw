#!/usr/bin/env bash
# Uninstall the OpenClaw gateway from the Mac: stop the gateway, remove the
# global npm package (and its plugins), and optionally purge the config.
#
# Usage:
#   ./mac/uninstall.sh           # stop + remove the openclaw package
#   ./mac/uninstall.sh --purge   # ...and delete ~/.openclaw (config + state)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos

PURGE=0
for arg in "$@"; do
  case "${arg}" in
    --purge) PURGE=1 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option: ${arg} (try --help)" ;;
  esac
done

# --- Stop the gateway + daemon ---------------------------------------------
if command -v openclaw >/dev/null 2>&1; then
  log_info "Stopping the gateway ..."
  openclaw gateway stop 2>/dev/null || true
fi
# Best-effort removal of the launchd service created by onboard --install-daemon.
if command -v launchctl >/dev/null 2>&1; then
  launchctl remove openclaw 2>/dev/null || true
fi

# --- Remove the npm package (this also removes its bundled plugins) ---------
if command -v npm >/dev/null 2>&1; then
  log_info "Removing the global openclaw package ..."
  npm uninstall -g openclaw 2>/dev/null || log_warn "npm uninstall -g openclaw failed (already gone?)."
else
  log_warn "npm not found — skipping package removal."
fi

# --- Purge config (optional) -----------------------------------------------
if [ "${PURGE}" -eq 1 ]; then
  if [ -d "${OPENCLAW_DIR}" ]; then
    log_info "Purging ${OPENCLAW_DIR} ..."
    rm -rf "${OPENCLAW_DIR}"
    log_ok "Removed ${OPENCLAW_DIR}."
  fi
else
  log_info "Kept config at ${OPENCLAW_DIR} (use --purge to delete it)."
fi

log_ok "OpenClaw uninstalled. Reinstall fresh with:  ./mac/setup.sh"
