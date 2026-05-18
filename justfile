# Force bash everywhere (Git Bash on Windows)
set shell := ["bash", "-uc"]
set positional-arguments

# ---------- Paths derived from .zephyr-version ----------
zephyr_version := `cat .zephyr-version`
zephyr_root    := home_directory() / ".zephyr" / zephyr_version
sdk_root       := home_directory() / ".zephyr" / "sdk" / "zephyr-sdk-0.17.0"
venv_bin       := if os_family() == "windows" {
    zephyr_root / ".venv" / "Scripts"
} else {
    zephyr_root / ".venv" / "bin"
}
project_root   := justfile_directory()

# Exported to every recipe
export ZEPHYR_BASE             := zephyr_root / "zephyr"
export ZEPHYR_SDK_INSTALL_DIR  := sdk_root
export BOARD_ROOT              := project_root
export DTS_ROOT                := project_root
export PATH                    := venv_bin + ":" + env_var("PATH")

# ---------- Defaults ----------
board := "nucleo_f767zi"
app   := "hello_world"

# List recipes
default:
    @just --list

# Show resolved env (sanity check)
info:
    @echo "Zephyr version : {{zephyr_version}}"
    @echo "ZEPHYR_BASE    : $ZEPHYR_BASE"
    @echo "SDK            : $ZEPHYR_SDK_INSTALL_DIR"
    @echo "Board          : {{board}}"

# Build an app: `just build` or `just build blinky nucleo_f767zi`
build app=app board=board:
    west build -p auto -b {{board}} -d apps/{{app}}/build apps/{{app}}

# Pristine build
rebuild app=app board=board:
    west build -p always -b {{board}} -d apps/{{app}}/build apps/{{app}}

# Flash via openocd
flash app=app:
    west flash -d apps/{{app}}/build --runner openocd

# Debug
debug app=app:
    west debug -d apps/{{app}}/build --runner openocd

# Clean one app's build dir
clean app=app:
    rm -rf apps/{{app}}/build

# Wipe all build dirs
clean-all:
    find apps -type d -name build -exec rm -rf {} +

# Serial monitor (override with `just monitor /dev/ttyACM1`)
monitor port="/dev/ttyACM0" baud="115200":
    tio -b {{baud}} {{port}}

# Run Twister tests
test:
    west twister -T tests/ -p {{board}}

# Update Zephyr to whatever revision its west.yml references
update:
    cd "$ZEPHYR_BASE/.." && west update