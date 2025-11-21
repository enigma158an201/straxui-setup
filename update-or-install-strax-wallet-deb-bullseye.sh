#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
#source "${sLaunchDir}/include/pre-install-pkgs.sh"
source "${sLaunchDir}/include/test-superuser-privileges.sh"
#source "${sLaunchDir}/include/file-edition.sh"
source "${sLaunchDir}/include/apt-functions.sh" #apt-pre-instal-pkg-ubuntu.sh"
#source "${sLaunchDir}/include/set-common-settings.sh"

function determinerOS() {
	cat /etc/os-release # echo `lsb_release -a`
}
sOS=$(determinerOS)

function determineSiUbuntu() {
	echo "${sOS}" | grep -i Ubuntu || echo "false"
}
function determineSiMint() {
	echo "${sOS}" | grep -i Mint || echo "false"
} # pas besoin de truc pour différencier si debian ou ubuntu based, si debian on trouve du buster debbie
function determineSiUbuntuBionic() {
	echo "${sOS}" | grep -i bionic || echo "false"
}
function determineSiUbuntuFocal() {
	echo "${sOS}" | grep -i focal || echo "false"
}
function determineSiUbuntuJammy() {
	echo "${sOS}" | grep -i jammy || echo "false"
}
function determineSiDebian() {
	echo "${sOS}" | grep -i debian || echo "false"
}
function determineSiDebianBuster() {
	echo "${sOS}" | grep -i buster || echo "false"
}
function determineSiDebianBullsEye() {
	echo "${sOS}" | grep -i bullseye || echo "false"
}
function determineSiDebianBookworm() {
	echo "${sOS}" | grep -i bookworm || echo "false"
}
function determineSiDebianTrixie() {
	echo "${sOS}" | grep -i trixie || echo "false"
}
function determineSiDebianForky() {
	echo "${sOS}" | grep -i forky || echo "false"
}
function determineSiDebianTesting() {
	echo "${sOS}" | grep -i testing || echo "false"
}
function determineSiDebianSid() {
	echo "${sOS}" | grep -i sid || echo "false"
}
function determineSiMintLMDE() {
	echo "${sOS}" | grep -i lmde || echo "false"
}
function determineSiDeepin() {
	echo "${sOS}" | grep -i deepin || echo "false"
}

isUbuntu=$(determineSiUbuntu)
isMint=$(determineSiMint)
isUbuntuLike="${isUbuntu}${isMint}"
#if [[ ! "${isUbuntuLike}" = "" ]]; then
	# isTrusty=$(determineSiUbuntuTrusty)
	# isXenial=$(determineSiUbuntuXenial)
	# isBionic=$(determineSiUbuntuBionic)
	# isFocal=$(determineSiUbuntuFocal)
	# isJammy=$(determineSiUbuntuJammy)
#fi
isDebian=$(determineSiDebian)
if [[ ! "${isDebian}" = "" ]] || [[ ! "${isMint}" = "" ]]; then
	isBuster=$(determineSiDebianBuster)
	# isBullseye=$(determineSiDebianBullsEye)
	# isBookworm=$(determineSiDebianBookworm)
	# isTesting=$(determineSiDebianTesting)
	# isSid=$(determineSiDebianSid)
	# isLmde=$(determineSiMintLMDE)
fi
isDeepin=$(determineSiDeepin)
isDebianLike="${isUbuntuLike}${isDebian}${isDeepin}"

