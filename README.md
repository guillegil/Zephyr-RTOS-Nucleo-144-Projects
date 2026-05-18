# nucleo-144

Zephyr RTOS firmware projects for the STM32 Nucleo-144 (F767ZI) and future custom boards.

Built on a shared Zephyr workspace (T1 topology): one Zephyr install per version lives in `~/.zephyr/<version>/`, this repo holds applications, custom boards, and project-specific config.

## Apps

| App           | Description                                            |
| ------------- | ------------------------------------------------------ |
| `hello_world` | Two threads ticking at different rates, mutex-guarded  |
| `blinky`      | Three-LED blinker, one thread per LED, drift-free      |

## Requirements

- **OS**: Linux, macOS, or Windows (with Git Bash / WSL)
- **Tools**: `git`, `just`, `uv`, `cmake`, `ninja`, `dtc`, `openocd`
- **Board**: STM32 Nucleo-144 F767ZI (or any board with `led0`..`led2` aliases)
- A serial terminal: `tio`, `picocom`, or `screen` on Unix; PuTTY/MobaXterm on Windows

## Installing `just`

`just` is the command runner this project uses. Install it for your OS:

### Linux

**Arch / Manjaro:**
```bash
sudo pacman -S just
```

**Debian / Ubuntu (22.04+):**
```bash
sudo apt install just
```

**Fedora:**
```bash
sudo dnf install just
```

**Any Linux (cargo):**
```bash
cargo install just
```

### macOS

**Homebrew (recommended):**
```bash
brew install just
```

**MacPorts:**
```bash
sudo port install just
```

### Windows

**winget (recommended, Windows 10+):**
```powershell
winget install Casey.Just
```

**Scoop:**
```powershell
scoop install just
```

**Chocolatey:**
```powershell
choco install just
```

> On Windows, run subsequent project commands from **Git Bash** (bundled with Git for Windows), not `cmd.exe` or PowerShell. The `justfile` is configured to use bash and assumes Unix-style paths.

Verify the install:
```bash
just --version
```

## Installing the other host tools

### Arch Linux
```bash
sudo pacman -S --needed git uv cmake ninja gperf dtc openocd stlink tio base-devel
```

### Debian / Ubuntu
```bash
sudo apt install git cmake ninja-build gperf device-tree-compiler \
    openocd stlink-tools tio xz-utils file make
# uv (not in apt): use the official installer
curl -LsSf https://astral.sh/uv/install.sh | sh
```

### macOS
```bash
brew install git uv cmake ninja gperf dtc openocd tio
```

### Windows
```powershell
winget install Git.Git astral-sh.uv Kitware.CMake Ninja-build.Ninja
# OpenOCD + dtc: install via MSYS2 or use the binaries bundled with the Zephyr SDK
```

## One-time setup

### 1. Clone this repo

```bash
git clone git@github.com:<you>/nucleo-144.git ~/projects/nucleo-144
cd ~/projects/nucleo-144
```

### 2. Install Zephyr at the version this repo pins

The version is in `.zephyr-version`:

```bash
ZV=$(cat .zephyr-version)         # e.g. v4.3
mkdir -p ~/.zephyr
uv venv --seed ~/.zephyr/$ZV/.venv
source ~/.zephyr/$ZV/.venv/bin/activate
uv pip install west

west init -m https://github.com/zephyrproject-rtos/zephyr --mr ${ZV}.0 ~/.zephyr/$ZV
cd ~/.zephyr/$ZV
west update
west zephyr-export
uv pip install -r zephyr/scripts/requirements.txt
```

### 3. Install the Zephyr SDK (once, shared across versions)

```bash
west sdk install -t arm-zephyr-eabi -b ~/.zephyr/sdk
```

### 4. Linux only — udev rules for ST-LINK

```bash
sudo curl -L https://raw.githubusercontent.com/openocd-org/openocd/master/contrib/60-openocd.rules \
    -o /etc/udev/rules.d/60-openocd.rules
sudo udevadm control --reload-rules && sudo udevadm trigger
sudo usermod -aG uucp,plugdev $USER
```
Log out and back in.

