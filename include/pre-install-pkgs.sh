#!/usr/bin/env bash
set -euo pipefail #; set -x

#pwd
sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
#source "${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh"

aptPreinstall() {
	if command -v apt-get &> /dev/null; then 	echo -e "/t--> add deps packages for the script to run correctly"
												suExecCommand "source ${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	else 										exit 1
	fi
}

main_aptPreinstall() {
	echo -e "/t--> add script test-superuser-privileges.sh to /usr/local/bin/su-alternatives-exec location"
	suExecCommand "install -o root -g root -m 0755 -pv ${sLaunchDir}/include/test-superuser-privileges.sh /usr/local/bin/su-alternatives-exec"
	aptPreinstall
}
main_aptPreinstall