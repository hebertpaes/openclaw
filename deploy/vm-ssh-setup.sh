#!/usr/bin/env bash
# Prepare SSH access to the openclaw-vm. Run this ON YOUR MAC.
#
# It does the LOCAL parts for you — generates an SSH key if you don't have one —
# and prints the exact Azure command to register that key on the VM plus the
# command to connect. The Azure step itself must be run by you (it needs your
# authenticated `az` / Cloud Shell); this script never touches Azure.
#
# Usage:
#   ./deploy/vm-ssh-setup.sh                 # ensure key, print az + ssh commands
#   VM_IP=20.30.40.50 ./deploy/vm-ssh-setup.sh   # also save VM_HOST to secrets.env
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

# --- 1. Ensure a local SSH key ---------------------------------------------
if [ -f "${SSH_KEY}" ]; then
  log_info "Using existing SSH key: ${SSH_KEY}"
else
  require_cmd ssh-keygen
  log_info "Generating a new SSH key at ${SSH_KEY} ..."
  mkdir -p "$(dirname "${SSH_KEY}")"
  ssh-keygen -t ed25519 -f "${SSH_KEY}" -N "" -C "openclaw-vm"
  log_ok "Key created."
fi
PUBKEY="$(cat "${SSH_KEY}.pub")"

# --- 2. Azure command to register the key (you run this) -------------------
echo
log_info "STEP A — register this key on the VM. Run it in Azure Cloud Shell"
log_info "(the >_ icon in the Portal; it's already authenticated):"
echo
printf '  az vm user update -g %s -n %s -u %s --ssh-key-value "%s"\n' \
  "${AZ_RESOURCE_GROUP}" "${AZ_VM_NAME}" "${VM_USER}" "${PUBKEY}"
echo
log_info "(This resets the public key for '${VM_USER}'. To set a password instead,"
log_info " use:  az vm user update -g ${AZ_RESOURCE_GROUP} -n ${AZ_VM_NAME} -u ${VM_USER} --password '<new-pass>')"
log_info "Also make sure the VM's NSG allows inbound TCP 22."
echo
log_info "IMPORTANT — confirm the admin username (the #1 cause of 'Permission denied')."
log_info "If it isn't '${VM_USER}', re-run with VM_USER=<name>. Check it with:"
printf '  az vm show -g %s -n %s --query "osProfile.adminUsername" -o tsv\n' \
  "${AZ_RESOURCE_GROUP}" "${AZ_VM_NAME}"

# --- 3. Connect ------------------------------------------------------------
echo
if [ -n "${VM_IP:-}" ]; then
  log_info "STEP B — connect (use -v to debug auth):"
  printf '  ssh -i %s -o IdentitiesOnly=yes %s@%s\n' "${SSH_KEY}" "${VM_USER}" "${VM_IP}"

  # Persist VM_HOST to secrets.env for connect.sh / setup.sh convenience.
  secrets="${DEPLOY_DIR}/../secrets.env"
  if [ ! -f "${secrets}" ]; then
    cp "${DEPLOY_DIR}/../secrets.env.example" "${secrets}" 2>/dev/null || : > "${secrets}"
  fi
  if grep -q '^export VM_HOST=' "${secrets}" 2>/dev/null; then
    tmp="$(mktemp)"; sed "s|^export VM_HOST=.*|export VM_HOST=${VM_USER}@${VM_IP}|" "${secrets}" > "${tmp}" && mv "${tmp}" "${secrets}"
  else
    printf 'export VM_HOST=%s@%s\n' "${VM_USER}" "${VM_IP}" >> "${secrets}"
  fi
  log_ok "Saved VM_HOST=${VM_USER}@${VM_IP} to secrets.env (gitignored)."
else
  log_info "STEP B — connect (replace <vm-ip> with the Public IP from the VM Overview):"
  printf '  ssh -i %s -o IdentitiesOnly=yes %s@<vm-ip>\n' "${SSH_KEY}" "${VM_USER}"
  log_info "Tip: re-run as  VM_IP=<vm-ip> ./deploy/vm-ssh-setup.sh  to save it for connect.sh."
fi
