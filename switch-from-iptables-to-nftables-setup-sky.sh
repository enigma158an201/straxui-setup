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

binNft=$(su - -c 'which nft')

getNetworkManagement() {
	mynetplandst="/etc/netplan/"
	if [ -d "$mynetplandst" ]; then
		for myfile in "$mynetplandst"*; do
			myNetworkRenderer="$(grep -i 'renderer' "$myfile")"
			echo -e "${myNetworkRenderer##* }\n" #echo "${A##* }"
		done
	fi
	unset mynetplandst
}
restore-nft-conf() {
	suExecCommand "mynftconfdst=/etc/nftables.conf; \
	mynftconfsrc=\"\${launchDir}\$mynftconfdst\"; \
	binNft=\$(su - -c 'which nft')\; \
	isErrorFree=\"$(\$binNft -c -f \$mynftconfsrc)\"; \
	if [ \"\$isErrorFree\" = \"\" ]; then \
		echo \"mise en place de la nouvelle version du fichier de configuration nftables\"; \
		suExecCommand \"install -o root -g root -m 0744 -pv \$mynftconfsrc \$mynftconfdst\"; \
	else \
		echo \"\$isErrorFree\"\; \
		exit 1\; \
	fi;
	unset mynftconf{dst,src}"
}
blacklist-iptables-kernel-modules() {
	myiptablesbckldst="/etc/modprobe.d/iptables-blacklist.conf"
	myiptablesbcklsrc=".$myiptablesbckldst"
	suExecCommand install -o root -g root -m 0744 -pv "$myiptablesbcklsrc" "$myiptablesbckldst"
	unset myiptablesbckl{dst,src}
}
mainDisableAndRemoveIptables() {
	blacklist-iptables-kernel-modules
	echo "  >>> Désactivation de ufw si necessaire"
	suExecCommand "if [ -x /usr/sbin/ufw ]; then suExecCommand ufw disable; fi; \
	echo '  >>> Remise à zéro des éventuelles règles iptables chargées en mémoire';
	if [ -x /usr/sbin/iptables ]; then iptables -F; fi; if [ -x /usr/sbin/ip6tables ]; then ip6tables -F; fi; \
	echo '  >>> Suppression de ip-tables';
	for fwPkg in iptables{-persistent,} {g,}ufw; do apt autoremove --purge \"\$fwPkg\" 2>&1; done; \
	if (systemctl status NetworkManager); then suExecCommand systemctl restart NetworkManager; fi"
	unset fwPkg
}
mainInstallAndSetupNftable() {

	suExecCommand "apt install nftables; \
	echo '  >>> Remise à zéro des eventuelles règles nftables chargées en mémoire' \
	$binNft flush ruleset; $binNft list ruleset"
	echo "  >>> Mise en route du service nftables"
	restore-nft-conf #&& suExecCommand $binNft list ruleset
	if true; then
		suExecCommand systemctl enable --now nftables
	else
		suExecCommand systemctl restart nftables
	fi
	if (systemctl status NetworkManager); then suExecCommand systemctl restart NetworkManager; fi
	
	if [ -x /usr/bin/update-alternatives ]; then
		suExecCommand "if [ -x /usr/sbin/iptables-nft ]; then update-alternatives --set iptables /usr/sbin/iptables-nft; fi; \
		if [ -x /usr/sbin/ip6tables-nft ]; then update-alternatives --set ip6tables /usr/sbin/ip6tables-nft; fi; \
		if [ -x /usr/sbin/arptables-nft ]; then update-alternatives --set arptables /usr/sbin/arptables-nft; fi; \
		if [ -x /usr/sbin/ebtables-nft ]; then update-alternatives --set ebtables /usr/sbin/ebtables-nft; fi"
	fi
}

mainInstallStraxuiDeb() {
	installStraxuiDeb="./update-or-install-strax-wallet-deb-bullseye.sh"
	if [ -f "$installStraxuiDeb" ]; then bash "$installStraxuiDeb"; fi
	unset installStraxuiDeb
}

mainInstallStraxuiTargz() {
	installStraxuiTargz="./install-strax-wallet-gz.sh"
	if [ -f "$installStraxuiTargz" ]; then bash "$installStraxuiTargz"; fi
	unset installStraxuiTargz
}

main() {
	mainDisableAndRemoveIptables
	mainInstallAndSetupNftable
	read -rp "Install straxui wallet from deb file (1) or from tarball (2), other key to do nothing" -n 1 installStraxui
	if [ "$installStraxui" = "1" ]; then	mainInstallStraxuiDeb
	elif [ "$installStraxui" = "2" ]; then	mainInstallStraxuiTargz
	fi
	unset installStraxui
}
main
