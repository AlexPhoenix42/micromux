#!/usr/bin/env bash
# install.sh — install micro, tmux, flake8, and micromux.
# Supports Ubuntu/Debian and Void Linux.
#
# Never modifies native tmux configuration.
# PATH setup only appends a missing entry to an existing shell config.
#
# Flags:
#   --keep-existing   Don't overwrite existing configs
#   --force           Overwrite managed configs without prompting (backs up)
#   --dry-run         Show what would happen, change nothing
#   --no-sudo         Never invoke sudo (Debian/Ubuntu only; Void uses normal flow)
#   -h, --help        Show this help
#
# Must be run from a checked-out copy of the repo.

set -euo pipefail

if [ ! -t 0 ]; then
    cat >&2 <<'EOF'
!! Run this installer from a checked-out copy of the repository.
   It needs the local configs/ directory.
EOF
    exit 1
fi

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KEEP_EXISTING=0
FORCE=0
DRY_RUN=0
NO_SUDO=0

for arg in "$@"; do
    case "$arg" in
        --keep-existing) KEEP_EXISTING=1 ;;
        --force)         FORCE=1 ;;
        --dry-run)       DRY_RUN=1 ;;
        --no-sudo)       NO_SUDO=1 ;;
        -h|--help)
            printf '%s\n' \
                "Usage: ./install.sh [OPTIONS]" \
                "  --keep-existing  Preserve existing managed configs" \
                "  --force          Overwrite managed configs after backup" \
                "  --dry-run        Show actions without changing anything" \
                "  --no-sudo        Avoid sudo where supported" \
                "  -h, --help       Show this help"
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$arg" >&2
            exit 1
            ;;
    esac
done

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        printf '  [dry-run]'
        printf ' %q' "$@"
        printf '\n'
    else
        "$@"
    fi
}

# safe_install SRC DEST LABEL
safe_install() {
    local src="$1" dest="$2" label="$3"

    if [ ! -e "$dest" ]; then
        echo ">> Installing $label to $dest"
        run mkdir -p "$(dirname "$dest")"
        run cp -- "$src" "$dest"
        return 0
    fi

    if [ "$KEEP_EXISTING" -eq 1 ]; then
        echo ">> Keeping existing $label: $dest"
        return 0
    fi

    local stamp backup answer
    stamp="$(date +%Y%m%d-%H%M%S)"
    backup="${dest}.bak.${stamp}"

    if [ "$FORCE" -eq 0 ]; then
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] Would ask before replacing $dest"
            echo "  [dry-run] Would back up existing file to $backup"
            return 0
        fi

        printf '\n!! %s already exists.\n' "$dest"
        printf '   Replace it after backing it up? [y/N] '
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS]) ;;
            *)
                echo "   Keeping existing $label"
                return 0
                ;;
        esac
    fi

    echo ">> Backing up $dest to $backup"
    run cp -- "$dest" "$backup"
    echo ">> Installing $label to $dest"
    run cp -- "$src" "$dest"
}

append_line_if_missing() {
    local file="$1" line="$2" label="$3"

    if [ ! -f "$file" ]; then
        echo "   No $label found; leaving shell configuration untouched: $file"
        return 0
    fi

    if grep -Fqx -- "$line" "$file"; then
        echo ">> $label already contains the PATH entry"
        return 0
    fi

    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] Would append PATH entry to $file"
        return 0
    fi

    printf '\n%s\n' "$line" >> "$file"
    echo ">> Appended PATH entry to $file"
}

# --- detect distro ---
if command -v apt >/dev/null 2>&1; then
    DISTRO="debian"
elif command -v xbps-install >/dev/null 2>&1; then
    DISTRO="void"
else
    echo "Unsupported distro. Install micro, tmux, and flake8 manually." >&2
    exit 1
fi

echo ">> Installing micro, tmux, and flake8 ($DISTRO)"

