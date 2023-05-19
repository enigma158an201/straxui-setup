comment() {
	local regex="${1:?}"
	local file="${2:?}"
	local comment_mark="${3:-#}"
	if [ -f "$file" ]; then suExecCommand sed -ri "s:^([ ]*)($regex):\\1$comment_mark\\2:" "$file"; fi
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
	if [ -f "$file" ]; then suExecCommand sed -ri "/^([ ]*)($regex)/i $newLine" "$file"; fi		#sed -ri "s:^([ ]*)($regex):\\1$newLine\n\\2:" "$file"
}
insertLineAfter() {
	local regex="${1:?}"
	local newLine="${2:?}"
	local file="${3:?}"
	if [ -f "$file" ]; then suExecCommand sed -ri "/^([ ]*)($regex)/a $newLine" "$file"; fi
}
