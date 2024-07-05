#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

sEtcOsReleasePath=/etc/os-release

checkIfDebianId() {
	if [ -r "${sEtcOsReleasePath}" ]; then
        sIsDebian="$(grep -i "^ID=" "${sEtcOsReleasePath}" || echo "false")"
		sIsDebianLike="$(grep -i "^ID_LIKE=" "${sEtcOsReleasePath}" || echo "false")"
		if [[ ${sIsDebian,,} =~ debian ]] || [[ ${sIsDebianLike,,} =~ debian ]]; then
			echo "true"
		else
			echo "false"
			exit 1
		fi
	else
		echo "false"
		exit 1
	fi
}

installWireguardDeb() {
	echo -e "\t>>> Install wireguard for debian"
	sudo apt-get install -y wireguard	
}
setKeysWireguard() {
	echo -e "\t>>> set conf wireguard for debian"
	suExecCommand "bash -c \"cd /etc/wireguard/ || exit 1; umask 077; if ! test -e privatekey && ! test -e publickey; then wg genkey | tee privatekey | wg pubkey > publickey; fi\""
}
setIp4ForwardSysctl() {
	sIp4FwdDst="/etc/sysctl.d/99-enable-ip4-forward.conf"
	sIp4FwdSrc="${launchDir}$sIp4FwdDst"
	if [ ! -f "$sIp4FwdDst" ]; then
		echo -e "\t>>> proceed add disable ipv6 file to /etc/sysctl.d/ "
		suExecCommand "mkdir -p \"$(dirname "$sIp4FwdDst")\""
		suExecCommand "install -o root -g root -m 0744 -pv $sIp4FwdSrc $sIp4FwdDst"
	fi
}
setLinksServer() {
	sPrivKey="$(suExecCommand "cat /etc/wireguard/privatekey")"
	sPublKey="$(suExecCommand "cat /etc/wireguard/publickey")"
	echo "[Interface]
Address = 192.168.11.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
ListenPort = 51820
#YOUR_SERVER_PRIVATE KEY
PrivateKey = ${sPrivKey} 

[Peer]
#YOUR_CLIENT_PUBLIC_KEY
PublicKey = ${sPublKey}
AllowedIPs = 192.168.11.2/32" | suExecCommand "tee /etc/wireguard/wg0.conf"
	suExecCommand "systemctl start wg-quick@wg0"
	ip a show wg0
}
setLinksClient() {
	sPrivKey="$(suExecCommand "cat /etc/wireguard/privatekey")"
	sPublKey="$(suExecCommand "cat /etc/wireguard/publickey")"
	echo "[Interface]
PrivateKey = ${sPrivKey}
#YOU_CLIENT_PRIVATE_KEY
## Client IP
Address = 192.168.11.2/24

## if you have DNS server running
# DNS = 192.168.11.1

[Peer]
PublicKey = ${sPublKey}
#YOUR_SERVER_PUBLIC_KEY
 
## to pass internet trafic 0.0.0.0 but for peer connection only use 192.168.11.0/24, or you can also specify comma separated IPs
AllowedIPs =  0.0.0.0/0

Endpoint = SERVER_PUBLIC_IP:51820
PersistentKeepalive = 20" | suExecCommand tee /etc/wireguard/wg0.conf
	suExecCommand systemctl start wg-quick@wg0
	ip a show wg0
}
setLinksWireguard() {
	if true; then 	setLinksServer
	else 			suExecCommand setLinksClient; fi
}

main() {
	bIsDebian="$(checkIfDebianId)"
	echo -e "\t>>> debian check: $bIsDebian"
	if $bIsDebian; then
		installWireguardDeb
		setIp4ForwardSysctl
		setKeysWireguard
		setLinksWireguard
	else
		exit 1
	fi

}
main