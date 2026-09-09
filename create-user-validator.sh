#!/usr/bin/env bash

# script by enigma158an201
#set -euo pipefail # set -euxo pipefail

mainCreateValidator() {
    sUser=deposit-validator
    sudo useradd -m -s /bin/bash "${sUser}"
    sudo passwd -l "${sUser}"
    sudo usermod -aG "${sUser}"
    #su "${sUser}"
}
mainCreateValidator
