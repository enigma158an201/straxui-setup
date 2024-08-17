#!/usr/bin/env bash

iSshPort=41122
export iSshPort

getNetworkManagement() {
	sNetPlanDst="/etc/netplan/"
	if [ -d "${sNetPlanDst}" ]; then
		for sFile in "${sNetPlanDst}"*; do
			sNetworkRenderer="$(grep -i 'renderer' "${sFile}")"
			echo -e "${sNetworkRenderer##* }\n" #echo "${A##* }"
		done
	fi
	unset sNetPlanDst
}
checkEnabledIpv6() {
	iIp6Disabled="$(cat /sys/module/ipv6/parameters/disable)"
	if [ "${iIp6Disabled}" -eq "0" ]; then			echo "true"
	elif [ "${iIp6Disabled}" -eq "1" ]; then		echo "false"
	fi
}
bIp6Enabled="$(checkEnabledIpv6)"
export bIp6Enabled

getFirstAddressIpRoute() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else 																				exit 1
	fi
	for sWord in $2; do
		if [[ ${sWord} =~ ${sTxt} ]]; then 
			echo "${sWord}"
			break
		fi
	done
}
getFirstAddressIpAddr() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else 																				exit 1
	fi
	for sWord in $2; do
		if [[ ${sWord} =~ ${sTxt}+[0-9a-fA-F] ]]; then 
			echo "${sWord}"
			break
		fi
	done
}
getNetworkAddress() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt='.'; bIp4="true"; bIp6="false"
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=':'; bIp4="false"; bIp6="true"
	else																				exit 1
	fi
	sInputAddress=$2 #sInputAddress="$(echo $2 | tr "${sTxt}" " " )"
	#for sWord in ${sInputAddress}; do
		#if [[ ${sWord} =~ ${sTxt} ]]; then 
			#echo "${sWord}"
			#break
		#fi
	#done
	if (${bIp4}); then 
		sOutputAddress="$(ipcalc -b "${sInputAddress}" | grep -i network: | awk '{ print $2 }')" # sOutputAddress="${sInputAddress%"${sTxt}"*}${sTxt}0"
	elif ${bIp6} && ${bIp6Enabled} && command -v ipv6calc 1>/dev/null; then
		#sUncompressedInputAddress="$(ipv6calc --addr2uncompaddr "${sInputAddress}")"
		#sOutputAddress="${sUncompressedInputAddress%"${sTxt}"*}${sTxt}"
		sOutputAddress="$(ipv6calc --out ipv6addr --printprefix --in ipv6addr "${sInputAddress}" || echo "false")"
	else
		sOutputAddress="false"
	fi
	echo "${sOutputAddress}"
}

getIpAddr4() {
	if command -v  awk 1>/dev/null; then
		if command -v ip 1>/dev/null; then 				ip -4 route get 1.2.3.4 | awk '{print $7}'					# after src string
		elif command -v hostname 1>/dev/null; then 		getFirstAddressIpRoute 4 "$(hostname -I)"							# hostname -I | awk '{ print $1 }'
		fi
	fi
}
getIpAddr6() {
	if command -v awk 1>/dev/null; then
		if command -v ip 1>/dev/null; then 				getFirstAddressIpAddr 6 "$(ip -6 -o addr | grep -v ': lo')" #ip -6 route get 2001:4860:4860::8888 | awk '{print $11}'	# after src string
		elif command -v hostname 1>/dev/null; then 		getFirstAddressIpRoute 6 "$(hostname -I)" 							# hostname -I | awk '{ print ${x} }'
		fi
	fi
}
getWanIpAddr4() {
	dig -4 +short myip.opendns.com @resolver1.opendns.com	#host myip.opendns.com resolver1.opendns.com
}
getGlobalIpAddr6() {
	#with telnet: 	$ telnet -6 ipv6.telnetmyip.com 
	#Even With ssh:	$ ssh -6 sshmyip.com
	#bIp6Enabled="$(checkEnabledIpv6)"		#cat /sys/module/ipv6/parameters/disable
	if (${bIp6Enabled}); then
		if true; then 						dig -t aaaa +short myip.opendns.com @resolver1.opendns.com
		elif command -v awk 1>/dev/null; then 	curl -6 https://ifconfig.co
		fi			
	else 									echo "false"
	fi
}
test() {
	#getNetworkAddress 4 "$(getIpAddr4)"
	#getNetworkAddress 6 "$(getIpAddr6)"
	#apt-get update && apt-get install dig ipcalc ipv6calc
	sPrvIP4="$(getIpAddr4)"
	sPrvNetworkIP4="$(getNetworkAddress 4 "${sPrvIP4}")"
	sPubIP4="$(getWanIpAddr4)"
	sPrvIP6="$(getIpAddr6)"
	sPrvNetworkIP6="$(getNetworkAddress 6 "${sPrvIP6}")"
	sPubIP6="$(getGlobalIpAddr6)"
	if [ ! "${sPrvIP4}" = "false" ]; then		echo -e "${sPrvIP4}"; fi
	if [ ! "${sPrvNetworkIP4}" = "false" ]; then echo -e "${sPrvNetworkIP4}"; fi
	if [ ! "${sPubIP4}" = "false" ]; then 		echo -e "${sPubIP4}"; fi
	if [ ! "${sPrvIP6}" = "false" ]; then 		echo -e "${sPrvIP6}"; fi
	if [ ! "${sPrvNetworkIP6}" = "false" ]; then echo -e "${sPrvNetworkIP6}"; fi
	if [ ! "${sPubIP6}" = "false" ]; then 		echo -e "${sPubIP6}"; fi
}
test