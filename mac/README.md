# Running OpenClaw on the MacBook

Automation to build and run the [OpenClaw](https://github.com/pjasicek/OpenClaw)
engine (a reimplementation of *Captain Claw*, 1997) **locally on macOS** — as an
alternative to the Azure VM (see [`../deploy/`](../deploy/) for the VM path).

Works on **Apple Silicon (M1/M2/M3…)** and **Intel** Macs. The scripts are
written for the system `bash` that ships with macOS.

---

## What each piece does

| Script | Purpose |
| --- | --- |
| `config.sh` | Tunables (paths, repo). Edit here or override via env vars. |
| `install-deps.sh` | Installs the SDL2 build stack via **Homebrew**. |
| `build.sh` | Clones + compiles OpenClaw → `Build_Release/openclaw` (auto-detects brew prefix + CPU arch). |
| `organize-assets.sh` | Finds `CLAW.REZ` in your downloads, places it, and packs `ASSETS.ZIP`. |
| `run.sh` | Launches the game in its own window (native display — no VNC needed). |
| `setup.sh` | Runs deps → build → organize in one go (`--run` optional). |

---

## Prerequisites

1. **Homebrew** — install from <https://brew.sh> if you don't have it. The
   scripts check for it and stop with instructions if it's missing.
2. **Xcode Command Line Tools** — `xcode-select --install` (provides the
   compiler/`make`).
3. **The original `CLAW.REZ`** from a legitimate copy of *Captain Claw*. It's
   copyrighted and **not redistributable**, so it's not included — supply your
   own and drop it in `~/Downloads`.

---

## Quick start

```bash
git clone <this-repo> openclaw && cd openclaw
# put your CLAW.REZ where the script will find it
cp /path/to/CLAW.REZ ~/Downloads/

./mac/setup.sh        # deps + build + organize assets
./mac/run.sh          # play
```

Or do it in one line: `./mac/setup.sh --run`.

---

## Step by step (if you prefer)

```bash
./mac/install-deps.sh      # brew install cmake sdl2 sdl2_image sdl2_mixer sdl2_ttf sdl2_gfx tinyxml timidity
./mac/build.sh             # clone + cmake + make
./mac/organize-assets.sh   # place CLAW.REZ + build ASSETS.ZIP
./mac/run.sh               # launch
```

---

## Configuration

Override any value from `config.sh` inline:

```bash
OPENCLAW_HOME=~/Games/OpenClaw DOWNLOADS_DIR=~/claw ./mac/setup.sh
```

Common knobs: `OPENCLAW_REPO` / `OPENCLAW_BRANCH`, `OPENCLAW_HOME`,
`DOWNLOADS_DIR`, `MAKE_JOBS`.

---

## Troubleshooting

- **`Homebrew is not installed`** — install it from <https://brew.sh>, then
  re-run.
- **Linker / SDL2 errors on Apple Silicon** — `build.sh` already passes
  `-DCMAKE_PREFIX_PATH=$(brew --prefix)` and `-DCMAKE_OSX_ARCHITECTURES=$(uname -m)`.
  If problems persist, make sure brew itself is the native-arch install
  (`which brew` → `/opt/homebrew/bin/brew` on Apple Silicon).
- **`Could not find CLAW.REZ`** — drop the file into `~/Downloads` (or set
  `DOWNLOADS_DIR`) and re-run `./mac/organize-assets.sh`.
- **No music** — install/verify `timidity` (`brew install timidity`); gameplay
  is unaffected if it's missing.
- **"These scripts target macOS"** — you're not on a Mac; use
  [`../deploy/`](../deploy/) for the Linux Azure VM instead.
