#!/usr/bin/env bash

# https://github.com/stratisproject/StraxUI.git

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source "${launchDir}/include/pre-install-pkgs.sh"
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"
source "${launchDir}/include/apt-functions.sh" #apt-pre-instal-pkg-ubuntu.sh"
#source "${launchDir}/include/set-common-settings.sh"

function determinerOS() {
	cat /etc/os-release # echo `lsb_release -a`
}
myOS=$(determinerOS)

function determineSiUbuntu() {
	echo "${myOS}" | grep -i Ubuntu || echo "false"
}
function determineSiMint() {
	echo "${myOS}" | grep -i Mint || echo "false"
} # pas besoin de truc pour différencier si debian ou ubuntu based, si debian on trouve du buster debbie
function determineSiUbuntuBionic() {
	echo "${myOS}" | grep -i bionic || echo "false"
}
function determineSiUbuntuFocal() {
	echo "${myOS}" | grep -i focal || echo "false"
}
function determineSiUbuntuJammy() {
	echo "${myOS}" | grep -i jammy || echo "false"
}
function determineSiDebian() {
	echo "${myOS}" | grep -i debian || echo "false"
}
function determineSiDebianBuster() {
	echo "${myOS}" | grep -i buster || echo "false"
}
function determineSiDebianBullsEye() {
	echo "${myOS}" | grep -i bullseye || echo "false"
}
function determineSiDebianBookworm() {
	echo "${myOS}" | grep -i bookworm || echo "false"
}
function determineSiDebianTrixie() {
	echo "${myOS}" | grep -i trixie || echo "false"
}
function determineSiDebianForky() {
	echo "${myOS}" | grep -i forky || echo "false"
}
function determineSiDebianTesting() {
	echo "${myOS}" | grep -i testing || echo "false"
}
function determineSiDebianSid() {
	echo "${myOS}" | grep -i sid || echo "false"
}
function determineSiMintLMDE() {
	echo "${myOS}" | grep -i lmde || echo "false"
}
function determineSiDeepin() {
	echo "${myOS}" | grep -i deepin || echo "false"
}

isUbuntu=$(determineSiUbuntu)
isMint=$(determineSiMint)
isUbuntuLike="${isUbuntu}${isMint}"
#if [ ! "${isUbuntuLike}" = "" ]; then
	# isTrusty=$(determineSiUbuntuTrusty)
	# isXenial=$(determineSiUbuntuXenial)
	# isBionic=$(determineSiUbuntuBionic)
	# isFocal=$(determineSiUbuntuFocal)
	# isJammy=$(determineSiUbuntuJammy)
