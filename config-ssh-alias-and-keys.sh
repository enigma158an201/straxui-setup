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

installSshAlias() {
	echo -e "\t>>> setup ssh alias config at ${sSshLocalAliasConfig}{,.d/}"
	mkdir -p "${sSshLocalAliasConfigd}"
	install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoAliasConfig}" "${sSshLocalAliasConfig}"
	for sAliasConfigSrc in "${sSshRepoAliasConfigd}"/*; do 
		#install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoAliasConfigd}/${sAliasConfigSrc}" "${sSshLocalAliasConfigd}/${sAliasConfigSrc}"
		sAliasConfigDst="${sAliasConfigSrc/$sSshRepoSource/$HOME}"
		echo -e "\t>>> proceed file $sAliasConfigSrc to ${sAliasConfigDst}"
		install -o "$USER" -g "$USER" -pv -m 0644 "${sAliasConfigSrc}" "${sAliasConfigDst}"
	done
}
installSshKeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"
	echo -e "\t>>> checking ssh authorized_keys keys at ${sSshLocalAuthKeys}"
	if ! test -e "${sSshLocalAuthKeys}"; then 	touch "${sSshLocalAuthKeys}"; fi
	install -o "$USER" -g "$USER" -pv truc machin
	for sAliasPubKey in "${sSshRepoConf}"/*.pub; do 
		install -o "$USER" -g "$USER" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}"
		install -o "$USER" -g "$USER" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}"
	done
}
importSshKeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"	#ssh-copy-id -i debian_server.pub pragmalin@debianvm
	for sSshPubKey in "${sSshLocalConf}"/*.pub; do
		for sSshAlias in freebox-delta-wan SKY41 testsalonk wtestsalonk; do
			if true; then 	echo "ssh-copy-id -i \"${sSshPubKey}\" \"${sSshAlias}\""; fi
		done
	done
}
main_ssh_config() {
	installSshAlias
	#installSshKeys
	importSshKeys
}
main_ssh_config