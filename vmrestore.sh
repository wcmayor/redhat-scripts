#!/bin/bash
function vmrestore {
	#powers off the vm and then deletes it
	virsh destroy $1
	virsh undefine --remove-all-storage $1
	
	#installs the vm
	virt-install -n $1 -r 768 --vcpus=2 --os-type=linux --os-variant=rhel6 -l http://$3/inst --extra-args="ks=http://$3/inst/cfg/$1.cfg
" --disk path=/var/lib/libvirt/images$1.img,size=12,format=raw --network=NETWORK,network=$2 --noautoconsole
}

echo "Welcome to the VM restore script"
echo "WARNING: proceeding will wipe all selected VM's"
echo ""
echo "Which VM would you like to restore?"
echo "1 - server1.example.com"
echo "2 - tester1.example.com"
echo "3 - outsider1.example.org"
echo "a - restores all VM's"
echo "x - exits without changes"
echo ""
echo "Enter a choice:" 
read vm

if [ "$vm" == "x" ]; then
	exit
elif [ "$vm" == "1" ]; then
	vmrestore server1.example.com default 192.168.122.1
	vol-create-as KVM server1.drive2.img 1GB
	vol-create-as KVM server1.drive3.img 1GB
	attach-disk server1.example.com /home/KVM/server1.drive2.img vdb --persistent
	attach-disk server1.example.com /home/KVM/server1.drive3.img vdb --persistent
elif [ "$vm" == "2" ]; then
	vmrestore tester1.example.com default 192.168.122.1
elif [ "$vm" == "3" ]; then
	#virsh net-create outsider.xml
	vmrestore outsider1.example.org outsider 192.168.100.1
elif [ "$vm" == "a" ]; then
	vmrestore server1.example.com default 192.168.122.1
	vmrestore tester1.example.com default 192.168.122.1
	#virsh net-create outsider.xml
	vmrestore outsider1.example.org outsider 192.168.100.1
else
	echo "invalid choice! Press enter to exit"
	read $nonsense
	exit
fi