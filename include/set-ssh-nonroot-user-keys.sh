#!/usr/bin/env bash

set -euo pipefail #; set -x

launchDir="$(dirname "$0")"
if [ "${launchDir}" = "." ]; then launchDir="$(pwd)"; elif [ "${launchDir}" = "include" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
#source for getting ip addresses
source "${launchDir}/include/get-network-settings.sh"
mySshDir="${HOME}/.ssh/"
myPubAutKeysFile="${mySshDir}authorized_keys"

set_ssh_nonroot_user_keys() {
	if [ ! "${EUID}" = "0" ]; then		
		myPrvIP4="$(getIpAddr4)"
		myPubIP4="$(getWanIpAddr4)"
		
		(mkdir -p "${mySshDir}" && cd "${mySshDir}" || exit 1) || exit 1
		outPrvKeyFilePath="${mySshDir}${HOSTNAME}_${USER}_$(date +%Y%m%d%H%M%S)"
		keysAlreadySet=$(LANG=C find "${mySshDir}" -iwholename "*${HOSTNAME}_${USER}_*" | grep -v ".pub$" || echo "false")
		if [ "${keysAlreadySet}" = "false" ] || [ "${keysAlreadySet}" = "" ]; then	# si pas de clé on crée une paire de clés ed25519
			mySshPrvKeyPath="${outPrvKeyFilePath}"
			mySshPrvKeyName="$(basename "${mySshPrvKeyPath}")"
			#read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
			#if [ ! "${genNewKeyPair^^}" = "N" ] && [ ! "${genNewKeyPair}" = "" ]; then
				ssh-keygen -t ed25519 -f "${mySshPrvKeyPath}" -C "${mySshPrvKeyName}"
			#fi
		else
			read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
			if [ ! "${genNewKeyPair^^}" = "N" ] && [ ! "${genNewKeyPair}" = "" ]; then
				bNewKey="true"
				mySshPrvKeyPath="${outPrvKeyFilePath}"
				mySshPrvKeyName="$(basename "${mySshPrvKeyPath}")"
				ssh-keygen -t ed25519 -f "${mySshPrvKeyPath}" -C "${mySshPrvKeyName}"
			else
				bNewKey="false"
			fi
			echo -e "\t"
			read -rp "change passphrase ${keysAlreadySet} ? o/N"  -n 1 genNewKeyPass
			if [ ! "${genNewKeyPass^^}" = "N" ] && [ ! "${genNewKeyPass}" = "" ]; then
				bNewPass="true"
				for keyAlreadySet in ${keysAlreadySet}; do
					mySshPrvKeyPath="${keyAlreadySet}"
					mySshPrvKeyName="$(basename "${mySshPrvKeyPath}")"
					ssh-keygen -p -t ed25519 -f "${mySshPrvKeyPath}" -C "${mySshPrvKeyName}" # here -p is for change passphrase (doesn't work if file doesn't exist)
				done
			else
				bNewPass="false"
			fi
			if [ "${bNewKey}" = "false" ] && [ "${bNewPass}" = "false" ]; then	mySshPrvKeyPath="${keysAlreadySet}"; fi
			echo -e ""
		fi
		keysAlreadySet=$(LANG=C find "${mySshDir}" -iwholename "*${HOSTNAME}_${USER}_*" | grep -v ".pub$" || echo "false")
		for keyAlreadySet in ${keysAlreadySet}; do
			mySshPrvKeyName="$(basename "${keyAlreadySet}")"	# mySshPrvKeyPath
			mySshPubKeyFilePath="${keyAlreadySet}.pub"		# mySshPrvKeyPath
			#ssh-copy-id -p "${SSH_PORT}" -i "${mySshDir}/${outKeyFileName}.pub" "${USER}@localhost" # for remote key install
			if [ ! -f "${myPubAutKeysFile}" ]; then touch "${myPubAutKeysFile}"; fi
			mySshPubKeyFileContent="$(cat "${mySshPubKeyFilePath}")" # 1>/dev/null)" #		echo "${mySshPubKeyFileContent}"
			if (! grep "${mySshPubKeyFileContent}" "${myPubAutKeysFile}"); then echo -e "\n${mySshPubKeyFileContent}" | tee -a "${myPubAutKeysFile}"; fi
		done
		echo -e "  >>> penser si usage d'alias, à:
		\t >> 1/ copier la clé privée uniquement ~/.ssh/${mySshPrvKeyName} sur le client de connexion distant
		\t >> 2/ changer les permissions de la clé privée ~/.ssh/${mySshPrvKeyName} sur le client de connexion distant
		\t\t > exemples de commandes: $ chown ${USER}:${USER} ~/.ssh/${mySshPrvKeyName}; chmod 0600 ~/.ssh/${mySshPrvKeyName}
		\t >> 3/ optionnel: 
		\t\t >> 3.1/ajouter cette config à votre fichier ~/.ssh/config pour le compte situé sur la machine distante
\tHost ${HOSTNAME}
\t\tHostName ${myPubIP4}   #${myPrvIP4}
\t\tPort \${mySshPort}              #replace by router port if necessary or 22 by default
\t\tUser ${USER}               #user for ssh host|server
\t\tIdentityFile ~/.ssh/${mySshPrvKeyName}
  >>> nota: possibilité de remplacer l'adresse IP ${myPubIP4} par ${myPrvIP4} si pas de connection WAN souhaitée ou par une autre adresse IP4 WAN, c'est-à-dire ne commencant par 
  \t 127.x.y.z	\t ni 10.x.y.z	\t ni 192.168.y.z	\t ni entre 172.16.0.0 et 172.31.255.255 )"
	else
		echo "par sécurité, pas de clé générée pour l'user système root, abandon de la création de clés"
		#exit 1
	fi
}

main_set_ssh_keys() {
	echo -e "\t>>> Ce script va tenter d'effectuer une configuration semi automatique pour cet hote ssh d'une paire de clés en procédant de la facon suivante
	\t>> 1. déterminer les IPv4 (LAN+WAN) et éventuelles IPv6
	\t>> 2. vérifier l'eventuelle présence de clés existantes selon ce schéma de noms de fichiers: ${HOSTNAME}_${USER}_\*
	\t>> 3. Créer une paire de clés ed25519 si pas de clé trouvée
	\t>> 4. proposer l'ajout ou le changement de la passphrase pour la clé trouvée (si pas de création)
	\t>> 5. si besoin, ajouter la clé publique dans le fichier ${myPubAutKeysFile}
	\t>> 6. proposer une configuration d'alias à insérer manuellement sur la/les machine(s) distante(s)"	
 	set_ssh_nonroot_user_keys
}
main_set_ssh_keys	