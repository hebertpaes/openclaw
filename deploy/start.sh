#!/usr/bin/env bash
# "Activate" the OpenClaw gateway on the VM.
#
# Default: run the official onboarding, which configures the provider/channel
# (interactively the first time) and installs a systemd **user** service so the
# gateway persists across reboots.
#
# Usage:
#   ./deploy/start.sh                # onboard + install daemon, then show status
#   ./deploy/start.sh --foreground   # run the gateway in the foreground (debug)
#   ./deploy/start.sh --status       # just show gateway status
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cmd openclaw

MODE="daemon"
case "${1:-}" in
  --foreground) MODE="foreground" ;;
  --status)     MODE="status" ;;
  "")           MODE="daemon" ;;
  -h|--help)    grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  *) die "Unknown option: ${1} (try --help)" ;;
esac

if [ "${MODE}" != "status" ]; then
  if [ "${OPENCLAW_BACKEND}" = "codex" ] && [ -z "${OPENAI_API_KEY}" ]; then
    log_warn "Backend codex: OPENAI_API_KEY not set; 'openclaw onboard' will prompt (or log in with ChatGPT/Codex)."
  elif [ "${OPENCLAW_BACKEND}" = "claude" ] && [ -z "${ANTHROPIC_API_KEY}" ]; then
    log_warn "Backend claude: ANTHROPIC_API_KEY not set; 'openclaw onboard' will prompt you for credentials."
  fi
fi

case "${MODE}" in
  daemon)
    log_info "Onboarding and installing the gateway daemon (port ${OPENCLAW_PORT}) ..."
    openclaw onboard --install-daemon
    # systemd --user services stop at logout unless lingering is enabled; turn it
    # on so the gateway keeps running in the background (and starts at boot).
    if command -v loginctl >/dev/null 2>&1; then
      loginctl enable-linger "$(id -un)" \
        || log_warn "Could not enable lingering automatically. Run: loginctl enable-linger $(id -un)"
    fi
    log_info "Gateway status:"
    openclaw gateway status || true
    log_ok "Gateway daemon installed. Dashboard: http://localhost:${OPENCLAW_PORT}"
    log_info "From your Mac, tunnel in with:  ./deploy/connect.sh   (set VM_HOST first)"
    ;;
  foreground)
    log_info "Running the gateway in the foreground on port ${OPENCLAW_PORT} (Ctrl-C to stop) ..."
    exec openclaw gateway --port "${OPENCLAW_PORT}" --verbose
    ;;
  status)
    openclaw gateway status
    ;;
esac
