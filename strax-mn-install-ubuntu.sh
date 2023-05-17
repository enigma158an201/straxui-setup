#!/usr/bin/env bash
# for ubuntu 20.04 mini iso: http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso
set -euxo pipefail

#myCpuArch=$(uname -i) #amd64 x64 arm arm64

setupDotNet() {
	# see https://learn.microsoft.com/fr-fr/dotnet/core/install/linux-ubuntu?source=recommendations for more recent instrcutions
	tmpDotNetArchive=/tmp/dotnet.tar.gz
	targetDotNetInstall=/usr/share/dotnet/

	if true; then
		#sudo curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
	#elif false; then
		#sudo curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
		#myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
	elif false; then
		#sudo curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
	elif false; then
		#sudo curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
		myDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
	fi
	curl -SL -o "$tmpDotNetArchive" "$myDotNetArchUrl"
	sudo mkdir -p "$targetDotNetInstall"
	sudo tar -zxf "$tmpDotNetArchive" -C "$targetDotNetInstall"
	sudo ln -s "$targetDotNetInstall/dotnet" /usr/bin/dotnet
}

setupNode() {
	# see https://github.com/stratisproject/StratisFullNode/releases for more recent instructions

	tmpNodeArchive=/tmp/SNode.zip
	targetNodeInstall=$HOME/StraxNode/

	if true; then
		#sudo wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip"
	elif false; then
		#sudo wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip"
	elif false; then
		#sudo wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip
		myDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip"
	fi
	wget -O "$tmpNodeArchive" "$myDotNetArchUrl"
	sudo unzip "$tmpNodeArchive" -d "$targetNodeInstall"
	sudo screen dotnet "$targetNodeInstall/Stratis.StraxD.dll" run -mainnet
	sudo screen -ls
	# voir pour avoir la bonne valeur depuis la commande screen -ls et remplacer 2848
	sudo screen -r 2848
}

setupWalletCli() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	tmpWalletCliArchive=/tmp/SCli.zip
	targetWalletCliInstall=$HOME/StraxCLI/
	urlWalletCli="https://github.com/stratisproject/StraxCLI/archive/refs/tags/StraxCLI-1.0.0.zip"
	nameFile=$(basename "$urlWalletCli" .zip)
	sudo wget -O "$tmpWalletCliArchive" "$urlWalletCli"
	sudo unzip "$tmpWalletCliArchive" -d "$targetWalletCliInstall"
	sudo python3 "$targetWalletCliInstall/StraxCLI-$nameFile/straxcli.py"
}
setupWalletUi() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	tmpWalletUiArchive=/tmp/SUi.zip
	targetWalletUiInstall=$HOME/StraxCLI/
	urlWalletUi="https://github.com/stratisproject/StraxCLI/archive/refs/tags/StraxCLI-1.0.0.zip" 
	nameFile=$(basename "$urlWalletUi" .zip)
	sudo wget -O "$tmpWalletUiArchive" "$urlWalletUi"
	sudo unzip "$tmpWalletUiArchive" -d "$targetWalletUiInstall"
	sudo python3 "$targetWalletUiInstall/StraxCLI-$nameFile/straxcli.py"
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
		sudo apt-get -y install ufw
		sudo ufw enable
		sudo ufw allow from "$myNetAddr4/24" to any port 22
		if false; then sudo ufw allow from "$myNetAddr6/24" to any port 22; fi
	fi
}
test() {
	getNetworkAddress 4 "$(getIpAddr4)"
	getNetworkAddress 6 "$(getIpAddr6)"
}
test
main() {
	bash ./apt-pre-instal-pkg-ubuntu.sh
	setupDotNet
	setupNode
	setupWalletCli
	#setupWalletUi
	setupSecurityConsiderations
}
main