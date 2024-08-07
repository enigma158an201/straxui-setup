#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

sEtcOsReleasePath=/etc/os-release
sVirtualIpVpnServer=192.168.11.1 # constant fixed for all machines
sVirtualIpVpnClient=192.168.11.2
sPortVpnServer=51820
sSshAliasVpnServer=freebox-delta-local
sSshAliasVpnClient=gwen@192.168.0.53 #gl553vd-archlinux

echo -e "to do: get free ip address for new client, or check existing ip"
sEtcWg=/etc/wireguard

checkIfDebianId() {
	if [ -r "${sEtcOsReleasePath}" ]; then
        sIsDebian="$(grep -i "^ID=" "${sEtcOsReleasePath}" || echo "false")"
		sIsDebianLike="$(grep -i "^ID_LIKE=" "${sEtcOsReleasePath}" || echo "false")"
		if [[ ${sIsDebian,,} =~ debian ]] || [[ ${sIsDebianLike,,} =~ debian ]]; then
			echo "true"
		else
			echo "false"
			#exit 1
		fi
	else
		echo "false"
		#exit 1
	fi
}
installWireguardDeb() {
	echo -e "\t>>> Install wireguard for debian"
	suExecCommand "apt-get install -y wireguard"	
}
setWgKeysName() {
	sClientPubKey=${sEtcWg}/${sHostnameVpnClient}.pub.key
	sClientPrvKey=${sEtcWg}/${sHostnameVpnClient}.key
	sServerPubKey=${sEtcWg}/${sHostnameVpnServer}.pub.key
	sServerPrvKey=${sEtcWg}/${sHostnameVpnServer}.key
	export sClientPrvKey sClientPubKey sServerPubKey sServerPrvKey
}
setKeysWireguard() {
	echo -e "\t>>> set private and pulic keys for wireguard"
	if [ "${1}" -eq "1" ]; then
		sPubKey=${sClientPubKey}
		sPrvKey=${sClientPrvKey}
	elif [ "${1}" -eq "2" ]; then
		sPubKey=${sServerPubKey}
		sPrvKey=${sServerPrvKey}
	fi
	suExecCommand "bash -c \"mkdir -p ${sEtcWg} && cd ${sEtcWg}/ || exit 1
		umask 077
		if ! test -e ${sPrvKey} && ! test -e ${sPubKey}; then
			#wg genkey | tee /etc/wireguard/private.key && cat /etc/wireguard/private.key | wg pubkey | tee /etc/wireguard/public.key
			wg genkey | tee ${sPrvKey} | wg pubkey > ${sPubKey}
		fi\"
		if true; then
			chmod -R 0600 ${sEtcWg}
		fi"
}
setIp4ForwardSysctl() {
	sIp4FwdDst="/etc/sysctl.d/99-enable-ip4-forward.conf"
	sIp4FwdSrc="${launchDir}$sIp4FwdDst"
	if [ ! -f "$sIp4FwdDst" ]; then
		echo -e "\t>>> proceed add enable ipv4 formward file to /etc/sysctl.d/ "
		suExecCommand "mkdir -p \"$(dirname "$sIp4FwdDst")\""
		suExecCommand "install -o root -g root -m 0744 -pv $sIp4FwdSrc $sIp4FwdDst"
	fi
	suExecCommand "sysctl --system" #reload sysctl conf files without reboot
}
setIp6ForwardSysctl() {
	sIp6FwdDst="/etc/sysctl.d/99-enable-ip6-forward.conf"
	sIp6FwdSrc="${launchDir}$sIp6FwdDst"
	if [ ! -f "$sIp6FwdDst" ]; then
		echo -e "\t>>> proceed add enable ipv6 formward file to /etc/sysctl.d/ "
		suExecCommand "mkdir -p \"$(dirname "$sIp6FwdDst")\""
		suExecCommand "install -o root -g root -m 0744 -pv $sIp6FwdSrc $sIp6FwdDst"
	fi
	suExecCommand "sysctl --system" #reload sysctl conf files without reboot
}
getEchoWgKey() {
	sSshAlias=${1}
	sKeyFile=${2}
	# shellcheck disable=SC2029
	ssh "${sSshAlias}" "sudo -S cat \"${sKeyFile}\" || su - -c cat \"${sKeyFile}\""
}
setLinksServer() {
	sSrvPrivKey="$(suExecCommand "cat ${sServerPrvKey}")"
	sCliPublKey="$(getEchoWgKey ${sSshAliasVpnClient} "${sClientPubKey}")" #"$(suExecCommand "cat ${sEtcWg}/publickey")"
	export sCliPublKey
	echo "[Interface]
Address = ${sVirtualIpVpnServer}/24
SaveConfig = true
#PostUp = ufw route allow in on wg0 out on eth0
#PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
#PostUp = ip6tables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
#PreDown = ufw route delete allow in on wg0 out on eth0
#PreDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
#PreDown = ip6tables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = ${sPortVpnServer}
#YOUR_SERVER_PRIVATE KEY
PrivateKey = ${sSrvPrivKey}

[Peer]
#YOUR_CLIENT_PUBLIC_KEY
PublicKey = ${sCliPublKey}
AllowedIPs = ${sVirtualIpVpnClient}/32" #| suExecCommand "tee ${sEtcWg}/wg0.conf"
	#suExecCommand "systemctl start wg-quick@wg0"
	ip a show wg0
}
setLinksClient() {
	sCliPrivKey="$(suExecCommand "cat ${sClientPrvKey}")"
	sSrvPublKey="$(getEchoWgKey ${sSshAliasVpnServer} "${sServerPubKey}")" #"$(suExecCommand "cat ${sEtcWg}/publickey")"
	echo "[Interface]
PrivateKey = ${sCliPrivKey}
#YOU_CLIENT_PRIVATE_KEY
## Client IP
Address = ${sVirtualIpVpnClient}/24

## if you have DNS server running
# DNS = ${sVirtualIpVpnServer}

[Peer]
PublicKey = ${sSrvPublKey}
#YOUR_SERVER_PUBLIC_KEY

## to pass internet trafic 0.0.0.0 but for peer connection only use 192.168.11.0/24, or you can also specify comma separated IPs
AllowedIPs =  0.0.0.0/0

Endpoint = ${sWanIp4VpnServer}:${sPortVpnServer}
PersistentKeepalive = 20" #| suExecCommand tee ${sEtcWg}/wg0.conf
	#suExecCommand "systemctl enable wg-quick@wg0"
	#suExecCommand "systemctl start wg-quick@wg0"
	#ip a show wg0
}
getExistingWgInterfaces() {
	sWgCmdResult=$( (sudo wg | grep -iE ^interface:) || true) #wg
	for sWgIf in "${sWgCmdResult[@]}"; do #sWgCmdResult
		sWgIfList+="${sWgIf#* } "
	done
	echo "${sWgIfList}"
}
getExistingWgpeers() {
	sWgCmdResult=$( (sudo wg | grep -iE ^peer:) || true) #wg
	for sWgPeer in "${sWgCmdResult[@]}"; do #sWgCmdResult
		sWgPeerList+="${sWgPeer#* } "
	done
	echo "${sWgPeerList}"
}

