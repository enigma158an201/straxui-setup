#!/usr/bin/env bash

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
source "${sLaunchDir}/include/file-edition.sh"
echo -e "\t>>> proceed set-common-settings.sh"
suExecCommand "bash -c \"${sLaunchDir}/include/set-common-settings.sh\""

blacklist-ip6-kernel-modules() {
	#todo check if include /etc/systctl.d present -> not necessary
	blacklist-ip6-kernel-modules-sysctl
	blacklist-ip6-kernel-modules-grub
	suExecCommand "update-initramfs -u"
}
blacklist-ip6-kernel-modules-sysctl() {
	sIp6BcklDst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	sIp6BcklSrc="${sLaunchDir}${sIp6BcklDst}"
	if [[ ! -f "${sIp6BcklDst}" ]]; then
		echo -e "\t>>> proceed add disable ipv6 file to /etc/sysctl.d/ "
		suExecCommand "mkdir -p \"$(dirname "${sIp6BcklDst}")\""
		suExecCommand "install -o root -g root -m 0744 -pv ${sIp6BcklSrc} ${sIp6BcklDst}"
	fi
	unset sIp6Bckl{Dst,Src}
}
blacklist-ip6-kernel-modules-grub() {
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX= /etc/default/grub | grep ipv6.disable || echo "false")"
	bDisabledDefaultIpV6="$(grep ^GRUB_CMDLINE_LINUX_DEFAULT= /etc/default/grub | grep ipv6.disable || echo "false")"
	if [[ "${bDisabledIpV6}" = "false" ]] || [[ "${bDisabledDefaultIpV6}" = "false" ]]; then
		echo -e "\t>>> proceed add disable ipv6 to grub kernel parameters"
		suExecCommandNoPreserveEnv "bash -x -c \"${sLaunchDir}/include/set-grub-kernel-parameter.sh\""
	fi
	unset bDisabled{,Default}IpV6
}
blacklist-ip6-NetworkManagement() {
	#non persistant, but take effect immediately
	if false; then
		echo -e "\t>>> proceed set disable ipv6 to sysctl kernel parameters"
		suExecCommand "sysctl -w net.ipv6.conf.all.disable_ipv6=1; \
		sysctl -w net.ipv6.conf.default.disable_ipv6=1; \
		sysctl -w net.ipv6.conf.lo.disable_ipv6=1; \
		sysctl -p"
	fi

	if (command -v nmcli &> /dev/null) && (systemctl status NetworkManager); then
		# all=$(LC_ALL=C nmcli dev status | tail -n +2); first=${all%% *}; echo "${first}"
		echo -e "\t>>> proceed set disable ipv6 to network manager" ## $(nmcli connection show | awk '{ print $1 }')
		# be careful with connection names including spaces
		suExecCommand "bash -c \"for ConnectionName in $(LC_ALL=C nmcli dev status | tail -n +2 | grep -Eo '^[^ ]+'); do  
			nmcli connection modify \${ConnectionName} ipv6.method disabled || true ; 
		done\""
	fi
	#if (systemctl status systemd-networkd); then
		##sed -i '/[Network]/ s/"$/nLinkLocalAddressing=ipv4"/' /etc/systemd/networkd.conf; fi
		#if (! grep '^LinkLocalAddressing=ipv4' /etc/systemd/networkd.conf); then	suExecCommand sed -i '/^\[Network\].*/a LinkLocalAddressing=ipv4 ' /etc/systemd/networkd.conf ;fi 
	#fi
}
disable-etc-hosts-ipv6() {
	if (false); then
		cp -p /etc/hosts /etc/hosts.disableipv6
		sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
	fi
}
disable-sshd-config-ipv6() {
	sSshdDst="/etc/ssh/sshd_config.d/enable-only-ip4.conf"
	sSshdSrc="${sLaunchDir}${sSshdDst}"
	echo -e "\t>>> proceed set disable ipv6 to sshd_config" 
	suExecCommand "bash -c \"if [[ -d $(dirname ${sSshdDst}) ]] && [[ -f ${sSshdSrc} ]]; then 	install -o root -g root -m 0744 -pv ${sSshdSrc} ${sSshdDst}; fi; \
	systemctl reload sshd.service\""
	unset sSshdSrc{Dst,Src}
}
disable-postfix-ipv6() {
	# sPostfixSrc="${sLaunchDir}${sPostfixDst}" -> pas de install mais un sed
	if command -v postfix &> /dev/null; then
		echo -e "\t>>> proceed set disable ipv6 to postfix mail" 
		suExecCommand "bash -c \"sPostfixDst=/etc/postfix/main.cf;
		if [[ -f \${sPostfixDst} ]]; then
			if (grep -iE '^inet_interfaces = localhost' \${sPostfixDst}); then 		comment 'inet_interfaces = localhost' \${sPostfixDst}; fi;
			if (! grep -iE '^inet_interfaces = 127.0.0.1' \${sPostfixDst}); then 	insertLineAfter 'inet_interfaces = localhost' 'inet_interfaces = 127.0.0.1' \${sPostfixDst}; fi;
		fi;
		systemctl reload postfix\""
	fi
}
disable-etc-ntp-ipv6() {
	sNtpdDst="/etc/ntp.conf"
	if [[ -f "${sNtpdDst}" ]] && (grep -i "^restrict ::1" "${sNtpdDst}"); then 	echo -e "\t>>> proceed set disable ipv6 to ntp (network time protocol)"
																				suExecCommand "comment \"restrict ::1\" ${sNtpdDst}"
	fi
	unset sNtpdDst
}
disable-etc-chrony-ipv6() {
	sChronyDst="/etc/chrony.conf"
	if [[ -f "${sChronyDst}" ]] && (grep -i "^OPTIONS=\"-4\"" "${sChronyDst}"); then 	echo -e "\t>>> proceed set disable ipv6 to chrony (network time protocol)"
																					suExecCommand "appendLineAtEnd \"OPTIONS=\"-4\"\" ${sChronyDst}"
	fi
	unset sChronyDst
}
disable-etc-netconfig-ipv6() {
	sNetConfigDst=/etc/netconfig;
	if [[ -f "${sNetConfigDst}" ]]; then
		echo -e "\t>>> proceed set disable ipv6 to netconfig file";
		suExecCommand "source ${sLaunchDir}/include/file-edition.sh;		
		if (grep -i ^udp6 ${sNetConfigDst}); then 	comment udp6 ${sNetConfigDst}; fi;
		if (grep -i ^tcp6 ${sNetConfigDst}); then 	comment tcp6 ${sNetConfigDst}; fi"
	fi
	unset sNetConfigDst
}
disable-etc-dhcpcdconf-ipv6() {
	sDhcpcdConfigDst=/etc/dhcpcd.conf;
	if [[ -f "${sDhcpcdConfigDst}" ]]; then
		echo -e "\t>>> proceed set disable ipv6 to netconfig file"
		suExecCommand "source ${sLaunchDir}/include/file-edition.sh;
		if (grep -i ^noipv6rs ${sDhcpcdConfigDst}); then 		appendLineAtEnd \"noipv6rs\" ${sDhcpcdConfigDst}; fi;
		if (grep -i ^noipv6 ${sDhcpcdConfigDst}); then 			appendLineAtEnd \"noipv6\" ${sDhcpcdConfigDst}; fi"
	fi
	unset sDhcpcdConfigDst
}
disable-ipv6-cron-task() {
	scriptFilename="disable-ip6.sh"
	sCronIp6JobDst="/usr/local/bin/${scriptFilename}"
	sCronIp6JobSrc="${sLaunchDir}/${scriptFilename}"
	#example: (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -
	echo -e "\t>>> proceed set install crontab job"
	suExecCommand "install -o root -g root -m 0755 -pv ${sCronIp6JobSrc} ${sCronIp6JobDst}; \
	(crontab -l 2>/dev/null; echo \"0 * * * * root ${sCronIp6JobDst}\") | crontab -"
	unset sCronIp6Job{Src,Dst}
}

main_DisableIpv6() {
	blacklist-ip6-kernel-modules
	# blacklist-ip6-NetworkManagement
	# disable-etc-hosts-ipv6
	disable-sshd-config-ipv6
	disable-postfix-ipv6
	disable-etc-ntp-ipv6
	disable-etc-chrony-ipv6
	#disable-etc-netconfig-ipv6
	#disable-etc-dhcpcdconf-ipv6
	if command -v crontab &> /dev/null; then 	disable-ipv6-cron-task; fi
}

main_DisableIpv6
