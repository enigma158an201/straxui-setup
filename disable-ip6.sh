#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
source "${launchDir}/include/file-edition.sh"
echo -e "\t>>> proceed set-common-settings.sh"
suExecCommand "bash -c \"${launchDir}/include/set-common-settings.sh\""

blacklist-ip6-kernel-modules() {
	myip6bckldst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	myip6bcklsrc="${launchDir}$myip6bckldst"
	if [ ! -f "$myip6bckldst" ]; then
		echo -e "\t>>> proceed add disable ipv6 file to /etc/sysctl.d/ "
		suExecCommand "mkdir -p /etc/sysctl.d/; install -o root -g root -m 0744 -pv $myip6bcklsrc $myip6bckldst"
	fi
	#todo check if include /etc/systctl.d present -> not necessary
	#suExecCommand update-initramfs -u
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX= /etc/default/grub | grep ipv6.disable || echo "false")"
	bDisabledDefaultIpV6="$(grep ^GRUB_CMDLINE_LINUX_DEFAULT= /etc/default/grub | grep ipv6.disable || echo "false")"
	if [ "$bDisabledIpV6" = "false" ] || [ "$bDisabledDefaultIpV6" = "false" ]; then
		#echo -e "$sCommand \n $sCommandDefault"; read -rp " "
		#suExecCommand ""
		echo -e "\t>>> proceed add disable ipv6 to grub kernel parameters"
		suExecCommandNoPreserveEnv "bash -x -c \"${launchDir}/include/set-grub-kernel-parameter.sh\""
	fi
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

	if [ -x /usr/bin/nmcli ] && (systemctl status NetworkManager); then
		# all=$(LC_ALL=C nmcli dev status | tail -n +2); first=${all%% *}; echo "$first"
		echo -e "\t>>> proceed set disable ipv6 to network manager" ## $(nmcli connection show | awk '{ print $1 }')
		# be careful with connection names including spaces
		suExecCommand "for ConnectionName in $(LC_ALL=C nmcli dev status | tail -n +2 | grep -Eo '^[^ ]+'); do  
			nmcli connection modify \"\$ConnectionName\" ipv6.method disabled || true ; 
		done"
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
	mysshddst="/etc/ssh/sshd_config.d/enable-only-ip4.conf"
	mysshdsrc="${launchDir}$mysshddst"
	echo -e "\t>>> proceed set disable ipv6 to sshd_config" 
	suExecCommand "if [ -d $(dirname $mysshddst) ] && [ -f $mysshdsrc ]; then 		install -o root -g root -m 0744 -pv $mysshdsrc $mysshddst; fi; \
	systemctl reload sshd.service"
}
disable-postfix-ipv6() {
	# mypostfixsrc="${launchDir}$mypostfixdst" -> pas de install mais un sed
	if (which postfix); then
		echo -e "\t>>> proceed set disable ipv6 to postfix mail" 
		suExecCommand "bash -c \"mypostfixdst=/etc/postfix/main.cf;
		if [ -f \$mypostfixdst ]; then
			if (grep -iE '^inet_interfaces = localhost' \$mypostfixdst); then 		comment 'inet_interfaces = localhost' \$mypostfixdst; fi;
			if (! grep -iE '^inet_interfaces = 127.0.0.1' \$mypostfixdst); then 	insertLineAfter 'inet_interfaces = localhost' 'inet_interfaces = 127.0.0.1' \$mypostfixdst; fi;
		fi;
		systemctl reload postfix\""
	fi
}
disable-etc-ntp-ipv6() {
	myntpdst="/etc/ntp.conf"
	if [ -f "$myntpdst" ] && (grep -i "^restrict ::1" "$myntpdst"); then 			echo -e "\t>>> proceed set disable ipv6 to ntp (network time protocol)"
																					suExecCommand "comment \"restrict ::1\" $myntpdst"
	fi
}
disable-etc-chrony-ipv6() {
	mychronydst="/etc/chrony.conf"
	if [ -f "$mychronydst" ] && (grep -i "^OPTIONS=\"-4\"" "$mychronydst"); then 	echo -e "\t>>> proceed set disable ipv6 to chrony (network time protocol)"
																					suExecCommand "appendLineAtEnd \"OPTIONS=\"-4\"\" $mychronydst"
	fi
}
disable-etc-netconfig-ipv6() {
	mynetconfigdst=/etc/netconfig;
	if [ -f "$mynetconfigdst" ]; then
		echo -e "\t>>> proceed set disable ipv6 to netconfig file";
		suExecCommand "source ${launchDir}/include/file-edition.sh;		
		if (grep -i ^udp6 ${mynetconfigdst}); then									comment udp6 ${mynetconfigdst}; fi;
		if (grep -i ^tcp6 ${mynetconfigdst}); then									comment tcp6 ${mynetconfigdst}; fi"
	fi
}
disable-etc-dhcpcdconf-ipv6() {
	mydhcpcdconfdst=/etc/dhcpcd.conf;
	if [ -f "$mydhcpcdconfdst" ]; then
		echo -e "\t>>> proceed set disable ipv6 to netconfig file";
		suExecCommand "source ${launchDir}/include/file-edition.sh;
		if (grep -i ^noipv6rs ${mydhcpcdconfdst}); then 							appendLineAtEnd \"noipv6rs\" ${mydhcpcdconfdst}; fi;
		if (grep -i ^noipv6 ${mydhcpcdconfdst}); then 								appendLineAtEnd \"noipv6\" ${mydhcpcdconfdst}; fi"
	fi
}
disable-ipv6-cron-task() {
	scriptFilename="disable-ip6.sh"
	mycronip6jobdst="/usr/local/bin/$scriptFilename"
	mycronip6jobsrc="${launchDir}/$scriptFilename"
	#example: (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -

	suExecCommand "install -o root -g root -m 0755 -pv $mycronip6jobsrc $mycronip6jobdst; \
	(crontab -l 2>/dev/null; echo \"0 * * * * root $mycronip6jobdst\") | crontab -"
}

main_DisableIpv6() {
	blacklist-ip6-kernel-modules
	blacklist-ip6-NetworkManagement
	disable-etc-hosts-ipv6
	disable-sshd-config-ipv6 
	disable-postfix-ipv6
	disable-etc-ntp-ipv6
	disable-etc-chrony-ipv6
	disable-etc-netconfig-ipv6
	disable-etc-dhcpcdconf-ipv6
	disable-ipv6-cron-task
}

main_DisableIpv6
