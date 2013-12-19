#kickstart files, install vm host, export local ks, network xml file, change dir for libvirt images
function vmrestore {
	#powers off the vm and then deletes it
	virsh destroy $1
	virsh undefine --remove-all-storage $1
	
	#installs the vm
	virt-install -n $1 -r 768 --vcpus=2 --os-type=linux --os-variant=rhel6 -l http://$3/inst --extra-args="ks=http://$3/inst/cfg/$1.cfg
" --disk path=/home/KVM/$1.img,size=12,format=raw --network=NETWORK,network=$2 --noautoconsole
}


echo "Lab setup v1.0 by Cameron Mayor"
echo "NOTE: all created VM's will have a root password of redhatlabs"
echo "Please input the path for the rhel 6.4 iso (including the filename):"
read isopath

echo "Please enter a username for the new regular user"
read newuser

clear

echo "Mounting the ISO in /media"
mount -o loop $isopath /media

#creates a temp locatlhost repository. will be changed later
echo "Creating a temporary YUM repository"
cat > /etc/yum.repos.d/localhost.repo << EOL
[localhost]
name=localhost
baseurl=file:///media
gpgcheck=no
EOL

echo "Installing the httpd and tigervnc-server packages"
yum -y install httpd tigervnc-server

echo "Enabling the installed services"
chkconfig httpd on
chkconfig vncserver

echo "Adding user $newuser, creating the sudoers group, and adding $newuser to it"
useradd $newuser
groupadd sudoers
usermod -aG sudoers $newuser
echo "%sudoers ALL=(ALL) ALL" >> /etc/sudoers

echo "Configuring the VNC server"
rm -f /etc/sysconfig/vncservers
echo 'VNCSERVERS="2:$newuser"' >> /etc/sysconfig/vncservers
echo 'VNCSERVERARGS[2]="-geometry 1920x1080 -nolisten tcp"' >> /etc/sysconfig/vncservers

echo "Please run both vncpasswd and passwd as user $newuser before continuing!!"
read -p "Press Enter to continue"

echo "Configuring the firewall"
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 5902 -j ACCEPT
iptables -A INPUT -p udp --dport 5902 -j ACCEPT
iptables -P FORWARD ACCEPT
service iptables save
service iptables restart
service httpd start
service vncserver start

echo "Copying the files from the ISO to the inst directory on the local webserver"
mkdir /var/www/html/inst
cp -ar /media/. /var/www/html/inst
chcon -R --reference /var/www/html /var/www/html/inst

echo "Recreating the localhost repository to use the local webserver"
#recreates the localhost repo, to use the http repository rather than the disk
cat > /etc/yum.repos.d/localhost.repo << EOL
[localhost]
name=localhost
baseurl=http://localhost/inst
gpgcheck=no
EOL

yum clean all



echo "creates a policy to allow the firewall gui utilitiy to be used over vnc"
# one '>' after cat overwrites the file if it exists. 2 would append to the end of the current file
cat > /etc/polkit-1/localauthority/50-local.d/50-firewall-$newuser-access.pkla << EOL
[Allow $newuser remote access to system-config-firewall]
Identity=unix-user:$newuser
Action=org.fedoraproject.config.firewall.auth
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOL


###cfg creation

echo "Creating all the kickstart files for the 3 VM's"
mkdir /var/www/html/inst/cfg

touch /var/www/html/inst/cfg/server1.example.com.cfg
cat > /var/www/html/inst/cfg/server1.example.com.cfg << EOL
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --enabled --ssh
# Install OS instead of upgrade
install
# Use network installation
url --url="http://192.168.122.1/inst"
# Root password
rootpw redhatlabs
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info

# System timezone
timezone --utc America/New_York
# Network information
network  --bootproto=static --device=eth0 --gateway=192.168.122.1 --ip=192.168.122.50 --nameserver=192.168.122.1 --netmask=255.255.255.0 --onboot=on --hostname=server1.example.com
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part /boot --fstype="ext4" --size=500
part / --fstype="ext4" --size=8000
part /home --fstype="ext4" --size=1000
part swap --fstype="swap" --size=1000

poweroff

%packages

@base
@client-mgmt-tools
@console-internet
@core
@debugging
@basic-desktop
@directory-client
@fonts
@hardware-monitoring
@internet-browser
@java-platform
@large-systems
@network-file-system-client
@performance
@perl-runtime
@server-platform
@server-policy
@x11
mtools
pax
python-dmidecode
oddjob
sgpio
device-mapper-persistent-data
samba-winbind
certmonger
pam_krb5
krb5-workstation
perl-DBD-SQLite

%end
EOL


touch /var/www/html/inst/cfg/tester1.example.com.cfg
cat > /var/www/html/inst/cfg/tester1.example.com.cfg << EOL
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --enabled --ssh
# Install OS instead of upgrade
install
# Use network installation
url --url="http://192.168.122.1/inst"
# Root password
rootpw redhatlabs
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info

