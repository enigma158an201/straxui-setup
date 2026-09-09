#!/usr/bin/env bash

#set -euo pipefail #; set -x
main() {
	#for sFile in *.sh include/*.sh; do
	#disable-ip6.sh strax-mn-install-ubuntu.sh update-or-install-strax-wallet-deb-bullseye.sh switch-from-iptables-to-nftables-setup-sky.sh check-echo-before-suexec.sh strax-mn-start.sh install-strax-wallet-gz.sh
	# test-superuser-privileges.sh set-common-settings.sh pre-install-pkgs.sh set-ssh-nonroot-user-keys.sh get-network-settings.sh
	for sFile in *.sh include/*.sh; do
		grep --color -inH 'echo -e' "${sFile}"
		grep --color -inH 'suexec' "${sFile}"
	done
}
main