#!/bin/bash

source common.sh

function install_xfce() {
    colorecho "Installing XFCE desktop stack"
    fapt dbus-x11 novnc tigervnc-standalone-server tigervnc-tools websockify xfce4 xfce4-terminal xfce4-goodies
    mkdir -p /usr/share/backgrounds/goat
    mkdir -p /root/.vnc /root/.config/xfce4/xfconf/xfce-perchannel-xml
    cp -f /root/sources/assets/desktop/wallpapers/goatos-wallpaper.jpg /usr/share/backgrounds/goat/goatos-wallpaper.jpg
    cp -f /root/sources/assets/desktop/configuration/xstartup.conf /root/.vnc/xstartup
    chmod u+x /root/.vnc/xstartup
    cp -f /root/sources/assets/desktop/configuration/xfce4-desktop.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml
    cp -f /root/sources/assets/desktop/configuration/xsettings.xml /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml
    register_tool "xfce4"
    register_tool "tigervnc"
    register_tool "novnc"
}

function package_desktop() {
    install_xfce
    post_install
}
