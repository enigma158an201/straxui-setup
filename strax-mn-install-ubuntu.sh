#!/usr/bin/env bash
# for ubuntu 20.04 mini iso: http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso
set -euo pipefail #set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"	
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"
source "${launchDir}/include/set-common-settings.sh"

#myCpuArch=$(uname -i) #amd64 x64 arm arm64

setupDotNet() {
	# see https://learn.microsoft.com/fr-fr/dotnet/core/install/linux-ubuntu?source=recommendations for more recent instrcutions
	tmpDotNetArchive=/tmp/dotnet.tar.gz
	targetDotNetInstall=/usr/share/dotnet/

	if true; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
	#elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
		#myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
	elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
	elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
	fi
	/usr/bin/curl -SL -o "$tmpDotNetArchive" "$myDotNetArchUrl"
	suExecCommand "mkdir -p \"$targetDotNetInstall\"; \
	tar -zxf \"$tmpDotNetArchive\" -C \"$targetDotNetInstall\"; \
	ln -sfv \"$targetDotNetInstall/dotnet\" /usr/bin/dotnet"
}

setupNode() {
	# see https://github.com/stratisproject/StratisFullNode/releases for more recent instructions

	#tmpNodeArchive=/tmp/SNode.zip
	#targetNodeInstall=$HOME/StraxNode/

	if true; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip"
	elif false; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip"
	elif false; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip"
	fi
	tmpNodeArchive=/tmp/SNode.zip
	wget -O "$tmpNodeArchive" "$myDotNetArchUrl"
	suExecCommand "targetNodeInstall=\$HOME/StraxNode/; \
	unzip \"$tmpNodeArchive\" -d \"$targetNodeInstall\"; \
	screen dotnet \"$targetNodeInstall/Stratis.StraxD.dll\" run -mainnet
	screen -ls
	# voir pour avoir la bonne valeur depuis la commande screen -ls et remplacer 2848
	screen -r 2848"
}

setupWalletCli() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	tmpWalletCliArchive=/tmp/SCli.zip
	targetWalletCliInstall=$HOME/StraxCLI/
	urlWalletCli="https://github.com/stratisproject/StraxCLI/archive/refs/tags/StraxCLI-1.0.0.zip"
	nameFile=$(basename "$urlWalletCli" .zip)
	suExecCommand wget -O "$tmpWalletCliArchive" "$urlWalletCli"
	suExecCommand unzip "$tmpWalletCliArchive" -d "$targetWalletCliInstall"
	suExecCommand python3 "$targetWalletCliInstall/StraxCLI-$nameFile/straxcli.py"
}
setupWalletUi() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	source "${launchDir}/install-strax-wallet-gz.sh"
}
getFirstAddressIpRoute() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else																				exit 1
	fi
	for myWord in $2; do
		if [[ $myWord =~ $sTxt ]]; then 
			echo "$myWord"
			break
		fi
	done
}
getFirstAddressIpAddr() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else																				exit 1
	fi
	for myWord in $2; do
		if [[ $myWord =~ $sTxt+[0-9a-fA-F] ]]; then 
			echo "$myWord"
			break
		fi
	done
}
getNetworkAddress() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt='.'; bIp4="true"; bIp6="false"
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=':'; bIp4="false"; bIp6="true"
	else																				exit 1
	fi
	myInputAddress=$2 #myInputAddress="$(echo $2 | tr "$sTxt" " " )"
	#for myWord in $myInputAddress; do
		#if [[ $myWord =~ $sTxt ]]; then 
			#echo "$myWord"
			#break
		#fi
	#done
	if ($bIp4); then 
		myOutputAddress="${myInputAddress%"$sTxt"*}${sTxt}0"
	elif ($bIp6) && [ -x /usr/bin/ipv6calc ]; then
		#myUncompressedInputAddress="$(ipv6calc --addr2uncompaddr "$myInputAddress")"
		#myOutputAddress="${myUncompressedInputAddress%"$sTxt"*}${sTxt}"
		myOutputAddress="$(ipv6calc --out ipv6addr --printprefix --in ipv6addr "$myInputAddress")"
	else
		myOutputAddress="false"
	fi
	echo "$myOutputAddress"
}

getIpAddr4() {
	if [ -x /usr/bin/awk ]; then
		if [ -x /bin/ip ]; then				ip -4 route get 1.2.3.4 | awk '{print $7}'					# after src string
		elif [ -x /bin/hostname ]; then		getFirstAddressIpRoute 4 "$(hostname -I)"							# hostname -I | awk '{ print $1 }'
		fi
	fi
}
getIpAddr6() {
	if [ -x /usr/bin/awk ]; then
		if [ -x /bin/ip ]; then				getFirstAddressIpAddr 6 "$(ip -6 -o addr | grep -v ': lo')" #ip -6 route get 2001:4860:4860::8888 | awk '{print $11}'	# after src string
		elif [ -x /bin/hostname ]; then		getFirstAddressIpRoute 6 "$(hostname -I)" 							# hostname -I | awk '{ print $x }'
		fi
	fi
}
setupSecurityConsiderations() {
	myIpAddr4=$(getIpAddr4)
	myNetAddr4="$(getNetworkAddress 4 "$myIpAddr4")"
	myIpAddr6=$(getIpAddr6)
	myNetAddr6="$(getNetworkAddress 6 "$myIpAddr6")"
	if false; then 
		suExecCommand apt-get -y install ufw
		suExecCommand ufw enable
		suExecCommand ufw allow from "$myNetAddr4/24" to any port 22
		if false; then suExecCommand ufw allow from "$myNetAddr6/24" to any port 22; fi
	fi
}
test() {
	getNetworkAddress 4 "$(getIpAddr4)"
	getNetworkAddress 6 "$(getIpAddr6)"
}
test
main_mn() {
	suExecCommand "source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	setupDotNet
	setupNode
	setupWalletCli
	#setupWalletUi
	setupSecurityConsiderations
}
main_mn
