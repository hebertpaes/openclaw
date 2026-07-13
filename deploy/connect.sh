#!/usr/bin/env bash
# Open an SSH tunnel from your Mac/laptop to the OpenClaw gateway dashboard on
# the VM, then print the local URL. Run this ON YOUR MAC (not on the VM).
#
# The gateway binds to localhost on the VM, so the dashboard is reached through
# an SSH tunnel — nothing needs to be opened in the Azure NSG.
#
# Requires VM_HOST, e.g.:
#   VM_HOST=azureuser@20.30.40.50 ./deploy/connect.sh
#
# Usage:
#   ./deploy/connect.sh            # open the tunnel (stays in foreground)
#   ./deploy/connect.sh --print    # just print the ssh command + URL, don't connect
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

PRINT_ONLY=0
[[ "${1:-}" == "--print" ]] && PRINT_ONLY=1

if [[ -z "${VM_HOST}" ]]; then
  die "VM_HOST is not set. Set it to the VM's SSH target, e.g. VM_HOST=azureuser@<vm-ip> (find the IP in the Azure Portal)."
fi

# Use the configured key explicitly so SSH doesn't get rejected for offering
# the wrong identity first ("Permission denied (publickey)"). Build the argv as
# an array so paths with spaces (e.g. SSH_KEY) survive word splitting.
ssh_args=()
if [ -n "${SSH_KEY:-}" ] && [ -f "${SSH_KEY}" ]; then
  ssh_args+=("-i" "${SSH_KEY}" "-o" "IdentitiesOnly=yes")
fi
ssh_args+=("-N" "-L" "${OPENCLAW_PORT}:localhost:${OPENCLAW_PORT}" "${VM_HOST}")

url="http://localhost:${OPENCLAW_PORT}"

log_info "Tunnel target : ${VM_HOST}"
log_info "Dashboard URL : ${url}"

if [[ "${PRINT_ONLY}" -eq 1 ]]; then
  log_info "Run this to open the tunnel:"
  printf '    ssh %s\n' "${ssh_args[*]}"
  log_info "Then open ${url} in your browser."
  exit 0
fi

require_cmd ssh
log_info "Opening SSH tunnel (Ctrl-C to close). Then open ${url} in your browser."
exec ssh "${ssh_args[@]}"
