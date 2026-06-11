# shellcheck shell=bash
# =============================================================================
# OpenClaw AI gateway — macOS (MacBook) configuration
# -----------------------------------------------------------------------------
# Edit here, or override any value by exporting it before running a script.
# Docs: https://docs.openclaw.ai  •  Repo: https://github.com/openclaw/openclaw
# =============================================================================

export OPENCLAW_PKG="${OPENCLAW_PKG:-openclaw@latest}"

# Homebrew Node formula (node@24 recommended; minimum Node 22.19).
export NODE_FORMULA="${NODE_FORMULA:-node@24}"

# Gateway listen port (local dashboard/API). 18789 is the OpenClaw default.
export OPENCLAW_PORT="${OPENCLAW_PORT:-18789}"

# Config lives in ~/.openclaw/openclaw.json. Model format: "<provider>/<model-id>".
export OPENCLAW_DIR="${OPENCLAW_DIR:-${HOME}/.openclaw}"
export OPENCLAW_CONFIG="${OPENCLAW_CONFIG:-${OPENCLAW_DIR}/openclaw.json}"

# Anthropic (Claude). Adjust the exact model id per https://docs.openclaw.ai if needed.
export OPENCLAW_MODEL="${OPENCLAW_MODEL:-anthropic/claude-sonnet-4-6}"

# Your Anthropic API key. NEVER commit it — export it in your shell:
#     export ANTHROPIC_API_KEY=sk-ant-...
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-}"
