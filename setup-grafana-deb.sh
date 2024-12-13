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

installPrometheusDeb() {
	echo -e "\t>>> Install prometheus for debian"
	sudo apt-get install -y prometheus	
}

installGrafanaDeb() {
	echo -e "\t>>> Install prometheus / Grafana (repositories for debian)"
	#1. Install the prerequisite packages:
	sudo apt-get install -y apt-transport-https software-properties-common wget
	#2. Import the GPG key:
	sudo mkdir -p /etc/apt/keyrings/
	wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | sudo tee /etc/apt/keyrings/grafana.gpg > /dev/null
	#3. To add a repository for stable releases, run the following command:
	echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
		#4. To add a repository for beta releases, run the following command:
		#echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com beta main" | sudo tee -a /etc/apt/sources.list.d/grafana.list
	#5. Run the following command to update the list of available packages:
	# Updates the list of available packages
	sudo apt-get update
	#6. To install Grafana OSS, run the following command:
	# Installs the latest OSS release:
	sudo apt-get install grafana
		#7. # Installs the latest Enterprise release:
		#sudo apt-get install grafana-enterprise
}
main_prometheus_grafana() {
	bIsDebian="$(checkIfDebianId)"
	echo -e "\t>>> debian check: ${bIsDebian}"
	if ${bIsDebian}; then
		installPrometheusDeb
		installGrafanaDeb
	else
		exit 1
	fi

}
main_prometheus_grafana