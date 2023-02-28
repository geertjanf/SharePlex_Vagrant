. /vagrant_config/install.env

sh /vagrant_scripts/prepare_disks.sh

echo "******************************************************************************"
echo "Prepare yum repos and install base packages." `date`
echo "******************************************************************************"
echo "nameserver 192.168.1.80" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf
cd /etc/yum.repos.d
yum install -y yum-utils zip unzip mlocate tree telnet ksh htop

echo 'INSTALLER: allow ssh access by password'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

echo "******************************************************************************"
echo "Firewall." `date`
echo "******************************************************************************"
systemctl stop firewalld
systemctl disable firewalld

echo "******************************************************************************"
echo "SELinux." `date`
echo "******************************************************************************"
sed -i -e "s|SELINUX=enabled|SELINUX=permissive|g" /etc/selinux/config
setenforce permissive

chmod -R 775 /u01

#Foglight 6.1.0
yum install -y dejavu* fontconfig
fc-cache -f -v

sh /vagrant_scripts/configure_hosts_base.sh

sh /vagrant_scripts/configure_chrony.sh

ORACLE_HOSTNAME=${NODE4_HOSTNAME}
sh /vagrant_scripts/configure_hostname.sh

echo "******************************************************************************"
echo "Change ip configuration" `date`
echo "******************************************************************************"
sudo sed -i 's/BOOTPROTO/#BOOTPROTO/g' /etc/sysconfig/network-scripts/ifcfg-eth0
cat >> /etc/sysconfig/network-scripts/ifcfg-eth0 <<EOF
BOOTPROTO=static
IPADDR=10.0.2.18
ot_boo  =255.255.255.0
EOF

echo "******************************************************************************"
echo "Foglight installation." `date`
echo "******************************************************************************"

useradd foglight
echo -e "${FOGLIGHT_PASSWORD}\n${FOGLIGHT_PASSWORD}" | passwd foglight
chmod 755 /home/foglight

su - foglight -c "sh /vagrant/scripts/foglight_setup.sh"

echo ""
echo "******************************************************************************"
echo "Foglight auto start" `date`
echo "******************************************************************************"
sh /vagrant/scripts/foglight_auto_start.sh

echo "******************************************************************************"
echo "Foglight Installation finished." `date`
echo "******************************************************************************"
