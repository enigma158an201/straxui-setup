#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

main_set_hostname() {
    #source ${launchDir}/include/test-superuser-privileges.sh
    hostnameFile=/tmp/hostname
    hostsFile=/tmp/hosts
    sHardwareModel=$(dmidecode -s system-product-name)
    sOsIdLine=$(grep -i '^ID=' /etc/os-release)
    sOsId=${sOsIdLine//ID=/}
    sOldHostname=$(cat $hostnameFile)
    sNewHostname=${sHardwareModel,,}-${sOsId}
    if [ ! "${sOldHostname}" = "${sNewHostname}" ]; then  sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${hostnameFile}"; fi
    if (grep "${sOldHostname}" "${hostsFile}"); then      sed -i.old s/"${sOldHostname}"/"${sNewHostname}"/g "${hostsFile}"; fi
}
main_set_hostname