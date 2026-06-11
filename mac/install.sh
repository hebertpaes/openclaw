#!/usr/bin/env bash
# Install Node.js + the OpenClaw AI gateway on macOS via Homebrew.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
ensure_brew

# --- Node.js ---------------------------------------------------------------
need_node=1
if command -v node >/dev/null 2>&1; then
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${major}" -ge 22 ]; then
    log_info "Node $(node -v) already installed."
    need_node=0
  else
    log_warn "Node $(node -v) is too old (need >= 22.19); installing ${NODE_FORMULA}."
  fi
fi

if [ "${need_node}" -eq 1 ]; then
  log_info "Installing ${NODE_FORMULA} via Homebrew ..."
  brew install "${NODE_FORMULA}"
  # Keg-only versioned node formulas need to be linked / put on PATH.
  brew link --overwrite --force "${NODE_FORMULA}" 2>/dev/null || true
  command -v node >/dev/null 2>&1 \
    || log_warn "node not on PATH yet — you may need: echo 'export PATH=\"${BREW_PREFIX}/opt/${NODE_FORMULA}/bin:\$PATH\"' >> ~/.zshrc"
fi

# --- OpenClaw --------------------------------------------------------------
log_info "Installing OpenClaw globally (npm i -g ${OPENCLAW_PKG}) ..."
npm install -g "${OPENCLAW_PKG}"

require_cmd openclaw
log_ok "OpenClaw installed: $(openclaw --version 2>/dev/null || echo 'version unknown')"
