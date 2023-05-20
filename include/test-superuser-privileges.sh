#!/usr/bin/env bash

set -euo pipefail # -x
declare cmdParameters
cmdParameters="$*"
declare bSudoGroup
declare bSudoersUser
declare bDoasUser

checkUserSudoOrWheelGroup() {
    #set +x #myUser=$USER
	myUserGroups="$(groups "$USER")" 		# la commande id pourrait etre une alternative
	myUserGroups="${myUserGroups##*: }"		#myUserGroups="${`groups $USER`##*: }"
	bSudoGroup="false"
	for sGr in sudo wheel; do
		for myGr in $myUserGroups; do
			if [ "$sGr" = "$myGr" ]; then bSudoGroup="true"; break; fi
		done
		if [ "$bSudoGroup" = "true" ]; then break; fi
	done
	echo "$bSudoGroup"
}

checkSudoers() {
	#set +x #if false; then sudo -l -U $USER; fi
	#if false; then
		#printf "mypassword\n" | sudo -S /bin/chmod --help >/dev/null 2>&1
		#if [ $? -eq 0 ];then
			#has_sudo_access="YES"
		#else
			#has_sudo_access="NO"
		#fi

		#echo "Does user `id -Gn` has sudo access?: $has_sudo_access"
	#fi
	#if false; then
		#`timeout -k 2 2 bash -c "sudo /bin/chmod --help" >&/dev/null 2>&1` >/dev/null 2>&1
		#if [ $? -eq 0 ];then
		#   has_sudo_access="YES"
		#else
		#   has_sudo_access="NO"
		#fi

		#echo "Does user `id -Gn` has sudo access?: $has_sudo_access"
	#fi
	#if false; then sudo --validate; fi
	#if false; then sudo -n true; fi #sudo -l $USER -n true
	#is_user_sudo=$(sudo -v) # if is empty sudo can be used otherwise not
	#SUDO_ASKPASS=/bin/false sudo -A whoami 2>&1
	#getent group | grep -E 'wheel|sudo'
	#echo "a coder" #true
	is_user_sudo="$(LANG=C sudo -v -A 2>&1)" #is_user_sudo=$(LANG=C sudo -v -A || echo "false") # if is sudo error no SUDO_ASKPASS otherwise not
	keyWord="try setting SUDO_ASKPASS"
	if [[ $is_user_sudo =~ $keyWord ]] || [ "$is_user_sudo" = "" ]; then
		bSudoers="true"
	else bSudoers="false"
	fi
	echo "$bSudoers"
} 
checkDoasUser() {		#set +x
	is_user_doas="$(LANG=C timeout -v 1 doas true 2>&1)" #echo "test doas valid user" 
	keyWord="doas: Operation not permitted"
	if [[ ! $is_user_doas =~ $keyWord ]]; then	bDoasUser="true"
	else 										bDoasUser="false"; fi
	echo "$bDoasUser"
}
getSuCmd() {			#set +x
	if [ ! "$sudoPath" = "false" ] && { [ ! "$bSudoGroup" = "false" ] || [ ! "$bSudoersUser" = "false" ] ; }; then	suCmd="$sudoPath" #"/usr/bin/sudo"
	elif [ ! "$doasPath" = "false" ] && [ -f /etc/doas.conf ] && [ ! "$bSudoGroup" = "false" ]; then				suCmd="$doasPath" #"/usr/bin/doas"
	else																											suCmd="su -p -c"; fi #"su - -p -c"
	echo "$suCmd"
}
getSuCmdNoPreserveEnv() {			#set +x
	if [ ! "$sudoPath" = "false" ] && { [ ! "$bSudoGroup" = "false" ] || [ ! "$bSudoersUser" = "false" ] ; }; then	suCmd="$sudoPath" #"/usr/bin/sudo"
	elif [ ! "$doasPath" = "false" ] && [ -f /etc/doas.conf ] && [ ! "$bSudoGroup" = "false" ]; then				suCmd="$doasPath" #"/usr/bin/doas"
	else																											suCmd="su - -c"; fi #"su - -p -c"
	echo "$suCmd"
}

getSuQuotes() {
	#if [ -x /usr/bin/sudo ]; then	 			mySuQuotes=(false)
	#elif [ -x /usr/bin/doas ]; then	 		mySuQuotes=(false)
	#else										mySuQuotes=('"')
	#fi
	if [ ! "$sudoPath" = "false" ] || [ ! "$doasPath" = "false" ]; then				
		if [ ! "$bSudoGroup" = "false" ] || [ ! "$bSudoersUser" = "false" ] || [ ! "$bDoasUser" = "false" ]; then	
												mySuQuotes="false"
		else									mySuQuotes=('"')
		fi
	else										mySuQuotes=('"')
	fi
	echo "${mySuQuotes[@]}"
}
# shellcheck disable=SC2086
suExecCommand() {
	sCommand="$*"
	if [ ! "$suQuotes" = "false" ]; then	$sPfxSu "${sCommand}"
	else									$sPfxSu $sCommand #$sPfxSu $(echo $sCommand) 	#echo "$sCommand" | xargs bash -c $sPfxSu  #$sPfxSu "$(xargs "$sCommand")" 		#$sPfxSu "${sCommand}"
	fi
}
suExecCommandNoPreserveEnv() {
	sCommand="$*"
	if [ ! "$suQuotes" = "false" ]; then	$sPfxSuNoEnv "${sCommand}"
	else									$sPfxSuNoEnv $sCommand
	fi
}

main(){
	sudoPath="$(which sudo || echo "false")"
	doasPath="$(which doas || echo "false")"
	bSudoGroup="$(checkUserSudoOrWheelGroup)"
	bSudoersUser="$(checkSudoers)"
	if [ ! "$doasPath" = "false" ]; then bDoasUser="$(checkDoasUser)"; else bDoasUser="false"; fi
	suQuotes="$(getSuQuotes)"
	if ! sPfxSu="$(getSuCmd) "; then 		exit 01; fi
	if ! sPfxSuNoEnv="$(getSuCmdNoPreserveEnv) "; then 		exit 01; fi
	#tests
	#[ -x /usr/bin/apt ] && suExecCommand "apt-get upgrade" #install vim" #"cat /etc/sudoers"
	#[ -x /usr/bin/zypper ] && suExecCommand "zypper update" #install doas"
	if [ -n "$cmdParameters" ]; then suExecCommand "${cmdParameters}"; fi
}

main