main_wireguard_server() {
	getExistingWgInterfaces
	getExistingWgpeers
	sHostnameVpnClient=$(ssh ${sSshAliasVpnClient} hostname)
	sHostnameVpnServer=$(hostname)
	setWgKeysName
	#sWanIp4VpnServer="$(curl ifconfig.me)"
	setIp4ForwardSysctl
	setKeysWireguard 2
	setLinksServer
	#stuff
	suExecCommand "wg set wg0 peer ${sCliPublKey} allowed-ips ${sVirtualIpVpnClient}"
}
main_wireguard_client() {
	getExistingWgInterfaces
	getExistingWgpeers
	sHostnameVpnServer=$(ssh ${sSshAliasVpnServer} hostname)
	sHostnameVpnClient=$(hostname)
	setWgKeysName
	sWanIp4VpnServer="$(ssh ${sSshAliasVpnServer} curl ifconfig.me)"
	setKeysWireguard 1
	setLinksClient
	#stuff
	suExecCommand "wg-quick up wg0"
}

main_wireguard() {
	bIsDebian="$(checkIfDebianId)"
	echo -e "\t>>> debian check: ${bIsDebian}"
	if ${bIsDebian}; then
		installWireguardDeb
	fi
	#if false; then
		echo -e "\t>>>please confirm if running machine has to be a wireguard client [1] (default choice) or wireguard server [2]"; read -rp "1/2" -n 1 iUserChoice
		if [ "${iUserChoice:-}" -eq "1" ] || [ "${iUserChoice:-}" -eq "" ]; then 		bClient="true"
		elif [ "${iUserChoice:-}" -eq "2" ]; then										bClient="false"
		else 																			exit 1; fi
		if ! ${bClient}; then 		main_wireguard_server
		elif ${bClient}; then 		main_wireguard_client; fi
	#fi
	ip a
}
main_wireguard