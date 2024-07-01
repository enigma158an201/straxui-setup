#!/usr/bin/env bash

sExceptions="^xf|^desktop-base|^libexo|^libglib|libgtop|libsoup|libstartup|^libxml|^shared-mime|^adwaita|^libcups|^network-manager|^policy|^polkit|^at-spi"
installedString="[installed]"

pruneDpkg() {
  for pkg3 in gnome libreoff cups plymouth hitori quadrapassel sane scan transmission tumbler lynx wpasupplicant bluez
  do
    for pkg1 in $(dpkg -l | grep ^ii | awk '{ print $2 }' | grep $pkg3 | grep -vE "$sExceptions")
    do
      echo -e "\t>>> suppression de $pkg1"
      apt-get autoremove "$pkg1"
    done
  done
}
pruneAptSearch() {
  for pkg2 in $(LANG=C apt search gnome | grep "${installedString}" | grep -v "^ " | awk '{ print $1 }' | grep -vE "$sExceptions") # apt-get search not valid
  do
    echo -e "\t>>> suppression de echo $pkg2"
    apt-get autoremove "${pkg2%%/*}"
  done
}
main_prune() {
  pruneDpkg
  pruneAptSearch
}
main_prune