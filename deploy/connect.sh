#!/usr/bin/env bash
# Open an SSH tunnel from your Mac/laptop to the OpenClaw VM's VNC and print the
# URL to connect to. Run this ON YOUR MAC (not on the VM).
#
# Requires VM_HOST to be set to the VM's SSH target, e.g.:
#   VM_HOST=azureuser@20.30.40.50 ./deploy/connect.sh
#
# Usage:
#   ./deploy/connect.sh            # open the tunnel (stays in foreground)
#   ./deploy/connect.sh --print    # just print the ssh/VNC commands, don't connect
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PRINT_ONLY=0
[[ "${1:-}" == "--print" ]] && PRINT_ONLY=1

if [[ -z "${VM_HOST}" ]]; then
  die "VM_HOST is not set. Set it to the VM's SSH target, e.g. VM_HOST=azureuser@<vm-ip> (find the IP in the Azure Portal)."
fi

tunnel="ssh -N -L ${VNC_PORT}:localhost:${VNC_PORT} ${VM_HOST}"
vnc_url="vnc://localhost:${VNC_PORT}"

log_info "VNC tunnel target : ${VM_HOST}"
log_info "Local VNC URL     : ${vnc_url}"

if [[ "${PRINT_ONLY}" -eq 1 ]]; then
  log_info "Run this to open the tunnel:"
  printf '    %s\n' "${tunnel}"
  log_info "Then connect a VNC client to ${vnc_url}"
  exit 0
fi

require_cmd ssh
log_info "Opening SSH tunnel (Ctrl-C to close). Then connect a VNC client to ${vnc_url}"
# On macOS you can also just run:  open ${vnc_url}
exec ${tunnel}
