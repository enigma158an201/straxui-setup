#!/usr/bin/env bash

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"

grubUpdate() {
	if command -v update-grub &> /dev/null; then 		update-grub
	elif command -v update-grub2 &> /dev/null; then 	update-grub2
	elif command -v grub2-mkconfig &> /dev/null; then 	grub2-mkconfig -o /boot/grub2/grub.cfg
	elif command -v grub-mkconfig &> /dev/null; then 	grub-mkconfig -o /boot/grub/grub.cfg
	fi
}
grubDisableIpv6() {
	#sCommand="sed -i '/GRUB_CMDLINE_LINUX/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
	#sCommandDefault="sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
	##echo -e "${sCommand} \n ${sCommandDefault}"
	#${sCommand}
	#${sCommandDefault} 			#sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ ipv6.disable=1"/' /etc/default/grub then #sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ ipv6.disable=1"/' /etc/default/grub
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX= /etc/default/grub | grep ipv6.disable || echo "false")"
	bDisabledDefaultIpV6="$(grep ^GRUB_CMDLINE_LINUX_DEFAULT= /etc/default/grub | grep ipv6.disable || echo "false")"
	if [[ "${bDisabledIpV6}" = "false" ]]; then 				sed -i '/GRUB_CMDLINE_LINUX=/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub; fi
	if [[ "${bDisabledDefaultIpV6}" = "false" ]]; then 		sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub; fi
}
grubDisableIommu() {
	bDisabledIommu="$(grep ^GRUB_CMDLINE_LINUX= /etc/default/grub | grep iommu || echo "false")"
	bDisabledDefaultIommu="$(grep ^GRUB_CMDLINE_LINUX_DEFAULT= /etc/default/grub | grep iommu || echo "false")"
	if [[ "${bDisabledIommu}" = "false" ]]; then 				sed -i '/GRUB_CMDLINE_LINUX=/ s/\"$/ iommu=force\"/' /etc/default/grub; fi
	if [[ "${bDisabledDefaultIommu}" = "false" ]]; then 		sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ iommu=force\"/' /etc/default/grub; fi
}
grubDisableKernelModules() {
	bDisabledKMod="$(grep ^GRUB_CMDLINE_LINUX= /etc/default/grub | grep kernel.modules_disabled || echo "false")"
	bDisabledDefaultKMod="$(grep ^GRUB_CMDLINE_LINUX_DEFAULT= /etc/default/grub | grep kernel.modules_disabled || echo "false")"
	if [[ "${bDisabledKMod}" = "false" ]]; then 				sed -i '/GRUB_CMDLINE_LINUX=/ s/\"$/ kernel.modules_disabled=1\"/' /etc/default/grub; fi
	if [[ "${bDisabledDefaultKMod}" = "false" ]]; then 		sed -i '/GRUB_CMDLINE_LINUX_DEFAULT=/ s/\"$/ kernel.modules_disabled=1\"/' /etc/default/grub; fi
}
setPasswordGrub() {
	sGrubUsersDst="/etc/grub.d/01_users"
	sGrubUsersSrc="${sLaunchDir}${sGrubUsersDst}"
	sGrubDir=$(dirname ${sGrubUsersDst})
	mkdir -p "${sGrubDir}" && chmod -R 0700 "${sGrubDir}"
	if [[ ! -f ${sGrubUsersDst} ]]; then
		echo -e "\t--> proceed add grub password ${sGrubUsersDst}"
		#suExecCommand "mkdir -p \"$(dirname "${sGrubUsersDst}")\""
		install -o root -g root -m 0700 -pv "${sGrubUsersSrc}" "${sGrubUsersDst}"
		if command -v grub-mkpasswd-pbkdf2 &> /dev/null; then 		grub-mkpasswd-pbkdf2
		elif command -v grub2-mkpasswd-pbkdf2 &> /dev/null; then 	grub2-mkpasswd-pbkdf2; fi
	fi
	unset sGrub{Users{Dst,Src},Dir}
}
main_grubsettings() {
	grubDisableIpv6
	grubDisableIommu
	grubDisableKernelModules
	setPasswordGrub
	grubUpdate
}
main_grubsettings