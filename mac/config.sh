# shellcheck shell=bash
# =============================================================================
# OpenClaw AI gateway — macOS (MacBook) configuration
# -----------------------------------------------------------------------------
# Edit here, or override any value by exporting it before running a script.
# Docs: https://docs.openclaw.ai  •  Repo: https://github.com/openclaw/openclaw
# =============================================================================

# Load local secrets (gitignored) if present. MAC_DIR is set by lib.sh first.
for _sf in "${MAC_DIR:-.}/../secrets.env" "${MAC_DIR:-.}/secrets.env"; do
  # shellcheck source=/dev/null
  [ -f "${_sf}" ] && . "${_sf}"
done
unset _sf

export OPENCLAW_PKG="${OPENCLAW_PKG:-openclaw@latest}"

# Homebrew Node formula (node@24 recommended; minimum Node 22.19).
export NODE_FORMULA="${NODE_FORMULA:-node@24}"

# Gateway listen port (local dashboard/API). 18789 is the OpenClaw default.
export OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"

# Agent backend: "codex" (OpenAI Codex app-server) [default] or "claude" (Anthropic).
export OPENCLAW_BACKEND="${OPENCLAW_BACKEND:-codex}"
export OPENCLAW_CODEX_PLUGIN="${OPENCLAW_CODEX_PLUGIN:-@openclaw/codex}"

# Config lives in ~/.openclaw/openclaw.json. Model format: "<provider>/<model-id>".
export OPENCLAW_DIR="${OPENCLAW_DIR:-${HOME}/.openclaw}"
export OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-${OPENCLAW_DIR}/openclaw.json}"

# Model — mainly for the claude backend (codex discovers its own model).
export OPENCLAW_MODEL="${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-6}"

# Provider credentials — supply your own; NEVER commit them. Export in your shell:
#   Codex:  export OPENAI_API_KEY=sk-...        (or log in via ChatGPT/Codex during onboard)
#   Claude: export ANTHROPIC_API_KEY=sk-ant-...
export OPENAI_API_KEY="${OPENAI_API_KEY:-}"
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"

# GitHub integration: connect the agent to GitHub via the GitHub plugin.
export OPENCLAW_GITHUB="${OPENCLAW_GITHUB:-1}"
export OPENCLAW_GITHUB_PLUGIN="${OPENCLAW_GITHUB_PLUGIN:-@openclaw/github}"
# Fine-grained PAT (repo + read:org); read from env, never in openclaw.json.
export GITHUB_TOKEN="${GITHUB_TOKEN:-}"
