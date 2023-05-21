#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

sshd-config-settings() {
	echo -e "\t>>> application des fichiers config sshd"
	suExecCommand "for sshdfile in prohibit-root.conf pubkey-only.conf sshd-port.conf; do \
		mysshddst=\"/etc/ssh/sshd_config.d/\$sshdfile\"; \
		mysshdsrc=\"${launchDir}\$mysshddst\"; \
		if [ -d \"$(dirname \"\$mysshddst\")\" ] && [ -f \"\$mysshdsrc\" ]; then install -o root -g root -m 0744 -pv \"\$mysshdsrc\" \"\$mysshddst\"; fi; \
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
		echo -e "\t>>> désactivation des mises en veille systemd"
		suExecCommand "install -o root -g root -m 0744 -pv \"$mysystemdsrc\" \"$mysystemddst\"; \
		systemctl daemon-reload"
	fi
}
disable-wireless-connections() {
	echo -e "\t>>> désactivation des connexions wireless"
	suExecCommand " \
	if (systemctl status wpa_supplicant.service 1>/dev/null); then	systemctl disable --now wpa_supplicant.service; fi; \
 	if (which nmcli 1>/dev/null); then 								nmcli radio wifi off; fi; \
	if (which rfkill 1>/dev/null); then								rfkill block wlan bluetooth; fi"
}
disable-cups-services() {
	echo -e "\t>>> désactivation cups (impression)"
	if (systemctl status cups-browsed.service 1>/dev/null) || (systemctl status cups.service 1>/dev/null); then
		suExecCommand "systemctl disable --now cups-browsed.service; \
 		systemctl disable --now cups.service"
	fi
}
cronjob-disable-ipv6() {
	echo -e "\t>>> création du job cron en cas de reactivation ipV6"
 	if (systemctl status cron.service 1>/dev/null); then suExecCommand systemctl enable --now cron.service; fi
}
set-newhostname() {
	echo -e "\t>>> renommage de la machine suivant schéma modèle+distro"
	suExecCommand "bash -c ${launchDir}/include/set-hostname.sh" 
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
	set-newhostname
}
main_common