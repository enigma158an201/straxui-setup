#!/usr/bin/env bash

set -euo pipefail #; set -x

sLaunchDir="$(dirname "$0")"
if [[ "${sLaunchDir}" = "." ]]; then sLaunchDir="$(pwd)"; elif [[ "${sLaunchDir}" = "include" ]]; then eval sLaunchDir="$(pwd)"; fi; sLaunchDir="${sLaunchDir//include/}"
#source for getting ip addresses
source "${sLaunchDir}/include/get-network-settings.sh"
sSshDir="${HOME}/.ssh/"
sPubAutKeysFile="${sSshDir}authorized_keys"

set_ssh_nonroot_user_keys() {
	if [[ ! "${EUID}" = "0" ]]; then		
		sPrvIP4="$(getIpAddr4)"
		sPubIP4="$(getWanIpAddr4)"
		
		(mkdir -p "${sSshDir}" && cd "${sSshDir}" || exit 1) || exit 1
		sOutPrvKeyFilePath="${sSshDir}${HOSTNAME}_${USER}_$(date +%Y%m%d%H%M%S)"
		sKeysAlreadySet=$(LANG=C find "${sSshDir}" -iwholename "*${HOSTNAME}_${USER}_*" | grep -v ".pub$" || echo "false")
		if [[ "${sKeysAlreadySet}" = "false" ]] || [[ "${sKeysAlreadySet}" = "" ]]; then	# si pas de clé on crée une paire de clés ed25519
			sSshPrvKeyPath="${sOutPrvKeyFilePath}"
			sSshPrvKeyName="$(basename "${sSshPrvKeyPath}")"
			#read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
			#if [[ ! "${genNewKeyPair^^}" = "N" ]] && [[ ! "${genNewKeyPair}" = "" ]]; then
				ssh-keygen -t ed25519 -f "${sSshPrvKeyPath}" -C "${sSshPrvKeyName}"
			#fi
		else
			read -rp "Générer une nouvelle paire de clés ssh (type ed25519)? o/N"  -n 1 genNewKeyPair
			if [[ ! "${genNewKeyPair^^}" = "N" ]] && [[ ! "${genNewKeyPair}" = "" ]]; then
				bNewKey="true"
				sSshPrvKeyPath="${sOutPrvKeyFilePath}"
				sSshPrvKeyName="$(basename "${sSshPrvKeyPath}")"
				ssh-keygen -t ed25519 -f "${sSshPrvKeyPath}" -C "${sSshPrvKeyName}"
			else
				bNewKey="false"
			fi
			echo -e "\t"
			read -rp "change passphrase ${sKeysAlreadySet} ? o/N"  -n 1 genNewKeyPass
			if [[ ! "${genNewKeyPass^^}" = "N" ]] && [[ ! "${genNewKeyPass}" = "" ]]; then
				bNewPass="true"
				for keyAlreadySet in ${sKeysAlreadySet}; do
					sSshPrvKeyPath="${keyAlreadySet}"
					sSshPrvKeyName="$(basename "${sSshPrvKeyPath}")"
					ssh-keygen -p -t ed25519 -f "${sSshPrvKeyPath}" -C "${sSshPrvKeyName}" # here -p is for change passphrase (doesn't work if file doesn't exist)
				done
			else
				bNewPass="false"
			fi
			if [[ "${bNewKey}" = "false" ]] && [[ "${bNewPass}" = "false" ]]; then	sSshPrvKeyPath="${sKeysAlreadySet}"; fi
			echo -e ""
		fi
		sKeysAlreadySet=$(LANG=C find "${sSshDir}" -iwholename "*${HOSTNAME}_${USER}_*" | grep -v ".pub$" || echo "false")
		for keyAlreadySet in ${sKeysAlreadySet}; do
			sSshPrvKeyName="$(basename "${keyAlreadySet}")"	# sSshPrvKeyPath
			sSshPubKeyFilePath="${keyAlreadySet}.pub"		# sSshPrvKeyPath
			#ssh-copy-id -p "${SSH_PORT}" -i "${sSshDir}/${outKeyFileName}.pub" "${USER}@localhost" # for remote key install
			if [[ ! -f "${sPubAutKeysFile}" ]]; then touch "${sPubAutKeysFile}"; fi
			sSshPubKeyFileContent="$(cat "${sSshPubKeyFilePath}")" # 1>/dev/null)" #		echo "${sSshPubKeyFileContent}"
			if (! grep "${sSshPubKeyFileContent}" "${sPubAutKeysFile}"); then echo -e "\n${sSshPubKeyFileContent}" | tee -a "${sPubAutKeysFile}"; fi
		done
		echo -e "  >>> penser si usage d'alias, à:
		\t >> 1/ copier la clé privée uniquement ~/.ssh/${sSshPrvKeyName} sur le client de connexion distant
		\t >> 2/ changer les permissions de la clé privée ~/.ssh/${sSshPrvKeyName} sur le client de connexion distant
		\t\t > exemples de commandes: $ chown ${USER}:${USER} ~/.ssh/${sSshPrvKeyName}; chmod 0600 ~/.ssh/${sSshPrvKeyName}
		\t >> 3/ optionnel: 
		\t\t >> 3.1/ajouter cette config à votre fichier ~/.ssh/config pour le compte situé sur la machine distante
\tHost ${HOSTNAME}
\t\tHostName ${sPubIP4}   #${sPrvIP4}
\t\tPort \${sSshPort}              #replace by router port if necessary or 22 by default
\t\tUser ${USER}               #user for ssh host|server
\t\tIdentityFile ~/.ssh/${sSshPrvKeyName}
  >>> nota: possibilité de remplacer l'adresse IP ${sPubIP4} par ${sPrvIP4} si pas de connection WAN souhaitée ou par une autre adresse IP4 WAN, c'est-à-dire ne commencant par 
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
	\t>> 5. si besoin, ajouter la clé publique dans le fichier ${sPubAutKeysFile}
	\t>> 6. proposer une configuration d'alias à insérer manuellement sur la/les machine(s) distante(s)"	
 	set_ssh_nonroot_user_keys
}
main_set_ssh_keys	