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
| `run.sh` | **Activates OpenClaw**: launches it on a virtual display (Xvfb), prints the VM's local IP, and serves VNC (localhost or, with `VNC_EXPOSE=1`, the VM's IP). |
| `connect.sh` | Run **on your Mac**: opens the SSH tunnel to the VM (`VM_HOST`) and prints the `vnc://localhost:5900` URL. |
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
it over VNC. When it starts, it prints the **VM's local IP** (auto-detected via
`hostname -I`) and the exact connection command.

### Option A — SSH tunnel (default, recommended, secure)

VNC is **bound to localhost** and you reach it through an SSH tunnel — nothing
is opened in the Azure Network Security Group. Set `VM_HOST` to your VM's SSH
target and use the helper:

```bash
# On your Mac: set the VM address once, then open the tunnel
export VM_HOST=azureuser@<vm-ip>      # <vm-ip> = public IP from the Azure Portal
./deploy/connect.sh                   # opens ssh -L 5900:localhost:5900 and prints the URL

# Then connect a VNC client to:
vnc://localhost:5900                  # on macOS: open vnc://localhost:5900
```

`./deploy/connect.sh --print` just prints the commands without connecting.

### Option B — VNC on the VM's IP (no tunnel, less secure)

To connect straight to the VM's IP without a tunnel, run the game with VNC
exposed on the network. This **requires a password** and an **inbound rule for
the VNC port in the Azure NSG**:

```bash
VNC_EXPOSE=1 VNC_PASSWORD='choose-a-strong-pass' ./deploy/run.sh
# run.sh prints:  vnc://<vm-ip>:5900
```

If `VNC_EXPOSE=1` but no `VNC_PASSWORD` is set, `run.sh` refuses to expose VNC
and falls back to localhost-only.

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

Connection / VNC exposure knobs:

| Variable | Purpose |
| --- | --- |
| `VM_HOST` | VM SSH target for `connect.sh`, e.g. `azureuser@20.30.40.50`. |
| `VNC_EXPOSE` | `0` (default) = localhost only (SSH tunnel); `1` = listen on the VM's IP. |
| `VNC_PASSWORD` | Required when `VNC_EXPOSE=1`; sets the VNC password. |

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
