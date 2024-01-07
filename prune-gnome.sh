#!/bin/bash

sExceptions="^xf|^desktop-base|^libexo|^libglib|libgtop|libsoup|libstartup|^libxml|^shared-mime|^adwaita|^libcups|^network-manager"

for pkg3 in gnome libreoff cups #bluez
do
  for pkg1 in $(dpkg -l | grep ^ii | awk {'print $2'} | grep $pkg3 | grep -vE "$sExceptions")
  do
    echo -e "\t>>> suppression de $pkg1"
    apt-get autoremove $pkg1
  done
done

for pkg2 in $(LANG=C apt search gnome | grep "install" | awk {'print $1'}) | grep -vE "$sExceptions")
do
  echo $pkg2
  apt-get autoremove ${pkg2%%/*}
done
