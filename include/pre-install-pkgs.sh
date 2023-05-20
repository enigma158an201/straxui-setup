#!/usr/bin/env bash
set -euo pipefail #; set -x

#pwd
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/test-superuser-privileges.sh"
source "${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh"

aptPreinstall() {
	if [ -x /usr/bin/apt-get ]; then	suExecCommand "source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	else 								exit 1
	fi
}

main() {
	
	suExecCommand "install -o root -g root -m 0755 -pv $launchDir/include/test-superuser-privileges.sh /usr/local/bin/su-alternatives-exec"
	aptPreinstall
}
main