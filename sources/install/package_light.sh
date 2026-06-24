#!/bin/bash

source common.sh

function install_light_tools() {
    colorecho "Installing light profile tools"
    fapt dnsutils httpie netcat-openbsd nmap whatweb whois
    register_tool "nmap"
    register_tool "httpie"
    register_tool "whatweb"
}

function package_light() {
    install_light_tools
    post_install
}
