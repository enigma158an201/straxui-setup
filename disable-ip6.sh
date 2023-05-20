#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/test-superuser-privileges.sh"
source "${launchDir}/include/file-edition.sh"

grubUpdate() {
	if [ -x /usr/sbin/update-grub ]; then suExecCommand update-grub
	elif [ -x /usr/sbin/grub2-mkconfig ]; then suExecCommand grub2-mkconfig -o /boot/grub2/grub.cfg
	elif [ -x /usr/sbin/grub-mkconfig ]; then suExecCommand grub-mkconfig -o /boot/grub/grub.cfg
	fi
}
blacklist-ip6-kernel-modules() {
	myip6bckldst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	myip6bcklsrc="${launchDir}$myip6bckldst"
	suExecCommand mkdir -p /etc/sysctl.d/
	suExecCommand install -o root -g root -m 0744 -pv "$myip6bcklsrc" "$myip6bckldst"
	#todo check if include /etc/systctl.d present -> not necessary
	#suExecCommand update-initramfs -u
	#todo check if already added
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX /etc/default/grub | grep ipv6.disable || echo "false")"
	if [ "$bDisabledIpV6" = "false" ]; then
		sCommand="sed -i '/GRUB_CMDLINE_LINUX/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
		sCommandDefault="sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
		suExecCommand "$sCommand" 			#sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ ipv6.disable=1"/' /etc/default/grub
		suExecCommand "$sCommandDefault" 	#sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ ipv6.disable=1"/' /etc/default/grub
		grubUpdate
	fi
}
blacklist-ip6-NetworkManagement() {
	#non persistant, but take effect immediately
	if false; then
		suExecCommand sysctl -w net.ipv6.conf.all.disable_ipv6=1
		suExecCommand sysctl -w net.ipv6.conf.default.disable_ipv6=1
		suExecCommand sysctl -w net.ipv6.conf.lo.disable_ipv6=1
		suExecCommand sysctl -p
	fi

	if [ -x /usr/bin/nmcli ] && (systemctl status NetworkManager); then
		# all=$(LC_ALL=C nmcli dev status | tail -n +2); first=${all%% *}; echo "$first"
		for ConnectionName in $(LC_ALL=C nmcli dev status | tail -n +2 | grep -Eo '^[^ ]+'); do # $(nmcli connection show | awk '{ print $1 }') 
			suExecCommand nmcli connection modify "$ConnectionName" ipv6.method "disabled" || true # be careful with connection names including spaces
		done
	fi
	if (systemctl status systemd-networkd); then
		#sed -i '/[Network]/ s/"$/nLinkLocalAddressing=ipv4"/' /etc/systemd/networkd.conf; fi
		if (! grep '^LinkLocalAddressing=ipv4' /etc/systemd/networkd.conf); then suExecCommand sed -i '/^\[Network\].*/a LinkLocalAddressing=ipv4 ' /etc/systemd/networkd.conf ;fi 
	fi
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
	if [ -d "$(dirname "$mysshddst")" ] && [ -f "$mysshdsrc" ]; then suExecCommand install -o root -g root -m 0744 -pv "$mysshdsrc" "$mysshddst"; fi
	suExecCommand systemctl reload sshd.service
}
disable-postfix-ipv6() {
	if (which postfix); then
		mypostfixdst="/etc/postfix/main.cf" # mypostfixsrc="${launchDir}$mypostfixdst" -> pas de install mais un sed
		if [ -f "$mypostfixdst" ]; then
			if (grep -i "^inet_interfaces = localhost" "$mypostfixdst"); then comment "inet_interfaces = localhost" "$mypostfixdst"; fi
			if (! grep -i "^inet_interfaces = 127.0.0.1" "$mypostfixdst"); then insertLineAfter "inet_interfaces = localhost" "inet_interfaces = 127.0.0.1" "$mypostfixdst"; fi
		fi
		suExecCommand systemctl reload postfix
	fi
}
disable-etc-ntp-ipv6() {
	myntpdst="/etc/ntp.conf"
	if [ -f "$myntpdst" ] && (grep -i "^restrict ::1" "$myntpdst"); then comment "restrict ::1" "$myntpdst"; fi
}
disable-etc-chrony-ipv6() {
	mychronydst="/etc/chrony.conf"
	if [ -f "$mychronydst" ] && (grep -i "^OPTIONS=\"-4\"" "$mychronydst"); then appendLineAtEnd "OPTIONS=\"-4\"" "$mychronydst"; fi
}
disable-etc-netconfig-ipv6() {
	mynetconfigdst="/etc/netconfig"
	if [ -f "$mynetconfigdst" ]; then
		if (grep -i "^udp6" "$mynetconfigdst"); then comment "udp6" "$mynetconfigdst"; fi
		if (grep -i "^tcp6" "$mynetconfigdst"); then comment "tcp6" "$mynetconfigdst"; fi
	fi
}
disable-etc-dhcpcdconf-ipv6() {
	mydhcpcdconfdst="/etc/dhcpcd.conf"
	if [ -f "$mydhcpcdconfdst" ]; then
		if (grep -i "^noipv6rs" "$mydhcpcdconfdst"); then 	appendLineAtEnd "noipv6rs" "$mydhcpcdconfdst"; fi
		if (grep -i "^noipv6" "$mydhcpcdconfdst"); then 	appendLineAtEnd "noipv6" "$mydhcpcdconfdst"; fi
	fi
}
disable-ipv6-cron-task() {
	scriptFilename="disable-ip6.sh"
	mycronip6jobdst="/usr/local/bin/$scriptFilename"
	mycronip6jobsrc="./$scriptFilename"
	suExecCommand install -o root -g root -m 0755 -pv "$mycronip6jobsrc" "$mycronip6jobdst"
	#example: (crontab -l 2>/dev/null; echo "*/5 * * * * /path/to/job -with args") | crontab -
	(crontab -l 2>/dev/null; echo "0 * * * * root $mycronip6jobdst") | suExecCommand crontab -
}

mainDisableIpv6() {
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

main() {
	mainDisableIpv6
}
main