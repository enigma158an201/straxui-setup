#!/usr/bin/env bash
set -euo pipefail #; set -x

getDpkgListInstalled() {
	#dpkg -l | grep -E '(^|\s+)cron\b'
	dpkgGlobList="$(dpkg -l | tail -n +6)"
	prefix="ii  "
	dpkgInstalled="${dpkgGlobList[@]//$prefix/}"
	echo "${dpkgInstalled}"
}
checkDpkgInstalled() {
	#dpkg -l | grep -E '(^|\s+)cron\b'
	dpkgInstalledList="$(getDpkgListInstalled)"			# | grep cron
	pkgNamePrefix="$1"
	#sPkgInstalled="${dpkgInstalledList[@]//$pkgNamePrefix/}"
	
	#array=(elem1/a elem1/b elem2/a elem2/b)
	#prefix=elem1
	sPkgInstalled=()
	for element in "${dpkgInstalledList[@]}"; do
		[[ $element == $pkgNamePrefix/* ]] && sPkgInstalled+=("$element")
	done
	echo "${sPkgInstalled}"
}
aptPreinstallPkg() {
	declare -a pkgsToInstall
	pkgsToInstall=(net-tools wget curl tar zip ipv6calc git jq xinit cron)
	apt-get update && apt-get upgrade
	for pkgToInstall in "${pkgsToInstall[@]}" #${pkgsToInstall[*]}
	do
		if true; then
			apt-get -y install "$pkgToInstall"
		fi
	done
}
aptUnbloatPkg() {
	declare -a pkgsToRemove
	pkgsToRemove=(sane-utils )
	apt-get update && apt-get upgrade
	for pkgsToRemove in "${pkgsToRemove[@]}" #${pkgsToRemove[*]}
	do
		if true; then
			apt-get -y autoremove "$pkgsToRemove"
		fi
	done
}
main() {
	#getDpkgListInstalled
	checkDpkgInstalled "zip"
	read -rp ""
	checkDpkgInstalled "znimporte"
	#aptPreinstallPkg
	#aptUnbloatPkg
}
main