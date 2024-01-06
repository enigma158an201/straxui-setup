#!/usr/bin/env bash

# https://linuxize.com/post/how-to-upgrade-debian-10-to-debian-11/
# deb http://deb.debian.org/debian bullseye main
# deb-src http://deb.debian.org/debian bullseye main
# deb http://security.debian.org/debian-security bullseye-security main
# deb-src http://security.debian.org/debian-security bullseye-security main
# deb http://deb.debian.org/debian bullseye-updates main
# deb-src http://deb.debian.org/debian bullseye-updates main

if [ "$launchDir" = "." ] || [ "$launchDir" = "include" ] || [ "$launchDir" = "" ]; then eval launchDir="$(pwd)"; fi; launchDir="${launchDir//include/}"
source "${launchDir}/include/test-superuser-privileges.sh"

aptSourcesListFile=/etc/apt/sources.list
aptSourcesListSubfolder=${aptSourcesListFile}.d

getDebianVersion() {
    myDebMainVersion="$(cat /etc/debian_version)"
    echo ${myDebMainVersion%%.*}
}

upgradeJessieToStretch() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv sed -i 's/jessie/stretch/g' ${aptSourcesListFile}{,.d/*.list}
        #suExecCommandNoPreserveEnv sed -i 's#/debian-security stretch/updates# stretch-security#g' ${aptSourcesListFile}
    #fi
}

upgradeStretchToBuster() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv sed -i 's/stretch/buster/g' ${aptSourcesListFile}{,.d/*.list}
        #suExecCommandNoPreserveEnv sed -i 's#/debian-security buster/updates# buster-security#g' ${aptSourcesListFile} 
    #fi
}

upgradeBusterToBullseye() {
    #if command -v sudo 1>/dev/null 2>&1; then
        # suExecCommandNoPreserveEnv sed -i 's/buster/bullseye/g' ${aptSourcesListFile}
        # suExecCommandNoPreserveEnv sed -i 's/buster/bullseye/g' ${aptSourcesListFile}.d/*.list
        suExecCommandNoPreserveEnv sed -i 's/buster/bullseye/g' ${aptSourcesListFile}{,.d/*.list}
        suExecCommandNoPreserveEnv sed -i 's#/debian-security bullseye/updates# bullseye-security#g' ${aptSourcesListFile}
    #fi
}

upgradeBullseyeToBookworm() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv sed -i 's/bullseye/bookworm/g' ${aptSourcesListFile}
        suExecCommandNoPreserveEnv sed -i 's/non-free/non-free non-free-firmware/g' ${aptSourcesListFile}
    #fi
}

upgradeBookwormToTrixie() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv sed -i 's/bookworm/trixie/g' ${aptSourcesListFile}
        #suExecCommandNoPreserveEnv sed -i 's/non-free/non-free non-free-firmware/g' ${aptSourcesListFile}
    #fi
}

upgradeToSid() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv sed -i 's/bookworm/sid/g' ${aptSourcesListFile}
        #suExecCommandNoPreserveEnv sed -i 's/non-free/non-free non-free-firmware/g' ${aptSourcesListFile}
    #fi
}

upgradeSourcesList() {
    if [ -r /etc/debian_version ]; then
        debInstalledVersion=$(getDebianVersion)
        if [ "$debInstalledVersion" = "8" ]; then
            upgradeJessieToStretch
        elif [ "$debInstalledVersion" = "9" ]; then
            upgradeStretchToBuster
        elif [ "$debInstalledVersion" = "10" ]; then
            upgradeBusterToBullseye
        elif [ "$debInstalledVersion" = "11" ]; then
            upgradeBullseyeToBookworm
        # elif [ "$debInstalledVersion" = "12" ]; then
            # exit 1 #upgradeBookwormToTrixie
        else
            echo "No stable Release for upgrading to debian $((debInstalledVersion + 1))"
        fi
    else
        echo -e "\\tFile /etc/debian_version doesn't exists"
        exit 1
    fi
}

upgradeDebianDist() {
    #if command -v sudo 1>/dev/null 2>&1; then
        suExecCommandNoPreserveEnv apt-get update && suExecCommandNoPreserveEnv apt-get upgrade && suExecCommandNoPreserveEnv apt-get full-upgrade && suExecCommandNoPreserveEnv apt-get dist-upgrade 
    #fi
}

main() {
    upgradeSourcesList
    upgradeDebianDist
}
main