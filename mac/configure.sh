#!/usr/bin/env bash
# Scaffold the OpenClaw gateway config (~/.openclaw/openclaw.json) with the
# chosen Claude model. The Anthropic API key is read from ANTHROPIC_API_KEY at
# runtime and is never written here.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
mkdir -p "${OPENCLAW_DIR}"

if [ -f "${OPENCLAW_CONFIG}" ]; then
  log_warn "Config already exists at ${OPENCLAW_CONFIG} — leaving it untouched."
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

if [ -z "${ANTHROPIC_API_KEY}" ]; then
  log_warn "ANTHROPIC_API_KEY is not set. Export it before starting, or run"
  log_warn "'openclaw onboard' to enter it interactively:"
  log_warn "    export ANTHROPIC_API_KEY=sk-ant-..."
else
  log_ok "ANTHROPIC_API_KEY is present in the environment."
fi
