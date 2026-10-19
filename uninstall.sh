#!/usr/bin/env bash
# uninstall.sh — remove micromux launcher and owned configs.
# Never modifies shell startup files or native tmux configuration.
# Does NOT remove micro, tmux, or flake8.
#
# Flags:
#   --keep-configs   Remove only the launcher; leave configs alone
#   --restore        Restore the most recent Micro settings backup
#   --force          Don't prompt; delete eligible configs
#   --dry-run        Show what would happen, change nothing
#   -h, --help       Show this help

set -euo pipefail

KEEP_CONFIGS=0
RESTORE=0
FORCE=0
DRY_RUN=0

for arg in "$@"; do
    case "$arg" in
        --keep-configs) KEEP_CONFIGS=1 ;;
        --restore)      RESTORE=1 ;;
        --force)        FORCE=1 ;;
        --dry-run)      DRY_RUN=1 ;;
        -h|--help)
            printf '%s\n' \
                "Usage: uninstall.sh [OPTIONS]" \
                "  --keep-configs  Remove launcher only; preserve configs" \
                "  --restore       Restore latest Micro settings backup" \
                "  --force         Delete eligible configs without prompting" \
                "  --dry-run       Show actions without changing anything" \
                "  -h, --help      Show this help"
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

# 1. Remove the micromux launcher.
LAUNCHER="$HOME/bin/micromux"

if [ -f "$LAUNCHER" ]; then
    echo ">> Removing launcher: $LAUNCHER"
    run rm -f -- "$LAUNCHER"
else
    echo "   Launcher not found: $LAUNCHER"
fi

# 2. Handle micromux-owned extras.
# Preserve the directory if it contains anything else.
EXTRAS="$HOME/.config/micromux/tmux-extras.conf"
EXTRAS_DIR="$HOME/.config/micromux"

if [ "$KEEP_CONFIGS" -eq 1 ]; then
    echo "   Keeping micromux configs (--keep-configs)"
elif [ -f "$EXTRAS" ]; then
    echo ">> Removing micromux extras: $EXTRAS"
    run rm -f -- "$EXTRAS"

    if [ -d "$EXTRAS_DIR" ]; then
        run rmdir -- "$EXTRAS_DIR" 2>/dev/null || true
    fi
else
    echo "   Micromux extras not found: $EXTRAS"
fi

# 3. Optionally handle Micro settings.
# This is not a micromux-owned file, so preserve it by default.
MICRO_CONFIG="$HOME/.config/micro/settings.json"

if [ "$KEEP_CONFIGS" -eq 1 ]; then
    echo "   Keeping Micro settings (--keep-configs)"
elif [ -f "$MICRO_CONFIG" ]; then
    if [ "$RESTORE" -eq 1 ]; then
        latest_backup=""
        for backup in "$MICRO_CONFIG".bak.*; do
            [ -f "$backup" ] || continue
            if [ -z "$latest_backup" ] || [ "$backup" -nt "$latest_backup" ]; then
                latest_backup="$backup"
            fi
        done

        if [ -n "$latest_backup" ]; then
            echo ">> Restoring Micro settings from: $latest_backup"
            run cp -- "$latest_backup" "$MICRO_CONFIG"
        else
            echo "!! No Micro settings backup found; leaving it untouched"
        fi
    elif [ "$FORCE" -eq 1 ]; then
        echo ">> Removing Micro settings: $MICRO_CONFIG"
        run rm -f -- "$MICRO_CONFIG"
    elif [ "$DRY_RUN" -eq 1 ]; then
        echo "   Would ask whether to remove Micro settings: $MICRO_CONFIG"
    else
        printf 'Remove Micro settings %s? [y/N] ' "$MICRO_CONFIG"
        read -r answer
        case "$answer" in
            [yY]|[yY][eE][sS])
                run rm -f -- "$MICRO_CONFIG"
                ;;
            *)
                echo "   Keeping Micro settings"
                ;;
        esac
    fi
else
    echo "   Micro settings not found: $MICRO_CONFIG"
fi

# 4. Intentionally do not edit shell startup files or native tmux configs.
echo
echo "Shell startup files were left untouched:"
echo "  $HOME/.bashrc"
echo "  $HOME/.config/fish/config.fish"
echo
echo "Native tmux configs were left untouched:"
echo "  $HOME/.tmux.conf"
echo "  $HOME/.config/tmux/tmux.conf"
echo
echo "Done. micro, tmux, and flake8 were left installed."

