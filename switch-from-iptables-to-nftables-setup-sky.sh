#!/usr/bin/env bash

set -euo pipefail #; set -x

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
source "${launchDir}/include/file-edition.sh"

getNetworkManagement() {
	mynetplandst="/etc/netplan/"
	if [ -d "$mynetplandst" ]; then
		for myfile in "$mynetplandst"*; do
			myNetworkRenderer="$(grep -i 'renderer' "$myfile")"
			echo -e "${myNetworkRenderer##* }\n" #echo "${A##* }"
		done
	fi
}
restore-nft-conf () {
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
blacklist-iptables-kernel-modules {
	myiptablesbckldst="/etc/modprobe.d/iptables-blacklist.conf"
	myiptablesbcklsrc=".$myiptablesbckldst"
	suExecCommand install -o root -g root -m 0744 -pv "$myiptablesbcklsrc" "$myiptablesbckldst"
}
mainDisableAndRemoveIptables {
	blacklist-iptables-kernel-modules
	echo "  >>> Remise à zéro des éventuemlles règles iptables chargées en mémoire"
	if [ -x /usr/sbin/iptables ]; then suExecCommand iptables -F; fi
	if [ -x /usr/sbin/ip6tables ]; then suExecCommand ip6tables -F; fi
	echo "  >>> Suppression de ip-tables"
	suExecCommand apt autoremove --purge iptables{,-persistent}
	if (systemctl status NetworkManager); then suExecCommand systemctl restart NetworkManager; fi
}
mainInstallAndSetupNftable {
	suExecCommand apt install nftables
	echo "  >>> Remise à zéro des eventuelles règles nftables chargées en mémoire"
	suExecCommand nft flush ruleset
	suExecCommand nft list ruleset
	echo "  >>> Mise en route du service nftables"
	restore-nft-conf && suExecCommand nft list ruleset
	if true; then
		suExecCommand systemctl enable --now nftables
	else
		suExecCommand systemctl restart nftables
	fi
	if (systemctl status NetworkManager); then suExecCommand systemctl restart NetworkManager; fi
	
	if [ -x /usr/bin/update-alternatives ]; then
		if [ -x /usr/sbin/iptables-nft ]; then suExecCommand update-alternatives --set iptables /usr/sbin/iptables-nft; fi
		if [ -x /usr/sbin/ip6tables-nft ]; then suExecCommand update-alternatives --set ip6tables /usr/sbin/ip6tables-nft; fi
		if [ -x /usr/sbin/arptables-nft ]; then suExecCommand update-alternatives --set arptables /usr/sbin/arptables-nft; fi
		if [ -x /usr/sbin/ebtables-nft ]; then suExecCommand update-alternatives --set ebtables /usr/sbin/ebtables-nft; fi
	fi
}

mainInstallStraxuiDeb {
	installStraxuiDeb="./update-or-install-strax-wallet-deb-bullseye.sh"
	if [ -f "$installStraxuiDeb" ]; then bash "$installStraxuiDeb"; fi
}

mainInstallStraxuiTargz {
	installStraxuiTargz="./install-strax-wallet-gz.sh"
	if [ -f "$installStraxuiTargz" ]; then bash "$installStraxuiTargz"; fi
}

main {
	mainDisableAndRemoveIptables
	mainInstallAndSetupNftable
	if (false); then	mainInstallStraxuiDeb
	elif (false); then	mainInstallStraxuiTargz
	fi
}

main
