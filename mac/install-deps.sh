#!/usr/bin/env bash
# Install OpenClaw build dependencies on macOS via Homebrew.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_macos
ensure_brew

# Build toolchain + SDL2 stack required by the OpenClaw CMake build.
BUILD_PKGS="cmake sdl2 sdl2_image sdl2_mixer sdl2_ttf sdl2_gfx tinyxml"

log_info "Installing build dependencies via Homebrew (prefix: ${BREW_PREFIX}) ..."
# shellcheck disable=SC2086
brew install ${BUILD_PKGS}

# MIDI music is optional; the game runs without it. Best-effort install.
log_info "Installing optional audio dependency (timidity) ..."
brew install timidity || log_warn "timidity install failed — music may be silent, gameplay is unaffected."

log_ok "Dependencies installed."
