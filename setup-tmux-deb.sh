#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

sEtcOsReleasePath=/etc/os-release

checkIfDebianId() {
	if [ -r "${sEtcOsReleasePath}" ]; then
        sIsDebian="$(grep -i "^ID=" "${sEtcOsReleasePath}" || echo "false")"
		sIsDebianLike="$(grep -i "^ID_LIKE=" "${sEtcOsReleasePath}" || echo "false")"
		if [[ ${sIsDebian,,} =~ debian ]] || [[ ${sIsDebianLike,,} =~ debian ]]; then
			echo "true"
		else
			echo "false"
			exit 1
		fi
	else
		echo "false"
		exit 1
	fi
}

installTmuxDeb() {
	echo -e "\t>>> Install tmux terminal multiplexer for debian"
	sudo apt-get install -y tmux	
}

setupTmuxConf() {
	sTmuxConf=$HOME/.tmux.conf
	echo -e "\t>>> setup tmux config at ${sTmuxConf}"
	#3. To add a repository for stable releases, run the following command:
	echo "# Permet de définir le shell utilisé par défaut
set-option -g default-shell /usr/bin/bash
# Permet d'utiliser la souris dans un terminal virtuel (avant la version 2.1)
# setw -g mode-mouse on
# set -g mouse-resize-pane on
# set -g mouse-select-pane on
# set -g mouse-select-window on
# Permet d'utiliser la souris dans un terminal virtuel (à partir de la version 2.1)
set -g mouse on" | tee ${sTmuxConf}
}
main_tmux() {
	bIsDebian="$(checkIfDebianId)"
	echo -e "\t>>> debian check: $bIsDebian"
	if $bIsDebian; then
		installTmuxDeb
		setupTmuxConf
	else
		exit 1
	fi

}
main_tmux