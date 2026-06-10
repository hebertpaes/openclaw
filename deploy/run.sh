#!/usr/bin/env bash
# "Ativa o OpenClaw": launch the game.
#
# On a headless Azure VM there is no monitor, so unless a real $DISPLAY is
# available we spin up a virtual X server (Xvfb) and, optionally, expose it
# over VNC (bound to localhost — reach it through an SSH tunnel) so you can
# actually see and play the game remotely.
#
# Usage:
#   ./deploy/run.sh             # auto: use $DISPLAY if present, else go headless
#   ./deploy/run.sh --headless  # force the virtual display even if $DISPLAY is set
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

FORCE_HEADLESS=0
[[ "${1:-}" == "--headless" ]] && FORCE_HEADLESS=1

[[ -x "${OPENCLAW_BIN}" ]] \
  || die "OpenClaw binary not found at '${OPENCLAW_BIN}'. Run ./deploy/build.sh first."
[[ -f "${RELEASE_DIR}/CLAW.REZ" ]] \
  || die "CLAW.REZ missing from ${RELEASE_DIR}. Run ./deploy/organize-assets.sh first."

# Track helper PIDs so we can clean them up on exit.
XVFB_PID=""
VNC_PID=""
cleanup() {
  if [[ -n "${VNC_PID}"  ]]; then kill "${VNC_PID}"  2>/dev/null || true; fi
  if [[ -n "${XVFB_PID}" ]]; then kill "${XVFB_PID}" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

if [[ -n "${DISPLAY:-}" && "${FORCE_HEADLESS}" -eq 0 ]]; then
  log_info "Using existing display ${DISPLAY}."
else
  require_cmd Xvfb
  log_info "Starting virtual display Xvfb ${DISPLAY_NUM} (${SCREEN_GEOMETRY}) ..."
  Xvfb "${DISPLAY_NUM}" -screen 0 "${SCREEN_GEOMETRY}" -nolisten tcp &
  XVFB_PID=$!
  export DISPLAY="${DISPLAY_NUM}"

  # Wait for the X server to accept connections.
  for _ in $(seq 1 20); do
    if command -v xdpyinfo >/dev/null 2>&1; then
      xdpyinfo -display "${DISPLAY_NUM}" >/dev/null 2>&1 && break
    else
      [[ -S "/tmp/.X11-unix/X${DISPLAY_NUM#:}" ]] && break
    fi
    sleep 0.25
  done

  if [[ "${ENABLE_VNC}" == "1" ]]; then
    if command -v x11vnc >/dev/null 2>&1; then
      log_info "Exposing display over VNC on localhost:${VNC_PORT} (use an SSH tunnel to connect)."
      x11vnc -display "${DISPLAY_NUM}" -localhost -rfbport "${VNC_PORT}" \
             -forever -shared -nopw -quiet -bg >/dev/null 2>&1 || \
        log_warn "x11vnc failed to start; continuing headless."
      VNC_PID="$(pgrep -n x11vnc || true)"
      log_info "  From your machine:  ssh -L ${VNC_PORT}:localhost:${VNC_PORT} <user>@<vm-ip>"
      log_info "  Then point a VNC client at  localhost:${VNC_PORT}"
    else
      log_warn "x11vnc not installed; running headless (no remote view)."
    fi
  fi
fi

log_info "Launching OpenClaw from ${RELEASE_DIR} ..."
cd "${RELEASE_DIR}"
exec "${OPENCLAW_BIN}"
