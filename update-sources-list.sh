#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

getInstalledDebianDistCodeName() {
	sEtcOsrelease=/etc/os-release
	if [ -f "${sEtcOsrelease}" ]; then
		sOsId="$(grep -i ^ID= "${sEtcOsrelease}")"
		sOsId="${sOsId##*=}"
		if [ "$sOsId" = "debian" ]; then 
			sOsRelease="$(grep -i ^VERSION_CODENAME= "${sEtcOsrelease}")"
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
	sSourcesListDst="/etc/apt/sources.list"
	if [ "${sCurrentDistCodename}" = "buster" ]; then			sSourcesListSrc="${launchDir}/etc/apt/bullseye-sources.list"
	elif [ "${sCurrentDistCodename}" = "bullseye" ]; then		sSourcesListSrc="${launchDir}/etc/apt/bookworm-sources.list"
	elif [ "${sCurrentDistCodename}" = "bookworm" ]; then		sSourcesListSrc="${launchDir}/etc/apt/trixie-sources.list"
	elif [ "${sCurrentDistCodename}" = "trixie" ]; then			sSourcesListSrc="${launchDir}/etc/apt/forky-sources.list"
	fi
	sSourcesListBak="${sSourcesListDst}.${sCurrentDistCodename}-gg.save"
	if [ -f "${sSourcesListDst}" ]; then
		sResultDiff="$(diff "${sSourcesListSrc}" "${sSourcesListDst}")"
		if [ "${sResultDiff}" = "" ]; then bDiffApt="false"
		else bDiffApt="true"
		fi 	
	fi
	echo -e "\t>>> Avant d'installer la nouvelle version, s'assurer d'avoir bien appliqué les dernieres mises à jour avec \`apt update && apt upgrade\`"
	echo -e "\t>>> différences entre les versions de apt sources.list \n ${sResultDiff}"
	if [ "${bDiffApt}" = "true " ]; then read -rp " Confirmer la nouvelle version? (o/N)" -n 1 confirmOverwriteRepo
	else confirmOverwriteRepo="N"; fi
	if [ "${confirmOverwriteRepo^^}" = "O" ] || [ "${bDiffApt}" = "true" ]; then
		
		echo -e "\t>>> sauvegarde du fichier ${sSourcesListDst} pour Debian ${sCurrentDistCodename} dans ${sSourcesListBak}"
		if [ -f "${sSourcesListDst}" ]; then 
			suExecCommand mv -i "${sSourcesListDst}" "${sSourcesListBak}"	
		fi
		echo -e "\t>>> installation de la version suivante pour ${sSourcesListDst}"
		suExecCommand install -o root -g root -m 0744 -pv "${sSourcesListSrc}" "${sSourcesListDst}"
		if true; then 
			echo -e "\t>>> nouvelle version de ${sSourcesListDst} installee avec succès \
			\n\t>>> pour installer les nouveaux paquets, lancer en root (avec sudo ou su - ET sans les crochets) :\
			\n \t # [sudo] apt update && [sudo] apt dist-upgrade "
		fi
	elif [ "${bDiffApt}" = "false" ]; then
		echo -e "\t>>> pas de modification pour ${sSourcesListSrc} \
		\n\t>>> pour installer les nouveaux paquets, lancer en root (avec sudo ou su - ET sans les crochets) :\
		\n\t # [sudo] apt update && [sudo] apt dist-upgrade "
	else
		echo -e "\t>>> abandon de l'installation de la version suivante pour ${sSourcesListSrc}"
		exit 1
	fi
	unset sSourcesList{Dst,Src,Bak}
}

main_upgrade_sources() {
	installNewSourcesList
}

main_upgrade_sources