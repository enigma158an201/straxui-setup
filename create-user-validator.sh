#!/usr/bin/env bash

# script by enigma158an201
set -euo pipefail # set -euxo pipefail

createValidator() {
    myUser=deposit-validator
    sudo useradd -m -s /bin/bash "${myUser}"
    passwd -l "${myUser}"
    sudo usermod -aG "${myUser}"
    su "${myUser}"
}

main(){
    createValidator
}
main