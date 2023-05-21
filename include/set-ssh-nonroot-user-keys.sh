#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "$launchDir" = "." ]; then launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source for getting ip addresses
source "${launchDir}/include/get-network-settings.sh"


set-ssh-nonroot-user-keys() {
	if [ ! "$EUID" = "0" ]; then
		read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
		if [ ! "${genNewKeyPair^^}" = "N" ] && [ ! "$genNewKeyPair" = "" ]; then
			myPrvIP4="$(getIpAddr4)"
			myPubIP4="$(getWanIpAddr4)"
			myShhDir="$HOME/.ssh/"
			myPubAutKeysFile=""$myShhDir/authorized_keys""
			(mkdir -p "$myShhDir" && cd "$myShhDir" || exit 1) || exit 1
			outPrvKeyFileName="${myShhDir}${HOSTNAME}_${USER}_$(date +%Y%m%d%H%M%S)"
			ssh-keygen -p -t ed25519 -f "$outPrvKeyFileName" -C "myGithubKey" # here -p is for change passphrase
			outPubKeyFileName="${outPrvKeyFileName}.pub"
			#ssh-copy-id -p "$SSH_PORT" -i "$myShhDir/$outKeyFileName.pub" "$USER@localhost" # for remote key install
			if [ ! -f "$myPubAutKeysFile" ]; then touch "$myPubAutKeysFile"; fi
			outPubKeyFileContent="$(cat "$outPubKeyFileName")"
			if (! grep "$outPubKeyFileContent" "$myPubAutKeysFile"); then echo -e "\n$outPubKeyFileContent" | tee -a "$myPubAutKeysFile"; fi
			echo -e "  >>> penser si usage d'alias, à: \n\t>> 1/ copier la clé privée sur le client de connexion \n\t>> 2/ optionnel ajouter cette config \n \
Host $HOSTNAME
HostName $myPubIP4
Port $mySshPort
User $USER
IdentityFile ~/.ssh/ponchonbox.lan-server.key
  >>> possibilité de remplacer l'adresse IP $myPubIP4 par $myPrvIP4 si pas de connection WAN souhaitée ou par une autre adresse IP4 WAN, c'est-à-dire ne commencant par 
  /t 127.x.y.z 
  /t ni 10.x.y.z
  /t 192.168.y.z
  /t ni entre 172.16.0.0 et 172.31.255.255 )"
		fi
	else
		echo "par sécurité, pas de clé générée pour l'user système root, abandon de la création de clés"
		exit 1
	fi
}

main_set_ssh_keys() {
    set-ssh-nonroot-user-keys
}