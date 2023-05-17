#!/usr/bin/env bash
set -euxo pipefail

#pwd

aptPreinstall() {
	if [ -x /usr/bin/apt-get ]; then	suExecCommand "bash ${launchDir}/apt-pre-instal-pkg-ubuntu.sh"
	else 								exit 1
	fi
}

main() {
	launchDir="$(dirname "$0")"
	if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
	source "${launchDir}/test-superuser-privileges.sh"
	suExecCommand "install -o root -g root -m 0755 -pv $launchDir/test-superuser-privileges.sh /usr/local/bin/su-alternatives-exec"
	aptPreinstall
}
main