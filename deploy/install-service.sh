#!/usr/bin/env bash
# Install OpenClaw as a systemd service so it starts on boot and restarts on
# failure. Renders the unit template with the current user + resolved paths.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

TEMPLATE="${DEPLOY_DIR}/systemd/openclaw.service.template"
UNIT_PATH="/etc/systemd/system/openclaw.service"
RUN_AS="${SUDO_USER:-$(id -un)}"
RUN_HOME="$(getent passwd "${RUN_AS}" | cut -d: -f6)"
RUN_HOME="${RUN_HOME:-${HOME}}"

[[ -f "${TEMPLATE}" ]] || die "Template not found: ${TEMPLATE}"
command -v systemctl >/dev/null 2>&1 || die "systemd (systemctl) not available on this host."

log_info "Rendering systemd unit for user '${RUN_AS}' ..."
rendered="$(mktemp)"
sed \
  -e "s|__USER__|${RUN_AS}|g" \
  -e "s|__HOME__|${RUN_HOME}|g" \
  -e "s|__RELEASE_DIR__|${RELEASE_DIR}|g" \
  -e "s|__DEPLOY_DIR__|${DEPLOY_DIR}|g" \
  "${TEMPLATE}" > "${rendered}"

log_info "Installing ${UNIT_PATH} ..."
${SUDO} cp "${rendered}" "${UNIT_PATH}"
rm -f "${rendered}"

${SUDO} systemctl daemon-reload
${SUDO} systemctl enable openclaw.service

log_ok "Service installed and enabled."
log_info "Start it now:     ${SUDO:+sudo }systemctl start openclaw"
log_info "Check status:     ${SUDO:+sudo }systemctl status openclaw"
log_info "Follow logs:      journalctl -u openclaw -f"
