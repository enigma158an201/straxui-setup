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
function grubUpdate() {
	if [ -x /usr/sbin/update-grub ]; then sudo update-grub
	elif [ -x /usr/sbin/grub2-mkconfig ]; then sudo grub2-mkconfig -o /boot/grub2/grub.cfg
	elif [ -x /usr/sbin/grub-mkconfig ]; then sudo grub-mkconfig -o /boot/grub/grub.cfg
	fi
}
function getNetworkManagement() {
	if [ -f /etc/netplan/* ]; then
		grep -i renderer /etc/netplan/*
	fi
}
function restore-nft-conf () {
	mynftconfdst=/etc/nftables.conf
	mynftconfsrc=".$mynftconfdst"
	isErrorFree=$(sudo nft -c -f "$mynftconfsrc")
	if [ "$isErrorFree" = "" ]; then
		echo "mise en place de la nouvelle version du fichier de configuration nftables"
		sudo install -o root -g root -m 0744 -pv "$mynftconfsrc" "$mynftconfdst"
	else
		echo "$isErrorFree"
		exit 1 # return 1
	fi
}
function blacklist-iptables-kernel-modules {
	myiptablesbckldst="/etc/modprobe.d/iptables-blacklist.conf"
	myiptablesbcklsrc=".$myiptablesbckldst"
	sudo install -o root -g root -m 0744 -pv "$myiptablesbcklsrc" "$myiptablesbckldst"
}
function blacklist-ip6-kernel-modules {
	myip6bckldst="/etc/sysctl.d/00-disable-ip6-R13.conf"
	myip6bcklsrc=".$myip6bckldst"
	sudo mkdir -p /etc/sysctl.d/
	sudo install -o root -g root -m 0744 -pv "$myip6bcklsrc" "$myip6bckldst"
	#todo check if include /etc/systctl.d present -> not necessary
	#sudo update-initramfs -u
	#todo check if already added
	bDisabledIpV6="$(grep ^GRUB_CMDLINE_LINUX /etc/default/grub | grep ipv6.disable || echo "false")"
	if [ "$bDisabledIpV6" = "false" ]; then 
		sudo sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ ipv6.disable=1"/' /etc/default/grub
		grubUpdate
	fi
}
function blacklist-ip6-NetworkManagement() {
	#non persistant, but take effect immediately
	sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
	sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
	sudo sysctl -w net.ipv6.conf.lo.disable_ipv6=1
	sudo sysctl -p

	if [ -x /usr/bin/nmcli ] && (systemctl status NetworkManager); then
		# all=$(LC_ALL=C nmcli dev status | tail -n +2); first=${all%% *}; echo "$first"
		for ConnectionName in $(LC_ALL=C nmcli dev status | tail -n +2 | grep -Eo '^[^ ]+'); do # $(nmcli connection show | awk '{ print $1 }') 
			sudo nmcli connection modify "$ConnectionName" ipv6.method "disabled" || true # be careful with connection names including spaces
		done
	fi
	if (systemctl status systemd-networkd); then
		#sed -i '/[Network]/ s/"$/nLinkLocalAddressing=ipv4"/' /etc/systemd/networkd.conf; fi
		if (! grep '^LinkLocalAddressing=ipv4' /etc/systemd/networkd.conf); then sudo sed -i '/^\[Network\].*/a LinkLocalAddressing=ipv4 ' /etc/systemd/networkd.conf ;fi 
	fi
}
function mainDisableIptablesIp6 {
	restore-nft-conf
	blacklist-iptables-kernel-modules
	blacklist-ip6-kernel-modules
	blacklist-ip6-NetworkManagement
	sudo apt install nftables
	echo "  >>> Remise à zéro des règles chargées en mémoire avant basculement iptables vers nftables"
	sudo iptables -F
	sudo nft flush ruleset
	sudo nft list ruleset
	sudo systemctl restart nftables
	sudo nft list ruleset
	echo "  >>> Suppression de ip-tables"
	sudo apt autoremove --purge iptables{,-persistent}
	sudo apt install --reinstall nftables
	echo "  >>> Mise en route du service nftables"
	#restore-nft-conf
	sudo systemctl enable --now nftables
	sudo systemctl restart NetworkManager


	if [ -x /usr/sbin/iptables-nft ]; then sudo update-alternatives --set iptables /usr/sbin/iptables-nft; fi
	if [ -x /usr/sbin/ip6tables-nft ]; then sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-nft; fi
	if [ -x /usr/sbin/arptables-nft ]; then sudo update-alternatives --set arptables /usr/sbin/arptables-nft; fi
	if [ -x /usr/sbin/ebtables-nft ]; then sudo update-alternatives --set ebtables /usr/sbin/ebtables-nft; fi
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
	if false; then		mainInstallStraxuiDeb
	elif false; then	mainInstallStraxuiTargz
	fi
}

main
