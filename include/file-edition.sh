#!/usr/bin/env bash

set -euo pipefail #; set -x
launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

comment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	local sCommand="sed -ri \"s:^([ ]*)($regex):\\1$comment_mark\\2:\" $file"
	if [ -f "$file" ]; then suExecCommand "$sCommand"; fi
}
uncomment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	local sCommand="sed -ri s:^([ ]*)[$comment_mark]+[ ]?([ ]*$regex):\\1\\2: $file"
	if [ -f "$file" ]; then echo "$sCommand"; fi #suExecCommand "$sCommand"; fi
}
appendLineAtEnd() {
	local newLine="${1:?}"
	local file="${2:?}"
	if [ -f "$file" ]; then echo -e "$newLine" | suExecCommand tee -a "$file"; fi
}
insertLineBefore() {
	local regex="${1:?}"
	local newLine="${2:?}"
	local file="${3:?}"
	local sCommand="sed -ri \"/^([ ]*)($regex)/i $newLine\" $file"
	if [ -f "$file" ]; then suExecCommand "$sCommand"; fi		#sed -ri "s:^([ ]*)($regex):\\1$newLine\n\\2:" "$file"
}
insertLineAfter() {
	local regex="${1:?}"
	local newLine="${2:?}"
	local file="${3:?}"
	local sCommand="sed -ri \"/^([ ]*)($regex)/a $newLine\" $file"
	if [ -f "$file" ]; then suExecCommand ; fi
}
setParameterInFile() {
	# 2 cas de figures: 1/ le parametre est present et il faut le remplacer 2/ le parametre n'est pas présent, il sera ajouté à la fin
	local inputfile="$1"
	local findText="$2"
	local setnewparam="$3"

	for s in "|" "#" "/" ":" ";" "~"; do 
		if [ "$(grep "$s" <<< "$findText")" = "" ]; then 		separateursed="$"; break; fi
	done
	if [ "$(grep -i "$setnewparam" "$inputfile")" = "" ]; then	isAlreadySet="false"
	else														isAlreadySet="true"
	fi
	if [ "$isAlreadySet" = "false" ]; then
		if [ "$(grep -i "$findText" "$inputfile")" = "" ]; then	ispresent="false"
		else													ispresent="true"
		fi
		if [ "$ispresent" = "true" ]; then						cmdarg="s$separateursed.*$findText.*$separateursed$setnewparam$separateursed""g";	
																suExecCommand "sed -Ei_old \"$cmdarg\" \"$inputfile\"" # 'g' "$inputfile" # | tee "$inputfile" -
		else													suExecCommand "echo \"$setnewparam\" | tee -a \"$inputfile\" -" #echo "$setnewparam" | $sPfxSu tee -a "$inputfile" -
		fi
	fi
}
addCronJob() {
    if true; then
        echo "" > /etc/cron.hourly/
    fi
}