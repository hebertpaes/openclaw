#!/usr/bin/env bash
# Install Node.js + the OpenClaw AI gateway on a Debian/Ubuntu Azure VM.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_apt
require_cmd curl

# --- Node.js ---------------------------------------------------------------
need_node=1
if command -v node >/dev/null 2>&1; then
  major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
  if [ "${major}" -ge 22 ]; then
    log_info "Node $(node -v) already installed."
    need_node=0
  else
    log_warn "Node $(node -v) is too old (need >= 22.19); installing Node ${NODE_MAJOR}."
  fi
fi

if [ "${need_node}" -eq 1 ]; then
  log_info "Installing Node ${NODE_MAJOR} via NodeSource ..."
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" | ${SUDO} -E bash -
  ${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
  log_ok "Installed Node $(node -v)."
fi

# --- OpenClaw --------------------------------------------------------------
log_info "Installing OpenClaw globally (npm i -g ${OPENCLAW_PKG}) ..."
${SUDO} npm install -g "${OPENCLAW_PKG}"

require_cmd openclaw
log_ok "OpenClaw installed: $(openclaw --version 2>/dev/null || echo 'version unknown')"
