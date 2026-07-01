#!/usr/bin/env bash
# One-shot bootstrap for the OpenClaw gateway on a fresh Azure VM.
# Clones (or updates) this repo, then runs the deploy setup.
#
# Run it ON THE VM, e.g. over SSH:
#   ssh azureuser@<vm-ip>
#   export OPENAI_API_KEY=sk-...        # Codex backend (or ANTHROPIC_API_KEY + OPENCLAW_BACKEND=claude)
#   curl -fsSL <raw-url>/deploy/bootstrap.sh | bash      # if the repo is public
#   # or after cloning:  ./deploy/bootstrap.sh
#
# Or non-interactively from Azure Cloud Shell:
#   az vm run-command invoke -g openclaw-vm_group -n openclaw-vm \
#     --command-id RunShellScript \
#     --scripts 'sudo -u azureuser -i bash -s -- --no-start' < deploy/bootstrap.sh
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/hebertpaes/openclaw.git}"
REPO_BRANCH="${REPO_BRANCH:-claude/vigilant-hamilton-ig74tu}"
TARGET_DIR="${TARGET_DIR:-${HOME}/openclaw}"

# Ensure git is available (Azure Ubuntu images usually ship it).
if ! command -v git >/dev/null 2>&1; then
  echo "[bootstrap] installing git ..."
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update -y && sudo apt-get install -y git
  else
    echo "[bootstrap] git missing and no apt-get; install git and re-run." >&2
    exit 1
  fi
fi

# Clone or update.
if [ -d "${TARGET_DIR}/.git" ]; then
  echo "[bootstrap] updating ${TARGET_DIR} ..."
  git -C "${TARGET_DIR}" fetch origin "${REPO_BRANCH}"
  git -C "${TARGET_DIR}" checkout "${REPO_BRANCH}"
  git -C "${TARGET_DIR}" pull --ff-only origin "${REPO_BRANCH}"
else
  echo "[bootstrap] cloning ${REPO_URL} (${REPO_BRANCH}) -> ${TARGET_DIR} ..."
  git clone --branch "${REPO_BRANCH}" "${REPO_URL}" "${TARGET_DIR}"
fi

# Hand off to the platform setup (passes through any args, e.g. --no-start).
cd "${TARGET_DIR}"
echo "[bootstrap] running ./deploy/setup.sh $* ..."
exec ./deploy/setup.sh "$@"
