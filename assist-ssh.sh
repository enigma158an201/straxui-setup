#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sAssistedSshPort=22
sVncPort=5901
sTunnelSshPort=2222
sEd25519PrvKeyPath=~/.ssh/id_ed25519
sEd25519PubKeyPath=${sEd25519PrvKeyPath}.pub
sAssistantIp=82.66.69.134
tabAssistedUser=( david guillaume sky )
sAssistUser=gwen

oldRemoteAssistedCommands() {
	echo -e "\t>>>\$DISPLAY Value for assistant\n$DISPLAY"
	ssh-keygen -t ed25519
	ssh-copy-id -i "${sEd25519PubKeyPath}" ${sAssistUser}@${sAssistantIp}
	ssh -i "${sEd25519PrvKeyPath}" -R "${sVncPort}:localhost:${sVncPort}" "${sAssistedUser}@${sAssistantIp}"
}
oldLocalAssistantCommands() {	#se connecter à localhost:5901
	x11vnc -display :1 -rfbauth /chemin/vers/votre/fichier/de/mot_de_passe -via user@${sAssistantIp}
}

installX11vnc() {
	if command -v x11vnc 1>/dev/null 2>&1; then
		echo -e "\t>>> x11vnc already installed, skipping $0 !!!"
	elif ! command -v x11vnc 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt 1>/dev/null 2>&1; then 	sudo apt install x11vnc; fi
	fi
}
installOpensshServer() {
	if command -v sshd 1>/dev/null 2>&1; then
		echo -e "\t>>> openssh-server already installed, skipping $0 !!!"
	elif ! command -v sshd 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt 1>/dev/null 2>&1; then 	sudo apt install openssh-server; fi
	fi
}
localAssistantCommands() {
	sAssistedUser=$1
	#installX11vnc
	#x11vnc -nopw -display :0 -localhost
	ssh -R ${sTunnelSshPort}:localhost:${sAssistedSshPort} "${sAssistedUser}@${sAssistantIp}"
}
remoteAssistedCommands() {
	installX11vnc
	installOpensshServer
	#ssh -L 5900:localhost:5900 user@brother_ip "x11vnc -display :0 -localhost -nopw"
	ssh -p ${sTunnelSshPort} localhost -L ${sVncPort}:localhost:${sVncPort} "x11vnc -display :0 -localhost -nopw"
}
selectUserAssistOrAssistedCommands() {
	if [ ! $EUID = 0 ]; then
		sLoggedUser=$(whoami)
	else
		echo -e "\t>>> Please don't use as root !!!" 
		exit 1
	fi
	iAssisted=0
	for sAssistedUser in "${tabAssistedUser[@]}"; do
		if [ "${sLoggedUser}" = "${sAssistedUser}" ]; then
			remoteAssistedCommands
			iAssisted=$(( iAssisted + 1 )) # bAssisted=true
		#else 
			#bAssisted=$(${bAssisted:-} || echo "false")
		fi
	done

	if [ ${iAssisted} -eq 0 ] ; then #! ${bAssisted}; then
		if [ "${sLoggedUser}" = "${sAssistUser}" ]; then 	localAssistantCommands "${sAssistUser}"; fi #sAssistedUser
	fi
}

main() {
	selectUserAssistOrAssistedCommands
}

main
