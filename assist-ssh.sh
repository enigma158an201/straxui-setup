#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# ReadMe before use: this scrip intends to be used for establishing a ssh reverse tunneling for between local and remote machines
# for remote assisted machine: 
#	1. install openssh-server & x11vnc
#	2. kills existing x11vnc, then launch passwordless x11vnc process with localhost only access
#	3. create a tunnel with IP and port given in variables sAssistantIp and sTunnelSshPort
# for local assistant machine:
#	4. ask for remote username for vnc purpose
#	5. one line connect to ssh tunnel and vnc port remotely opened

sAssistantIp=82.66.69.134
sTunnelSshPort=49157 #49222 #22
sLocalAssistantUser=gwen
sLocalAssistedUser=assist

sAssistedRemoteSshPort=22
sRemoteVncPort=5900 #5922 #5901
#sEd25519PrvKeyPath=~/.ssh/id_ed25519
#sEd25519PubKeyPath=${sEd25519PrvKeyPath}.pub
tabAssistedUser=( assist david guillaume sky )
sLocalDisplay=$DISPLAY
sLocalSessionType=${XDG_SESSION_TYPE,,}

oldRemoteAssistedCommands() {
	echo -e "\t>>>\$DISPLAY Value for assistant\n$DISPLAY"
	ssh-keygen -t ed25519
	#ssh-copy-id -i "${sEd25519PubKeyPath}" ${sLocalAssistantUser}@${sAssistantIp}
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

installTerminator() {
	if command -v terminator 1>/dev/null 2>&1; then
		echo -e "\t>>> terminator already installed, skipping $0 !!!"
	elif ! command -v terminator 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt-get 1>/dev/null 2>&1; then 	sudo apt-get install terminator; fi
	else
		exit 1
	fi
}
installOpensshServer() {
	if command -v sshd 1>/dev/null 2>&1 || [ -x /usr/sbin/sshd ]; then
		echo -e "\t>>> openssh-server already installed, skipping $0 !!!"
	elif ! command -v sshd 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt-get 1>/dev/null 2>&1; then 	sudo apt-get install openssh-server; fi
	else
		exit 1
	fi
}
installX11vnc() {
	if command -v x11vnc 1>/dev/null 2>&1; then
		echo -e "\t>>> x11vnc already installed, skipping $0 !!!"
	elif ! command -v x11vnc 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt-get 1>/dev/null 2>&1; then 	sudo apt-get install x11vnc; fi
	else
		exit 1
	fi
}
installWayvnc() { #wayvnc works only with wlroots based WM/DE
	if command -v wayvnc 1>/dev/null 2>&1; then
		echo -e "\t>>> wayvnc already installed, skipping $0 !!!"
	elif ! command -v wayvnc 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt-get 1>/dev/null 2>&1; then 	sudo apt-get install wayvnc; fi
	else
		exit 1
	fi
	sWayvncConf=$HOME/.config/wayvnc/config
	if [ ! -e "${sWayvncConf}" ]; then
		mkdir -p "$(dirname "${sWayvncConf}")"
		echo -e "address=127.0.0.0\nusername=$(whoami)\n# port=5900\n# xkb_layout=fr # The keyboard layout to use for key code lookup.            Default: XKB_DEFAULT_LAYOUT or system default." > "${sWayvncConf}"
	fi
}
installWaypipe() {
	if command -v waypipe 1>/dev/null 2>&1; then
		echo -e "\t>>> waypipe already installed, skipping $0 !!!"
	elif ! command -v waypipe 1>/dev/null 2>&1 && command -v sudo 1>/dev/null 2>&1; then
		if command -v apt-get 1>/dev/null 2>&1; then 	sudo apt-get install waypipe; fi
	else
		exit 1
	fi
}
installShortcuts() {
	sShctName=assist.desktop
	for sShortcutF in $HOME/{Bureau,.local/share/applications}; do
		sShortcut=${sShortcutF}/${sShctName}
		echo -e "[Desktop Entry]\nName=Assistance Gwen\nExec=terminator -e \"bash -ic $HOME/bin/gwen/straxui-setup/assist-ssh.sh\"\n#Terminal=true\nType=Application\nIcon=network-transmit\nComment=Lance le reverse tunnel SSH pour connexion bureau distant via VNC " > "${sShortcut}"
		if [ ! -x truc ]; then chmod +x "${sShortcut}"; fi 
	done
}
localAssistantCommands() {
	echo -e "\t>>> give remote user name, be careful to letter case !!!"
	read -rp " " sAssitedRemoteUser
	ssh -p ${sAssistedRemoteSshPort} localhost -L ${sRemoteVncPort}:localhost:${sRemoteVncPort} "remmina -c vnc://${sAssitedRemoteUser}@localhost &" #"x11vnc -display :0 -localhost -nopw"
}
remoteAssistedCommands() {
	sAssistedUser=$1
	installTerminator
	installOpensshServer
	installShortcuts
	for sVncSrvApp in x11vnc wayvnc waypipe; do
		killall ${sVncSrvApp} || true
	done
	if [ "${sLocalSessionType}" = "x11" ]; then
		echo -e "\t>>> x11 session detected, processsing with x11vnc"
		installX11vnc
		x11vnc -display "${sLocalDisplay}" -localhost -nopw -forever &
	elif [ "${sLocalSessionType}" = "wayland" ] && false; then #wayvnc works only with wlroots based WM/DE
		echo -e "\t>>> wayland & wlroots based session detected, processsing with wayvnc"
		installWayvnc
		wayvnc # to complete
	elif [ "${sLocalSessionType}" = "wayland" ] && true; then
		echo -e "\t>>> wayland & non wlroots based session detected, processsing with waypipe"
		installWaypipe
		#waypipe ssh user@127.0.0.1 wayland
	fi
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
		if [ "${sLoggedUser}" = "${sLocalAssistantUser}" ]; then
			echo -e "\t>>> Do you plan to Send (1) or Receive(2) screen? 1/2?"
			read -rp " " -n 1 iAnswer
			if [ "${iAnswer}" -eq "1" ]; then
				remoteAssistedCommands "${sLoggedUser}"
			elif [ "${iAnswer}" -eq 2 ]; then
				localAssistantCommands "${sAssistedUser}" #sLocalAssistantUser
			fi
		fi
	fi
}

main() {
	selectUserAssistOrAssistedCommands
}
main
