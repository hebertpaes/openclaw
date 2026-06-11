# Deploying the OpenClaw AI gateway on the Azure VM

Automation to install and run the [OpenClaw](https://github.com/openclaw/openclaw)
AI assistant gateway (the 🦞 self-hosted agent — <https://openclaw.ai>) on the
**`openclaw-vm`** Azure virtual machine.

> **Target VM:** `openclaw-vm` (resource group `openclaw-vm_group`). These
> scripts assume a **Debian/Ubuntu** VM (the Azure default) and run *on* the VM
> over SSH — they don't talk to the Azure control plane.

The gateway is a Node app that listens on **port 18789** (the local
dashboard/API) and bridges your chat apps to a Claude agent.

---

## What each piece does

| Script | Purpose |
| --- | --- |
| `config.env` | Tunables: model, port, Node version, `VM_HOST`. |
| `install.sh` | Installs Node (via NodeSource) + `npm i -g openclaw@latest`. |
| `configure.sh` | Scaffolds `~/.openclaw/openclaw.json` with the Claude model (no secrets). |
| `start.sh` | Runs `openclaw onboard --install-daemon` (systemd user service) and shows status. |
| `connect.sh` | Run **on your Mac**: SSH-tunnels the dashboard and prints `http://localhost:18789`. |
| `setup.sh` | install → configure → start, in one go. |

---

## Prerequisites

1. **A running Ubuntu/Debian Azure VM.** In the [Azure Portal](https://portal.azure.com/#@abacs.org.br/resource/subscriptions/de047b31-2275-439a-a162-5596f80161cb/resourceGroups/openclaw-vm_group/providers/Microsoft.Compute/virtualMachines/openclaw-vm/overview),
   make sure `openclaw-vm` is **Running** and note its public IP. *(You do this
   in the portal — the scripts can't power the VM on.)*
2. **SSH access** (`ssh azureuser@<vm-ip>`).
3. **An Anthropic API key** for Claude. Export it as `ANTHROPIC_API_KEY` — it is
   never written to the repo or the config file.

---

## Quick start

```bash
# 1. Copy the repo to the VM and SSH in
scp -r openclaw azureuser@<vm-ip>:~/
ssh azureuser@<vm-ip>
cd ~/openclaw

# 2. Provide your Claude API key (used by the gateway at runtime)
export ANTHROPIC_API_KEY=sk-ant-...

# 3. Install + configure + start the daemon
./deploy/setup.sh
```

`setup.sh` installs Node + OpenClaw, writes the config, then runs
`openclaw onboard --install-daemon`. Onboarding is **interactive the first
time** — it walks you through the provider/channel (WhatsApp, Telegram, …) and
installs a systemd **user** service that survives reboots.

Manage it afterwards:

```bash
openclaw gateway status
systemctl --user status openclaw     # the daemon unit
journalctl --user -u openclaw -f     # logs
```

---

## Reaching the dashboard from your Mac

The gateway listens on `localhost:18789` on the VM. Reach it through an SSH
tunnel — nothing is opened in the Azure NSG:

```bash
# On your Mac:
export VM_HOST=azureuser@<vm-ip>     # public IP from the Azure Portal
./deploy/connect.sh                  # opens the tunnel and prints the URL
# then open  http://localhost:18789
```

`./deploy/connect.sh --print` shows the command without connecting.

---

## Choosing the Claude model

`configure.sh` writes `~/.openclaw/openclaw.json`:

```json
{
  "agent": {
    "model": "anthropic/claude-sonnet-4-6"
  }
}
```

Override with `OPENCLAW_MODEL=anthropic/<model-id> ./deploy/setup.sh`. Confirm
the exact model id your OpenClaw version expects in the
[docs](https://docs.openclaw.ai).

---

## Step by step (if you prefer)

```bash
./deploy/install.sh        # Node + openclaw
./deploy/configure.sh      # ~/.openclaw/openclaw.json
./deploy/start.sh          # onboard + install daemon
# or: ./deploy/start.sh --foreground   # run in the foreground for debugging
```

---

## Security notes

- OpenClaw is an autonomous agent that can run shell commands and read/write
  files. Treat the VM and the API key accordingly.
- Keep the gateway on `localhost` + SSH tunnel rather than exposing 18789 to the
  internet. If you must expose it, put it behind auth + TLS and an NSG rule.
- `ANTHROPIC_API_KEY` is read from the environment; never commit it.

---

## Troubleshooting

- **`ANTHROPIC_API_KEY is not set`** — `export ANTHROPIC_API_KEY=sk-ant-...`
  before `setup.sh`/`start.sh`, or let `openclaw onboard` prompt you.
- **`apt-get not found`** — these scripts target Debian/Ubuntu; adapt
  `install.sh` for another distro, or use the Docker install
  (<https://docs.openclaw.ai/install/docker>).
- **Node too old** — `install.sh` installs Node `NODE_MAJOR` (default 24) when
  the system Node is < 22.19.
