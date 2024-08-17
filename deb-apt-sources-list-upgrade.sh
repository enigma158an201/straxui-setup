#!/usr/bin/env bash

# https://linuxize.com/post/how-to-upgrade-debian-10-to-debian-11/
# deb http://deb.debian.org/debian bullseye main
# deb-src http://deb.debian.org/debian bullseye main
# deb http://security.debian.org/debian-security bullseye-security main
# deb-src http://security.debian.org/debian-security bullseye-security main
# deb http://deb.debian.org/debian bullseye-updates main
# deb-src http://deb.debian.org/debian bullseye-updates main

if [ "${sLaunchDir}" = "." ] || [ "${sLaunchDir}" = "include" ] || [ "${sLaunchDir}" = "" ]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
source "${sLaunchDir}/include/test-superuser-privileges.sh"

sAptSourcesListFile=/etc/apt/sources.list
sAptSourcesListSubfolder=${sAptSourcesListFile}.d
sTiersRepos="$(find ${sAptSourcesListSubfolder} -iwholename '*.list')"

getDebianVersion() {
	sDebMainVersion="$(cat /etc/debian_version)"
	echo "${sDebMainVersion%%.*}"
}

upgradeJessieToStretch() {
	suExecCommandNoPreserveEnv sed -i.old 's/jessie/stretch/g' ${sAptSourcesListFile}
	if [ -n "${sTiersRepos}" ]; then 
		for sRepo in ${sTiersRepos}; do
			suExecCommandNoPreserveEnv "sed -i.old 's/jessie/stretch/g' ${sRepo}"
		done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ stretch/updates#\ stretch-security#g' ${sAptSourcesListFile}
}

upgradeStretchToBuster() {
	suExecCommandNoPreserveEnv sed -i.old 's/stretch/buster/g' ${sAptSourcesListFile} #{,.d/*.list}
	if [ -n "${sTiersRepos}" ]; then 
		for sRepo in ${sTiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/stretch/buster/g' "${sRepo}"
		done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ buster/updates#\ buster-security#g' ${sAptSourcesListFile} 
}

upgradeBusterToBullseye() {
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${sAptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${sAptSourcesListFile}.d/*.list
	suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${sAptSourcesListFile} #{,.d/*.list}
	if grep bullseye/updates ${sAptSourcesListFile}; then 
        suExecCommandNoPreserveEnv sed -i 's#/debian-security\ bullseye/updates#\ bullseye-security#g' ${sAptSourcesListFile}
    fi
	if [ -n "${sTiersRepos}" ]; then
		for sRepo in ${sTiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' "${sRepo}"
		done
	fi
}

upgradeBullseyeToBookworm() {
	suExecCommandNoPreserveEnv sed -i.old 's/bullseye/bookworm/g' ${sAptSourcesListFile}
	suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free\ non-free-firmware/g' ${sAptSourcesListFile}
	if [ -n "${sTiersRepos}" ]; then
		for sRepo in ${sTiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/bullseye/bookworm/g' "${sRepo}"
		done	
	fi
}

upgradeBookwormToTrixie() {
	suExecCommandNoPreserveEnv sed -i.old 's/bookworm/trixie/g' ${sAptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free non-free-firmware/g' ${sAptSourcesListFile}
	if [ -n "${sTiersRepos}" ]; then
		for sRepo in ${sTiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/bookworm/trixie/g' "${sRepo}"
		done
	fi
}

upgradeToSid() {
	suExecCommandNoPreserveEnv sed -i.old 's/bookworm/sid/g' ${sAptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free\ non-free-firmware/g' ${sAptSourcesListFile}
}

upgradeSourcesList() {
	if [ -r /etc/debian_version ]; then
		debInstalledVersion=$(getDebianVersion)
		if [ "${debInstalledVersion}" = "8" ]; then 			upgradeJessieToStretch
		elif [ "${debInstalledVersion}" = "9" ]; then 			upgradeStretchToBuster
		elif [ "${debInstalledVersion}" = "10" ]; then 			upgradeBusterToBullseye
		elif [ "${debInstalledVersion}" = "11" ]; then 			upgradeBullseyeToBookworm
		elif [ "${debInstalledVersion}" = "12" ]; then 			echo "trixie not stable at moment of this script version"
		elif [ "${debInstalledVersion}" = "13" ]; then 			echo "forky not stable at moment of this script version"
			exit 1 #upgradeBookwormToTrixie
		else
			echo "No stable Release for upgrading to debian $((debInstalledVersion + 1))"
		fi
	else
		echo -e "\\tFile /etc/debian_version doesn't exists"
		exit 1
	fi
}

upgradeDebianDist() {
#if command -v sudo &> /dev/null; then
    if ! env | grep XDG_SESSION_TYPE=tty; then #check tty env
		echo -e "\t>>> Le processus d'upgrade peut prendre selon la vitesse de connexion internet et la performance matériel 30 minutes ou plus."
		echo -e "\t    La mise à jour depuis un environnement graphique est déconseillée, à moins d'avoir pris les dispositions pour empêcher"
		echo -e "\t    le verrouillage de la session graphique (ou d'avoir basculé en session sous le tty ce qui résoud tout probleme graphique),"
		echo -e "\t    Si tel est le cas, bien vérifier que tout écran de veille a bien été désactivé"
		read -rp "continuer (y/N)" -n 1 sConfirmUpgrade
	else
		sConfirmUpgrade="y"
    fi
	if [ "${sConfirmUpgrade,,}" = "y" ]; then
        suExecCommandNoPreserveEnv "apt-get autoremove && apt-get update && apt-get upgrade && apt-get full-upgrade && apt-get dist-upgrade && apt-get autoremove" 
	fi
}

main() {
    #1st run recommended to update old distro 
    upgradeDebianDist
	upgradeSourcesList
    #2nd run to version upgrading
	upgradeDebianDist
}
main