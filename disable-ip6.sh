#!/usr/bin/env bash

set -euo pipefail #; set -x

disable-etc-hosts-ipv6() {
	if (false); then
		cp -p /etc/hosts /etc/hosts.disableipv6
		sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
	fi
}
disable-sshd-config-ipv6() {
	mysshddst="/etc/ssh/sshd_config.d/enable-only-ip4.conf"
	mysshdsrc=".$mysshddst"
	if [ -d "$(dirname "$mysshddst")" ] && [ -f "$mysshdsrc" ]; then suExecCommand install -o root -g root -m 0744 -pv "$mysshdsrc" "$mysshddst"; fi
	suExecCommand systemctl restart sshd.service
}
disable-postfix-ipv6() {
	if (which postfix); then
		mypostfixdst="/etc/postfix/main.cf" # mypostfixsrc=".$mypostfixdst" -> pas de install mais un sed
		if [ -f "$mypostfixdst" ]; then
			if (grep -i "^inet_interfaces = localhost" "$mypostfixdst"); then comment "inet_interfaces = localhost" "$mypostfixdst"; fi
			if (! grep -i "^inet_interfaces = 127.0.0.1" "$mypostfixdst"); then insertLineAfter "inet_interfaces = localhost" "inet_interfaces = 127.0.0.1" "$mypostfixdst"; fi
		fi
		suExecCommand systemctl restart postfix
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
}

main() {
    mainDisableIpv6
}
main