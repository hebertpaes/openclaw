# Running the OpenClaw AI gateway on the MacBook

Automation to install and run the [OpenClaw](https://github.com/openclaw/openclaw)
AI assistant gateway (🦞 — <https://openclaw.ai>) **locally on macOS**, so the
same agent runs on your Mac as on the [Azure VM](../deploy/).

Works on **Apple Silicon** and **Intel**. The gateway listens on **port 18789**
(`http://localhost:18789`).

---

## What each piece does

| Script | Purpose |
| --- | --- |
| `config.sh` | Tunables: model, port, Node formula. |
| `install.sh` | Installs Node + `openclaw` globally via **Homebrew**/npm. |
| `configure.sh` | Scaffolds `~/.openclaw/openclaw.json` with the Claude model (no secrets). |
| `start.sh` | Runs `openclaw onboard --install-daemon` (launchd) and shows status. |
| `setup.sh` | install → configure → start, in one go. |

---

By default these scripts use the **Codex** backend (OpenAI Codex app-server, via
the `@openclaw/codex` plugin); set `OPENCLAW_BACKEND=claude` for Anthropic/Claude.

## Prerequisites

1. **Homebrew** — <https://brew.sh> (the scripts check for it).
2. **Provider credentials** (never written to the repo or config):
   - **Codex (default):** `OPENAI_API_KEY`, or ChatGPT/Codex login during onboarding.
   - **Claude:** `ANTHROPIC_API_KEY` (when `OPENCLAW_BACKEND=claude`).

---

## Quick start

```bash
git clone https://github.com/hebertpaes/openclaw.git
cd openclaw && git checkout claude/vigilant-hamilton-ig74tu   # until merged to main

export OPENAI_API_KEY=sk-...          # Codex backend (or log in via ChatGPT/Codex)
./mac/setup.sh
# For Claude instead:  OPENCLAW_BACKEND=claude ANTHROPIC_API_KEY=sk-ant-... ./mac/setup.sh
```

`setup.sh` installs Node + OpenClaw, adds the Codex plugin, writes the config,
then runs `openclaw onboard --install-daemon`. Onboarding is **interactive the
first time** (Codex auth + provider/channel setup) and installs a launchd
service so the gateway runs in the background.

Open the dashboard at **<http://localhost:18789>**.

Manage it:

```bash
openclaw gateway status
openclaw gateway stop
```

---

## Choosing the backend

- **Codex** (default): `OPENCLAW_BACKEND=codex` — `install.sh` adds the
  `@openclaw/codex` plugin; auth via `OPENAI_API_KEY` or ChatGPT/Codex login.
  The Codex app-server discovers its own model.
- **Claude**: `OPENCLAW_BACKEND=claude` — `configure.sh` writes `agent.model`
  (default `anthropic/claude-sonnet-4-6`, override with `OPENCLAW_MODEL`); auth
  via `ANTHROPIC_API_KEY`.

---

## Step by step

```bash
./mac/install.sh        # brew node + npm i -g openclaw
./mac/configure.sh      # ~/.openclaw/openclaw.json
./mac/start.sh          # onboard + install daemon
# or: ./mac/start.sh --foreground
```

---

## Connecting to GitHub

`install.sh` adds the **GitHub plugin** when `OPENCLAW_GITHUB=1` (default); the
agent authenticates with `GITHUB_TOKEN` from the environment. Create a
fine-grained PAT (`repo` + `read:org`) at <https://github.com/settings/tokens>
and put it in `secrets.env`:

```bash
export OPENCLAW_GITHUB=1
export GITHUB_TOKEN=github_pat_...
```

Set `OPENCLAW_GITHUB=0` to skip. See [`../deploy/README.md`](../deploy/README.md#connecting-to-github)
for details.

## Troubleshooting

- **`Homebrew is not installed`** — install from <https://brew.sh>, then re-run.
- **`node` not on PATH after install** — for a versioned formula add
  `export PATH="$(brew --prefix)/opt/node@24/bin:$PATH"` to `~/.zshrc`.
- **provider key not set** — export `OPENAI_API_KEY` (Codex) or
  `ANTHROPIC_API_KEY` (Claude), or let `openclaw onboard` prompt you.
- **"These scripts target macOS"** — you're not on a Mac; use [`../deploy/`](../deploy/)
  for the Azure VM.
