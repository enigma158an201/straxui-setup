#!/usr/bin/env bash

set -euo pipefail #; set -x

# this script requires super user privileges and do not contain any suExec
launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"

tSysctlKernelFiles=( 00-disable-ip6-R13.conf 10-magic-sysrq.conf 99-enable-ip4-forward.conf )

set-sysctl-kernel-modules() {
	#todo check if include /etc/systctl.d present -> not necessary
	#disable-sysrq-kernel-modules-sysctl
	echo -e "\t>>> this script will add following non existing files to /etc/sysctl.d\n${tSysctlKernelFiles[*]}"
	for sSysctlFile in "${tSysctlKernelFiles[@]}"; do
		sSysCtlFileDst="/etc/sysctl.d/${sSysctlFile}"
		sSysCtlFileSrc="${launchDir}${sSysCtlFileDst}"
		if [ ! -f "${sSysCtlFileDst}" ]; then
			echo -e "\t>>> proceed add ${sSysCtlFileSrc} to ${sSysCtlFileDst}"
			suExecCommand "mkdir -p \"$(dirname "${sSysCtlFileDst}")\""
			suExecCommand "install -o root -g root -m 0744 -pv ${sSysCtlFileSrc} ${sSysCtlFileDst}"
		fi
	done
	suExecCommand "update-initramfs -u"
}

main_kernel_hardening() {
	set-sysctl-kernel-modules
}
main_kernel_hardening