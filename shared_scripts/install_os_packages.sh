echo "******************************************************************************"
echo "Prepare yum repos and install base packages." `date`
echo "******************************************************************************"
echo "nameserver 192.168.1.80" >> /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# dnf install -y dnf-utils zip unzip mlocate ftp telnet tree readline-devel htop
yum install -y yum-utils zip unzip mlocate ftp telnet tree readline-devel htop

yum install -y oracle-database-preinstall-19c

echo 'INSTALLER: allow ssh access by password'
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config

# yum install -y rlwrap # sqlplus arrows 
cp /vagrant_software/rlwrap /usr/local/bin

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

cat >> /home/vagrant/.bash_profile <<EOF
PS1="[\u@\h:\[\033[33;1m\]\w\[\033[m\] ] $ "
alias o='sudo su - oracle'
EOF
