#!/usr/bin/env bash

#set -euo pipefail #; set -x

#for myFile in *.sh include/*.sh; do
#disable-ip6.sh strax-mn-install-ubuntu.sh update-or-install-strax-wallet-deb-bullseye.sh switch-from-iptables-to-nftables-setup-sky.sh check-echo-before-suexec.sh strax-mn-start.sh install-strax-wallet-gz.sh
# test-superuser-privileges.sh set-common-settings.sh pre-install-pkgs.sh set-ssh-nonroot-user-keys.sh get-network-settings.sh
for myFile in apt-install-cmd.sh file-edition.sh set-grub-kernel-parameter.sh apt-pre-instal-pkg-ubuntu.sh set-hostname.sh disable-systemd-sleep.sh dpkg-install-cmd.sh; do
 	grep --color -inH 'echo -e' $myFile
 	grep --color -inH 'suexec' $myFile
done