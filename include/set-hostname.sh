#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
systemdHostnameFile=/etc/hostname
hostsFile=/etc/hosts
osReleaseFile=/etc/os-release

getSystemdHostnameFileContent() {
	cat "$systemdHostnameFile"
}

getOsRelease() {
	if [ -r "${osReleaseFile}" ]; then
		sOsIdLine=$(grep -i '^ID=' "${osReleaseFile}")
		echo ${sOsIdLine//ID=/} #sOsId=
	else
		return 1
	fi
}

getProductName() {
	if command -v dmidecode 1>/dev/null 2>&1; then
		suExecCommandNoPreserveEnv "dmidecode -s system-product-name" #sHardwareModel=$()
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
		echo " > le nom de la machine ne correspond à celui determiné par le script, tentative de remplacement du nom ${sOldHostname} par ${sNewHostname} dans le fichier ${systemdHostnameFile}"
		if [ -w "${systemdHostnameFile}" ]; then		
			sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${systemdHostnameFile}"
		elif [ -r "${systemdHostnameFile}" ]; then
			suExecCommandNoPreserveEnv sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${systemdHostnameFile}"
		else
			return 1
		fi
	fi
}

updateHosts() {
	if (grep -w "${sOldHostname}" "${hostsFile}" && ! grep -w "${sNewHostname}" "${hostsFile}" ); then
		echo " > le nom de la machine ne correspond à celui determiné par le script, tentative de remplacement du nom ${sOldHostname} par ${sNewHostname} dans le fichier ${hostsFile}"
		if [ -w "${hostsFile}" ]; then
			echo "-w"
			sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${hostsFile}"
		elif [ -r "${hostsFile}" ]; then
			echo "-r"
			suExecCommandNoPreserveEnv sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${systemdHostnameFile}"
		else
			return 1
		fi
	fi

}

main_set_hostname() {
	#source ${launchDir}/include/test-superuser-privileges.sh
	#if systemd
	sOldHostname="$(getSystemdHostnameFileContent)" #$(cat $systemdHostnameFile)
	sNewHostname="$(getNewHostname)"
	#replace old hostname by new one if needed
	#updateHostname
	updateHosts
}
main_set_hostname