#!/bin/bash
# package_recon.sh – Recon/web enumeration profile
# Adds Go recon tools on top of base.

source common.sh

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

function install_recon_apt_tools() {
    colorecho "Installing recon profile apt tools"
    fapt dirb dnsutils httpie netcat-openbsd nmap whatweb whois
    install_nikto
    register_tool "nmap"
    register_tool "dirb"
    register_tool "whatweb"
    register_tool "httpie"
}

function install_recon_go_tools() {
    colorecho "Installing Go recon tools"
    go_install github.com/ffuf/ffuf/v2@latest
    go_install github.com/projectdiscovery/httpx/cmd/httpx@latest
    go_install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
    go_install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
    go_install github.com/OJ/gobuster/v3@latest
    go_install github.com/hakluke/hakrawler@latest
    go_install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
    # Update nuclei templates
    /opt/tools/bin/nuclei -update-templates -silent 2>/dev/null || true
}

function install_recon_wordlists() {
    colorecho "Installing discovery wordlists"
    mkdir -p /opt/lists/seclists/Discovery/Web-Content
    mkdir -p /opt/lists/seclists/Discovery/DNS
    local BASE="https://raw.githubusercontent.com/danielmiessler/SecLists/master"
    wget -q "${BASE}/Discovery/Web-Content/common.txt" \
        -O /opt/lists/seclists/Discovery/Web-Content/common.txt || true
    wget -q "${BASE}/Discovery/Web-Content/directory-list-2.3-small.txt" \
        -O /opt/lists/seclists/Discovery/Web-Content/directory-list-2.3-small.txt || true
    wget -q "${BASE}/Discovery/DNS/subdomains-top1million-5000.txt" \
        -O /opt/lists/seclists/Discovery/DNS/subdomains-top1million-5000.txt || true
    ln -sf /opt/lists/seclists /usr/share/wordlists/seclists 2>/dev/null || true
    colorecho "Discovery wordlists installed at /opt/lists/seclists/"
}

function package_recon() {
    install_recon_apt_tools
    install_recon_go_tools
    install_recon_wordlists
    post_install
}
