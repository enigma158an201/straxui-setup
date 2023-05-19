#!/usr/bin/env bash
set -euo pipefail #; set -x

#pwd
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi

aptPreinstall() {
	if [ -x /usr/bin/apt-get ]; then	suExecCommand "bash ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh"
	else 								exit 1
	fi
}

main() {
	source "${launchDir}/include/test-superuser-privileges.sh"
	suExecCommand "install -o root -g root -m 0755 -pv $launchDir/include/test-superuser-privileges.sh /usr/local/bin/su-alternatives-exec"
	aptPreinstall
}
main