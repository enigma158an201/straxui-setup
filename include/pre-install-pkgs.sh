#!/usr/bin/env bash
set -euo pipefail #; set -x

#pwd
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh"

aptPreinstall() {
	if command -v apt-get 1>/dev/null 2>&1; then	echo -e "/t>>> add deps packages for the script to run correctly"
													suExecCommand "source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	else 											exit 1
	fi
}

main_aptPreinstall() {
	echo -e "/t>>> add script test-superuser-privileges.sh to /usr/local/bin/su-alternatives-exec location"
	suExecCommand "install -o root -g root -m 0755 -pv $launchDir/include/test-superuser-privileges.sh /usr/local/bin/su-alternatives-exec"
	aptPreinstall
}
main_aptPreinstall