# System timezone
timezone --utc America/New_York
# Network information
network  --bootproto=static --device=eth0 --gateway=192.168.122.1 --ip=192.168.122.150 --nameserver=192.168.122.1 --netmask=255.255.255.0 --onboot=on --hostname=tester1.example.com
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part /boot --fstype="ext4" --size=500
part / --fstype="ext4" --size=8000
part /home --fstype="ext4" --size=1000
part swap --fstype="swap" --size=1000

poweroff

%packages

@base
@client-mgmt-tools
@console-internet
@core
@debugging
@basic-desktop
@directory-client
@fonts
@hardware-monitoring
@internet-browser
@java-platform
@large-systems
@network-file-system-client
@performance
@perl-runtime
@server-platform
@server-policy
@x11
mtools
pax
python-dmidecode
oddjob
sgpio
device-mapper-persistent-data
samba-winbind
certmonger
pam_krb5
krb5-workstation
perl-DBD-SQLite

%end
EOL


touch /var/www/html/inst/cfg/outsider1.example.org.cfg
cat > /var/www/html/inst/cfg/outsider1.example.org.cfg << EOL
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --enabled --ssh
# Install OS instead of upgrade
install
# Use network installation
url --url="http://192.168.100.1/inst"
# Root password
rootpw redhatlabs
# System authorization information
auth  --useshadow  --passalgo=sha512
# Use graphical install
graphical
firstboot --disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux --enforcing
# Installation logging level
logging --level=info

# System timezone
timezone --utc America/New_York
# Network information
network  --bootproto=static --device=eth0 --gateway=192.168.100.1 --ip=192.168.100.100 --nameserver=192.168.100.1 --netmask=255.255.255.0 --onboot=on --hostname=outsider1.example.org
# System bootloader configuration
bootloader --location=mbr
# Clear the Master Boot Record
zerombr
# Partition clearing information
clearpart --all --initlabel 
# Disk partitioning information
part /boot --fstype="ext4" --size=500
part / --fstype="ext4" --size=8000
part /home --fstype="ext4" --size=1000
part swap --fstype="swap" --size=1000

poweroff

%packages

@base
@client-mgmt-tools
@console-internet
@core
@debugging
@basic-desktop
@directory-client
@fonts
@hardware-monitoring
@internet-browser
@java-platform
@large-systems
@network-file-system-client
@performance
@perl-runtime
@server-platform
@server-policy
@x11
mtools
pax
python-dmidecode
oddjob
sgpio
device-mapper-persistent-data
samba-winbind
certmonger
pam_krb5
krb5-workstation
perl-DBD-SQLite

%end
EOL

restorecon -r /var/www/html

echo "Installing and starting the necessary packages for the virtual host"
yum -y install qemu-kvm python-virtinst virt-manager virt-top virt-viewer libvirt libvirt-client

service libvirtd start
service libvirt-guests start

echo "relocating the KVM images directory to /home/KVM"
##relocate KVM to /home/KVM
mkdir /home/KVM
chcon -R --reference /var/lib/libvirt/images /home/KVM
rmdir /var/lib/libvirt/images
ln -s /home/KVM /var/lib/libvirt/images

cat > home.KVM.xml << EOL
<pool type='dir'>
  <name>KVM</name>
  <uuid>ce831a75-aba0-ee15-a269-557492cda3d0</uuid>
  <capacity unit='bytes'>64173846528</capacity>
  <allocation unit='bytes'>15550259200</allocation>
  <available unit='bytes'>48623587328</available>
  <source>
  </source>
  <target>
    <path>/home/KVM</path>
    <permissions>
      <mode>0755</mode>
      <owner>0</owner>
      <group>0</group>
    </permissions>
  </target>
</pool>
EOL

echo "Creating the second storage pool"
virsh pool-define home.KVM.xml
virsh pool-autostart home.KVM.xml
virsh pool-start home.KVM.xml

echo "Adding new VM's to /etc/hosts"
cat >> /etc/hosts << EOL
192.168.122.150 tester1.example.com tester1
192.168.122.50 server1.example.com server1
192.168.100.100 outsider1.example.org outsider1
EOL

touch outsider.xml
cat > outsider.xml << EOL
<network>
  <name>outsider</name>
  <uuid>96dbc6a3-2696-d68c-745c-d7d3d53a6af0</uuid>
  <forward mode='nat'/>
  <bridge name='virbr1' stp='on' delay='0' />
  <mac address='52:54:00:FD:62:15'/>
  <ip address='192.168.100.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.100.128' end='192.168.100.254' />
    </dhcp>
  </ip>
</network>
EOL

echo "Creating the outsider network"
virsh net-define outsider.xml
virsh net-autostart outsider
virsh net-start outsider


echo "creating the 3 necessary VM's"
vmrestore server1.example.com default 192.168.122.1
vmrestore tester1.example.com default 192.168.122.1
vmrestore outsider1.example.org outsider 192.168.100.1

echo "Creating new hard drives for server1"
vol-create-as KVM server1.drive2.img 1GB
vol-create-as KVM server1.drive3.img 1GB
attach-disk server1.example.com /home/KVM/server1.drive2.img vdb --persistent
attach-disk server1.example.com /home/KVM/server1.drive3.img vdb --persistent
