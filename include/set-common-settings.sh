#!/usr/bin/env bash

set -euo pipefail #; set -x

# this script requires super user privileges and do not contain any suExec
launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source "${launchDir}/include/test-superuser-privileges.sh"
source "${launchDir}/include/file-edition.sh"

sshd-config-settings() {
	echo -e "\t>>> application des fichiers config sshd"
	#for sSshdConfigFile in enable-only-ip4.conf prohibit-root.conf pubkey-only.conf pubkey-accepted-types.conf sshd-port.conf; do
	for sSshdConfigFile in "${launchDir}"/etc/sshd_config.d/*.conf; do
		sSshdConfigDst="/etc/ssh/sshd_config.d/${sSshdConfigFile}"
		sSshdConfigSrc="${launchDir}${sSshdConfigDst}"
		if [ -d "$(dirname "${sSshdConfigDst}")" ] && [ -f "${sSshdConfigSrc}" ]; then 
			install -o root -g root -m 0744 -pv "${sSshdConfigSrc}" "${sSshdConfigDst}"
		fi
	done
	systemctl restart sshd.service
}
disable-systemd-sleep() {
	#AllowSuspend=yes				to	AllowSuspend=no
	#AllowHibernation=yes			to	AllowHibernation=no
	#AllowSuspendThenHibernate=yes	to	AllowSuspendThenHibernate=no
	#AllowHybridSleep=yes			to	AllowHybridSleep=no
	#suExecCommand "bash -c \"${launchDir}/include/disable-systemd-sleep.sh\""
	sSystemdSleepDst="/etc/systemd/sleep.conf"
	sSystemdSleepSrc="${launchDir}${sSystemdSleepDst}"
	if [ -d "$(dirname "${sSystemdSleepDst}")" ] && [ -f "${sSystemdSleepSrc}" ]; then
		echo -e "\t>>> désactivation des mises en veille systemd"
		install -o root -g root -m 0744 -pv "${sSystemdSleepSrc}" "${sSystemdSleepDst}"
		systemctl daemon-reload
	fi
}
disable-wireless-connections() {
	echo -e "\t>>> désactivation des connexions wireless"
	if (systemctl status wpa_supplicant.service 1>/dev/null); then 	systemctl disable --now wpa_supplicant.service; fi
	if (command -v nmcli 1>/dev/null 2>&1); then 					nmcli radio wifi off; fi
	if (command -v rfkill 1>/dev/null 2>&1); then 					rfkill block wlan bluetooth; fi
}
disable-cups-services() {
	echo -e "\t>>> désactivation cups (impression)"
	if (systemctl status cups-browsed.service 1>/dev/null) || (systemctl status cups.service 1>/dev/null || false); then
		systemctl disable --now cups-browsed.service
		systemctl disable --now cups.service
	fi
}
cronjob-disable-ipv6() {
	echo -e "\t>>> création du job cron en cas de reactivation ipV6"
	if (systemctl status cron.service 1>/dev/null); then systemctl enable --now cron.service; fi
}
set-newhostname() {
	echo -e "\t>>> renommage de la machine suivant schéma modèle+distro"
	bash -c "${launchDir}/include/set-hostname.sh"
}
main_common() {
	#source "${launchDir}/include/test-superuser-privileges.sh"
	whoami
	#set-newhostnam || true		# set new host name has to be done before sshd config
	echo -e "\t>>> initialisation des paramètres du serveur ssh"
	if command -v sshd 1>/dev/null 2>&1; then 											sshd-config-settings; fi
	read -rp "Désactiver les connections wifi et bluetooth? o/N"  -n 1 sDisableWireless
	if [ ! "${sDisableWireless^^}" = "N" ] && [ ! "${sDisableWireless}" = "" ]; then 	disable-wireless-connections; fi
	echo -e "\t>>> désactivation de cups"
	disable-cups-services
	echo -e "\t>>> désactivation de systemd-sleep"
	disable-systemd-sleep
	echo -e "\t>>> désactivation de ipv6"
	cronjob-disable-ipv6
}
main_common