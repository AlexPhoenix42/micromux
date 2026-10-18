#!/usr/bin/env bash
# install.sh — install micro + tmux + flake8 + micromux configs.
# Supports Ubuntu/Debian and Void Linux.
#
# Flags:
#   --keep-existing   Don't overwrite existing configs (install binaries + launcher only)
#   --force           Overwrite configs without prompting (still backs up)
#   --dry-run         Show what would happen, change nothing
#   --no-sudo         Never invoke sudo (Debian/Ubuntu only; Void falls back to its normal flow)
#   -h, --help        Show this help
#
# Must be run from a checked-out copy of the repo. Piped installs are refused.

set -euo pipefail

# --- refuse piped installs (script needs the repo) ---
if [ ! -t 0 ]; then
    cat >&2 <<'EOF'
!! This installer must be run from a checked-out copy of the repo.
   It needs the local configs/ directory to copy files from.

   Do this instead:

       git clone https://github.com/YOURNAME/micromux.git
       cd micromux
       ./install.sh

EOF
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEEP_EXISTING=0
FORCE=0
DRY_RUN=0
NO_SUDO=0

# --- parse args ---
for arg in "$@"; do
    case "$arg" in
        --keep-existing) KEEP_EXISTING=1 ;;
        --force)         FORCE=1 ;;
        --dry-run)       DRY_RUN=1 ;;
        --no-sudo)       NO_SUDO=1 ;;
        -h|--help)
            sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

# --- helpers ---
run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

# safe_install SRC DEST LABEL
# - DEST doesn't exist     → copy
# - --keep-existing        → skip
# - otherwise              → back up (timestamped), then copy
# - prompts unless --force or --dry-run
safe_install() {
    local src="$1" dest="$2" label="$3"

    if [ ! -e "$dest" ]; then
        echo ">> Installing $label to $dest"
        run mkdir -p "$(dirname "$dest")"
        run cp "$src" "$dest"
        return 0
    fi

    if [ "$KEEP_EXISTING" -eq 1 ]; then
        echo ">> $dest already exists — keeping it (--keep-existing)"
        return 0
    fi

    local stamp backup
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="${dest}.bak.${stamp}"

    if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
        echo
        echo "!! $dest already exists."
        echo "   Backing it up to: $backup"
        printf "   Overwrite %s? [y/N] " "$dest"
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS]) ;;
            *)
                echo "   Skipped $label."
                return 0
                ;;
        esac
    fi

    echo ">> Backing up existing $label → $backup"
    run cp "$dest" "$backup"
    echo ">> Installing $label to $dest"
    run cp "$src" "$dest"
    echo "   (to restore your old config: mv '$backup' '$dest')"
}

# --- detect distro ---
if command -v apt >/dev/null 2>&1; then
    DISTRO="debian"
elif command -v xbps-install >/dev/null 2>&1; then
    DISTRO="void"
else
    echo "Unsupported distro. Install micro, tmux, and flake8 manually, then copy configs." >&2
    exit 1
fi

echo ">> Installing micro, tmux, and flake8 ($DISTRO)"

case "$DISTRO" in
    debian)
        if [ "$NO_SUDO" -eq 1 ]; then
            echo "   --no-sudo: never invoking sudo"

            # tmux: cannot be installed user-local — refuse if missing
            if ! command -v tmux >/dev/null 2>&1; then
                cat >&2 <<'EOF'
!! tmux is required but not installed, and --no-sudo forbids apt.
   Install it once with:

       sudo apt install tmux

   Then re-run this installer.
EOF
                exit 1
            fi
            echo "   tmux already installed"

            # micro: install to ~/bin (user-local)
            if ! command -v micro >/dev/null 2>&1; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    echo "  [dry-run] would download micro to ~/bin"
                else
                    mkdir -p "$HOME/bin"
                    pushd "$HOME/bin" >/dev/null
                    if curl -fsSL https://getmic.ro | bash; then
                        echo "   installed micro to $HOME/bin (user-local)"
                    else
                        popd >/dev/null
                        cat >&2 <<'EOF'

!! Failed to download micro from getmic.ro.
   Check your internet connection, or install micro manually:
   https://github.com/zyedidia/micro#installation
EOF
                        exit 1
                    fi
                    popd >/dev/null
                fi
            else
                echo "   micro already installed"
            fi

            # flake8: bootstrap pip to ~/.local if missing, then install --user.
            # Handles PEP 668 ("externally managed") systems via --break-system-packages.
            if ! command -v flake8 >/dev/null 2>&1; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    echo "  [dry-run] would ensure pip exists (bootstrap to ~/.local if needed), then install flake8 via pip --user"
                else
                    # Step A: bootstrap pip to ~/.local if `python3 -m pip` fails
                    if ! python3 -m pip --version >/dev/null 2>&1; then
                        echo "   pip not found; bootstrapping to ~/.local (no sudo)..."
                        TMP_PIP="$(mktemp)"
                        if curl -fsSL https://bootstrap.pypa.io/get-pip.py -o "$TMP_PIP" && \
                           python3 "$TMP_PIP" --user --quiet; then
                            rm -f "$TMP_PIP"
                            export PATH="$HOME/.local/bin:$PATH"
                            echo "   pip installed to $HOME/.local/bin"
                        else
                            rm -f "$TMP_PIP"
                            cat >&2 <<'EOF'

