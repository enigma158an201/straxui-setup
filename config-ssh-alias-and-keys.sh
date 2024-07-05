#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"

sSshSubFolder=.ssh
sSshAliasConfig=${sSshSubFolder}/config
sSshAliasConfigd=${sSshAliasConfig}.d
sSshAuthKeys=${sSshSubFolder}/authorized_keys

sSshRepoSource="${launchDir}/home/user"
sSshRepoConf=${sSshRepoSource}/${sSshSubFolder}
sSshRepoAliasConfig=${sSshRepoSource}/${sSshAliasConfig}
sSshRepoAliasConfigd=${sSshRepoSource}/${sSshAliasConfigd}
#sSshRepoAuthKeys=${sSshRepoSource}/${sSshAuthKeys}

sSshLocalConf=$HOME/${sSshSubFolder}
sSshLocalAliasConfig=$HOME/${sSshAliasConfig}
sSshLocalAliasConfigd=$HOME/${sSshAliasConfigd}
sSshLocalAuthKeys=$HOME/${sSshAuthKeys}

setupSshAlias() {
	echo -e "\t>>> setup ssh alias config at ${sSshLocalAliasConfig}{,.d/}"
	mkdir -p "${sSshLocalAliasConfigd}"
	install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoAliasConfig}" "${sSshLocalAliasConfig}"
	for sAliasConfig in "${sSshRepoAliasConfigd}"/*; do 
		#install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoAliasConfigd}/${sAliasConfig}" "${sSshLocalAliasConfigd}/${sAliasConfig}"
		install -o "$USER" -g "$USER" -pv -m 0644 "${sAliasConfig}" "${sAliasConfig/$sSshRepoSource/$HOME}"
	done
}

setupSshkeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"
	echo -e "\t>>> checking ssh authorized_keys keys at ${sSshLocalAuthKeys}"
	if ! test -e "${sSshLocalAuthKeys}"; then 	touch "${sSshLocalAuthKeys}"; fi
	install -o "$USER" -g "$USER" -pv truc machin
	for sAliasPubKey in "${sSshRepoConf}"/*.pub; do 
		install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}"
		install -o "$USER" -g "$USER" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}"
	done
}
main_ssh_config() {
	setupSshAlias
	setupSshkeys
	}
main_ssh_config