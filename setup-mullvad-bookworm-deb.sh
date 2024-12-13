#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sEtcOsReleasePath=/etc/os-release

checkIfDebianId() {
	if [[ -r "${sEtcOsReleasePath}" ]]; then
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

installMullvadDeb() {
	echo -e "\t>>> Install mullvad vpn (repositories for debian)"
	sudo curl -fsSLo /etc/apt/keyrings/mullvad-keyring.asc https://repository.mullvad.net/deb/mullvad-keyring.asc
	#3. To add a repository for stable releases, run the following command:
	echo "deb [signed-by=/etc/apt/keyrings/mullvad-keyring.asc arch=$( dpkg --print-architecture )] https://repository.mullvad.net/deb/stable $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/mullvad.list
	sudo apt-get update
	sudo apt-get install mullvad-vpn
}
main_mullvad() {
	bIsDebian="$(checkIfDebianId)"
    echo -e "${bIsDebian}"
	if ${bIsDebian}; then
		installMullvadDeb
	fi
}
main_mullvad