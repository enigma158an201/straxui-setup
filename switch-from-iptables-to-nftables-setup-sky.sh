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

# sIfDevName=enp10s0 # enp4s0

#getSuCmd() {
	#if command -v sudo &> /dev/null; then		suCmd="/usr/bin/sudo"
	#elif command -v doas&> /dev/null; then	 	suCmd="/usr/bin/doas"
	#else										suCmd="su - -c "
	#fi
	#echo "$suCmd"
#}
#if ! sPfxSu="$(getSuCmd)"; then 		exit 02; fi

#getSuQuotes() {
	#if command -v sudo &> /dev/null; then		sSuQuotes=(false)
	#elif command -v doas&> /dev/null; then	 	sSuQuotes=(false)
	#else										sSuQuotes=('"')
	#fi
	#echo "${sSuQuotes[@]}"
#}
#suQuotes="$(getSuQuotes)"
#suExecCommand() {
	#sCommand="$*"
	#if [[ ! "$suQuotes" = "false" ]]; then	"$sPfxSu" $suQuotes$sCommand$suQuotes
	#else									"$sPfxSu" $sCommand
	#fi
#}
sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
source "${sLaunchDir}/include/file-edition.sh"

sBinNft=$(suExecCommandNoPreserveEnv "command -v nft")

restore-nft-conf() {
	echo -e "\t>>> mise en place de la nouvelle version du fichier de configuration nftables"
	sNftConfDst=/etc/nftables.conf
	sNftConfSrc="${sLaunchDir}${sNftConfDst}"
	suExecCommandNoPreserveEnv " \
	#sBinNft=\$(which nft); \
	isErrorFree=\"$(${sBinNft} -c -f "${sNftConfSrc}" && echo \"true\")\"; \
	if [[ \"\$isErrorFree\" = \"true\" ]]; then \
		#echo \"mise en place de la nouvelle version du fichier de configuration nftables\"; \
		install -o root -g root -m 0744 -pv ${sNftConfSrc} ${sNftConfDst}; \
	else \
		echo \"\$isErrorFree\"; \
		exit 1; \
	fi"
	unset sNftConf{Dst,Src}
}
blacklist-iptables-kernel-modules() {
	echo -e "\t>>> désactivation totale des modules de iptables"
	sIptablesBcklDst="/etc/modprobe.d/iptables-blacklist.conf"
	sIptablesBcklSrc="${sLaunchDir}${sIptablesBcklDst}"
	suExecCommand install -o root -g root -m 0744 -pv "${sIptablesBcklSrc}" "${sIptablesBcklDst}"
	unset sIptablesBckl{Dst,Src}
}
mainDisableAndRemoveIptables() {
	blacklist-iptables-kernel-modules
	echo -e "\t>>> Désactivation de ufw si necessaire"
	suExecCommand "if command -v ufw &> /dev/null; then suExecCommand ufw disable; fi; \
	echo '  >>> Remise à zéro des éventuelles règles iptables chargées en mémoire';
	if command -v iptables &> /dev/null; then iptables -F; fi; if command -v ip6tables &> /dev/null; then ip6tables -F; fi; \
	echo '  >>> Suppression de ip-tables';
	for fwPkg in iptables{-persistent,} {g,}ufw; do apt-get autoremove --purge \"\$fwPkg\" 2>&1; done; \
	if (systemctl status NetworkManager); then systemctl restart NetworkManager; fi"
	unset fwPkg
}
mainInstallAndSetupNftable() {
	echo -e "\t>>> Installation du firewall nftables"
	suExecCommand "apt-get install nftables; \
	echo '  >>> Remise à zéro des eventuelles règles nftables chargées en mémoire' \
	${sBinNft} flush ruleset; ${sBinNft} list ruleset"
	echo -e "\t>>> Mise en route du service nftables"
	restore-nft-conf #&& suExecCommand ${sBinNft} list ruleset
	suExecCommand "if true; then
		systemctl enable --now nftables
	else
		 systemctl restart nftables
	fi
	if (systemctl status NetworkManager); then systemctl restart NetworkManager; fi"
	
	if command -v update-alternatives &> /dev/null; then
		echo -e "\t>>> installation des alternatives nftables"
		suExecCommand "if [[ -x /usr/sbin/iptables-nft ]]; then update-alternatives --set iptables /usr/sbin/iptables-nft; fi; \
		if command -v /usr/sbin/ip6tables-nft; then update-alternatives --set ip6tables /usr/sbin/ip6tables-nft; fi; \
		if command -v arptables-nft; then update-alternatives --set arptables /usr/sbin/arptables-nft; fi; \
		if command -v ebtables-nft; then update-alternatives --set ebtables /usr/sbin/ebtables-nft; fi"
	fi
}

mainInstallStraxuiDeb() {
	installStraxuiDeb="${sLaunchDir}/update-or-install-strax-wallet-deb-bullseye.sh"
	if [[ -f "${installStraxuiDeb}" ]]; then bash "${installStraxuiDeb}"; fi
	unset installStraxuiDeb
}

mainInstallStraxuiTargz() {
	installStraxuiTargz="${sLaunchDir}/install-strax-wallet-gz.sh"
	if [[ -f "${installStraxuiTargz}" ]]; then bash "${installStraxuiTargz}"; fi
	unset installStraxuiTargz
}

main_iptables_to_nftables() {
	mainDisableAndRemoveIptables
	mainInstallAndSetupNftable
	read -rp "Install straxui wallet from deb file (1) or from tarball (2), other key to do nothing" -n 1 installStraxui
	if [[ "${installStraxui}" = "1" ]]; then	mainInstallStraxuiDeb
	elif [[ "${installStraxui}" = "2" ]]; then	mainInstallStraxuiTargz
	fi
	unset installStraxui
}
main_iptables_to_nftables
