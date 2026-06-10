#!/usr/bin/env bash
# Install OpenClaw build + runtime dependencies on a Debian/Ubuntu VM.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

assert_apt

# Build toolchain + SDL2 stack required by the OpenClaw CMake build.
BUILD_PKGS=(
  build-essential cmake git
  libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-ttf-dev libsdl2-gfx-dev
  libtinyxml-dev
  zip unzip
)

# MIDI music playback (OpenClaw uses timidity + the freepats patch set).
AUDIO_PKGS=(timidity freepats)

# Virtual display + remote viewing so the game can run on a headless server.
DISPLAY_PKGS=(xvfb x11vnc mesa-utils)

log_info "Updating apt package index..."
${SUDO} apt-get update -y

log_info "Installing build dependencies..."
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${BUILD_PKGS[@]}"

log_info "Installing audio (MIDI) dependencies..."
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${AUDIO_PKGS[@]}"

log_info "Installing virtual display / VNC dependencies..."
${SUDO} DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${DISPLAY_PKGS[@]}"

log_ok "All dependencies installed."
