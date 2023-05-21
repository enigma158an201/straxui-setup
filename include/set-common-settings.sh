#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source for getting ip addresses
source "${launchDir}/include/get-network-settings.sh"

mySshPort="41122"

set-ssh-user-keys() {
	if [ ! "$EUID" = "0" ]; then
		read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
		if [ ! "${genNewKeyPair^^}" = "N" ] && [ ! "$genNewKeyPair" = "" ]; then
			myPrvIP4="$(getNetworkAddress 4 "$(getIpAddr4)")"
			myPubIP4=""			
			myShhDir="$HOME/.ssh/"
			myPubAutKeysFile=""$myShhDir/authorized_keys""
			(mkdir -p "$myShhDir" && cd "$myShhDir" || exit 1) || exit 1
			outPrvKeyFileName="${myShhDir}${HOSTNAME}_${USER}_$(date +%Y%m%d%H%M%S)"
			ssh-keygen -p -t ed25519 -f "$outPrvKeyFileName" -C "myGithubKey" # here -p is for change passphrase
			outPubKeyFileName="${outPrvKeyFileName}.pub"
			#ssh-copy-id -p "$SSH_PORT" -i "$myShhDir/$outKeyFileName.pub" "$USER@localhost" # for remote key install
			if [ ! -f "$myPubAutKeysFile" ]; then touch "$myPubAutKeysFile"; fi
			outPubKeyFileContent="$(cat "$outPubKeyFileName")"
			if (! grep "$outPubKeyFileContent" "$myPubAutKeysFile"); then echo -e "\n$outPubKeyFileContent" | tee -a "$myPubAutKeysFile"; fi
			echo -e "  >>> penser si usage d'alias, à: \n\t>> 1/ copier la clé privée sur le client de connexion \n\t>> 2/ optionnel ajouter cette config \n \
Host $HOSTNAME
HostName $myPrvIP4
Port $mySshPort
User $USER
IdentityFile ~/.ssh/ponchonbox.lan-server.key"
		fi
	fi
}

sshd-config-settings() {
	suExecCommand "for sshdfile in prohibit-root.conf pubkey-only.conf sshd-port.conf; do \
		mysshddst=\"/etc/ssh/sshd_config.d/\$sshdfile\"; \
		mysshdsrc=\"${launchDir}\$mysshddst\"; \
		if [ -d \"$(dirname \"\$mysshddst\")\" ] && [ -f \"\$mysshdsrc\" ]; then install -o root -g root -m 0744 -pv \"\$mysshdsrc\" \"\$mysshddst\"; fi \
	done; \
	systemctl restart sshd.service"
}
disable-systemd-sleep() {
	#AllowSuspend=yes				to	AllowSuspend=no
	#AllowHibernation=yes			to	AllowHibernation=no
	#AllowSuspendThenHibernate=yes	to	AllowSuspendThenHibernate=no
	#AllowHybridSleep=yes			to	AllowHybridSleep=no
	#suExecCommand "bash -c \"$launchDir/include/disable-systemd-sleep.sh\""
	mysystemddst="/etc/systemd/sleep.conf"
	mysystemdsrc="${launchDir}$mysystemddst"
	if [ -d "$(dirname "$mysystemddst")" ] && [ -f "$mysystemdsrc" ]; then 
		suExecCommand "install -o root -g root -m 0744 -pv \"$mysystemdsrc\" \"$mysystemddst\"; \
		systemctl daemon-reload"
	fi
}
disable-wireless-connections() {
	if (systemctl status wpa_supplicant.service 1>/dev/null); then suExecCommand systemctl disable --now wpa_supplicant.service; fi
    if (which nmcli 1>/dev/null); then suExecCommand nmcli radio wifi off; fi
	if (which rfkill 1>/dev/null); then suExecCommand rfkill block wlan bluetooth; fi
}
disable-cups-services() {
	if (systemctl status cups-browsed.service 1>/dev/null); then suExecCommand systemctl disable --now cups-browsed.service; fi
    if (systemctl status cups.service 1>/dev/null); then suExecCommand systemctl disable --now cups.service; fi
}
cronjob-disable-ipv6() {
    if (systemctl status cron.service 1>/dev/null); then suExecCommand systemctl enable --now cron.service; fi
}
main_common() {
	source "${launchDir}/include/test-superuser-privileges.sh"
	source "${launchDir}/include/file-edition.sh"
	sshd-config-settings
	read -rp "Désactiver les connections wifi et bluetooth? o/N"  -n 1 disableWireless
	if [ ! "${disableWireless^^}" = "N" ] && [ ! "$disableWireless" = "" ]; then disable-wireless-connections; fi
    disable-cups-services
	disable-systemd-sleep
    cronjob-disable-ipv6
}
main_common