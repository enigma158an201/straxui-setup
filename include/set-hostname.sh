#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
systemdHostnameFile=/etc/hostname

getSystemdHostnameFileContent() {
	cat "$systemdHostnameFile"
}

main_set_hostname() {
 	#source ${launchDir}/include/test-superuser-privileges.sh
 	hostsFile=/etc/hosts
 	sHardwareModel=$(/usr/sbin/dmidecode -s system-product-name)
 	sOsIdLine=$(grep -i '^ID=' /etc/os-release)
 	sOsId=${sOsIdLine//ID=/}
	#if systemd
 	sOldHostname="$(getSystemdHostnameFileContent)" #$(cat $hostnameFile)
 	sNewHostname=${sHardwareModel,,}-${sOsId}
 	#replace old hostname by new one if needed
	if [ ! "${sOldHostname}" = "${sNewHostname}" ]; then  sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${hostnameFile}"; fi
 	if (grep "${sOldHostname}" "${hostsFile}"); then 	  sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${hostsFile}"; fi
}
main_set_hostname