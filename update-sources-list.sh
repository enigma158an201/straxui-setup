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
		sOsId="${sOsId##*=}"
		if [ "$sOsId" = "debian" ]; then 
			sOsRelease="$(grep -i ^VERSION_CODENAME= "${myetcosrelease}")"
			sOsRelease="${sOsRelease##*=}"
			echo "${sOsRelease}"
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
	if [ "${sCurrentDistCodename}" = "buster" ]; then			mysourceslistsrc="${launchDir}/etc/apt/bullseye-sources.list"
	elif [ "${sCurrentDistCodename}" = "bullseye" ]; then		mysourceslistsrc="${launchDir}/etc/apt/bookworm-sources.list"
	elif [ "${sCurrentDistCodename}" = "bookworm" ]; then		mysourceslistsrc="${launchDir}/etc/apt/bookworm-sources.list"
	fi
	mysourceslistbak="${mysourceslistdst}.${sCurrentDistCodename}-gg.save"
	if [ -f "${mysourceslistdst}" ]; then
		sResultDiff="$(diff "${mysourceslistsrc}" "${mysourceslistdst}")"
		if [ "${sResultDiff}" = "" ]; then bDiffApt="false"
		else bDiffApt="true"
		fi 	
	fi
	echo -e "\t>>> Avant d'installer la nouvelle version, s'assurer d'avoir bien appliqué les dernieres mises à jour avec \`apt update && apt upgrade\`"
	echo -e "\t>>> différences entre les versions de apt sources.list \n ${sResultDiff}"
	if [ "${bDiffApt}" = "true " ]; then read -rp " Confirmer la nouvelle version? (o/N)" -n 1 confirmOverwriteRepo
	else confirmOverwriteRepo="N"; fi
	if [ "${confirmOverwriteRepo^^}" = "O" ] || [ "${bDiffApt}" = "true" ]; then
		
		echo -e "\t>>> sauvegarde du fichier ${mysourceslistdst} pour Debian ${sCurrentDistCodename} dans ${mysourceslistbak}"
		if [ -f "${mysourceslistdst}" ]; then 
			suExecCommand mv -i "${mysourceslistdst}" "${mysourceslistbak}"	
		fi
		echo -e "\t>>> installation de la version suivante pour ${mysourceslistdst}"
		suExecCommand install -o root -g root -m 0744 -pv "${mysourceslistsrc}" "${mysourceslistdst}"
		if true; then 
			echo -e "\t>>> nouvelle version de ${mysourceslistdst} installee avec succès \
			\n\t>>> pour installer les nouveaux paquets, lancer en root (avec sudo ou su - ET sans les crochets) :\
			\n \t # [sudo] apt update && [sudo] apt dist-upgrade "
		fi
	elif [ "${bDiffApt}" = "false" ]; then
		echo -e "\t>>> pas de modification pour ${mysourceslistsrc}"
	else
		echo -e "\t>>> abandon de l'installation de la version suivante pour ${mysourceslistsrc}"
		exit 1
	fi
	unset mysourceslist{dst,src,bak}
}

main() {
	#if [ "${sCurrentDistCodename}" = "buster" ]; then		 installBusterSourcesList
	#elif [ "${sCurrentDistCodename}" = "bullseye" ]; then	 installBookwormSourcesList; fi
	installNewSourcesList
}

main