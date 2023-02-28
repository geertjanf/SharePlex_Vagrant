. /vagrant_config/install.env

sh /vagrant_scripts/prepare_disks.sh

sh /vagrant_scripts/install_os_packages.sh

mkdir -p ${SCRIPTS_DIR}
mkdir -p ${SOFTWARE_DIR}
mkdir -p ${DATA_DIR}
echo "******************************************************************************"
echo "Set root and oracle password and change ownership of /u01." `date`
echo "******************************************************************************"
echo -e "${ROOT_PASSWORD}\n${ROOT_PASSWORD}" | passwd
echo -e "${ORACLE_PASSWORD}\n${ORACLE_PASSWORD}" | passwd oracle
chown -R oracle:oinstall ${SCRIPTS_DIR} /u01
chmod -R 775 /u01

sh /vagrant_scripts/configure_hosts_base.sh

sh /vagrant_scripts/configure_chrony.sh

echo "******************************************************************************"
echo "Prepare environment and install the software." `date`
echo "******************************************************************************"
su - oracle -c 'sh /vagrant/scripts/oracle_user_environment_setup.sh'
. /home/oracle/scripts/setEnv.sh

sh /vagrant_scripts/configure_hostname.sh

su - oracle -c 'sh /vagrant_scripts/oracle_db_software_installation.sh'

echo "******************************************************************************"
echo "Run DB root scripts." `date` 
echo "******************************************************************************"
sh ${ORA_INVENTORY}/orainstRoot.sh
sh ${ORACLE_HOME}/root.sh

export PATCH_DB="true"
if [ "${PATCH_DB}" = "true" ]; then
  su - oracle -c 'sh /vagrant_scripts/oracle_software_patch.sh'
fi

su - oracle -c 'sh /vagrant/scripts/oracle_create_database.sh'

echo "******************************************************************************"
echo "Install Quest Shareplex." `date` 
echo "******************************************************************************"
su - oracle -c 'sh /vagrant_scripts/shareplex_install.sh'

echo ""
echo "******************************************************************************"
echo "Autostart DB scripts." `date` 
echo "******************************************************************************"
sh /vagrant_scripts/oracle_service_setup.sh
