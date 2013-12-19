#!/bin/bash
################################
#       Network Destroyer      #
#       By: Cameron Mayor      #
#Written to force oneself to   #
#practice for the RHCSA	       #
################################

#restore the original config if the restore argument is passed to the script
if [ "$1" == "restore" ]; then
{
	cat backups/ifcfg-eth0 > /etc/sysconfig/network-scripts/ifcfg-eth0
	cat backups/resolv.conf > /etc/resolv.conf
	cat backups/network > /etc/sysconfig/network
	service NetworkManager start
	chkconfig NetworkManager on
	chattr -i /root/breaknetwork.lock
	rm -rf /root/breaknetwork.lock
}
echo "Restored successfully!"
exit
fi

if [ -e /root/breaknetwork.lock ]; then
{
	echo "This script has already destoryed your network!"
	exit
}
exit
fi

#stop and disable Network Manager
service NetworkManager stop
chkconfig NetworkManager off

#backup existing network config files
mkdir backups >/dev/null 2>$1
cp /etc/sysconfig/network backups/network
cp /etc/resolv.conf backups/resolv.conf
cp /etc/sysconfig/network-scripts/ifcfg-eth0 backups/ifcfg-eth0

#blow away existing network config files
>/etc/sysconfig/network
>/etc/resolv.conf
>/etc/sysconfig/network-scripts/ifcfg-eth0

#create lock file
touch /root/breaknetwork.lock
chattr +i /root/breaknetwork.lock

#Done
echo "Done destroying your network! Have fun fixing it!"
exit