case "$DISTRO" in
    debian)
        if [ "$NO_SUDO" -eq 1 ]; then
            echo "   --no-sudo: never invoking sudo"

            if ! command -v tmux >/dev/null 2>&1; then
                echo "!! tmux is missing. Install it with: sudo apt install tmux" >&2
                exit 1
            fi
            echo "   tmux already installed"

            if ! command -v micro >/dev/null 2>&1; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    echo "  [dry-run] Would download micro into ~/bin"
                else
                    mkdir -p "$HOME/bin"
                    (
                        cd "$HOME/bin"
                        curl -fsSL https://getmic.ro | bash
                    )
                fi
            else
                echo "   micro already installed"
            fi

            if ! command -v flake8 >/dev/null 2>&1; then
                if [ "$DRY_RUN" -eq 1 ]; then
                    echo "  [dry-run] Would install flake8 using pip --user"
                else
                    if ! python3 -m pip --version >/dev/null 2>&1; then
                        echo "!! pip is missing. Install python3-pip, then rerun." >&2
                        exit 1
                    fi

                    if ! python3 -m pip install --user flake8 2>/dev/null; then
                        python3 -m pip install --user --break-system-packages flake8
                    fi
                fi
            else
                echo "   flake8 already installed"
            fi
        else
            need_sudo=0
            for pkg in tmux flake8 micro; do
                command -v "$pkg" >/dev/null 2>&1 || { need_sudo=1; break; }
            done

            if [ "$need_sudo" -eq 0 ]; then
                echo "   tmux already installed"
                echo "   flake8 already installed"
                echo "   micro already installed"
                echo "   nothing to install; skipping apt"
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
                        echo "  [dry-run] Would download micro and install to /usr/local/bin"
                    else
                        TMP_DIR="$(mktemp -d)"
                        trap 'rm -rf "$TMP_DIR"' EXIT
                        (
                            cd "$TMP_DIR"
                            curl -fsSL https://getmic.ro | bash
                        )
                        run sudo install -m 0755 "$TMP_DIR/micro" /usr/local/bin/micro
                        rm -rf "$TMP_DIR"
                        trap - EXIT
                    fi
                else
                    echo "   micro already installed"
                fi
            fi
        fi
        ;;
    void)
        if [ "$NO_SUDO" -eq 1 ]; then
            echo "   Note: --no-sudo is not supported for package installation on Void."
        fi

        need_sudo=0
        for pkg in tmux micro flake8; do
            command -v "$pkg" >/dev/null 2>&1 || { need_sudo=1; break; }
        done

        if [ "$need_sudo" -eq 0 ]; then
            echo "   tmux already installed"
            echo "   micro already installed"
            echo "   flake8 already installed"
            echo "   nothing to install; skipping xbps"
        else
            run sudo xbps-install -Sy

            for pkg in tmux micro flake8; do
                if command -v "$pkg" >/dev/null 2>&1; then
                    echo "   $pkg already installed"
                else
                    run sudo xbps-install -y "$pkg"
                fi
            done
        fi
        ;;
esac

# --- Micro config ---
echo ">> Installing Micro config"
safe_install "$REPO_DIR/configs/micro-settings.json" \
    "$HOME/.config/micro/settings.json" \
    "Micro settings"

# --- micromux-owned tmux extras only ---
echo ">> Installing micromux tmux extras"
run mkdir -p "$HOME/.config/micromux"
safe_install "$REPO_DIR/configs/tmux-extras.conf" \
    "$HOME/.config/micromux/tmux-extras.conf" \
    "micromux tmux extras"

# --- micromux launcher ---
echo ">> Installing micromux launcher"
run mkdir -p "$HOME/bin"
safe_install "$REPO_DIR/micromux" \
    "$HOME/bin/micromux" \
    "micromux launcher"

if [ "$DRY_RUN" -eq 0 ]; then
    chmod +x "$HOME/bin/micromux"
fi

# --- PATH setup: append only; never rewrite existing files ---
case "${SHELL##*/}" in
    fish)
		# Single quotes are intentional: the line is written literally into
        # the user's fish config, so $HOME must NOT expand here.
        # shellcheck disable=SC2016
        append_line_if_missing \
            "$HOME/.config/fish/config.fish" \
            'fish_add_path "$HOME/bin"' \
            "Fish config"
        ;;
    bash)
		# Single quotes are intentional: the line is written literally into
        # ~/.bashrc, so $HOME must NOT expand here.
        # shellcheck disable=SC2016
        append_line_if_missing \
            "$HOME/.bashrc" \
            'export PATH="$HOME/bin:$PATH"' \
            "Bash config"
        ;;
    *)
        echo "!! Unknown login shell; no shell config was modified."
        echo '   Add ~/bin to your PATH manually if needed.'
        ;;
esac

echo
echo "Done."
echo "Native tmux configs were left untouched."
echo "Shell PATH setup only appends a missing line to an existing shell config."
echo
echo "Restart your shell, then run:"
echo "    micromux myfile.py"
echo
echo "Linter: flake8 runs automatically on save in Micro."

