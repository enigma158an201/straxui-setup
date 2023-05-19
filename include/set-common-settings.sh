#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi

set-sshd-config-settings() {
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
}

main() {
	source "${launchDir}/include/test-superuser-privileges.sh"
	source "${launchDir}/include/file-edition.sh"
	set-sshd-config-settings
	disable-systemd-sleep
}