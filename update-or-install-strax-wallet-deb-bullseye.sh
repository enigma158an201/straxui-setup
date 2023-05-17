#!/bin/bash

# https://github.com/stratisproject/StraxUI.git
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi
source "${launchDir}/include/pre-install-pkgs.sh"

function determinerOS() {
	cat /etc/os-release # echo `lsb_release -a`
}
myOS=$(determinerOS)

function determineSiUbuntu() {
	echo "$myOS" | grep -i Ubuntu
}
function determineSiMint() {
	echo "$myOS" | grep -i Mint
} # pas besoin de truc pour différencier si debian ou ubuntu based, si debian on trouve du buster debbie
function determineSiUbuntuBionic() {
	echo "$myOS" | grep -i bionic
}
function determineSiUbuntuFocal() {
	echo "$myOS" | grep -i focal
}
function determineSiUbuntuJammy() {
	echo "$myOS" | grep -i jammy
}
function determineSiDebian() {
	echo "$myOS" | grep -i debian
}
function determineSiDebianBuster() {
	echo "$myOS" | grep -i buster
}
function determineSiDebianBullsEye() {
	echo "$myOS" | grep -i bullseye
}
function determineSiDebianBookworm() {
	echo "$myOS" | grep -i bookworm
}
function determineSiDebianTesting() {
	echo "$myOS" | grep -i testing
}
function determineSiDebianSid() {
	echo "$myOS" | grep -i sid
}
function determineSiMintLMDE() {
	echo "$myOS" | grep -i lmde
}
function determineSiDeepin() {
	echo "$myOS" | grep -i deepin
}

isUbuntu=$(determineSiUbuntu)
isMint=$(determineSiMint)
isUbuntuLike="$isUbuntu$isMint"
#if [ ! "$isUbuntuLike" = "" ]; then
	# isTrusty=$(determineSiUbuntuTrusty)
	# isXenial=$(determineSiUbuntuXenial)
	# isBionic=$(determineSiUbuntuBionic)
	# isFocal=$(determineSiUbuntuFocal)
	# isJammy=$(determineSiUbuntuJammy)
#fi
isDebian=$(determineSiDebian)
if [ ! "$isDebian" = "" ] || [ ! "$isMint" = "" ]; then
	isBuster=$(determineSiDebianBuster)
	# isBullseye=$(determineSiDebianBullsEye)
	# isBookworm=$(determineSiDebianBookworm)
	# isTesting=$(determineSiDebianTesting)
	# isSid=$(determineSiDebianSid)
	# isLmde=$(determineSiMintLMDE)
fi
isDeepin=$(determineSiDeepin)
isDebianLike="$isUbuntuLike$isDebian$isDeepin"

# read -rp "Mettre à jour Strax o/N" -n 1 upgradeStratis
# if [ ! "${upgradeStratis^^}" = "N" ] && [ ! "$upgradeStratis" = "" ]; then
	if [ ! "$isDebianLike" = "" ]; then
		#sudo apt-get install -y git jq curl
		#libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2
		if [ ! "$isBuster" = "" ]; then
			sudo apt-get install -y libgtk-3-0 libnotify4 libnss3 libxss1 libxtst6 xdg-utils libatspi2.0-0 libappindicator3-1 libsecret-1-0 libasound2
			projectlatestcontentdeb=$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[0] | .browser_download_url')
			myfilenamedeb=$(basename "$projectlatestcontentdeb")
			if [ ! -f "$myfilenamedeb" ]; then wget "$projectlatestcontentdeb"; fi
			sudo dpkg -i "$myfilenamedeb"
		elif [ "$isBuster" = "" ]; then
			sudo apt-get install -y libappindicator3-0.1-cil{,-dev}
			straxuidestfolder=/opt/straxui
			projectlatestcontentgz=$(curl -s https://api.github.com/repos/stratisproject/StraxUI/releases/latest | jq -r '.assets[1] | .browser_download_url')
			myfilenamegz=$(basename "$projectlatestcontentgz")
			if [ ! -f "$myfilenamegz" ]; then wget "$projectlatestcontentgz"; fi
			sudo mkdir -p "$straxuidestfolder"
			folderinsidetar=$(tar --exclude="*/*" -tf "$myfilenamegz")
			sudo tar --strip-components=1 -C "$straxuidestfolder" -xvzf "$myfilenamegz" "$folderinsidetar" # /opt/straxui
		fi

		# echo $projectlatestcontent
		
	fi
# fi
