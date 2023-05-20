#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi

sshd-config-settings() {
	for sshdfile in prohibit-root.conf pubkey-only.conf sshd-port.conf; do
		mysshddst="/etc/ssh/sshd_config.d/$sshdfile"
		mysshdsrc=".$mysshddst"
		if [ -d "$(dirname "$mysshddst")" ] && [ -f "$mysshdsrc" ]; then suExecCommand install -o root -g root -m 0744 -pv "$mysshdsrc" "$mysshddst"; fi
	done
	suExecCommand systemctl restart sshd.service
}
disable-systemd-sleep() {
	#AllowSuspend=yes				to	AllowSuspend=no
	#AllowHibernation=yes			to	AllowHibernation=no
	#AllowSuspendThenHibernate=yes	to	AllowSuspendThenHibernate=no
	#AllowHybridSleep=yes			to	AllowHybridSleep=no
	sleepconfDir="/etc/systemd/sleep.conf"
	sleepLines="AllowSuspend=yes AllowHibernation=yes AllowSuspendThenHibernate=yes AllowHybridSleep=yes"
	for sleepLine in ${sleepLines}; do
		lineWithoutVal="${sleepLine/yes/}"
		lineWithoutVal="${sleepLine/no/}"
		uncomment			"${lineWithoutVal}"	"$sleepconfDir"
		lineNo="${lineWithoutVal}no"
		setParameterInFile "${sleepconfDir}"	"${lineWithoutVal}"		"${lineNo}"
	done
	suExecCommand systemctl daemon-reload
}
disable-wifi-connections() {
	if (systemctl status wpa_supplicant.service); then suExecCommand systemctl disable --now wpa_supplicant.service; fi
    if (which nmcli 1>/dev/null); then suExecCommand nmcli radio wifi off; fi
	if (which rfkill 1>/dev/null); then suExecCommand rfkill block wlan bluetooth; fi
}
disable-cups-services() {
	if (systemctl status cups-browsed.service); then suExecCommand systemctl disable --now cups-browsed.service; fi
    if (systemctl status cups.service); then suExecCommand systemctl disable --now cups.service; fi
}
cronjob-disable-ipv6() {
    if (systemctl status cron.service); then suExecCommand systemctl enable --now cron.service; fi
}
main() {
	source "${launchDir}/include/test-superuser-privileges.sh"
	source "${launchDir}/include/file-edition.sh"
	sshd-config-settings
    disable-wifi-connections
    disable-cups-services
	disable-systemd-sleep
    cronjob-disable-ipv6
}