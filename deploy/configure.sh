#!/usr/bin/env bash
# Scaffold the OpenClaw gateway config (~/.openclaw/openclaw.json) with the
# chosen Claude model. Secrets are NOT written here — the Anthropic API key is
# read from the ANTHROPIC_API_KEY environment variable at runtime.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

mkdir -p "${OPENCLAW_DIR}"

if [ -f "${OPENCLAW_CONFIG}" ]; then
  log_warn "Config already exists at ${OPENCLAW_CONFIG} — leaving it untouched."
  log_warn "Set the model manually or delete the file to regenerate it."
else
  log_info "Writing ${OPENCLAW_CONFIG} (model: ${OPENCLAW_MODEL}) ..."
  cat > "${OPENCLAW_CONFIG}" <<JSON
{
  "agent": {
    "model": "${OPENCLAW_MODEL}"
  }
}
JSON
  chmod 600 "${OPENCLAW_CONFIG}"
  log_ok "Config created."
fi

# --- API key check ---------------------------------------------------------
if [ -z "${ANTHROPIC_API_KEY}" ]; then
  log_warn "ANTHROPIC_API_KEY is not set. The gateway needs it to reach Claude."
  log_warn "Export it before starting (and before installing the daemon):"
  log_warn "    export ANTHROPIC_API_KEY=sk-ant-..."
  log_warn "Or run 'openclaw onboard' to enter it interactively."
else
  log_ok "ANTHROPIC_API_KEY is present in the environment."
fi

log_info "Provider/channel details (WhatsApp, Telegram, …) are completed by"
log_info "'openclaw onboard' — see start.sh / https://docs.openclaw.ai"