main_installStrax() {
	# read -rp "Mettre à jour Strax o/N" -n 1 upgradeStratis
	# if [[ ! "${upgradeStratis^^}" = "N" ]] && [[ ! "${upgradeStratis}" = "" ]]; then
		echo -e "/t--> install des paquets pré requis et ajust hostname before ssh configuration"
		#apt-get update && apt-get install ipcalc ipv6calc dnsutils jq curl;
		suExecCommandNoPreserveEnv "${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \		
		${sLaunchDir}/include/set-common-settings.sh" # suExecCommandNoPreserveEnv "${sLaunchDir}/include/set-hostname.sh"
		echo -e "/t--> create ssh keys pair"
		bash -c "${sLaunchDir}/include/set-ssh-nonroot-user-keys.sh" # remember never put -i here

		if [[ ! "${isDebianLike}" = "" ]]; then
			dlDir="/tmp/"
			#sudo /usr/bin/apt-get install -y git jq curl
			#libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2
			echo -e "/t--> check and/or install straxui deps"
			if [[ ! "${isBuster}" = "" ]]; then
				#suExecCommandNoPreserveEnv "bash -v -c \"source ${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \
				#tPkgsToInstall=(libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2); \
				#for sPkgToInstall in \${tPkgsToInstall}; do \
				#	isInstalled=\$(checkDpkgInstalled \"\${sPkgToInstall}\"); \
				#	if [[ \"\${isInstalled}\" = \"false\" ]]; then \
				#		/usr/bin/apt-get install -y \${sPkgToInstall}; \
				#	fi; \
				#done\""
				#source "${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh"
				tPkgsToInstall=(libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2)
				for sPkgToInstall in "${tPkgsToInstall[@]}"; do
					isInstalled=$(checkDpkgInstalled "${sPkgToInstall}")
					if [[ "${isInstalled}" = "false" ]]; then
						#suExecCommand "bash -c \"/usr/bin/apt-get install -y ${sPkgToInstall}\""
						#suExecCommand "DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y ${sPkgToInstall}"
						suExecCommand "${sLaunchDir}/include/apt-install-cmd.sh ${sPkgToInstall}"
					fi
				done
				
				sProjectLatestContentDeb="$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[0] | .browser_download_url')"
				sFileNameDeb="${dlDir}$(basename "${sProjectLatestContentDeb}")"
				if [[ ! -f "${sFileNameDeb}" ]]; then wget -O "${sFileNameDeb}" "${sProjectLatestContentDeb}"; fi
				echo -e "/t--> check and/or install straxui .deb package"
				sDebVersion=$(dpkg-deb -I "${sFileNameDeb}" | grep -Ei "^ Version:")
				sDebVersion="${sDebVersion##* }"
				sDpkgVersion="$(dpkg-query -l straxui | grep ^ii | awk '{ print $3 }' || echo "false")"
				if [[ ! "${sDebVersion}" = "${sDpkgVersion}"  ]]; then 
					#suExecCommandNoPreserveEnv "LANG=C DEBIAN_FRONTEND=noninteractive dpkg -i ${sFileNameDeb} 2>&1 || echo \"false\""
					suExecCommandNoPreserveEnv "${sLaunchDir}/include/dpkg-install-cmd.sh ${sFileNameDeb}"
				fi
			elif [[ "${isBuster}" = "" ]]; then
				#suExecCommandNoPreserveEnv "bash -v -c \"source ${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \
				#tPkgsToInstall=(libappindicator3-0.1-cil{,-dev}); \
				#for sPkgToInstall in \${tPkgsToInstall}; do \
				#	isInstalled=\$(checkDpkgInstalled \"\${sPkgToInstall}\"); \
				#	if [[ \"\${isInstalled}\" = \"false\" ]]; then \
				#		/usr/bin/apt-get install -y \${sPkgToInstall}; \
				#	fi; \
				#done\""
				#source "${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh"
				tPkgsToInstall=(libappindicator3-0.1-cil{,-dev})
				for sPkgToInstall in "${tPkgsToInstall[@]}"; do
					isInstalled=$(checkDpkgInstalled "${sPkgToInstall}")
					if [[ "${isInstalled}" = "false" ]]; then
						#suExecCommand "bash -c \"/usr/bin/apt-get install -y ${sPkgToInstall}\""
						#suExecCommand "bash -v -c LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y ${sPkgToInstall}"
						suExecCommand "${sLaunchDir}/include/apt-install-cmd.sh ${sPkgToInstall}"
					fi
				done

				projectlatestcontentgz="$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[1] | .browser_download_url')"
				sFilenameGz="${dlDir}$(basename "${projectlatestcontentgz}")"
				if [[ ! -f "${sFilenameGz}" ]]; then wget -O "${sFilenameGz}" "${projectlatestcontentgz}"; fi			
				echo -e "/t--> extract and install straxui .gz archive"
				#shellcheck disable=SC1083
				suExecCommand "folderinsidetar=$(tar --exclude=\"*/*\" -tf \"\${sFilenameGz}\"); straxuidestfolder=/opt/straxui/; mkdir -p \${straxuidestfolder}; \ 
				tar --strip-components=1 -C \"\${straxuidestfolder}" -xvzf "\${sFilenameGz}\" \"\${folderinsidetar}" # /opt/straxui
			fi

			# echo ${projectlatestcontent}
			
		fi
	# fi
}
main_installStrax