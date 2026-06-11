#!/usr/bin/env bash
# Remove unusable .dmg files from the download folder.
#
# .dmg files are macOS disk images — they are useless on the Linux Azure VM
# that runs OpenClaw (which needs CLAW.REZ, not a .dmg). This clears them out
# of DOWNLOADS_DIR so the download folder only holds usable assets.
#
# Deletion is irreversible, so by default this lists the files and asks for
# confirmation first.
#
# Usage:
#   ./deploy/clean-downloads.sh            # list .dmg files, then ask before deleting
#   ./deploy/clean-downloads.sh --dry-run  # only show what would be deleted
#   ./deploy/clean-downloads.sh --yes      # delete without prompting (non-interactive)
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

DRY_RUN=0
ASSUME_YES=0
for arg in "$@"; do
  case "${arg}" in
    --dry-run) DRY_RUN=1 ;;
    --yes|-y)  ASSUME_YES=1 ;;
    -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "Unknown option: ${arg} (try --help)" ;;
  esac
done

[[ -d "${DOWNLOADS_DIR}" ]] \
  || die "Download folder '${DOWNLOADS_DIR}' not found (set DOWNLOADS_DIR to your folder)."

# Collect .dmg files null-safely (handles spaces/newlines in names).
mapfile -d '' -t dmgs < <(find "${DOWNLOADS_DIR}" -type f -iname '*.dmg' -print0 2>/dev/null)

if [[ "${#dmgs[@]}" -eq 0 ]]; then
  log_ok "No .dmg files found in ${DOWNLOADS_DIR}. Nothing to clean."
  exit 0
fi

log_info "Found ${#dmgs[@]} .dmg file(s) in ${DOWNLOADS_DIR}:"
for f in "${dmgs[@]}"; do
  printf '    %s  (%s)\n' "${f}" "$(du -h "${f}" 2>/dev/null | cut -f1)"
done

if [[ "${DRY_RUN}" -eq 1 ]]; then
  log_info "Dry run — nothing deleted."
  exit 0
fi

if [[ "${ASSUME_YES}" -ne 1 ]]; then
  if [[ ! -t 0 ]]; then
    die "Refusing to delete without confirmation in a non-interactive shell. Re-run with --yes."
  fi
  read -r -p "Delete these ${#dmgs[@]} file(s)? [y/N] " reply
  case "${reply}" in
    y|Y|yes|YES|s|S|sim|SIM) ;;
    *) log_info "Aborted. Nothing deleted."; exit 0 ;;
  esac
fi

deleted=0
for f in "${dmgs[@]}"; do
  if rm -f -- "${f}"; then
    log_info "Removed: ${f}"
    ((deleted++)) || true
  else
    log_warn "Could not remove: ${f}"
  fi
done

log_ok "Cleaned ${deleted} unusable .dmg file(s) from ${DOWNLOADS_DIR}."
