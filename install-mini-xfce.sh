#!/usr/bin/env bash

# written by enigma158an201 and totally inspired by:
# https://github.com/coonrad/Debian-Xfce4-Minimal-Install/blob/main/xfce-install.sh

## configure and install minimal xfce desktop environment

## check for sudo/root
if ! [ "$(id -u)" = "0" ]; then
  echo "This script must run with sudo, try again..."
  exit 1
fi

#cat ./xsessionrc >> /home/${SUDO_USER}/.xsessionrc
#chown ${SUDO_USER}:${SUDO_USER} /home/${SUDO_USER}/.xsessionrc

apt-get install -y \
    libxfce4ui-utils \
    thunar \
    xfce4-appfinder \
    xfce4-panel \
    xfce4-pulseaudio-plugin \
    xfce4-whiskermenu-plugin \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfconf \
    xfdesktop4 \
    xfwm4 \
    adwaita-qt \
    qt5ct \
    xfce4-power-manager

echo 
echo xfce install complete, please reboot and issue 'startx'
echo