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

#
# ███████╗██╗  ██╗ █████╗ ██████╗ ███████╗██████╗ ██╗     ███████╗██╗  ██╗    
# ██╔════╝██║  ██║██╔══██╗██╔══██╗██╔════╝██╔══██╗██║     ██╔════╝╚██╗██╔╝    
# ███████╗███████║███████║██████╔╝█████╗  ██████╔╝██║     █████╗   ╚███╔╝     
# ╚════██║██╔══██║██╔══██║██╔══██╗██╔══╝  ██╔═══╝ ██║     ██╔══╝   ██╔██╗     
# ███████║██║  ██║██║  ██║██║  ██║███████╗██║     ███████╗███████╗██╔╝ ██╗    
# ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝    
#                                                                            
#            ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗               
#            ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║               
#            ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║               
#            ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║               
#            ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗          
#            ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝          
#                                                                           
echo "******************************************************************************"
echo "Install Quest Shareplex." `date` 
echo "******************************************************************************"
su - oracle -c 'sh /vagrant_scripts/shareplex_install.sh'

echo "******************************************************************************"
echo "Quest Shareplex queue configuration." `date`
echo "******************************************************************************"
su - oracle -c '. /vagrant_config/install.env && cat > ${SP_SYS_VARDIR}/config/my_config_oracle.cfg <<EOF
datasource:o.pdb1
#source tables      target tables           routing map
expand test.%       test.%                  ol7-19-splex2@o.pdb1
EOF'
su - oracle -c '. /vagrant_config/install.env && cat > ${SP_SYS_VARDIR}/config/cdc.cfg <<EOF
datasource:o.pdb1
#source tables      target tables           routing map
expand test.%       test.%                  ol7-19-splex2@o.pdb1
test.cdc            !cdc:cdc.cdc            ol7-19-splex2@c.pdb1
EOF'
if [ $AWS_RDS = 'Y' ]; then
  . /vagrant_scripts/shareplex_install_AWS.sh
  echo "******************************************************************************"
  echo "Quest Shareplex AWS configuration." `date`
  echo "******************************************************************************"
  su - oracle -c 'cd ${SHAREPLEX_DIRINSTALL}/bin | echo -e "activate config my_config_AWS_oracle.cfg" | sp_ctrl'
else
  echo "******************************************************************************"
  echo "Quest Shareplex configuration." `date`
  echo "******************************************************************************"
  su - oracle -c 'cd ${SHAREPLEX_DIRINSTALL}/bin | echo -e "activate config my_config_oracle.cfg" | sp_ctrl'
fi

echo "******************************************************************************"
echo "Quest Shareplex show configuration." `date`
echo "******************************************************************************"
su - oracle -c 'cd ${SP_SYS_BINDIR} | echo -e "show\nstatus" | sp_ctrl'

echo "******************************************************************************"
echo "Set the PDB to auto-start." `date`
echo "******************************************************************************"
sleep 5
su - oracle -c 'sh /vagrant_scripts/shareplex_create_test_table.sh'

echo "******************************************************************************"
echo "Autostart DB scripts." `date` 
echo "******************************************************************************"
sh /vagrant_scripts/oracle_service_setup.sh
