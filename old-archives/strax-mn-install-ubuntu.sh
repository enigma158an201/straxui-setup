#!/usr/bin/env bash
# for ubuntu 20.04 mini iso: http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso
set -euo pipefail #set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"	
source "${launchDir}/include/test-superuser-privileges.sh"
#source "${launchDir}/include/file-edition.sh"
source "${launchDir}/include/set-common-settings.sh"
source "${launchDir}/include/get-network-settings.sh"

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
	if [ ! -f "$tmpDotNetArchive" ]; then /usr/bin/curl -SL -o "$tmpDotNetArchive" "$myDotNetArchUrl"; fi
	echo -e "\t>>> extract then install dotnet archive"
	suExecCommandNoPreserveEnv "mkdir -p \"$targetDotNetInstall\"; \
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
	if [ ! -f "$tmpNodeArchive" ]; then wget -O "$tmpNodeArchive" "$myDotNetArchUrl"; fi
	echo -e "\t>>> extract then install node archive"
	suExecCommandNoPreserveEnv "targetNodeInstall=\$HOME/StraxNode/; \
	unzip \"$tmpNodeArchive\" -d \"\$targetNodeInstall\"; \
	screen dotnet \"\$targetNodeInstall/Stratis.StraxD.dll\" run -mainnet
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
	echo -e "\t>>> extract then install wallet cli archive"
	suExecCommand "wget -O $tmpWalletCliArchive $urlWalletCli;
	unzip $tmpWalletCliArchive -d $targetWalletCliInstall;
	python3 $targetWalletCliInstall/StraxCLI-$nameFile/straxcli.py"
}
setupWalletUi() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	source "${launchDir}/install-strax-wallet-gz.sh"
}
setupSecurityConsiderations() {
	myIpAddr4=$(getIpAddr4)
	myNetAddr4="$(getNetworkAddress 4 "$myIpAddr4")"
	myIpAddr6=$(getIpAddr6)
	myNetAddr6="$(getNetworkAddress 6 "$myIpAddr6")"
	if false; then
		echo -e "\t>>> install then set ufw firewall"
		suExecCommand "apt-get -y install ufw;
		ufw enable;
		ufw allow from $myNetAddr4/24 to any port 22
		if false; then ufw allow from $myNetAddr6/24 to any port 22; fi"
	fi
}
main_mn() {
	echo -e "\t>>> install needed deps packages for script usage"
	suExecCommand "source ${launchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	setupDotNet
	setupNode
	setupWalletCli
	#setupWalletUi
	setupSecurityConsiderations
}
main_mn
