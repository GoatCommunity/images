#!/bin/bash
# package_full.sh – Full pentest profile
# Installs everything from package_pentest plus the broader security stack.

source common.sh
source package_pentest.sh

function install_full_apt_tools() {
    colorecho "Installing full profile apt tools"
    fapt \
        binutils chromium dirb dnsutils hydra \
        libimage-exiftool-perl mitmproxy net-tools \
        netcat-openbsd nmap proxychains4 sqlmap \
        tcpdump tshark whatweb whois

    install_nikto

    register_tool "chromium"
    register_tool "mitmproxy"
    register_tool "hydra"
    register_tool "tshark"
    register_tool "nmap"
    register_tool "proxychains4"
}

function install_nikto() {
    if [[ -d "/opt/tools/nikto" ]] && [[ -x "/usr/local/bin/nikto" ]]; then
        colorecho "Nikto already installed"
        return
    fi
    colorecho "Installing nikto from upstream repository"
    fapt perl
    git -C /opt/tools clone --depth 1 https://github.com/sullo/nikto.git
    cat <<'EOF' >/usr/local/bin/nikto
#!/bin/sh
exec /opt/tools/nikto/program/nikto.pl "$@"
EOF
    chmod +x /usr/local/bin/nikto
    register_tool "nikto"
}

function package_full() {
    install_full_apt_tools
    package_pentest
    post_install
}
