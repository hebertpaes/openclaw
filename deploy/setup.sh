#!/usr/bin/env bash
# One-shot setup for the OpenClaw gateway on the Azure VM:
# install Node + OpenClaw -> scaffold config -> onboard + install daemon.
#
# Usage:
#   ./deploy/setup.sh                 # install + configure + start daemon
#   ./deploy/setup.sh --no-start      # install + configure only (no daemon yet)
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

log_info "==> Step 1/3: installing Node + OpenClaw"
bash "${DEPLOY_DIR}/install.sh"

log_info "==> Step 2/3: scaffolding config"
bash "${DEPLOY_DIR}/configure.sh"

if [ "${WITH_START}" -eq 1 ]; then
  log_info "==> Step 3/3: onboarding + installing the gateway daemon"
  bash "${DEPLOY_DIR}/start.sh"
else
  log_ok "Install + config done. Start later with:  ./deploy/start.sh"
fi
