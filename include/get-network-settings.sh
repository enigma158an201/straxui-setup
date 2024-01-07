#!/usr/bin/env bash

mySshPort="41122"
export mySshPort

getNetworkManagement() {
	mynetplandst="/etc/netplan/"
	if [ -d "$mynetplandst" ]; then
		for myfile in "$mynetplandst"*; do
			myNetworkRenderer="$(grep -i 'renderer' "$myfile")"
			echo -e "${myNetworkRenderer##* }\n" #echo "${A##* }"
		done
	fi
	unset mynetplandst
}
checkEnabledIpv6() {
	ip6Disabled="$(cat /sys/module/ipv6/parameters/disable)"
	if [ "$ip6Disabled" -eq "0" ]; then			echo "true"
	elif [ "$ip6Disabled" -eq "1" ]; then		echo "false"
	fi
}
ip6Enabled="$(checkEnabledIpv6)"
export ip6Enabled

getFirstAddressIpRoute() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else																				exit 1
	fi
	for myWord in $2; do
		if [[ $myWord =~ $sTxt ]]; then 
			echo "$myWord"
			break
		fi
	done
}
getFirstAddressIpAddr() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt="."
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=":"
	else																				exit 1
	fi
	for myWord in $2; do
		if [[ $myWord =~ $sTxt+[0-9a-fA-F] ]]; then 
			echo "$myWord"
			break
		fi
	done
}
getNetworkAddress() {
	if [ "$1" = "4" ] || [ "$1" = "-4" ] || [ "$1" = "v4" ] || [ "$1" = "-v4" ]; then	sTxt='.'; bIp4="true"; bIp6="false"
	elif [ "$1" = "6" ] || [ "$1" = "-6" ] || [ "$1" = "v6" ] || [ "$1" = "-v6" ]; then sTxt=':'; bIp4="false"; bIp6="true"
	else																				exit 1
	fi
	myInputAddress=$2 #myInputAddress="$(echo $2 | tr "$sTxt" " " )"
	#for myWord in $myInputAddress; do
		#if [[ $myWord =~ $sTxt ]]; then 
			#echo "$myWord"
			#break
		#fi
	#done
	if ($bIp4); then 
		myOutputAddress="$(ipcalc -b "$myInputAddress" | grep -i network: | awk '{ print $2 }')" # myOutputAddress="${myInputAddress%"$sTxt"*}${sTxt}0"
	elif ($bIp6) && ($ip6Enabled) && (which ipv6calc 1>/dev/null); then
		#myUncompressedInputAddress="$(ipv6calc --addr2uncompaddr "$myInputAddress")"
		#myOutputAddress="${myUncompressedInputAddress%"$sTxt"*}${sTxt}"
		myOutputAddress="$(ipv6calc --out ipv6addr --printprefix --in ipv6addr "$myInputAddress" || echo "false")"
	else
		myOutputAddress="false"
	fi
	echo "$myOutputAddress"
}

getIpAddr4() {
	if (which awk 1>/dev/null); then
		if (which ip 1>/dev/null); then				ip -4 route get 1.2.3.4 | awk '{print $7}'					# after src string
		elif (which hostname 1>/dev/null); then		getFirstAddressIpRoute 4 "$(hostname -I)"							# hostname -I | awk '{ print $1 }'
		fi
	fi
}
getIpAddr6() {
	if (which awk 1>/dev/null); then
		if (which ip 1>/dev/null); then				getFirstAddressIpAddr 6 "$(ip -6 -o addr | grep -v ': lo')" #ip -6 route get 2001:4860:4860::8888 | awk '{print $11}'	# after src string
		elif (which hostname 1>/dev/null); then		getFirstAddressIpRoute 6 "$(hostname -I)" 							# hostname -I | awk '{ print $x }'
		fi
	fi
}
getWanIpAddr4() {
	#host myip.opendns.com resolver1.opendns.com
	dig -4 +short myip.opendns.com @resolver1.opendns.com
}
getGlobalIpAddr6() {
	#with telnet: 	$ telnet -6 ipv6.telnetmyip.com 
	#Even With ssh:	$ ssh -6 sshmyip.com
	#ip6Enabled="$(checkEnabledIpv6)"		#cat /sys/module/ipv6/parameters/disable
	if ($ip6Enabled); then
		if (true); then						dig -t aaaa +short myip.opendns.com @resolver1.opendns.com
		elif (which awk 1>/dev/null); then 	curl -6 https://ifconfig.co
		fi			
	else									echo "false"
	fi
}
test() {
	#getNetworkAddress 4 "$(getIpAddr4)"
	#getNetworkAddress 6 "$(getIpAddr6)"
	#apt-get update && apt-get install dig ipcalc ipv6calc
	myPrvIP4="$(getIpAddr4)"
	myPrvNetworkIP4="$(getNetworkAddress 4 "$myPrvIP4")"
	myPubIP4="$(getWanIpAddr4)"
	myPrvIP6="$(getIpAddr6)"
	myPrvNetworkIP6="$(getNetworkAddress 6 "$myPrvIP6")"
	myPubIP6="$(getGlobalIpAddr6)"
	if [ ! "$myPrvIP4" = "false" ]; then		echo -e "$myPrvIP4"; fi
	if [ ! "$myPrvNetworkIP4" = "false" ]; then echo -e "$myPrvNetworkIP4"; fi
	if [ ! "$myPubIP4" = "false" ]; then 		echo -e "$myPubIP4"; fi
	if [ ! "$myPrvIP6" = "false" ]; then 		echo -e "$myPrvIP6"; fi
	if [ ! "$myPrvNetworkIP6" = "false" ]; then echo -e "$myPrvNetworkIP6"; fi
	if [ ! "$myPubIP6" = "false" ]; then 		echo -e "$myPubIP6"; fi
}
test