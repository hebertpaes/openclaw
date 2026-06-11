#!/usr/bin/env bash
# "Activate" the OpenClaw gateway on the Mac. Runs the official onboarding,
# which configures the provider/channel (interactively the first time) and
# installs a launchd service so the gateway runs in the background.
#
# Usage:
#   ./mac/start.sh                # onboard + install daemon, then show status
#   ./mac/start.sh --foreground   # run the gateway in the foreground (debug)
#   ./mac/start.sh --status       # just show gateway status
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
require_cmd openclaw

MODE="daemon"
case "${1:-}" in
  --foreground) MODE="foreground" ;;
  --status)     MODE="status" ;;
  "")           MODE="daemon" ;;
  -h|--help)    grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "Unknown option: ${1} (try --help)" ;;
esac

if [ -z "${ANTHROPIC_API_KEY}" ] && [ "${MODE}" != "status" ]; then
  log_warn "ANTHROPIC_API_KEY is not set; 'openclaw onboard' will prompt you for credentials."
fi

case "${MODE}" in
  daemon)
    log_info "Onboarding and installing the gateway daemon (port ${OPENCLAW_PORT}) ..."
    openclaw onboard --install-daemon
    log_info "Gateway status:"
    openclaw gateway status || true
    log_ok "Gateway running. Open the dashboard at:  http://localhost:${OPENCLAW_PORT}"
    ;;
  foreground)
    log_info "Running the gateway in the foreground on port ${OPENCLAW_PORT} (Ctrl-C to stop) ..."
    exec openclaw gateway --port "${OPENCLAW_PORT}" --verbose
    ;;
  status)
    openclaw gateway status
    ;;
esac
