#!/usr/bin/env bash
# One-shot setup for the MacBook: dependencies -> build -> organize assets.
#
# Usage:
#   ./mac/setup.sh          # deps + build + organize assets
#   ./mac/setup.sh --run    # ...and launch the game at the end
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

WITH_RUN=0
for arg in "$@"; do
  case "${arg}" in
    --run) WITH_RUN=1 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option: ${arg} (try --help)" ;;
  esac
done

assert_macos

log_info "==> Step 1/3: installing dependencies (Homebrew)"
bash "${MAC_DIR}/install-deps.sh"

log_info "==> Step 2/3: building OpenClaw"
bash "${MAC_DIR}/build.sh"

log_info "==> Step 3/3: organizing assets (CLAW.REZ / ASSETS.ZIP)"
bash "${MAC_DIR}/organize-assets.sh"

log_ok "Setup complete."

if [ "${WITH_RUN}" -eq 1 ]; then
  log_info "==> Launching OpenClaw"
  exec bash "${MAC_DIR}/run.sh"
else
  log_info "Run the game with:   ./mac/run.sh"
fi
