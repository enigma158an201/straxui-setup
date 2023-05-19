#!/bin/bash

set -euxo pipefail

# https://www.gaelanlloyd.com/blog/migrating-debian-buster-from-iptables-to-nftables/
# https://wiki.archlinux.org/title/Nftables#List_tables

# pour consulter la liste des regles
# sudo nft list tables
# or
# sudo nft list table $family_type $table_name
# or
# nft list chain $family_type $table_name $chain_name

# nftables family 	iptables utility
# ip 				iptables
# ip6 				ip6tables
# inet 				iptables and ip6tables
# arp 				arptables
# bridge 			ebtables

# myifname=enp10s0 # enp4s0

#getSuCmd() {
	#if [ -x /usr/bin/sudo ]; then		suCmd="/usr/bin/sudo"
	#elif [ -x /usr/bin/doas ]; then	 	suCmd="/usr/bin/doas"
	#else								suCmd="su - -c "
	#fi
	#echo "$suCmd"
#}
#if ! sPfxSu="$(getSuCmd)"; then 		exit 02; fi

#getSuQuotes() {
	#if [ -x /usr/bin/sudo ]; then		mySuQuotes=(false)
	#elif [ -x /usr/bin/doas ]; then	 	mySuQuotes=(false)
	#else								mySuQuotes=('"')
	#fi
	#echo "${mySuQuotes[@]}"
#}
#suQuotes="$(getSuQuotes)"
#suExecCommand() {	
	#sCommand="$*"
	#if [ ! "$suQuotes" = "false" ]; then	"$sPfxSu" $suQuotes$sCommand$suQuotes
	#else									"$sPfxSu" $sCommand
	#fi
#}
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/test-superuser-privileges.sh"

