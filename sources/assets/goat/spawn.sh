#!/bin/bash
# spawn.sh – Goat container shell spawner
# Mirrors Exegol's spawn.sh: handles shell selection, session logging, and startup.
#
# Spawn Version:1
# The spawn version allows the wrapper to detect version mismatches.

# ── Shell selection ────────────────────────────────────────────────────────────
# GOAT_START_SHELL  → "zsh" | "bash" | "tmux"  (default: zsh)
user_shell="/bin/${GOAT_START_SHELL:-zsh}"

# Fall back to bash if the requested shell is not installed
if ! command -v "$user_shell" &>/dev/null; then
    echo "[GOAT][WARN] Shell $user_shell not found, falling back to /bin/bash"
    user_shell="/bin/bash"
fi

# ── Tmux mode ──────────────────────────────────────────────────────────────────
if [[ "$GOAT_START_SHELL" == "tmux" ]]; then
    # Launch tmux; the tmux.conf sets the default shell
    exec tmux new-session -s main
fi

# ── Shell logging ──────────────────────────────────────────────────────────────
# GOAT_SHELL_LOG=1       → enable logging
# GOAT_SHELL_LOG_METHOD  → "script" | "asciinema"  (default: script)
# GOAT_SHELL_LOG_COMPRESS=1 → gzip log at session end

if [[ "${GOAT_SHELL_LOG}" == "1" ]]; then
    method="${GOAT_SHELL_LOG_METHOD:-script}"

    if ! command -v "$method" &>/dev/null; then
        echo "[GOAT][WARN] Logging method '$method' not found, running shell without logging."
        exec "$user_shell"
    fi

    umask 007
    mkdir -p /workspace/logs
    timestamp=$(date +%d-%m-%Y_%H-%M-%S)
    logfile="/workspace/logs/${timestamp}_shell.${method}"

    case "$method" in
        asciinema)
            container_name="${GOAT_NAME:-$(hostname)}"
            title="[GOAT] ${container_name} $(date '+%d/%m/%Y %H:%M:%S')"
            asciinema rec -i 2 --stdin --quiet \
                --command "$user_shell" \
                --title "$title" \
                "$logfile"
            ;;
        script)
            script -qefac "$user_shell" "$logfile"
            ;;
        *)
            echo "[GOAT][WARN] Unknown logging method '$method', using 'script'."
            script -qefac "$user_shell" "$logfile"
            ;;
    esac

    if [[ "${GOAT_SHELL_LOG_COMPRESS}" == "1" ]]; then
        echo "[GOAT] Compressing session log..."
        gzip "$logfile" 2>/dev/null || true
    fi

    exit 0
fi

# ── Default: launch shell directly ────────────────────────────────────────────
exec "$user_shell"
