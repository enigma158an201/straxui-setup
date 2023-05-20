#!/usr/bin/env bash

set -euo pipefail #; set -x
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"

main() {
    source "${launchDir}/include/file-edition.sh"
	sleepconfDir=/etc/systemd/sleep.conf
	sleepLines="AllowSuspend=yes AllowHibernation=yes AllowSuspendThenHibernate=yes AllowHybridSleep=yes"
	for sleepLine in ${sleepLines}; do
		lineWithoutVal="${sleepLine/yes/}"
		lineWithoutVal="${sleepLine/no/}"
		read -rp "$sleepLine"
		uncomment			"${lineWithoutVal}"	"${sleepconfDir}"
		lineNo="${lineWithoutVal}no"
		setParameterInFile "${sleepconfDir}"	"${lineWithoutVal}"		"${lineNo}"
	done
	systemctl daemon-reload
}
main