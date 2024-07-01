#!/usr/bin/env bash
set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; elif [ "$launchDir" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/apt-functions.sh"

aptPreinstallPkg() {
	declare -a pkgsToInstall
	pkgsToInstall=(net-tools wget curl tar zip grep gawk ipcalc ipv6calc git jq  cron rfkill conntrack dnsutils ) #xinit screen desktop-file-utils
	apt-get update && apt-get upgrade
	for pkgToInstall in "${pkgsToInstall[@]}" #${pkgsToInstall[*]}
	do
		#echo "verification si paquet $pkgToInstall installé" #; read -rp " "
		#if [ "$(checkDpkgInstalled "$pkgToInstall")" = "false" ]; then
			apt-get -y install "$pkgToInstall"
		#fi
	done
}
aptUnbloatPkg() {
	declare -a pkgsToRemove
	pkgsToRemove=(sane-utils bluez evolution-data-server-common libbluetooth3 plymouth system-config-printer-common samba-common exim4-base)
	# voir pour inclure gnome-settings-daemon-common gdm3 gnome-software  (apg bolt chrome-gnome-shell gdm3 gir1.2-accountsservice-1.0 gir1.2-gck-1 gir1.2-gcr-3 gir1.2-gdm-1.0 gir1.2-gnomebluetooth-3.0 gir1.2-gnomedesktop-3.0 gir1.2-grilo-0.3 gir1.2-ibus-1.0 gir1.2-mediaart-2.0
	# gir1.2-mutter-11 gir1.2-nma-1.0 gir1.2-rsvg-2.0 gir1.2-totemplparser-1.0 gir1.2-tracker-3.0 gir1.2-upowerglib-1.0 gnome-browser-connector gnome-control-center gnome-control-center-data gnome-music gnome-remote-desktop gnome-session
	# gnome-session-common gnome-settings-daemon gnome-settings-daemon-common gnome-shell gnome-shell-common gnome-shell-extension-prefs gnome-shell-extensions gnome-software gnome-software-common gnome-software-plugin-flatpak gnome-tweaks
	# gstreamer1.0-pipewire ibus ibus-data ibus-gtk ibus-gtk3 ibus-gtk4 im-config libcolord-gtk4-1 libflashrom1 libfreerdp-server2-2 libftdi1-2 libfwupd2 libgcab-1.0-0 libgdm1 libgnome-bg-4-2 libgnome-bluetooth-ui-3.0-13 libgnome-rr-4-2
	# libibus-1.0-5 libjaylink0 libjcat1 libmbim-glib4 libmbim-proxy libmutter-11-0 libnss-myhostname libqmi-glib5 libqmi-proxy libqrtr-glib0 libsmbios-c2 libsnapd-glib-2-1 libtss2-tctildr0 mutter mutter-common pipewire-alsa pipewire-audio
	# power-profiles-daemon python3-ibus-1.0 realmd switcheroo-control

	for pkgsToRemove in "${pkgsToRemove[@]}" #${pkgsToRemove[*]}
	do
		if [ "$(checkDpkgInstalled "$pkgToInstall")" = "true" ]; then
			apt-get -y autoremove "$pkgsToRemove"
		fi
	done
}
main_preInstall() {
	#getDpkgListInstalled
	#checkDpkgInstalled "zip"
	#read -rp ""
	#checkDpkgInstalled "nimporte"
	aptPreinstallPkg
	aptUnbloatPkg
}
main_preInstall