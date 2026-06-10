#!/usr/bin/env bash
# One-shot orchestrator: dependencies -> build -> organize assets -> (optional) service.
# Run this on the Azure VM after copying the repo over. Each step is also a
# standalone script if you'd rather run them one at a time.
#
# Usage:
#   ./deploy/setup.sh                # deps + build + organize assets
#   ./deploy/setup.sh --service      # ...and install+enable the systemd service
#   ./deploy/setup.sh --run          # ...and launch the game at the end
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

WITH_SERVICE=0
WITH_RUN=0
for arg in "$@"; do
  case "${arg}" in
    --service) WITH_SERVICE=1 ;;
    --run)     WITH_RUN=1 ;;
    -h|--help)
      grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) die "Unknown option: ${arg} (try --help)" ;;
  esac
done

log_info "==> Step 1/3: installing dependencies"
bash "${DEPLOY_DIR}/install-deps.sh"

log_info "==> Step 2/3: building OpenClaw"
bash "${DEPLOY_DIR}/build.sh"

log_info "==> Step 3/3: organizing download folder / assets"
bash "${DEPLOY_DIR}/organize-assets.sh"

if [[ "${WITH_SERVICE}" -eq 1 ]]; then
  log_info "==> Extra: installing systemd service"
  bash "${DEPLOY_DIR}/install-service.sh"
fi

log_ok "Setup complete."

if [[ "${WITH_RUN}" -eq 1 ]]; then
  log_info "==> Launching OpenClaw"
  exec bash "${DEPLOY_DIR}/run.sh"
else
  log_info "Activate the game with:   ./deploy/run.sh"
  [[ "${WITH_SERVICE}" -eq 1 ]] && log_info "...or as a service:       ${SUDO:+sudo }systemctl start openclaw"
fi