#fi
isDebian=$(determineSiDebian)
if [ ! "${isDebian}" = "" ] || [ ! "${isMint}" = "" ]; then
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
	# if [ ! "${upgradeStratis^^}" = "N" ] && [ ! "${upgradeStratis}" = "" ]; then
		echo -e "/t>>> install des paquets pré requis et ajust hostname before ssh configuration"
		#apt-get update && apt-get install ipcalc ipv6calc dnsutils jq curl;
		suExecCommandNoPreserveEnv "${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \		
		${launchDir}/include/set-common-settings.sh" # suExecCommandNoPreserveEnv "${launchDir}/include/set-hostname.sh"
		echo -e "/t>>> create ssh keys pair"
		bash -c "${launchDir}/include/set-ssh-nonroot-user-keys.sh" # remember never put -i here

		if [ ! "${isDebianLike}" = "" ]; then
			dlDir="/tmp/"
			#sudo /usr/bin/apt-get install -y git jq curl
			#libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2
			echo -e "/t>>> check and/or install straxui deps"
			if [ ! "${isBuster}" = "" ]; then
				#suExecCommandNoPreserveEnv "bash -v -c \"source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \
				#pkgsToInstall=(libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2); \
				#for pkgToInstall in \${pkgsToInstall}; do \
				#	isInstalled=\$(checkDpkgInstalled \"\${pkgToInstall}\"); \
				#	if [ \"\${isInstalled}\" = \"false\" ]; then \
				#		/usr/bin/apt-get install -y \${pkgToInstall}; \
				#	fi; \
				#done\""
				#source "${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh"
				pkgsToInstall=(libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2)
				for pkgToInstall in "${pkgsToInstall[@]}"; do
					isInstalled=$(checkDpkgInstalled "${pkgToInstall}")
					if [ "${isInstalled}" = "false" ]; then
						#suExecCommand "bash -c \"/usr/bin/apt-get install -y ${pkgToInstall}\""
						#suExecCommand "DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y ${pkgToInstall}"
						suExecCommand "${launchDir}/include/apt-install-cmd.sh ${pkgToInstall}"
					fi
				done
				
				projectlatestcontentdeb="$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[0] | .browser_download_url')"
				sFileNameDeb="${dlDir}$(basename "${projectlatestcontentdeb}")"
				if [ ! -f "${sFileNameDeb}" ]; then wget -O "${sFileNameDeb}" "${projectlatestcontentdeb}"; fi
				echo -e "/t>>> check and/or install straxui .deb package"
				debVersion=$(dpkg-deb -I "${sFileNameDeb}" | grep -Ei "^ Version:")
				debVersion="${debVersion##* }"
				dpkgVersion="$(dpkg-query -l straxui | grep ^ii | awk '{ print $3 }' || echo "false")"
				if [ ! "${debVersion}" = "${dpkgVersion}"  ]; then 
					#suExecCommandNoPreserveEnv "LANG=C DEBIAN_FRONTEND=noninteractive dpkg -i ${sFileNameDeb} 2>&1 || echo \"false\""
					suExecCommandNoPreserveEnv "${launchDir}/include/dpkg-install-cmd.sh ${sFileNameDeb}"
				fi
			elif [ "${isBuster}" = "" ]; then
				#suExecCommandNoPreserveEnv "bash -v -c \"source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; \
				#pkgsToInstall=(libappindicator3-0.1-cil{,-dev}); \
				#for pkgToInstall in \${pkgsToInstall}; do \
				#	isInstalled=\$(checkDpkgInstalled \"\${pkgToInstall}\"); \
				#	if [ \"\${isInstalled}\" = \"false\" ]; then \
				#		/usr/bin/apt-get install -y \${pkgToInstall}; \
				#	fi; \
				#done\""
				#source "${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh"
				pkgsToInstall=(libappindicator3-0.1-cil{,-dev})
				for pkgToInstall in "${pkgsToInstall[@]}"; do
					isInstalled=$(checkDpkgInstalled "${pkgToInstall}")
					if [ "${isInstalled}" = "false" ]; then
						#suExecCommand "bash -c \"/usr/bin/apt-get install -y ${pkgToInstall}\""
						#suExecCommand "bash -v -c LANG=C DEBIAN_FRONTEND=noninteractive /usr/bin/apt-get install -y ${pkgToInstall}"
						suExecCommand "${launchDir}/include/apt-install-cmd.sh ${pkgToInstall}"
					fi
				done

				projectlatestcontentgz="$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[1] | .browser_download_url')"
				myfilenamegz="${dlDir}$(basename "${projectlatestcontentgz}")"
				if [ ! -f "${myfilenamegz}" ]; then wget -O "${myfilenamegz}" "${projectlatestcontentgz}"; fi			
				echo -e "/t>>> extract and install straxui .gz archive"
				suExecCommand "folderinsidetar=$(tar --exclude=\"*/*\" -tf \"\$myfilenamegz\"); straxuidestfolder=/opt/straxui/; mkdir -p \$straxuidestfolder; \ 
				tar --strip-components=1 -C \"\$straxuidestfolder" -xvzf "\${myfilenamegz}\" \"\$folderinsidetar" # /opt/straxui
			fi

			# echo ${projectlatestcontent}
			
		fi
	# fi
}
main_installStrax