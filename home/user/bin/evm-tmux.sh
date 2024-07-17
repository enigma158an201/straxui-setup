#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

# to allow aliases in script as in `bash -i`

sTmuxSession="sky41"
sTmuxWindow="evm"

if shopt -q expand_aliases; then
    echo "Aliases are already enabled in this script."
else
    echo "Aliases are not enabled in this script, try to enable aliases."
	shopt -s expand_aliases || exit 1
	source "$HOME/.bashrc"
fi
if ! command -v detach; then alias detach='tmux detach'; fi
#if ! command -v attach; then alias attach="tmux -a -t $sTmuxWindow"; fi # does not work

startMainnetTmux() {
	if ! command -v tmux 1>/dev/null 2>&1; then 
		echo -e "\t>>> tmux not found, please install tmux, aborting"; exit 1; 
	else

		# Check if the tmux session "${sTmuxSession}" exists, # If it doesn't exist, create a new session named "${sTmuxSession}"
		if ! tmux has-session -t "${sTmuxSession}" 2>/dev/null; then			
			tmux new-session -s "${sTmuxSession}" -d -x "$(tput cols)" -y "$(tput lines)"
		fi
		
		if ! tmux list-windows -t "${sTmuxSession}" | grep "${sTmuxWindow}"; then
			# Create a window named ""${sTmuxWindow}"" if not exists in the "${sTmuxSession}" session
			tmux new-window -t "${sTmuxSession}": -n "${sTmuxWindow}" #-P 'p1'
		fi

		tmux set-option -g mouse on		#deprecated: tmux set-option -g mouse-select-pane on

		# Split the window into four panes: two panes on the left and two (one higher) on the right
		if [ "$(tmux list-panes | wc -l)" -eq "1" ] ; then
			tmux select-pane -t 0
			tmux split-window -h -t "${sTmuxSession}"
			tmux select-pane -t 0 #-P 'p1'
			tmux split-window -v -t "${sTmuxSession}" #-n 'p2'
			tmux select-pane -t 2 #-n 'p3'
			tmux split-window -v -l 3 #-p 90 #-t "${sTmuxSession}"

			# Execute specific commands in each pane: 0 1 2 are names of panes
			tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.0" 'tt' C-m
			tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.1" "watch -n 1 ps aux" C-m
			tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.2" "watch -n 1 netstat -tuln" C-m #validator
		fi
		# alway echo this line at right bottom
		tmux send-keys -t "${sTmuxSession}:${sTmuxWindow}.3" "echo -e 'press ctrl+b then d or enter \`detach\` to hide\n or enter \`tmux kill-session -t evm\` to kill'" C-m
		tmux attach-session -t "${sTmuxSession}"	#tmux attach-session -t "${sTmuxSession}" -c "${sTmuxWindow}"	# Attach to the "${sTmuxSession}" session
	fi
}
upgradeBinTmuxEvmScript() {
	if command -v evm-tmux.sh 1>/dev/null 2>&1; then
		sTmuxEvmPath=$(command -v evm-tmux.sh) #
		echo "${sTmuxEvmPath}"
	fi
	if true; then
		mkdir -p "$HOME/bin"
		#if ! test -z "${sTmuxEvmPath:-}"; then 
			LANG=C find "$HOME" -iwholename '*/straxui-setup/*evm-tmux.sh' -exec install --mode=0755 --compare --target-directory="$HOME/bin" {} \; 2>/dev/null || true
		#else
			#find "$HOME" -iwholename '*/straxui-setup/*evm-tmux.sh' -exec install --mode=0755 --preserve-timestamps --target-directory="$HOME/bin" {} \;
		#fi
	fi
}
main_evm() {
	upgradeBinTmuxEvmScript # 1st find git source, and locally installed script, then upgrade if necessary
	startMainnetTmux 		# then start new script
}
main_evm