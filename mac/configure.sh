#!/usr/bin/env bash
# Scaffold the OpenClaw gateway config (~/.openclaw/openclaw.json) for the chosen
# agent backend. Secrets are NEVER written here — provider keys are read from the
# environment (OPENAI_API_KEY / ANTHROPIC_API_KEY) at runtime.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
mkdir -p "${OPENCLAW_DIR}"

case "${OPENCLAW_BACKEND}" in
  codex)
    log_info "Backend: codex (OpenAI Codex app-server)."
    if [ -f "${OPENCLAW_CONFIG}" ]; then
      log_warn "Config already exists at ${OPENCLAW_CONFIG} — leaving it untouched."
    else
      log_info "Writing minimal ${OPENCLAW_CONFIG} (backend wired by 'openclaw onboard') ..."
      printf '{\n}\n' > "${OPENCLAW_CONFIG}"
      chmod 600 "${OPENCLAW_CONFIG}"
      log_ok "Config created."
    fi
    if [ -z "${OPENAI_API_KEY}" ]; then
      log_warn "OPENAI_API_KEY is not set. Export it (export OPENAI_API_KEY=sk-...)"
      log_warn "or log in with your ChatGPT/Codex account during 'openclaw onboard'."
    else
      log_ok "OPENAI_API_KEY is present in the environment."
    fi
    ;;

  claude)
    log_info "Backend: claude (Anthropic)."
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
      log_warn "ANTHROPIC_API_KEY is not set. Export it or enter it during 'openclaw onboard'."
    else
      log_ok "ANTHROPIC_API_KEY is present in the environment."
    fi
    ;;

  *)
    die "Unknown OPENCLAW_BACKEND='${OPENCLAW_BACKEND}' (expected: codex or claude)."
    ;;
esac
