#!/usr/bin/env bash

set -euo pipefail #; set -x

grubUpdate() {
	if [ -x /usr/sbin/update-grub ]; then update-grub
	elif [ -x /usr/sbin/grub2-mkconfig ]; then grub2-mkconfig -o /boot/grub2/grub.cfg
	elif [ -x /usr/sbin/grub-mkconfig ]; then grub-mkconfig -o /boot/grub/grub.cfg
	fi
}
main_grubsettings() {
    #sCommand="sed -i '/GRUB_CMDLINE_LINUX/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
    #sCommandDefault="sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub"
	##echo -e "$sCommand \n $sCommandDefault"
	#$sCommand
    #$sCommandDefault 			#sed -i '/GRUB_CMDLINE_LINUX/ s/"$/ ipv6.disable=1"/' /etc/default/grub then #sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/"$/ ipv6.disable=1"/' /etc/default/grub
	sed -i '/GRUB_CMDLINE_LINUX/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub
    sed -i '/GRUB_CMDLINE_LINUX_DEFAULT/ s/\"$/ ipv6.disable=1\"/' /etc/default/grub
	
	grubUpdate
}
main_grubsettings