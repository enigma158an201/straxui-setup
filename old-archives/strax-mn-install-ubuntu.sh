#!/usr/bin/env bash
# for ubuntu 20.04 mini iso: http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso
set -euo pipefail #set -x

sLaunchDir="$(dirname "$0")"
if [ "${sLaunchDir}" = "." ]; then sLaunchDir="$(pwd)"; elif [ "${sLaunchDir}" = "include" ]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"	
source "${sLaunchDir}/include/test-superuser-privileges.sh"
#source "${sLaunchDir}/include/file-edition.sh"
source "${sLaunchDir}/include/set-common-settings.sh"
source "${sLaunchDir}/include/get-network-settings.sh"

#sCpuArch=$(uname -i) #amd64 x64 arm arm64

setupDotNet() {
	# see https://learn.microsoft.com/fr-fr/dotnet/core/install/linux-ubuntu?source=recommendations for more recent instrcutions
	sTmpDotNetArchive=/tmp/dotnet.tar.gz
	sTargetDotNetInstall=/usr/share/dotnet/

	if true; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
		sDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-x64.tar.gz"
	#elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
		#sDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-i386.tar.gz"
	elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
		sDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm64.tar.gz"
	elif false; then
		#suExecCommand curl -SL -o dotnet.tar.gz "https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
		sDotNetArchUrl="https://dotnetcli.blob.core.windows.net/dotnet/Sdk/master/dotnet-sdk-latest-linux-arm.tar.gz"
	fi
	if [ ! -f "${sTmpDotNetArchive}" ]; then /usr/bin/curl -SL -o "${sTmpDotNetArchive}" "${sDotNetArchUrl}"; fi
	echo -e "\t>>> extract then install dotnet archive"
	suExecCommandNoPreserveEnv "mkdir -p \"${sTargetDotNetInstall}\"; \
	tar -zxf \"${sTmpDotNetArchive}\" -C \"${sTargetDotNetInstall}\"; \
	ln -sfv \"${sTargetDotNetInstall}/dotnet\" /usr/bin/dotnet"
}

setupNode() {
	# see https://github.com/stratisproject/StratisFullNode/releases for more recent instructions

	#sTmpNodeArchive=/tmp/SNode.zip
	#targetNodeInstall=${HOME}/StraxNode/

	if true; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip
		sDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-x64.zip"
	elif false; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip
		sDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm64.zip"
	elif false; then
		#suExecCommand wget -O SNode.zip https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip
		sDotNetArchUrl="https://github.com/stratisproject/StratisFullNode/releases/download/1.1.1.1/Stratis.StraxD-linux-arm.zip"
	fi
	sTmpNodeArchive=/tmp/SNode.zip
	if [ ! -f "${sTmpNodeArchive}" ]; then wget -O "${sTmpNodeArchive}" "${sDotNetArchUrl}"; fi
	echo -e "\t>>> extract then install node archive"
	suExecCommandNoPreserveEnv "targetNodeInstall=\${HOME}/StraxNode/; \
	unzip \"${sTmpNodeArchive}\" -d \"\${targetNodeInstall}\"; \
	screen dotnet \"\${targetNodeInstall}/Stratis.StraxD.dll\" run -mainnet
	screen -ls
	# voir pour avoir la bonne valeur depuis la commande screen -ls et remplacer 2848
	screen -r 2848"
}

setupWalletCli() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	sTmpWalletCliArchive=/tmp/SCli.zip
	sTargetWalletCliInstall=${HOME}/StraxCLI/
	sUrlWalletCli="https://github.com/stratisproject/StraxCLI/archive/refs/tags/StraxCLI-1.0.0.zip"
	sNameFile=$(basename "${sUrlWalletCli}" .zip)
	echo -e "\t>>> extract then install wallet cli archive"
	suExecCommand "wget -O ${sTmpWalletCliArchive} ${sUrlWalletCli};
	unzip ${sTmpWalletCliArchive} -d ${sTargetWalletCliInstall};
	python3 ${sTargetWalletCliInstall}/StraxCLI-${sNameFile}/straxcli.py"
}
setupWalletUi() {
	# see https://github.com/stratisproject/StraxUI/releases or https://github.com/stratisproject/StraxCLI/releases/tag/StraxCLI-1.0.0 for more recent instructions
	source "${sLaunchDir}/install-strax-wallet-gz.sh"
}
setupSecurityConsiderations() {
	sIpAddr4=$(getIpAddr4)
	sNetAddr4="$(getNetworkAddress 4 "${sIpAddr4}")"
	sIpAddr6=$(getIpAddr6)
	sNetAddr6="$(getNetworkAddress 6 "${sIpAddr6}")"
	if false; then
		echo -e "\t>>> install then set ufw firewall"
		suExecCommand "apt-get -y install ufw;
		ufw enable;
		ufw allow from ${sNetAddr4}/24 to any port 22
		if false; then ufw allow from ${sNetAddr6}/24 to any port 22; fi"
	fi
}
main_mn() {
	echo -e "\t>>> install needed deps packages for script usage"
	suExecCommand "source ${sLaunchDir}/include/apt-pre-instal-pkg-ubuntu.sh; aptPreinstallPkg; aptUnbloatPkg"
	setupDotNet
	setupNode
	setupWalletCli
	#setupWalletUi
	setupSecurityConsiderations
}
main_mn