comment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	if [ -f "$file" ]; then suExecCommand sed -ri "s:^([ ]*)($regex):\\1$comment_mark\\2:" "$file"; fi
}
appendLineAtEnd() {
	local newLine="${1:?}"
	local file="${2:?}"
	if [ -f "$file" ]; then echo -e "$newLine" | suExecCommand tee -a "$file"; fi
}
insertLineBefore() {
	local regex="${1:?}"
	local newLine="${2:?}"
	local file="${3:?}"
	if [ -f "$file" ]; then suExecCommand sed -ri "/^([ ]*)($regex)/i $newLine" "$file"; fi		#sed -ri "s:^([ ]*)($regex):\\1$newLine\n\\2:" "$file"
}
insertLineAfter() {
	local regex="${1:?}"
	local newLine="${2:?}"
	local file="${3:?}"
	if [ -f "$file" ]; then suExecCommand sed -ri "/^([ ]*)($regex)/a $newLine" "$file"; fi
}
function grubUpdate() {
	if [ -x /usr/sbin/update-grub ]; then suExecCommand update-grub
	elif [ -x /usr/sbin/grub2-mkconfig ]; then suExecCommand grub2-mkconfig -o /boot/grub2/grub.cfg
	elif [ -x /usr/sbin/grub-mkconfig ]; then suExecCommand grub-mkconfig -o /boot/grub/grub.cfg
	fi
}
function getNetworkManagement() {
	mynetplandst="/etc/netplan/"
	if [ -d "$mynetplandst" ]; then
		for myfile in "$mynetplandst"*; do
			myNetworkRenderer="$(grep -i 'renderer' "$myfile")"
			echo -e "${myNetworkRenderer##* }\n" #echo "${A##* }"
		done
	fi
}
function restore-nft-conf () {
	mynftconfdst=/etc/nftables.conf
	mynftconfsrc=".$mynftconfdst"
	isErrorFree=$(suExecCommand nft -c -f "$mynftconfsrc")
	if [ "$isErrorFree" = "" ]; then
		echo "mise en place de la nouvelle version du fichier de configuration nftables"
		suExecCommand install -o root -g root -m 0744 -pv "$mynftconfsrc" "$mynftconfdst"
	else
		echo "$isErrorFree"
		exit 1 # return 1
	fi
}
function disable-etc-hosts-ipv6() {
	if (false); then
		cp -p /etc/hosts /etc/hosts.disableipv6
		sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
	fi
}
function disable-sshd-config-ipv6() {
	mysshddst="/etc/ssh/sshd_config.d/enable-only-ip4.conf"
	mysshdsrc=".$mysshddst"
	if [ -d "$(dirname "$mysshddst")" ] && [ -f "$mysshdsrc" ]; then suExecCommand install -o root -g root -m 0744 -pv "$mysshdsrc" "$mysshddst"; fi
	suExecCommand systemctl restart sshd.service
}
function disable-postfix-ipv6() {
	mypostfixdst="/etc/postfix/main.cf" # mypostfixsrc=".$mypostfixdst" -> pas de install mais un sed
	if [ -f "$mypostfixdst" ]; then 
		if (grep -i "^inet_interfaces = localhost" "$mypostfixdst"); then comment "inet_interfaces = localhost" "$mypostfixdst"; fi
		if (! grep -i "^inet_interfaces = 127.0.0.1" "$mypostfixdst"); then insertLineAfter "inet_interfaces = localhost" "inet_interfaces = 127.0.0.1" "$mypostfixdst"; fi
	fi
	suExecCommand systemctl restart postfix
}
function disable-etc-ntp-ipv6() {
	myntpdst="/etc/ntp.conf"
	if [ -f "$myntpdst" ] && (grep -i "^restrict ::1" "$myntpdst"); then comment "restrict ::1" "$myntpdst"; fi
}
function disable-etc-chrony-ipv6() {
	mychronydst="/etc/chrony.conf"
	if [ -f "$mychronydst" ] && (grep -i "^OPTIONS=\"-4\"" "$mychronydst"); then appendLineAtEnd "OPTIONS=\"-4\"" "$mychronydst"; fi
}
function disable-etc-netconfig-ipv6() {
	mynetconfigdst="/etc/netconfig"
	if [ -f "$mynetconfigdst" ]; then
		if (grep -i "^udp6" "$mynetconfigdst"); then comment "udp6" "$mynetconfigdst"; fi
		if (grep -i "^tcp6" "$mynetconfigdst"); then comment "tcp6" "$mynetconfigdst"; fi
	fi
}
function disable-etc-dhcpcdconf-ipv6() {
	mydhcpcdconfdst="/etc/dhcpcd.conf"
	if [ -f "$mydhcpcdconfdst" ]; then
		if (grep -i "^noipv6rs" "$mydhcpcdconfdst"); then 	appendLineAtEnd "noipv6rs" "$mydhcpcdconfdst"; fi
		if (grep -i "^noipv6" "$mydhcpcdconfdst"); then 	appendLineAtEnd "noipv6" "$mydhcpcdconfdst"; fi
	fi
}
function blacklist-iptables-kernel-modules {
	myiptablesbckldst="/etc/modprobe.d/iptables-blacklist.conf"
	myiptablesbcklsrc=".$myiptablesbckldst"
	suExecCommand install -o root -g root -m 0744 -pv "$myiptablesbcklsrc" "$myiptablesbckldst"
}
function blacklist-ip6-kernel-modules {
	myip6bckldst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	myip6bcklsrc=".$myip6bckldst"
	suExecCommand mkdir -p /etc/sysctl.d/
	suExecCommand install -o root -g root -m 0744 -pv "$myip6bcklsrc" "$myip6bckldst"
	#todo check if include /etc/systctl.d present -> not necessary
	#suExecCommand update-initramfs -u
	#todo check if already added
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX /etc/default/grub | grep ipv6.disable || echo "false")"
	if [ "$bDisabledIpV6" = "false" ]; then
		suExecCommand sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ ipv6.disable=1"/' /etc/default/grub
		suExecCommand sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ ipv6.disable=1"/' /etc/default/grub
		grubUpdate
	fi
}
function blacklist-ip6-NetworkManagement() {
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
function mainDisableIptablesIp6 {
	blacklist-iptables-kernel-modules
	blacklist-ip6-kernel-modules
	blacklist-ip6-NetworkManagement
	disable-etc-hosts-ipv6
	disable-sshd-config-ipv6
	disable-postfix-ipv6
	disable-etc-ntp-ipv6
	disable-etc-chrony-ipv6
	disable-etc-netconfig-ipv6
	disable-etc-dhcpcdconf-ipv6
	suExecCommand apt install nftables
	echo "  >>> Remise à zéro des règles chargées en mémoire avant basculement iptables vers nftables"
	suExecCommand iptables -F
	suExecCommand nft flush ruleset
	suExecCommand nft list ruleset
	suExecCommand systemctl restart nftables
	suExecCommand nft list ruleset
	echo "  >>> Suppression de ip-tables"
	suExecCommand apt autoremove --purge iptables{,-persistent}
	suExecCommand apt install --reinstall nftables
	echo "  >>> Mise en route du service nftables"
	restore-nft-conf
	suExecCommand systemctl enable --now nftables
	suExecCommand systemctl restart NetworkManager

	if [ -x /usr/sbin/iptables-nft ]; then suExecCommand update-alternatives --set iptables /usr/sbin/iptables-nft; fi
	if [ -x /usr/sbin/ip6tables-nft ]; then suExecCommand update-alternatives --set ip6tables /usr/sbin/ip6tables-nft; fi
	if [ -x /usr/sbin/arptables-nft ]; then suExecCommand update-alternatives --set arptables /usr/sbin/arptables-nft; fi
	if [ -x /usr/sbin/ebtables-nft ]; then suExecCommand update-alternatives --set ebtables /usr/sbin/ebtables-nft; fi
}

function mainInstallStraxuiDeb {
	installStraxuiDeb="./update-or-install-strax-wallet-deb-bullseye.sh"
	if [ -f "$installStraxuiDeb" ]; then bash "$installStraxuiDeb"; fi
}

function mainInstallStraxuiTargz {
	installStraxuiTargz="./install-strax-wallet-gz.sh"
	if [ -f "$installStraxuiTargz" ]; then bash "$installStraxuiTargz"; fi
}

function main {
	mainDisableIptablesIp6
	if (false); then	mainInstallStraxuiDeb
	elif (false); then	mainInstallStraxuiTargz
	fi
}

main
