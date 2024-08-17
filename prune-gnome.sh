#!/usr/bin/env bash

sExceptions="^xf|^desktop-base|^libexo|^libglib|libgtop|libsoup|libstartup|^libxml|^shared-mime|^adwaita|^libcups|^network-manager|^policy|^polkit|^at-spi"
installedString="[installed]"

pruneDebianDefaultSoftware() {
  sPkgListFile=include/debian-software-debloat.txt
  if test -f $sPkgListFile; then
    #shellcheck disable=SC2013
    for sPkg in $(grep -v ^# $sPkgListFile); do 
      echo -e "\t$sPkg"; sudo apt autoremove "${sPkg}"
    done
  fi
}

pruneObsoletePkg() {
  sPkgObsolete="$(apt-get list ~o)"
  if [ -n "${sPkgObsolete}" ]; then
    echo -e "\t>>> the Following packages are not in your apt repositories, proceed to autoremove ?"
    read -rp "y/N" -n 1 sAutoremovePkg
    if [ "${sAutoremovePkg^^}" = "Y" ]; then apt-get autoremove --purge ~o; fi
  fi
}
pruneUndeletedConf() {
  sPkgUndeleted="$(apt-get list ~c)"
  if [ -n "${sPkgUndeleted}" ]; then
    echo -e "\t>>> the Following packages were not completely removed, proceed to autoremove remaining configs ?"
    read -rp "y/N" -n 1 sAutoremovePkg
    if [ "${sAutoremovePkg^^}" = "Y" ]; then apt-get autoremove --purge ~c; fi
  fi
}

pruneDpkg() {
  for pkg3 in gnome libreoff cups plymouth hitori quadrapassel sane scan transmission tumbler lynx wpasupplicant bluez
  do
    for pkg1 in $(dpkg -l | grep ^ii | awk '{ print $2 }' | grep "${pkg3}" | grep -vE "${sExceptions}")
    do
      echo -e "\t>>> suppression de ${pkg1}"
      apt-get autoremove "${pkg1}"
    done
  done
}
pruneAptSearch() {
  for pkg2 in $(LANG=C apt search gnome | grep "${installedString}" | grep -v "^ " | awk '{ print $1 }' | grep -vE "${sExceptions}") # apt-get search not valid
  do
    echo -e "\t>>> suppression de ${pkg2}"
    apt-get autoremove "${pkg2%%/*}"
  done
}
main_prune_pkg() {
  #pruneDpkg
  #pruneAptSearch
  pruneUndeletedConf
  pruneObsoletePkg
  pruneDebianDefaultSoftware
}
main_prune_pkg