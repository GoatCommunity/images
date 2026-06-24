#!/bin/bash

export RED='\033[1;31m'
export BLUE='\033[1;34m'
export GREEN='\033[1;32m'
export NOCOLOR='\033[0m'

function colorecho () {
    echo -e "${BLUE}[GOAT] $*${NOCOLOR}"
}

function criticalecho () {
    echo -e "${RED}[GOAT ERROR] $*${NOCOLOR}" 2>&1
    exit 1
}

function fapt() {
    colorecho "Installing apt package(s): $*"
    if [ -z "$( ls -A '/var/lib/apt/lists/' 2>/dev/null )" ]; then
      apt-get update
    fi
    apt-get install -y --no-install-recommends "$@"
}

function filesystem() {
    colorecho "Preparing filesystem"
    mkdir -p /opt/tools/bin /data /var/log/goat /.goat /opt/resources /opt/my-resources /usr/share/backgrounds/goat
    touch /.goat/installed_tools.txt
    # Create go workspace
    mkdir -p /opt/go/{bin,pkg,src}
}

function deploy_goat() {
    colorecho "Deploying Goat runtime assets"
    rm -rf /.goat || true
    cp -r /root/sources/assets/goat /.goat
    chown -R root:root /.goat
    chmod 500 /.goat/*.sh
}

function configure_shells() {
    colorecho "Configuring shell defaults"
    cp -f /root/sources/assets/shells/zshrc /root/.zshrc
    cp -f /root/sources/assets/shells/tmux.conf /root/.tmux.conf
}

function install_locales() {
    colorecho "Installing locales"
    fapt locales
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
    locale-gen
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US.UTF-8
}

function post_install() {
    colorecho "Cleaning post-install files"
    rm -rf /tmp/*
    rm -rf /var/lib/apt/lists/*
}

function post_build() {
    colorecho "Finalizing image build"
    rm -rf /root/sources
    if command -v updatedb >/dev/null 2>&1; then
        updatedb || true
    fi
}

function register_tool() {
    echo "$1" >> /.goat/installed_tools.txt
}

# ── Go toolchain helper ───────────────────────────────────────────────────────
# Sets up Go env and installs a Go tool from a module path.
# Usage: go_install github.com/owner/repo/cmd/tool@latest
function go_install() {
    local module="$1"
    colorecho "Installing Go tool: $module"
    export GOROOT=/usr/local/go
    export GOPATH=/opt/go
    export PATH="$PATH:$GOROOT/bin:$GOPATH/bin"
    $GOROOT/bin/go install "$module"
    # Symlink to /opt/tools/bin so tools are on PATH without GOPATH
    local binary
    binary=$(basename "${module%%@*}")
    [[ -x "/opt/go/bin/$binary" ]] && ln -sf "/opt/go/bin/$binary" "/opt/tools/bin/$binary" || true
    register_tool "$binary"
}

# ── Python venv helper ────────────────────────────────────────────────────────
# Creates a venv for a tool under /opt/tools and installs pip packages into it.
# Usage: pipx_install_git https://github.com/owner/tool "tool-binary-name"
function pipx_install_git() {
    local repo="$1"
    local bin_name="${2:-$(basename "$repo")}"
    colorecho "Installing Python tool from git: $repo"
    pipx install --system-site-packages "git+$repo"
    register_tool "$bin_name"
}