!! pip is not available, and bootstrapping it to ~/.local failed.
   Options:
   1. Install pip once (needs sudo, one time only):
          sudo apt install python3-pip
      Then re-run: ./install.sh --no-sudo

   2. Install flake8 system-wide (needs sudo, one time only):
          sudo apt install flake8
      Then re-run: ./install.sh --no-sudo

   3. Run the full installer without --no-sudo:
          ./install.sh
EOF
                            exit 1
                        fi
                    fi

                    # Step B: install flake8, handling PEP 668
                    if python3 -m pip install --user flake8 2>/dev/null; then
                        echo "   installed flake8 via pip --user"
                    elif python3 -m pip install --user --break-system-packages flake8 2>/dev/null; then
                        echo "   installed flake8 via pip --user (--break-system-packages for PEP 668)"
                    else
                        cat >&2 <<'EOF'

!! Could not install flake8 via pip --user.
   Options:
   1. Install system-wide (needs sudo, one time only):
          sudo apt install flake8

   2. Run the full installer without --no-sudo:
          ./install.sh
EOF
                        exit 1
                    fi
                fi
            else
                echo "   flake8 already installed"
            fi
        else
            run sudo apt update
            for pkg in tmux flake8; do
                if command -v "$pkg" >/dev/null 2>&1; then
                    echo "   $pkg already installed"
                else
                    run sudo apt install -y "$pkg"
                fi
            done
            if ! command -v micro >/dev/null 2>&1; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    echo "  [dry-run] would download micro and install to /usr/local/bin"
                else
                    curl -fsSL https://getmic.ro | bash
                    sudo mv micro /usr/local/bin/
                fi
            else
                echo "   micro already installed"
            fi
        fi
        ;;
    void)
        if [ "$NO_SUDO" -eq 1 ]; then
            echo "   Note: --no-sudo is a no-op on Void (xbps requires root). Continuing normally."
        fi
        run sudo xbps-install -Sy
        for pkg in tmux micro flake8; do
            if command -v "$pkg" >/dev/null 2>&1; then
                echo "   $pkg already installed"
            else
                run sudo xbps-install -y "$pkg"
            fi
        done
        ;;
esac

if ! command -v flake8 >/dev/null 2>&1; then
    echo "!! flake8 not found on PATH. Trying pip fallback..."
    run python3 -m pip install --user flake8 || \
        echo "!! Could not install flake8. Linting will be disabled."
fi

# --- micro config ---
echo ">> Installing micro config"
safe_install "$REPO_DIR/configs/micro-settings.json" \
             "$HOME/.config/micro/settings.json" \
             "micro settings"

# --- tmux config: pick the location tmux actually reads ---
echo ">> Installing tmux config"

TMUX_DEST=""
if [ -f "$HOME/.tmux.conf" ]; then
    TMUX_DEST="$HOME/.tmux.conf"
elif [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    TMUX_DEST="$HOME/.config/tmux/tmux.conf"
elif [ -d "$HOME/.config/tmux" ]; then
    TMUX_DEST="$HOME/.config/tmux/tmux.conf"
else
    TMUX_DEST="$HOME/.tmux.conf"
fi

if [ -f "$HOME/.tmux.conf" ] && [ -f "$HOME/.config/tmux/tmux.conf" ]; then
    echo "!! Note: both tmux config locations exist."
    echo "   tmux reads ~/.tmux.conf and ignores ~/.config/tmux/tmux.conf."
fi

echo "   Using: $TMUX_DEST"
safe_install "$REPO_DIR/configs/tmux.conf" "$TMUX_DEST" "tmux config"

# --- micromux launcher ---
echo ">> Installing micromux to ~/bin"
run mkdir -p "$HOME/bin"
safe_install "$REPO_DIR/micromux" "$HOME/bin/micromux" "micromux launcher"
if [ "$DRY_RUN" -eq 0 ]; then
    chmod +x "$HOME/bin/micromux"
fi

# --- PATH (bash) ---
if ! grep -q 'HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] would add ~/bin to PATH in ~/.bashrc"
    else
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        echo ">> Added ~/bin to PATH in ~/.bashrc"
    fi
fi

# --- PATH (fish, only if user has a fish config) ---
FISH_CONFIG="$HOME/.config/fish/config.fish"
if [ -f "$FISH_CONFIG" ] && ! grep -qx 'fish_add_path ~/bin' "$FISH_CONFIG"; then
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] would add ~/bin to fish PATH in $FISH_CONFIG"
    else
        echo '' >> "$FISH_CONFIG"
        echo '# added by micromux install.sh' >> "$FISH_CONFIG"
        echo 'fish_add_path ~/bin' >> "$FISH_CONFIG"
        echo ">> Added ~/bin to fish PATH in $FISH_CONFIG"
    fi
fi

echo
echo "Done. Restart your shell (or run: source ~/.bashrc), then:"
echo
echo "    micromux myfile.py"
echo
echo "Linter: flake8 runs automatically on save in micro."