## Daily usage

All workflow is driven by `just` from the repo root. Run `just` with no args to list recipes.

```bash
cd ~/projects/nucleo-144

just build blinky         # build apps/blinky/ for nucleo_f767zi
just flash blinky         # flash via openocd
just monitor              # serial console on /dev/ttyACM0 @ 115200
just clean blinky         # remove apps/blinky/build/
```

Different board (custom or upstream):
```bash
just build hello_world widget_v1
```

Run tests with Twister:
```bash
just test
```

## Project layout

```
nucleo-144/
├── .zephyr-version       # which Zephyr to use (~/.zephyr/<this>/)
├── justfile              # build / flash / debug recipes
├── .clangd               # clangd flag overrides for Zephyr
├── apps/
│   ├── hello_world/
│   │   ├── CMakeLists.txt
│   │   ├── prj.conf
│   │   └── src/main.c
│   └── blinky/
│       └── ...
├── boards/               # custom board definitions (BOARD_ROOT)
├── dts/bindings/         # custom devicetree bindings (DTS_ROOT)
├── drivers/              # out-of-tree drivers (future)
└── lib/                  # shared application code (future)
```

`build/` directories are created per app (`apps/<name>/build/`) and gitignored.

## Editor setup (VSCode)

```bash
code ~/projects/nucleo-144
```

The repo includes:
- `.vscode/settings.json` — disables MS C/C++ parser, configures clangd
- `.vscode/tasks.json` — `Ctrl+Shift+B` runs `just build`
- `.vscode/extensions.json` — recommends `clangd` and `cpptools`

clangd auto-discovers `apps/<name>/build/compile_commands.json` after the first build. First-time indexing of Zephyr takes ~30 seconds; afterwards it's cached and fast.

## Adding a new app

```bash
just new my_app
just build my_app
just flash my_app
```

This scaffolds `apps/my_app/{CMakeLists.txt, prj.conf, src/main.c}` ready to edit.

## Adding a custom board

Drop the board under `boards/<vendor>/<board_name>/` (HWMv2 format: `board.yml`, `Kconfig.<name>`, `<name>_defconfig`, `<name>.dts`, `<name>.yaml`). `BOARD_ROOT` is already set to the repo root, so `just build <app> <board_name>` finds it.

Easiest start: copy `~/.zephyr/<version>/zephyr/boards/st/nucleo_f767zi/` into `boards/<your_vendor>/`, rename files, and edit the DTS to match your hardware.

## Upgrading Zephyr

To move this project to a newer Zephyr release:

1. Install the new version under `~/.zephyr/v4.5/` (repeat step 2 above with the new tag).
2. Edit `.zephyr-version` to `v4.5`.
3. `just rebuild <app>` to verify nothing broke.
4. Commit `.zephyr-version`.

The old version stays installed for other projects pinned to it.

## Troubleshooting

**`west: command not found`** — the `.venv` isn't on PATH. The `justfile` handles this automatically; if running west manually, `source ~/.zephyr/$(cat .zephyr-version)/.venv/bin/activate` first.

**`Permission denied` on `/dev/ttyACM0`** — udev rules not applied or group membership not active. Check `groups | grep uucp`; if missing, re-run step 4 of setup and log out fully.

**clangd shows red squiggles on Zephyr headers** — run `just build <app>` at least once so `compile_commands.json` exists, then in VSCode: `Ctrl+Shift+P` → `clangd: Restart language server`.

**`BOARD_ROOT element without a 'boards' subdirectory`** — `boards/` got deleted. Recreate it: `mkdir -p boards dts/bindings && touch boards/.gitkeep dts/bindings/.gitkeep`.

**`just` complains about shell on Windows** — make sure you're running it from Git Bash, not `cmd` or PowerShell. The `justfile` forces `bash` via `set shell := ["bash", "-uc"]`.

## License

[Pick one: MIT / Apache-2.0 / proprietary]