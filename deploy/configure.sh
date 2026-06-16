#!/usr/bin/env bash
# Scaffold the OpenClaw gateway config (~/.openclaw/openclaw.json) for the chosen
# agent backend. Secrets are NEVER written here — provider keys are read from the
# environment (OPENAI_API_KEY / ANTHROPIC_API_KEY) at runtime.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

mkdir -p "${OPENCLAW_DIR}"

case "${OPENCLAW_BACKEND}" in
  codex)
    # The Codex app-server (added by the @openclaw/codex plugin) handles model
    # discovery, so we don't pin a model here. Backend selection + Codex auth
    # are completed by 'openclaw onboard' (start.sh).
    log_info "Backend: codex (OpenAI Codex app-server)."
    if [ -f "${OPENCLAW_CONFIG}" ]; then
      log_warn "Config already exists at ${OPENCLAW_CONFIG} — leaving it untouched."
    else
      log_info "Writing minimal ${OPENCLAW_CONFIG} ..."
      printf '{\n}\n' > "${OPENCLAW_CONFIG}"
      chmod 600 "${OPENCLAW_CONFIG}"
      log_ok "Config created (backend wired by 'openclaw onboard')."
    fi
    if [ -z "${OPENAI_API_KEY}" ]; then
      log_warn "OPENAI_API_KEY is not set. Either export it:"
      log_warn "    export OPENAI_API_KEY=sk-..."
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
      log_warn "ANTHROPIC_API_KEY is not set. Export it before starting:"
      log_warn "    export ANTHROPIC_API_KEY=sk-ant-..."
      log_warn "or enter it during 'openclaw onboard'."
    else
      log_ok "ANTHROPIC_API_KEY is present in the environment."
    fi
    ;;

  *)
    die "Unknown OPENCLAW_BACKEND='${OPENCLAW_BACKEND}' (expected: codex or claude)."
    ;;
esac

# --- GitHub connection -----------------------------------------------------
if [ "${OPENCLAW_GITHUB}" = "1" ]; then
  if [ -z "${GITHUB_TOKEN}" ]; then
    log_warn "GitHub plugin enabled but GITHUB_TOKEN is not set."
    log_warn "Create a fine-grained PAT (scopes: repo + read:org) at"
    log_warn "https://github.com/settings/tokens and put it in secrets.env (GITHUB_TOKEN=...)."
  else
    log_ok "GITHUB_TOKEN present — the GitHub plugin can authenticate."
  fi
fi

log_info "Provider/channel details (WhatsApp, Telegram, …) are completed by"
log_info "'openclaw onboard' — see start.sh / https://docs.openclaw.ai"
