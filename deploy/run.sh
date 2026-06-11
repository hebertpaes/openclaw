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

# Track helper PIDs / temp files so we can clean them up on exit.
XVFB_PID=""
VNC_PID=""
PASSFILE=""
cleanup() {
  if [[ -n "${VNC_PID}"  ]]; then kill "${VNC_PID}"  2>/dev/null || true; fi
  if [[ -n "${XVFB_PID}" ]]; then kill "${XVFB_PID}" 2>/dev/null || true; fi
  if [[ -n "${PASSFILE}" ]]; then rm -f "${PASSFILE}" 2>/dev/null || true; fi
}
trap cleanup EXIT INT TERM

# Best-effort detection of the VM's primary local IP (for connection hints).
detect_local_ip() {
  local ip=""
  ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
  [[ -z "${ip}" ]] && ip="$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)"
  printf '%s' "${ip}"
}

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
      vm_ip="$(detect_local_ip)"; [[ -z "${vm_ip}" ]] && vm_ip="<vm-ip>"

      # Base args; binding mode depends on VNC_EXPOSE.
      vnc_args=( -display "${DISPLAY_NUM}" -rfbport "${VNC_PORT}" -forever -shared -quiet -bg )
      expose_mode="localhost"

      if [[ "${VNC_EXPOSE}" == "1" ]]; then
        if [[ -z "${VNC_PASSWORD}" ]]; then
          log_warn "VNC_EXPOSE=1 but VNC_PASSWORD is empty — refusing to expose VNC without a password."
          log_warn "Falling back to localhost-only (set VNC_PASSWORD to expose on the network)."
          vnc_args+=( -localhost -nopw )
        else
          # Listen on all interfaces, protected by a password file (avoids
          # putting the password on the x11vnc command line).
          PASSFILE="$(mktemp)"
          x11vnc -storepasswd "${VNC_PASSWORD}" "${PASSFILE}" >/dev/null 2>&1
          vnc_args+=( -rfbauth "${PASSFILE}" )
          expose_mode="network"
        fi
      else
        vnc_args+=( -localhost -nopw )
      fi

      x11vnc "${vnc_args[@]}" >/dev/null 2>&1 || log_warn "x11vnc failed to start; continuing headless."
      VNC_PID="$(pgrep -n x11vnc || true)"

      log_info "VM local IP: ${vm_ip}"
      if [[ "${expose_mode}" == "network" ]]; then
        log_info "VNC exposed on the network — connect a VNC client to:  vnc://${vm_ip}:${VNC_PORT}"
        log_info "  (make sure the Azure NSG allows inbound TCP ${VNC_PORT})"
      else
        log_info "VNC on localhost:${VNC_PORT}. Connect via SSH tunnel from your Mac:"
        log_info "  ssh -L ${VNC_PORT}:localhost:${VNC_PORT} ${VM_HOST:-<user>@${vm_ip}}"
        log_info "  Then point a VNC client at  vnc://localhost:${VNC_PORT}"
        log_info "  (or just run ./deploy/connect.sh on the Mac with VM_HOST set)"
      fi
    else
      log_warn "x11vnc not installed; running headless (no remote view)."
    fi
  fi
fi

log_info "Launching OpenClaw from ${RELEASE_DIR} ..."
cd "${RELEASE_DIR}"
exec "${OPENCLAW_BIN}"
