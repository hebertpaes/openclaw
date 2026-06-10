#!/usr/bin/env bash
# Clone (or update) and compile the OpenClaw engine from source.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

require_cmd git
require_cmd cmake
require_cmd make

# --- Fetch source ----------------------------------------------------------
if [[ -d "${OPENCLAW_HOME}/.git" ]]; then
  log_info "Updating existing checkout at ${OPENCLAW_HOME} ..."
  git -C "${OPENCLAW_HOME}" fetch --depth 1 origin "${OPENCLAW_BRANCH}"
  git -C "${OPENCLAW_HOME}" checkout "${OPENCLAW_BRANCH}"
  git -C "${OPENCLAW_HOME}" reset --hard "origin/${OPENCLAW_BRANCH}"
else
  log_info "Cloning ${OPENCLAW_REPO} (${OPENCLAW_BRANCH}) into ${OPENCLAW_HOME} ..."
  git clone --depth 1 --branch "${OPENCLAW_BRANCH}" "${OPENCLAW_REPO}" "${OPENCLAW_HOME}"
fi

# --- Configure + compile ---------------------------------------------------
log_info "Configuring build (cmake) ..."
mkdir -p "${BUILD_DIR}"
cmake -S "${OPENCLAW_HOME}" -B "${BUILD_DIR}" -DCMAKE_BUILD_TYPE=Release

log_info "Compiling with ${MAKE_JOBS} job(s) ..."
cmake --build "${BUILD_DIR}" -- -j"${MAKE_JOBS}"

# Upstream CMake emits the binary to Build_Release (CMAKE_RUNTIME_OUTPUT_DIRECTORY).
if [[ -x "${OPENCLAW_BIN}" ]]; then
  log_ok "Build complete: ${OPENCLAW_BIN}"
else
  log_warn "Build finished but '${OPENCLAW_BIN}' was not found."
  log_warn "Locating the compiled 'openclaw' binary under ${OPENCLAW_HOME} ..."
  found="$(find "${OPENCLAW_HOME}" -maxdepth 3 -type f -name openclaw -perm -u+x 2>/dev/null | head -n1 || true)"
  [[ -n "${found}" ]] \
    && log_warn "Found a binary at: ${found} (update OPENCLAW_BIN/RELEASE_DIR in config.env)" \
    || die "Could not locate the compiled binary. Check the cmake/make output above."
fi
