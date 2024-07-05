#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sEtcOsReleasePath=/etc/os-release
sVncConfDir=$HOME/.vnc
sVncPasswd="${sVncConfDir}/passwd"
sX11vncrc=$HOME/.x11vncrc
	
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

installX11vncDeb() {
	echo -e "\t>>> Install x11vnc terminal multiplexer for debian"
	sudo apt-get install -y x11vnc	
}
setupVncPassword() {
	echo "" > "${sVncPasswd}"
}

setupX11vncConf() {
	echo -e "\t>>> setup x11vnc config at ${sX11vncrc}"
	echo "# x11vnc configuration

display :0	# Overides DISPLAY to use local framebuffer
# shared	# Let more than one person attach
#forever	# Keep running, even after last one detaches
#usepw		# Use a password: may be commented if only local ssh connections
auth guess
noipv6
localhost	# allow only connections through localhost (usefull for ssh tunnelling)
nopw		# uncomment nopw ONLY if localhost uncommented
#unixpw		# uses su to check password
" | tee "${sX11vncrc}"
}
main() {
	bIsDebian="$(checkIfDebianId)"
	echo -e "\t>>> debian check: $bIsDebian"
	if $bIsDebian; then
		installX11vncDeb
		setupX11vncConf
	else
		exit 1
	fi

}
main