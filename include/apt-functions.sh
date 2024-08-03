#!/usr/bin/env bash
set -euo pipefail #; set -x

getDpkgListInstalled() {
	#dpkg -l | grep -E '(^|\s+)cron\b'
	#declare -a dpkgInstalled
	dpkgGlobList="$(dpkg -l | tail -n +6 | awk '{ print $2 }')"
	prefix="ii  " # to do: check if other prefix can return installed software (ie: for update purpose)
	dpkgInstalled="${dpkgGlobList[*]//${prefix}/}"
	echo "${dpkgInstalled[*]}"
}
checkDpkgInstalledTests() {
	#dpkg -l | grep -E '(^|\s+)cron\b'
	#dpkgInstalledList="$(getDpkgListInstalled)"			# | grep cron
	#pkgNamePrefix="$1"
	#sPkgInstalled="${dpkgInstalledList[@]//${pkgNamePrefix}/}"
	
	#array=(elem1/a elem1/b elem2/a elem2/b)
	#prefix=elem1
	#sPkgInstalled=()
	#for element in ${dpkgInstalledList[@]}; do
		#[[ ${element} == ${pkgNamePrefix}/* ]] && sPkgInstalled+=("${element}")
		#echo "${element} ";read -rp " "
		#[[ ${element} == ${pkgNamePrefix} ]] && sPkgInstalled+=("${element}")
	#done
	#if [ -z "${sPkgInstalled[@]}" ]; then echo "false"; exit 1; else echo "true"; exit 0; fi
	#unset sPkgInstalled
	package_name=pkg-to-test
	if dpkg -l | grep -q -w "${package_name}"; then
		echo "Le paquet ${package_name} est installé."
	elif apt list --installed 2>/dev/null | grep -q -w "${package_name}"; then
		echo "Le paquet ${package_name} est installé."
	elif apt-get list --installed 2>/dev/null | grep -q -w "${package_name}"; then
		echo "Le paquet ${package_name} est installé."
	else
		echo "Le paquet ${package_name} n'est pas installé."
	fi
}
checkDpkgInstalled() {
	pkgname="$1"
	#noPackageFoundString="no packages found matching"
	#result="$(dpkg-query --show "${pkgname}" && echo "true") || echo "false")"
	#result="$(LANG=C /usr/bin/dpkg-query --show --showformat='\${db:Status-Status}\n' "${pkgname}")"
	#if [[ ${result} =~ \${not-installed} ]] || [[ ${result} =~ ${noPackageFoundString} ]]; then echo "false"; else echo "true"; fi 
	installedString="[installed]"
	result="$(LANG=C /usr/bin/apt search --names-only ^"${pkgname}"$ | grep -Ew "${pkgname}|${installedString}")" # apt-get search not valid
	if [[ ${result} =~ ${installedString} ]]; then echo "true"; else echo "false"; fi 
}
