#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# Reset
# Color_Off='\033[0m'       # Text Reset
normal=$(tput sgr0)

# Regular Colors
# Black='\033[0;30m'        # Black
# Red='\033[0;31m'          # Red
# Green='\033[0;32m'        # Green
# Yellow='\033[0;33m'       # Yellow
# Blue='\033[0;34m'         # Blue
# Purple='\033[0;35m'       # Purple
# Cyan='\033[0;36m'         # Cyan
# White='\033[0;37m'        # White

# Bold
# BBlack='\033[1;30m'       # Black
# BRed='\033[1;31m'         # Red
# BGreen='\033[1;32m'       # Green
# BYellow='\033[1;33m'      # Yellow
BBlue='\033[1;34m'        # Blue
# BPurple='\033[1;35m'      # Purple
# BCyan='\033[1;36m'        # Cyan
# BWhite='\033[1;37m'       # White
# bold=$(tput bold)

sArch=amd64
sSystem=linux
sRepoFileFormat=tar.gz
sStratisRepoHome=/media/CommonData/telechargements/stratisEVM		#sStratisRepoHome=$HOME/data/mainnet
sBeaconChainBin=${sStratisRepoHome}/beacon-chain							#sDepositBin=${sStratisRepoHome}/deposit
sGethBin=${sStratisRepoHome}/geth
sValidatorBin=${sStratisRepoHome}/validator							#tLocalBins=("${sBeaconChainBin}" "${sGethBin}" "${sValidatorBin}")	#"${sDepositBin}"
sProjectOwner=stratisproject
declare -A tStratisFile=(["beacon-chain"]="beacon-chain" ["geth"]="geth" ["validator"]="validator")
declare -A tStratisRepoName=(["beacon-chain"]="prysm-stratis" ["geth"]="go-stratis" ["validator"]="prysm-stratis")
declare -A tStratisRepoOwnerAndName=(["beacon-chain"]="${sProjectOwner}/${tStratisRepoName[beacon-chain]}" ["geth"]="${sProjectOwner}/${tStratisRepoName[geth]}" ["validator"]="${sProjectOwner}/${tStratisRepoName[validator]}")
sStratisEvmUrl=https://api.github.com/repos/${sProjectOwner}/
sBeaconUrl=${sStratisEvmUrl}${tStratisRepoName[beacon-chain]}/releases/latest		#sStratisEvmUrl=https://api.github.com/repos/stratisproject/prysm-stratis
sGethUrl=${sStratisEvmUrl}${tStratisRepoName[geth]}/releases/latest
sValidatorUrl=${sStratisEvmUrl}${tStratisRepoName[validator]}/releases/latest	#sDepositUrl=${sStratisRepoHome}/deposit
declare -A tRepoUrl=(["beacon-chain"]="${sBeaconUrl}" ["geth"]="${sGethUrl}" ["validator"]="${sValidatorUrl}")
declare -A tLocalBin=(["beacon-chain"]="${sBeaconChainBin}" ["geth"]="${sGethBin}" ["validator"]="${sValidatorBin}")

getLocalBinVersion() {
	sBinPath=${1}
	eval "$sBinPath --version"
}
oldGitRepoBinVersion() {
	sBinUrl=${1}
	curl -s "$sBinUrl" | grep -i tag_name
}
oldGitRepoLatestBinUrl() {
	sBinUrl=${1}
	curl -s "$sBinUrl" | grep -i browser_download_url
}
gitRepoContent() {
	sBinUrl=${1}
	curl -s "$sBinUrl"
}
gitRepoBinVersion() {
	sContent="${1}"
	sTag=$(echo "${sContent}" | grep -i tag_name)
	sTag="${sTag#*\: }"
	sTag="${sTag%,*}"
	echo "${sTag}"
}
gitRepoLatestBinUrl() {
	sContent="${1}"
	sName="${2}"
	sUrl=$(echo "${sContent}" | grep -i browser_download_url)
	for sCrit in "$(basename "${sName}")" ${sSystem} ${sArch} ${sRepoFileFormat}; do
		#echo -e "$sCrit\t${sUrl}"; read -rp " "
		sUrl="$(echo "${sUrl}" | grep "${sCrit}" || echo "false")"
		read -rp " "
		if [ "${sUrl}" = "false" ]; then sUrl="${sUrl#*\: }"; break; fi
	done
	sUrl="${sUrl#*\: }"
	sUrl="${sUrl%,*}"
	echo "${sUrl}"
}
getGhRepoReleases() {
	sProject=${1}
	gh release list --repo "${sProject}" #| grep --color=auto -i latest
}
dlGhReleaseTarball() {
	sProject=${1}
	sBeginFilename=${2}
	#cd "${sStratisRepoHome}" || exit 1
	#gh release download --skip-existing --repo "${sProject}" --pattern "*$sBeginFilename*" --pattern "*$sSystem*" --pattern "*$sArch*" --pattern "*$sRepoFileFormat"
	gh release download --dir "${sStratisRepoHome}" --skip-existing --repo "${sProject}" --pattern "*$sBeginFilename*$sSystem*$sArch*$sRepoFileFormat"
	#echo $?
}
preRequisitesInstall() {
	if command -v sudo 1>dev/null 2>&1; then
		if command -v apt-get 1>dev/null 2>&1; then
			sudo apt-get update
			if ! command -v gh 1>dev/null 2>&1; then 		sudo apt-get install gh; fi		#github-cli
			if ! command -v curl 1>dev/null 2>&1; then 		sudo apt-get install curl; fi	#curl
		fi		
	fi
	if [ -d "$HOME/.config/gh" ] || ! gh auth status; then 	gh auth login; fi
}
main() {
	for sStratisFile in "${tStratisFile[@]}"; do #for sStratisUrl in "${tRepoUrl[@]}"; do
		sStratisUrl="${tRepoUrl["${sStratisFile}"]}"
		echo -e "\t>>> waiting for answer ${sStratisUrl}, please wait..."
		sGitRepoContent="$(gitRepoContent "${sStratisUrl}")"
		sRepoVersion=$(gitRepoBinVersion "${sGitRepoContent}")
						#for sStratisBin in "${tLocalBins[@]}"; do
						#	#getLocalBinVersion "${sStratisBin}"
						#	sBinUrl="$(gitRepoLatestBinUrl "${sGitRepoContent}" "${sStratisBin}")"
						#	if [ ! "${sBinUrl}" = "false" ]; then break; fi
						#done
		sBinUrl="$(gitRepoLatestBinUrl "${sGitRepoContent}" "${tLocalBin["${sStratisFile}"]}")"
		read -rp " "
		echo -e "${sStratisFile}\t${sStratisUrl}\t${sBinUrl}\n${sRepoVersion}\n\n" #${sStratisBin}
	done
}
test() {
	for sBinFileName in "${tStratisFile[@]}"; do
		sOwnerAndRepo="${tStratisRepoOwnerAndName[$sBinFileName]}"
		echo -e "\t>>> Getting repo ${BBlue}${sOwnerAndRepo}$normal releases for ${BBlue}${sBinFileName}${normal} binary, please wait!"
		getGhRepoReleases "${sOwnerAndRepo}" #gitRepoBinVersion ""
		if true; then 	dlGhReleaseTarball "${sOwnerAndRepo}" "${sBinFileName}"; fi #|| echo -e "\t>>> File Already downloaded"
	done
}
#preRequisitesInstall
test
#main
