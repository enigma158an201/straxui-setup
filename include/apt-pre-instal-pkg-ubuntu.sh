#!/usr/bin/env bash
set -euo pipefail #; set -x

main() {
	declare -a pkgsToInstall
	pkgsToInstall=(net-tools wget curl tar zip ipv6calc git jq xinit)
	apt-get update && apt-get upgrade
	for pkgToInstall in "${pkgsToInstall[@]}" #${pkgsToInstall[*]}
	do
		apt-get -y install "$pkgToInstall"
	done
}

main