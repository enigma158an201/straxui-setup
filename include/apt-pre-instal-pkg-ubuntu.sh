#!/usr/bin/env bash
set -euo pipefail #; set -x

getDpkgListInstalled() {
	#dpkg -l | grep -E '(^|\s+)cron\b'
	dpkgGlobList="$(dpkg -l)"
	prefix="ii"
	dpkgInstalled="${dpkgGlobList[@]//$prefix/}"
	echo "${dpkgInstalled}"
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
	getDpkgListInstalled
	#aptPreinstallPkg
	#aptUnbloatPkg
}
main