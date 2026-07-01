#!/usr/bin/env bash
# One-shot setup for the OpenClaw gateway on the MacBook:
# install Node + OpenClaw (Homebrew) -> scaffold config -> onboard + daemon.
#
# Usage:
#   ./mac/setup.sh                 # install + configure + start daemon
#   ./mac/setup.sh --no-start      # install + configure only
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

WITH_START=1
for arg in "$@"; do
  case "${arg}" in
    --no-start) WITH_START=0 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option: ${arg} (try --help)" ;;
  esac
done

assert_macos

log_info "==> Step 1/3: installing Node + OpenClaw (Homebrew)"
bash "${MAC_DIR}/install.sh"

log_info "==> Step 2/3: scaffolding config"
bash "${MAC_DIR}/configure.sh"

if [ "${WITH_START}" -eq 1 ]; then
  log_info "==> Step 3/3: onboarding + installing the gateway daemon"
  bash "${MAC_DIR}/start.sh"
else
  log_ok "Install + config done. Start later with:  ./mac/start.sh"
fi
