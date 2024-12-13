#!/usr/bin/env bash

set -euo pipefail #; set -x
sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"; sLaunchDir="${sLaunchDir//\/\//}"

main_disable_sleep() {
 	source "${sLaunchDir}/include/file-edition.sh"
	sSleepconfDir=/etc/systemd/sleep.conf
	sSleepLines="AllowSuspend=yes AllowHibernation=yes AllowSuspendThenHibernate=yes AllowHybridSleep=yes"
	for sleepLine in ${sSleepLines}; do
		sLineWithoutVal="${sleepLine/yes/}"
		sLineWithoutVal="${sleepLine/no/}"
		#read -rp "${sleepLine}"
		uncomment			"${sLineWithoutVal}"	"${sSleepconfDir}"
		lineNo="${sLineWithoutVal}no"
		setParameterInFile "${sSleepconfDir}"	"${sLineWithoutVal}"		"${lineNo}"
	done
	systemctl daemon-reload
}
main_disable_sleep