# shellcheck shell=bash
# =============================================================================
# OpenClaw — macOS (MacBook) configuration
# -----------------------------------------------------------------------------
# Edit here, or override any value by exporting it before running a script:
#
#     OPENCLAW_HOME=~/Games/OpenClaw ./mac/setup.sh
#
# Every value uses ${VAR:-default}, so an exported value always wins.
# =============================================================================

# --- OpenClaw source -------------------------------------------------------
export OPENCLAW_REPO="${OPENCLAW_REPO:-https://github.com/pjasicek/OpenClaw.git}"
export OPENCLAW_BRANCH="${OPENCLAW_BRANCH:-master}"

# Where the engine is cloned and built on the Mac.
export OPENCLAW_HOME="${OPENCLAW_HOME:-${HOME}/OpenClaw}"
export BUILD_DIR="${BUILD_DIR:-${OPENCLAW_HOME}/build}"

# Upstream CMake emits the binary + assets here (CMAKE_RUNTIME_OUTPUT_DIRECTORY=../Build_Release).
# CLAW.REZ and ASSETS.ZIP must live in this directory; the game runs from here.
export RELEASE_DIR="${RELEASE_DIR:-${OPENCLAW_HOME}/Build_Release}"
export OPENCLAW_BIN="${OPENCLAW_BIN:-${RELEASE_DIR}/openclaw}"

# Folder scanned for the original game archive (CLAW.REZ).
export DOWNLOADS_DIR="${DOWNLOADS_DIR:-${HOME}/Downloads}"

# Parallel build jobs (number of CPU cores on macOS).
export MAKE_JOBS="${MAKE_JOBS:-$(sysctl -n hw.ncpu 2>/dev/null || echo 2)}"
