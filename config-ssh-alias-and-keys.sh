#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/set-common-settings.sh"

sSshSubFolder=.ssh
sSshAliasConfig=${sSshSubFolder}/config
sSshAliasConfigd=${sSshAliasConfig}.d
sSshAuthKeys=${sSshSubFolder}/authorized_keys

sSshRepoSource="${launchDir}/home/user"
sSshRepoConf=${sSshRepoSource}/${sSshSubFolder}
sSshRepoAliasConfig=${sSshRepoSource}/${sSshAliasConfig}
sSshRepoAliasConfigd=${sSshRepoSource}/${sSshAliasConfigd}
#sSshRepoAuthKeys=${sSshRepoSource}/${sSshAuthKeys}

sSshLocalConf=${HOME}/${sSshSubFolder}
sSshLocalAliasConfig=${HOME}/${sSshAliasConfig}
sSshLocalAliasConfigd=${HOME}/${sSshAliasConfigd}
sSshLocalAuthKeys=${HOME}/${sSshAuthKeys}

installSshAlias() {
	#sLoggedUser=$(whoami)
	echo -e "\t>>> setup ssh alias config at ${sSshLocalAliasConfig}{,.d/}"
	mkdir -p "${sSshLocalAliasConfigd}"
	install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoAliasConfig}" "${sSshLocalAliasConfig}"
	for sAliasConfigSrc in "${sSshRepoAliasConfigd}"/*; do 
		#install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoAliasConfigd}/${sAliasConfigSrc}" "${sSshLocalAliasConfigd}/${sAliasConfigSrc}"
		sAliasConfigDst="${sAliasConfigSrc/${sSshRepoSource}/${HOME}}"
		#if [[ ${sAliasConfigDst} =~ ${sLoggedUser} ]]; then
			echo -e "\t>>> proceed file ${sAliasConfigSrc} to ${sAliasConfigDst}"
			install -o "${USER}" -g "${USER}" -pv -m 0644 "${sAliasConfigSrc}" "${sAliasConfigDst}"
		#fi
	done
}
installSshKeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"
	echo -e "\t>>> checking ssh authorized_keys keys at ${sSshLocalAuthKeys}"
	if ! test -e "${sSshLocalAuthKeys}"; then 	touch "${sSshLocalAuthKeys}"; fi
	install -o "${USER}" -g "${USER}" -pv truc machin
	for sAliasPubKey in "${sSshRepoConf}"/*.pub; do 
		install -o "${USER}" -g "${USER}" -pv -m 0644 "${sSshRepoConf}/${sAliasPubKey}" "${sSshLocalConf}/${sAliasPubKey}"
		install -o "${USER}" -g "${USER}" -pv -m 0600 "${sSshRepoConf}/${sAliasPubKey/.pub/}" "${sSshLocalConf}/${sAliasPubKey/.pub/}"
	done
}
importSshKeys() {
	echo -e "\t>>> setup ssh keys at ${sSshLocalConf}"	#ssh-copy-id -i debian_server.pub pragmalin@debianvm
	#for sSshPubKey in "${sSshRepoConf}"/*.pub; do
		for sSshAlias in SKY41 testsalonk wtestsalonk #freebox-delta-wan
		do
			sSshPubKey="to-do-check_if_alias_reachable_and_key_importable"
			if true; then 	echo "ssh-copy-id -i \"${sSshPubKey}\" \"${sSshAlias}\""; fi
		done
	#done
}
updateSshdConfig() {
	echo -e "\t>>> application des fichiers config sshd"
	suExecCommand "bash -c 'for sSshdConfigFile in ${launchDir}/etc/sshd_config.d/*.conf; do
		sSshdConfigDst=/etc/ssh/sshd_config.d/\$sSshdConfigFile
		sSshdConfigSrc=${launchDir}\$sSshdConfigDst
		if [ -d $\(dirname \"\$sSshdConfigDst\"\) ] && [ -f \"\$sSshdConfigSrc\" ]; then
			install -o root -g root -m 0744 -pv \$sSshdConfigSrc \$sSshdConfigDst
		fi
	done
	systemctl restart sshd.service'"
}
main_ssh_config() {
	updateSshdConfig
	installSshAlias
	#installSshKeys
	#importSshKeys
	#suExecCommand sshd-config-settings
}
main_ssh_config