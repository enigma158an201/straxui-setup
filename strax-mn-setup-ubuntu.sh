#!/usr/bin/env bash
# for ubuntu 20.04 mini iso: http://archive.ubuntu.com/ubuntu/dists/focal/main/installer-amd64/current/legacy-images/netboot/mini.iso
set -euxo pipefail

#myCpuArch=$(uname -i) #amd64 x64 arm arm64

sudo apt-get update && sudo apt-get upgrade
sudo apt-get -y install net-tools wget curl tar install zip

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

main() {
    setupDotNet
    setupNode
    setupWalletCli
    #setupWalletUi
}
