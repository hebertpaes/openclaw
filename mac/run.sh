#!/usr/bin/env bash
# Launch OpenClaw on the Mac. macOS has a native display, so the game just runs
# in its own window — no virtual display needed.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos

[ -x "${OPENCLAW_BIN}" ] \
  || die "OpenClaw binary not found at '${OPENCLAW_BIN}'. Run ./mac/build.sh first."
[ -f "${RELEASE_DIR}/CLAW.REZ" ] \
  || die "CLAW.REZ missing from ${RELEASE_DIR}. Run ./mac/organize-assets.sh first."

log_info "Launching OpenClaw from ${RELEASE_DIR} ..."
cd "${RELEASE_DIR}"
exec "${OPENCLAW_BIN}"
