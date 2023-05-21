#!/bin/bash

# variables
#straxDlUrl="https://github.com/stratisproject/StraxUI/releases/download/1.4.1.0/STRAX.Wallet-v1.4.1-linux-x64.tar.gz"
if [ "$HOSTTYPE" = "x86_64" ]; then 	straxDlUrl="https://github.com/stratisproject/StraxUI/releases/download/1.5.1.0/STRAX.Wallet-v1.5.1-linux-x64.tar.gz"
#elif [ "$HOSTTYPE" = "" ]; then 	 	  straxDlUrl="https://github.com/stratisproject/StraxUI/releases/download/1.5.1.0/STRAX.Wallet-v1.5.1-linux-x64.tar.gz"
else  echo "pas de fichier prêt à l'emploi pour $HOSTTYPE, voir pour une compilation des binaires depuis le code source https://github.com/stratisproject/StraxUI/archive/refs/tags/1.5.1.0.tar.gz"; exit 1
fi

persBins="$HOME/bin"
tmpFld="/tmp"
straxUIFld="Strax-Wallet"
straxUIFldPath="$persBins/$straxUIFld" # on va utiliser un nom qui ne contient pas de version
gzArchName=$(basename "$straxDlUrl")
gzArchFullPath="$tmpFld/$gzArchName"
binNamestraxUI="straxui"
persShFolder="$HOME/.local/share/applications"
# persShFolderGnome="$HOME/.local/share/applications"
# persShFolderXfce=""


# creation du dossier cible pour hoster l'application straxui (donc sans indication de version)
mkdir -p "$straxUIFldPath"

# telechargement de l'archinve depuis github
# cd "$persBins" || exit
if [ ! -f "$gzArchFullPath" ]; then wget "$straxDlUrl" -O "$gzArchFullPath"; fi

# Extraction de l'archive vers le dossier cible (toujours sans version)
tar xzvf "$gzArchFullPath" -C "$straxUIFldPath" --strip-components=1
if [ ! -L "$straxUIFldPath/$binNamestraxUI" ]; then 
  ln -sf "$straxUIFldPath/$binNamestraxUI" "$persBins/$binNamestraxUI"
fi

# creation d'un raccourci mpour le menu applications
# testGnomeDE=$(env | grep XDG_SESSION_DESKTOP | grep -i gnome)
# testXfceDE=$(env | grep XDG_SESSION_DESKTOP | grep -i xfce)

# if [ ! "$testGnomeDE" = "" ]; then
  # persShFolder="$persShFolderGnome"
# elif [ ! "$testGnomeDE" = "" ]; then
  # persShFolder="$persShFolderXfce"
# fi

mkdir -p "$persShFolder"
straxuiSh="$persShFolder/$binNamestraxUI.desktop"
if [ ! -f "$straxuiSh" ]; then touch "$straxuiSh"; fi 
echo -e "[Desktop Entry]
Type=Application
Encoding=UTF-8
Name=$straxUIFld
Comment=$persBins/$binNamestraxUI
Exec=$persBins/$binNamestraxUI
Icon=$straxUIFldPath/resources/src/assets/images/stratis/icon-16.png
Terminal=False" > "$straxuiSh"
