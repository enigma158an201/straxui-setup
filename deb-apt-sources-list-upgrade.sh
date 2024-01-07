#!/usr/bin/env bash

# https://linuxize.com/post/how-to-upgrade-debian-10-to-debian-11/
# deb http://deb.debian.org/debian bullseye main
# deb-src http://deb.debian.org/debian bullseye main
# deb http://security.debian.org/debian-security bullseye-security main
# deb-src http://security.debian.org/debian-security bullseye-security main
# deb http://deb.debian.org/debian bullseye-updates main
# deb-src http://deb.debian.org/debian bullseye-updates main

if [ "$launchDir" = "." ] || [ "$launchDir" = "include" ] || [ "$launchDir" = "" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

aptSourcesListFile=/etc/apt/sources.list
aptSourcesListSubfolder=${aptSourcesListFile}.d
tiersRepos="$(find ${aptSourcesListSubfolder} -iwholename '*.list')"

getDebianVersion() {
	myDebMainVersion="$(cat /etc/debian_version)"
	echo "${myDebMainVersion%%.*}"
}

upgradeJessieToStretch() {
#if command -v sudo 1>/dev/null 2>&1; then
	suExecCommandNoPreserveEnv sed -i.old 's/jessie/stretch/g' ${aptSourcesListFile}
	if [ -n "${tiersRepos}" ]; then 
		for sRepo in ${tiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/jessie/stretch/g' "${sRepo}"
		done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ stretch/updates#\ stretch-security#g' ${aptSourcesListFile}
#fi
}

upgradeStretchToBuster() {
#if command -v sudo 1>/dev/null 2>&1; then
	suExecCommandNoPreserveEnv sed -i.old 's/stretch/buster/g' ${aptSourcesListFile} #{,.d/*.list}
	if [ -n "${tiersRepos}" ]; then 
		for sRepo in ${tiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/stretch/buster/g' "${sRepo}"
		done
	fi
	#suExecCommandNoPreserveEnv sed -i 's#/debian-security\ buster/updates#\ buster-security#g' ${aptSourcesListFile} 
#fi
}

upgradeBusterToBullseye() {
#if command -v sudo 1>/dev/null 2>&1; then
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${aptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${aptSourcesListFile}.d/*.list
	suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' ${aptSourcesListFile} #{,.d/*.list}
	if grep bullseye/updates ${aptSourcesListFile}; then 
        suExecCommandNoPreserveEnv sed -i 's#/debian-security\ bullseye/updates#\ bullseye-security#g' ${aptSourcesListFile}
    fi
	if [ -n "${tiersRepos}" ]; then
		for sRepo in ${tiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/buster/bullseye/g' "${sRepo}"
		done
	fi
#fi
}

upgradeBullseyeToBookworm() {
#if command -v sudo 1>/dev/null 2>&1; then
	suExecCommandNoPreserveEnv sed -i.old 's/bullseye/bookworm/g' ${aptSourcesListFile}
	suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free\ non-free-firmware/g' ${aptSourcesListFile}
	if [ -n "${tiersRepos}" ]; then
		for sRepo in ${tiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/bullseye/bookworm/g' "${sRepo}"
		done	
	fi
#fi
}

upgradeBookwormToTrixie() {
#if command -v sudo 1>/dev/null 2>&1; then
	suExecCommandNoPreserveEnv sed -i.old 's/bookworm/trixie/g' ${aptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free non-free-firmware/g' ${aptSourcesListFile}
	if [ -n "${tiersRepos}" ]; then
		for sRepo in ${tiersRepos}; do
			suExecCommandNoPreserveEnv sed -i.old 's/bookworm/trixie/g' "${sRepo}"
		done
	fi
#fi
}

upgradeToSid() {
#if command -v sudo 1>/dev/null 2>&1; then
	suExecCommandNoPreserveEnv sed -i.old 's/bookworm/sid/g' ${aptSourcesListFile}
	#suExecCommandNoPreserveEnv sed -i.old 's/non-free/non-free\ non-free-firmware/g' ${aptSourcesListFile}
#fi
}

upgradeSourcesList() {
	if [ -r /etc/debian_version ]; then
		debInstalledVersion=$(getDebianVersion)
		if [ "$debInstalledVersion" = "8" ]; then
			upgradeJessieToStretch
		elif [ "$debInstalledVersion" = "9" ]; then
			upgradeStretchToBuster
		elif [ "$debInstalledVersion" = "10" ]; then
			upgradeBusterToBullseye
		elif [ "$debInstalledVersion" = "11" ]; then
			upgradeBullseyeToBookworm
		elif [ "$debInstalledVersion" = "12" ]; then
			echo "trixie not stable at moment of this script version"
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
#if command -v sudo 1>/dev/null 2>&1; then
    if ! env | grep XDG_SESSION_TYPE=tty; then #check tty env
		echo -e "\t>>> La mise à jour depuis un environnement graphique est deconseillée,"
		echo -e "\t    il est préférable de basculer sous le tty pour éviter le verrouillage de la session graphique,"
		acho -e "\t    ou a minima de desactiver tout écran de veille"
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