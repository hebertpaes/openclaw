# Deploying OpenClaw on the Azure VM

Automation to build and run the [OpenClaw](https://github.com/pjasicek/OpenClaw)
engine (a reimplementation of *Captain Claw*, 1997) on the
**`openclaw-vm`** Azure virtual machine.

> **Target VM:** `openclaw-vm` (resource group `openclaw-vm_group`,
> subscription `de047b31-…`). These scripts assume a **Debian/Ubuntu** Linux
> VM, which is the Azure default. They do **not** talk to the Azure control
> plane — you run them *on* the VM over SSH.

---

## What each piece does

| Script | Purpose |
| --- | --- |
| `config.env` | All tunables (paths, repo, display, VNC port). Edit here or override via env vars. |
| `install-deps.sh` | Installs the SDL2 build stack, MIDI audio, and Xvfb/VNC (`apt`). |
| `build.sh` | Clones + compiles OpenClaw → `Build_Release/openclaw`. |
| `organize-assets.sh` | **Organizes the download folder**: finds `CLAW.REZ`, drops it next to the binary, and packs `ASSETS.ZIP`. |
| `clean-downloads.sh` | Removes unusable `.dmg` files (macOS images, useless on Linux) from the download folder. |
| `run.sh` | **Activates OpenClaw**: launches it on a virtual display (Xvfb), optionally over VNC. |
| `install-service.sh` | Installs a `systemd` unit so the game runs on boot / restarts on failure. |
| `setup.sh` | Runs deps → build → organize in one go (`--service`, `--run` optional). |

---

## Prerequisites

1. **A running Ubuntu/Debian Azure VM.** In the [Azure Portal](https://portal.azure.com/#@abacs.org.br/resource/subscriptions/de047b31-2275-439a-a162-5596f80161cb/resourceGroups/openclaw-vm_group/providers/Microsoft.Compute/virtualMachines/openclaw-vm/overview),
   make sure `openclaw-vm` shows **Running** (Start it if not), and note its
   public IP / DNS name. *(This must be done by you in the portal — these
   scripts can't power the VM on.)*
2. **SSH access** to the VM (`ssh azureuser@<vm-ip>`).
3. **The original `CLAW.REZ`** from a legitimate copy of *Captain Claw*. It is
   copyrighted and **not redistributable**, so it is not included here — you
   must supply it.

---

## Quick start

From your workstation, copy the repo to the VM and SSH in:

```bash
# 1. Get the deploy scripts onto the VM
scp -r openclaw azureuser@<vm-ip>:~/

# 2. Put your CLAW.REZ where the script will find it (default: ~/Downloads)
ssh azureuser@<vm-ip> 'mkdir -p ~/Downloads'
scp /path/to/CLAW.REZ azureuser@<vm-ip>:~/Downloads/

# 3. Build + organize assets in one shot
ssh azureuser@<vm-ip>
cd ~/openclaw
./deploy/setup.sh
```

Then **activate** the game:

```bash
./deploy/run.sh
```

---

## Viewing / playing it remotely (headless VM)

The VM has no monitor, so `run.sh` renders to a **virtual display** and exposes
it over VNC **bound to localhost only**. Reach it through an SSH tunnel — do
**not** open the VNC port in the Azure Network Security Group:

```bash
# On your machine: tunnel localhost:5900 to the VM's VNC
ssh -L 5900:localhost:5900 azureuser@<vm-ip>

# Then connect any VNC client to:
localhost:5900
```

To run purely headless (e.g. a smoke test, no viewer): `ENABLE_VNC=0 ./deploy/run.sh`.

---

## Run it as a service (starts on boot)

```bash
sudo ./deploy/install-service.sh   # render + enable the unit
sudo systemctl start openclaw
systemctl status openclaw
journalctl -u openclaw -f          # follow logs
```

The service runs `run.sh --headless`, so Xvfb (and VNC on localhost) come up
automatically. Tunnel in with the same `ssh -L` command above to watch it.

---

## Cleaning the download folder

`.dmg` files are macOS disk images and are unusable on the Linux VM. Remove
them from `DOWNLOADS_DIR` with:

```bash
./deploy/clean-downloads.sh --dry-run   # preview what would be deleted
./deploy/clean-downloads.sh             # list, then confirm before deleting
./deploy/clean-downloads.sh --yes       # delete without prompting
```

It targets only `*.dmg` (recursively), so usable assets like `CLAW.REZ` are
left untouched. Deletion is irreversible — it asks before removing anything
unless you pass `--yes`.

## Configuration

Override any value in `config.env` inline:

```bash
OPENCLAW_HOME=/opt/openclaw DOWNLOADS_DIR=/srv/claw SCREEN_GEOMETRY=1920x1080x24 \
  ./deploy/setup.sh
```

Common knobs: `OPENCLAW_REPO` / `OPENCLAW_BRANCH`, `OPENCLAW_HOME`,
`DOWNLOADS_DIR`, `DISPLAY_NUM`, `SCREEN_GEOMETRY`, `ENABLE_VNC`, `VNC_PORT`,
`MAKE_JOBS`.

---

## Troubleshooting

- **`Could not find CLAW.REZ`** — drop the file into `DOWNLOADS_DIR` (default
  `~/Downloads`) and re-run `./deploy/organize-assets.sh`.
- **`openclaw binary not found`** — the build failed; re-run `./deploy/build.sh`
  and read the `cmake`/`make` output.
- **Black screen / poor performance over VNC** — expected on CPU-only VMs
  (software GL rendering). A VM SKU with a GPU improves this.
- **`apt-get not found`** — these scripts target Debian/Ubuntu; adapt
  `install-deps.sh` for other distros.
