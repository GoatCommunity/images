#!/bin/bash
# entrypoint.sh – Goat container entrypoint
# Mirrors Exegol's entrypoint.sh: initialisation, VPN, desktop, shell spawn.
#
# Environment variables consumed:
#   GOAT_NAME              → container name (self-identification in prompt)
#   GOAT_START_SHELL       → "zsh" | "bash" | "tmux"  (default: zsh)
#   GOAT_SHELL_LOG         → "1" to enable session recording
#   GOAT_SHELL_LOG_METHOD  → "script" | "asciinema"
#   GOAT_SHELL_LOG_COMPRESS→ "1" to gzip log at session end
#   GOAT_VPN               → "1" if a VPN config was mounted at /.goat/vpn/config
#   DISPLAY                → X11 display string (set by wrapper when --disable-X11 is NOT set)

set -e

trap shutdown SIGTERM

# ── Shutdown handler ──────────────────────────────────────────────────────────

function shutdown() {
    # Stop VNC desktop if running
    if pgrep -x Xtigervnc &>/dev/null; then
        vncserver -kill :0 2>/dev/null || true
    fi
    # Stop OpenVPN if running
    pkill -SIGTERM openvpn 2>/dev/null || true
    # Stop interactive shells
    pkill -x zsh  2>/dev/null || true
    pkill -x bash 2>/dev/null || true
    exit 0
}

# ── Initialisation ─────────────────────────────────────────────────────────────

function goat_init() {
    # Expose GOAT_NAME to shells via /etc/environment so every child process sees it
    if [[ -n "${GOAT_NAME}" ]]; then
        grep -q '^GOAT_NAME=' /etc/environment 2>/dev/null || \
            echo "GOAT_NAME=${GOAT_NAME}" >> /etc/environment
    fi

    # Set the default login shell to spawn.sh so every new shell goes through it
    if [[ -f "/.goat/spawn.sh" ]]; then
        usermod -s "/.goat/spawn.sh" root &>/dev/null || true
    fi

    # X11 – configure xauth if DISPLAY is set and xauth is available
    if [[ -n "${DISPLAY}" ]] && command -v xauth &>/dev/null; then
        touch /root/.Xauthority
        xauth generate "${DISPLAY}" . trusted 2>/dev/null || true
    fi
}

# ── VPN ───────────────────────────────────────────────────────────────────────

function start_vpn() {
    local config_dir="/.goat/vpn/config"
    if [[ ! -d "$config_dir" ]] && [[ ! -f "$config_dir" ]]; then
        echo "[GOAT][ERROR] VPN config not found at $config_dir"
        return 1
    fi

    # WireGuard (.conf)
    local wg_conf
    wg_conf=$(find "$config_dir" -maxdepth 1 -name "*.conf" 2>/dev/null | head -1)
    if [[ -n "$wg_conf" ]] && command -v wg-quick &>/dev/null; then
        echo "[GOAT] Starting WireGuard VPN: $wg_conf"
        wg-quick up "$wg_conf" &>>/var/log/goat/vpn.log && \
            echo "[GOAT][OK] WireGuard started" || \
            echo "[GOAT][ERROR] WireGuard failed — check /var/log/goat/vpn.log"
        return
    fi

    # OpenVPN (.ovpn)
    local ovpn_conf
    ovpn_conf=$(find "$config_dir" -maxdepth 1 -name "*.ovpn" 2>/dev/null | head -1)
    if [[ -n "$ovpn_conf" ]] && command -v openvpn &>/dev/null; then
        echo "[GOAT] Starting OpenVPN: $ovpn_conf"
        openvpn --log-append /var/log/goat/vpn.log --config "$ovpn_conf" &
        sleep 2
        echo "[GOAT][OK] OpenVPN started (check /var/log/goat/vpn.log)"
        return
    fi

    echo "[GOAT][ERROR] No supported VPN config found (.ovpn / .conf) — or vpn client not installed"
}

# ── Desktop ────────────────────────────────────────────────────────────────────

function desktop() {
    echo "[GOAT] Starting XFCE desktop via TigerVNC + noVNC"
    mkdir -p /root/.vnc /var/log/goat

    # Kill any existing session
    vncserver -kill :0 2>/dev/null || true

    # Start VNC server
    vncserver \
        -localhost no \
        -geometry 1920x1080 \
        -depth 24 \
        -SecurityTypes None \
        :0 &>>/var/log/goat/vnc.log

    # Start noVNC web proxy (port 6080 → VNC port 5900)
    if command -v websockify &>/dev/null; then
        websockify --web=/usr/share/novnc 6080 localhost:5900 &>>/var/log/goat/novnc.log &
    elif command -v novnc &>/dev/null; then
        novnc --listen 6080 --vnc localhost:5900 &>>/var/log/goat/novnc.log &
    fi

    echo "[GOAT][OK] Desktop ready — connect via browser at http://localhost:6080"
    # Keep container alive by tailing logs
    exec tail -f /var/log/goat/vnc.log
}

# ── Shell ─────────────────────────────────────────────────────────────────────

function shell() {
    if [[ -x "/.goat/spawn.sh" ]]; then
        exec /.goat/spawn.sh
    else
        exec /bin/${GOAT_START_SHELL:-zsh}
    fi
}

# ── Command execution ─────────────────────────────────────────────────────────

function cmd() {
    # Execute arbitrary command passed as arguments (used by goat exec)
    "${@:2}"
}

# ── Default action ────────────────────────────────────────────────────────────

function default() {
    if [[ -t 0 ]]; then
        shell
    else
        # Daemon mode: keep container alive without a TTY
        [[ ! -p /tmp/.goat_entrypoint ]] && mkfifo -m 000 /tmp/.goat_entrypoint
        read -r <> /tmp/.goat_entrypoint
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────

goat_init

# Start VPN if requested
if [[ "${GOAT_VPN}" == "1" ]]; then
    start_vpn || true
fi

# Dispatch to the requested function
FUNC_NAME="${1:-default}"

if declare -f "$FUNC_NAME" > /dev/null; then
    $FUNC_NAME "$@"
else
    echo "[GOAT][ERROR] Unknown action '$FUNC_NAME'." >&2
    echo "  Supported: default | shell | desktop | cmd | start_vpn" >&2
    exit 1
fi
