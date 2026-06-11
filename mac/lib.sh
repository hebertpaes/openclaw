# shellcheck shell=bash
# Shared helpers for the macOS OpenClaw scripts.
# Sourced by every mac/ script; not meant to be executed directly.
# Written to work with the system bash 3.2 that ships with macOS.

MAC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export MAC_DIR

# shellcheck source=/dev/null
source "${MAC_DIR}/config.sh"

# --- Logging ---------------------------------------------------------------
if [ -t 1 ]; then
  _C_BLUE=$'\033[0;34m'; _C_GREEN=$'\033[0;32m'; _C_YELLOW=$'\033[0;33m'
  _C_RED=$'\033[0;31m'; _C_RESET=$'\033[0m'
else
  _C_BLUE=''; _C_GREEN=''; _C_YELLOW=''; _C_RED=''; _C_RESET=''
fi

log_info()  { printf '%s[openclaw]%s %s\n' "${_C_BLUE}"   "${_C_RESET}" "$*"; }
log_ok()    { printf '%s[openclaw]%s %s\n' "${_C_GREEN}"  "${_C_RESET}" "$*"; }
log_warn()  { printf '%s[openclaw]%s %s\n' "${_C_YELLOW}" "${_C_RESET}" "$*" >&2; }
log_error() { printf '%s[openclaw]%s %s\n' "${_C_RED}"    "${_C_RESET}" "$*" >&2; }
die()       { log_error "$*"; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

# Refuse to run on anything but macOS — these scripts assume Homebrew + Darwin.
assert_macos() {
  [ "$(uname -s)" = "Darwin" ] \
    || die "These scripts target macOS. For the Linux Azure VM use the deploy/ scripts instead."
}

# Ensure Homebrew is installed and expose its prefix (/opt/homebrew on Apple
# Silicon, /usr/local on Intel).
ensure_brew() {
  if ! command -v brew >/dev/null 2>&1; then
    log_error "Homebrew is not installed."
    log_error "Install it from https://brew.sh then re-run, e.g.:"
    # shellcheck disable=SC2016  # printing the literal command, not expanding it
    log_error '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    exit 1
  fi
  BREW_PREFIX="$(brew --prefix)"
  export BREW_PREFIX
}
