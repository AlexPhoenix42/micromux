#!/usr/bin/env bash
# uninstall.sh — remove micromux launcher and configs.
# Does NOT remove micro, tmux, or flake8 — those are your utilities, keep them.
#
# Flags:
#   --keep-configs   Remove only the launcher and PATH entries; leave configs alone
#   --restore        Restore the most recent config backups instead of deleting
#   --force          Don't prompt; delete configs and remove PATH entries
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
            sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

run() {
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] $*"
    else
        "$@"
    fi
}

# --- 1. remove launcher ---
LAUNCHER="$HOME/bin/micromux"
if [ -f "$LAUNCHER" ]; then
    echo ">> Removing launcher: $LAUNCHER"
    run rm -f "$LAUNCHER"
else
    echo "   $LAUNCHER not found (already removed)"
fi

# --- 2. remove tmux extras (ours, always safe to delete) ---
EXTRAS="$HOME/.config/micromux/tmux-extras.conf"
if [ -f "$EXTRAS" ]; then
    echo ">> Removing tmux extras: $EXTRAS"
    run rm -f "$EXTRAS"
    run rmdir "$HOME/.config/micromux" 2>/dev/null || true
else
    echo "   $EXTRAS not found (already removed)"
fi

# --- 3. handle config files (prompt unless --keep-configs / --restore / --force) ---
handle_config() {
    local file="$1" label="$2"

    if [ ! -e "$file" ]; then
        echo "   $label not found: $file"
        return 0
    fi

    if [ "$KEEP_CONFIGS" -eq 1 ]; then
        echo "   Keeping $label (--keep-configs): $file"
        return 0
    fi

    local latest_backup=""
    latest_backup="$(ls -1t "${file}".bak.* 2>/dev/null | head -n 1 || true)"

    if [ "$RESTORE" -eq 1 ]; then
        if [ -n "$latest_backup" ]; then
            echo ">> Restoring $label from $latest_backup"
            run cp "$latest_backup" "$file"
        else
            echo "!! --restore given but no backup exists for $file; leaving it"
        fi
        return 0
    fi

    if [ "$FORCE" -eq 0 ] && [ "$DRY_RUN" -eq 0 ]; then
        echo
        echo "!! $file"
        if [ -n "$latest_backup" ]; then
            echo "   Latest backup: $latest_backup"
            printf "   [d]elete / [r]estore backup / [k]eep? [k] "
        else
            printf "   [d]elete / [k]eep? [k] "
        fi
        read -r answer
        case "$answer" in
            [dD]|[dD][eE][lL][eE][tT][eE])
                run rm -f "$file"
                echo "   Deleted $file"
                ;;
            [rR]|[rR][eE][sS][tT][oO][rR][eE])
                if [ -n "$latest_backup" ]; then
                    run cp "$latest_backup" "$file"
                    echo "   Restored from $latest_backup"
                else
                    echo "   No backup to restore; kept $file"
                fi
                ;;
            *)
                echo "   Kept $file"
                ;;
        esac
    else
        echo ">> Deleting $label: $file"
        run rm -f "$file"
    fi
}

handle_config "$HOME/.config/micro/settings.json" "micro settings"

# --- 4. remove PATH entries ---
remove_bash_path() {
    local rc="$HOME/.bashrc"
    [ -f "$rc" ] || return 0

    if grep -qx '# added by micromux install.sh' "$rc" 2>/dev/null; then
        echo ">> Removing micromux PATH block from $rc"
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] would remove marker + following PATH line from $rc"
        else
            sed -i '/^# added by micromux install\.sh$/,+1d' "$rc"
        fi
        return 0
    fi

    # No marker (old install). Only remove if exactly one instance.
    local count
    count="$(grep -cF 'export PATH="$HOME/bin:$PATH"' "$rc" 2>/dev/null || true)"
    count="${count:-0}"
    if [ "$count" -eq 1 ]; then
        echo ">> Removing '\$HOME/bin' PATH line from $rc (no marker; one match found)"
        if [ "$DRY_RUN" -eq 1 ]; then
            echo "  [dry-run] would remove that line from $rc"
        else
            grep -vF 'export PATH="$HOME/bin:$PATH"' "$rc" > "$rc.tmp" && mv "$rc.tmp" "$rc"
        fi
    elif [ "$count" -eq 0 ]; then
        echo "   No micromux PATH entry in $rc"
    else
        echo "!! $rc has $count matching PATH lines; not auto-removing. Edit manually:"
        grep -nF 'export PATH="$HOME/bin:$PATH"' "$rc"
    fi
}

remove_fish_path() {
    local rc="$HOME/.config/fish/config.fish"
    [ -f "$rc" ] || return 0

    if ! grep -qx '# added by micromux install.sh' "$rc" 2>/dev/null; then
        echo "   No micromux fish block in $rc"
        return 0
    fi

    echo ">> Removing micromux fish block from $rc"
    if [ "$DRY_RUN" -eq 1 ]; then
        echo "  [dry-run] would remove marker + fish_add_path line from $rc"
    else
        sed -i '/^# added by micromux install\.sh$/,+1d' "$rc"
    fi
}

remove_bash_path
remove_fish_path

echo
echo "Done. Restart your shell to pick up PATH changes."
echo
echo "micro, tmux, and flake8 were left installed (system utilities)."

