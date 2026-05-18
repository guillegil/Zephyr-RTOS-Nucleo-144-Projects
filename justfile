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


new name:
    @if [ -d "apps/{{name}}" ]; then echo "apps/{{name}} already exists"; exit 1; fi
    @mkdir -p apps/{{name}}/src
    @printf 'cmake_minimum_required(VERSION 3.20.0)\nfind_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})\nproject({{name}})\n\ntarget_sources(app PRIVATE src/main.c)\n' > apps/{{name}}/CMakeLists.txt
    @printf '# Kconfig overrides for {{name}}\n' > apps/{{name}}/prj.conf
    @printf '#include <zephyr/kernel.h>\n#include <zephyr/sys/printk.h>\n\nint main(void)\n{\n\tprintk("Hello from {{name}} on %%s!\\n", CONFIG_BOARD);\n\treturn 0;\n}\n' > apps/{{name}}/src/main.c
    @echo "Created apps/{{name}} — build with: just build {{name}}"

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