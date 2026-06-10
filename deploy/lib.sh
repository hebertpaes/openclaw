#!/usr/bin/env bash
# Shared helpers for the OpenClaw deploy scripts.
# Sourced by every script; not meant to be executed directly.

# Resolve the directory this library lives in so scripts can find siblings.
DEPLOY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DEPLOY_DIR

# Load configuration (defaults + any exported overrides).
# shellcheck source=/dev/null
source "${DEPLOY_DIR}/config.env"

# --- Logging ---------------------------------------------------------------
if [[ -t 1 ]]; then
  _C_BLUE=$'\033[0;34m'; _C_GREEN=$'\033[0;32m'; _C_YELLOW=$'\033[0;33m'
  _C_RED=$'\033[0;31m'; _C_RESET=$'\033[0m'
else
  _C_BLUE=''; _C_GREEN=''; _C_YELLOW=''; _C_RED=''; _C_RESET=''
fi

log_info()  { printf '%s[openclaw]%s %s\n'  "${_C_BLUE}"   "${_C_RESET}" "$*"; }
log_ok()    { printf '%s[openclaw]%s %s\n'  "${_C_GREEN}"  "${_C_RESET}" "$*"; }
log_warn()  { printf '%s[openclaw]%s %s\n'  "${_C_YELLOW}" "${_C_RESET}" "$*" >&2; }
log_error() { printf '%s[openclaw]%s %s\n'  "${_C_RED}"    "${_C_RESET}" "$*" >&2; }
die()       { log_error "$*"; exit 1; }

# --- Guards ----------------------------------------------------------------
require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Prefix a command with sudo only when not already root.
SUDO=""
if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi
fi
export SUDO

# Ensure we are on a Debian/Ubuntu-style host (Azure default images are Ubuntu).
assert_apt() {
  command -v apt-get >/dev/null 2>&1 \
    || die "These scripts target Debian/Ubuntu (apt-get not found). Adapt the package step for your distro."
}
