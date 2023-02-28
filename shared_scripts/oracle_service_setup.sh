echo "******************************************************************************"
echo "Create start/stop scripts." `date`
echo "******************************************************************************"
. ${SCRIPTS_DIR}/setEnv.sh

cat > ${SCRIPTS_DIR}/start_all.sh <<EOF
#!/bin/bash
. ${SCRIPTS_DIR}/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbstart \$ORACLE_HOME
EOF


cat > ${SCRIPTS_DIR}/stop_all.sh <<EOF
#!/bin/bash
. ${SCRIPTS_DIR}/setEnv.sh

export ORAENV_ASK=NO
. oraenv
export ORAENV_ASK=YES

dbshut \$ORACLE_HOME
EOF

chown -R oracle.oinstall /home/oracle/scripts
chmod u+x /home/oracle/scripts/*.sh

echo "******************************************************************************"
echo "Create the database auto-start service." `date`
echo "******************************************************************************"
cp /vagrant_scripts/dbora.service /lib/systemd/system/dbora.service
systemctl daemon-reload
systemctl start dbora.service
systemctl enable dbora.service
systemctl status dbora.service