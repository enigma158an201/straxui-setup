#!/usr/bin/env bash

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [ "${sLaunchDir}" = "." ]; then sLaunchDir="$(pwd)"; elif [ "${sLaunchDir}" = "include" ]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
sSystemdHostnameFile=/etc/hostname
sHostsFile=/etc/hosts
sOsReleaseFile=/etc/os-release

getSystemdHostnameFileContent() {
	cat "${sSystemdHostnameFile}"
}
getOsRelease() {
	if [ -r "${sOsReleaseFile}" ]; then
		sOsIdLine=$(grep -i '^ID=' "${sOsReleaseFile}")
		echo "${sOsIdLine//ID=/}" #sOsId=
	else
		return 1
	fi
}
getProductName() {
	if command -v dmidecode &> /dev/null; then
		dmidecode -s system-product-name #sHardwareModel=$()
	else
		return 1
	fi
}
getNewHostname() {
	if sHardwareModel=$(getProductName) && sOsId=$(getOsRelease); then
		echo "${sHardwareModel,,}-${sOsId}"
	else
		return 1
	fi
}
updateHostname() {
	if [ ! "${sOldHostname}" = "${sNewHostname}" ]; then
		echo -e "\t>>> le nom de la machine ne correspond à celui determiné par le script, tentative de remplacement du nom ${sOldHostname} par ${sNewHostname} dans le fichier ${sSystemdHostnameFile}"
		if [ -w "${sSystemdHostnameFile}" ]; then		
			sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${sSystemdHostnameFile}"
		elif [ -r "${sSystemdHostnameFile}" ]; then
			suExecCommandNoPreserveEnv sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${sSystemdHostnameFile}"
		else
			return 1
		fi
	fi
}
updateHosts() {
	if (grep -w "${sOldHostname}" "${sHostsFile}" && ! grep -w "${sNewHostname}" "${sHostsFile}" ); then
		echo -e "\t>>> le nom de la machine ne correspond pas à celui determiné par le script, tentative de remplacement du nom ${sOldHostname} par ${sNewHostname} dans le fichier ${sHostsFile}"
		if [ -w "${sHostsFile}" ]; then
			echo "-w"
			sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${sHostsFile}"
		elif [ -r "${sHostsFile}" ]; then
			echo "-r"
			suExecCommandNoPreserveEnv sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${sSystemdHostnameFile}"
		else
			return 1
		fi
	fi
}

main_set_hostname() {
	#source ${sLaunchDir}/include/test-superuser-privileges.sh
	#if systemd
	sOldHostname="$(getSystemdHostnameFileContent)"
	sNewHostname="$(getNewHostname)"
	#replace old hostname by new one if needed
	updateHostname
	updateHosts
}
main_set_hostname