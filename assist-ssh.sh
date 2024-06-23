#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# ReadMe before use: this scrip intends to be used for establishing a ssh reverse tunneling for between local and remote machines
# for remote assisted machine: 
#	1. install openssh-server & x11vnc, 
#	2. launch passwordless x11vnc process with localhost only access
#	3. create a tunnel with IP and port given in variables sAssistantIp and sTunnelSshPort

sAssistantIp=82.66.69.134
sTunnelSshPort=49157 #49222 #22
sLocalAssistantUser=gwen
sLocalAssistedUser=assist

sAssistedRemoteSshPort=22
sRemoteVncPort=5900 #5922 #5901
sEd25519PrvKeyPath=~/.ssh/id_ed25519
sEd25519PubKeyPath=${sEd25519PrvKeyPath}.pub
tabAssistedUser=( assist david guillaume sky )

oldRemoteAssistedCommands() {
	echo -e "\t>>>\$DISPLAY Value for assistant\n$DISPLAY"
	ssh-keygen -t ed25519
	ssh-copy-id -i "${sEd25519PubKeyPath}" ${sLocalAssistantUser}@${sAssistantIp}
	#ssh -L 5900:localhost:5900 user@brother_ip "x11vnc -display :0 -localhost -nopw"
	#ssh -p ${sTunnelSshPort} localhost -L ${sRemoteVncPort}:localhost:${sRemoteVncPort} "x11vnc -display :0 -localhost -nopw"
	#ssh -p ${sAssistedRemoteSshPort} localhost -L ${sRemoteVncPort}:localhost:${sRemoteVncPort} "x11vnc -display :0 -localhost -nopw"
	#ssh -i "${sEd25519PrvKeyPath}" -R "${sRemoteVncPort}:localhost:${sRemoteVncPort}" "${sAssistedUser}@${sAssistantIp}"	
}
oldLocalAssistantCommands() {	#se connecter à localhost:5901
	#installX11vnc && 11vnc -nopw -display :0 -localhost
	#ssh -R ${sTunnelSshPort}:localhost:${sAssistedRemoteSshPort} "${sAssistedUser}@${sAssistantIp}"
	#remmina -c vnc://david@localhost &
	x11vnc -display :1 -rfbauth /chemin/vers/votre/fichier/de/mot_de_passe -via user@${sAssistantIp}
}
oldCreateUser() {
	sAssistedUser=$1
	if ! id "${sAssistedUser}"; then
		if command -v sudo 1>/dev/null 2>&1; then
			if command -v adduser 1>/dev/null 2>&1; then
				sudo adduser --no-create-home "${sAssistedUser}"
			else
				sudo useradd -M "${sAssistedUser}"
				sudo passwd david
			fi
		else
			exit 1
		fi
	fi
}

installX11vnc() {
	if command -v x11vnc 1>/dev/null 2>&1; then
		echo -e "\t>>> x11vnc already installed, skipping $0 !!!"
	elif ! command -v x11vnc 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt 1>/dev/null 2>&1; then 	sudo apt install x11vnc; fi
	else
		exit 1
	fi
}
installOpensshServer() {
	if command -v sshd 1>/dev/null 2>&1; then
		echo -e "\t>>> openssh-server already installed, skipping $0 !!!"
	elif ! command -v sshd 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt 1>/dev/null 2>&1; then 	sudo apt install openssh-server; fi
	else
		exit 1
	fi
}
localAssistantCommands() {
	echo -e "\t>>> give remote user name, be careful to letter case !!!"
	read -rp " " sAssitedRemoteUser
	ssh -p ${sAssistedRemoteSshPort} localhost -L ${sRemoteVncPort}:localhost:${sRemoteVncPort} "remmina -c vnc://${sAssitedRemoteUser}@localhost &" #"x11vnc -display :0 -localhost -nopw"
}
remoteAssistedCommands() {
	sAssistedUser=$1
	installX11vnc
	installOpensshServer
	killall x11vnc || true
	x11vnc -display :0 -localhost -nopw -forever &
	ssh -vv -p ${sTunnelSshPort} -NR "${sRemoteVncPort}:localhost:${sRemoteVncPort}" "${sLocalAssistedUser}@${sAssistantIp}" #
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
			remoteAssistedCommands "${sLoggedUser}"
			iAssisted=$(( iAssisted + 1 )) # bAssisted=true
		#else 
			#bAssisted=$(${bAssisted:-} || echo "false")
		fi
	done
	if [ ${iAssisted} -eq 0 ] ; then #! ${bAssisted}; then
		if [ "${sLoggedUser}" = "${sLocalAssistantUser}" ]; then 	localAssistantCommands "${sAssistedUser}"; fi #sLocalAssistantUser
	fi
}

main() {
	selectUserAssistOrAssistedCommands
}
main
