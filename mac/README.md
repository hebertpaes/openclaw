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

## Prerequisites

1. **Homebrew** — <https://brew.sh> (the scripts check for it).
2. **An Anthropic API key** for Claude — exported as `ANTHROPIC_API_KEY`
   (never written to the repo or config).

---

## Quick start

```bash
git clone https://github.com/hebertpaes/openclaw.git
cd openclaw && git checkout claude/vigilant-hamilton-ig74tu   # until merged to main

export ANTHROPIC_API_KEY=sk-ant-...
./mac/setup.sh
```

`setup.sh` installs Node + OpenClaw, writes the config, then runs
`openclaw onboard --install-daemon`. Onboarding is **interactive the first
time** (provider/channel setup) and installs a launchd service so the gateway
runs in the background.

Open the dashboard at **<http://localhost:18789>**.

Manage it:

```bash
openclaw gateway status
openclaw gateway stop
```

---

## Choosing the Claude model

`configure.sh` writes `~/.openclaw/openclaw.json` with
`"model": "anthropic/claude-sonnet-4-6"`. Override with
`OPENCLAW_MODEL=anthropic/<model-id> ./mac/setup.sh`; confirm the exact id in the
[docs](https://docs.openclaw.ai).

---

## Step by step

```bash
./mac/install.sh        # brew node + npm i -g openclaw
./mac/configure.sh      # ~/.openclaw/openclaw.json
./mac/start.sh          # onboard + install daemon
# or: ./mac/start.sh --foreground
```

---

## Troubleshooting

- **`Homebrew is not installed`** — install from <https://brew.sh>, then re-run.
- **`node` not on PATH after install** — for a versioned formula add
  `export PATH="$(brew --prefix)/opt/node@24/bin:$PATH"` to `~/.zshrc`.
- **`ANTHROPIC_API_KEY is not set`** — export it, or let `openclaw onboard`
  prompt you.
- **"These scripts target macOS"** — you're not on a Mac; use [`../deploy/`](../deploy/)
  for the Azure VM.
