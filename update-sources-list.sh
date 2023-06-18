#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"


getInstalledDebianDistCodeName() {
	myetcosrelease=/etc/os-release
	if [ -f "${myetcosrelease}" ]; then
		sOsId="$(grep -i ^ID= "${myetcosrelease}")"
		if [ "$sOsId" = "debian" ]; then 
			sOsRelease="$(grep -i ^VERSION_CODENAME= "${myetcosrelease}")"
			sOsRelease="${sOsRelease##*}"
		else
			exit 2
		fi
	else
		exit 1
	fi
}
sCurrentDistCodename="$(getInstalledDebianDistCodeName)"

installNewSourcesList() {
	mysourceslistdst="/etc/apt/sources.list"
	if [ "$sCurrentDistCodename" = "buster" ]; then			mysourceslistsrc="${launchDir}etc/apt/bullseye-sources.list"
	elif [ "$sCurrentDistCodename" = "bullseye" ]; then		mysourceslistsrc="${launchDir}etc/apt/bookworm-sources.list"
	elif [ "$sCurrentDistCodename" = "bookworm" ]; then		mysourceslistsrc="${launchDir}etc/apt/bookworm-sources.list"
	fi
	mysourceslistbak="${mysourceslistdst}.${sCurrentDistCodename}-gg.save"
	echo -e "\t>>> sauvegarde du fichier ${mysourceslistdst} buster dans ${mysourceslistbak}"
	suExecCommand mv -i "$mysourceslistdst" "$mysourceslistbak"	
	echo -e "\t>>> installation de la version suivante pour ${mysourceslistdst} "
	suExecCommand install -o root -g root -m 0744 -pv "$mysourceslistsrc" "$mysourceslistdst"
	unset mysourceslist{dst,src,bak}
}

main() {
	#if [ "$sCurrentDistCodename" = "buster" ]; then		 installBusterSourcesList
	#elif [ "$sCurrentDistCodename" = "bullseye" ]; then	 installBookwormSourcesList; fi
	installNewSourcesList
}

main