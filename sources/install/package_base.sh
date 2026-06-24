#!/bin/bash

source common.sh

function update() {
    colorecho "Updating base system"
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections
    apt-get update
    apt-get install -y --no-install-recommends \
        apt-utils ca-certificates curl dialog git gnupg2 jq locales \
        lsb-release procps sudo tmux vim-tiny wget zsh \
        pipx python3-full python3-pip python3-venv
    apt-get upgrade -y
    apt-get autoremove -y
    apt-get clean
}

function install_ohmyzsh() {
    colorecho "Installing oh-my-zsh"
    RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

function install_python_runtime() {
    colorecho "Installing Python runtime"
    fapt python3 python3-pip python3-venv python3-requests python3-bs4
    register_tool "python3"
    register_tool "pip3"
}

# Install the Go toolchain from upstream (not apt — apt version is too old for modern tools)
function install_go_runtime() {
    colorecho "Installing Go runtime from upstream"
    local GO_VERSION="1.23.4"
    local ARCH
    case "$(uname -m)" in
        x86_64)   ARCH="amd64" ;;
        aarch64)  ARCH="arm64" ;;
        *)        ARCH="amd64" ;;
    esac

    wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${ARCH}.tar.gz" -O /tmp/go.tar.gz
    rm -rf /usr/local/go
    tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz

    export GOROOT=/usr/local/go
    export GOPATH=/opt/go
    export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
    mkdir -p "$GOPATH"

    cat > /etc/profile.d/go.sh << 'EOF'
export GOROOT=/usr/local/go
export GOPATH=/opt/go
export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
EOF

    colorecho "Go $(go version) installed"
    register_tool "go"
}

# ── Shell logging tools (mirrors Exegol's spawn.sh requirements) ──────────────
function install_shell_logging() {
    colorecho "Installing shell logging tools (script + asciinema)"
    # 'script' is provided by bsdutils (usually pre-installed)
    fapt bsdutils
    # asciinema for richer session recording
    pipx install asciinema 2>/dev/null || fapt asciinema
    register_tool "asciinema"
    register_tool "script"
}

# ── X11 forwarding support ─────────────────────────────────────────────────────
function install_x11_support() {
    colorecho "Installing X11 forwarding support"
    fapt xauth x11-utils
    register_tool "xauth"
}

function package_base() {
    update
    filesystem
    deploy_goat
    install_locales
    install_ohmyzsh
    configure_shells
    install_python_runtime
    install_go_runtime
    install_shell_logging
    install_x11_support
    post_install
}
