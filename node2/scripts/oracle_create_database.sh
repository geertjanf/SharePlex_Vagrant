. /vagrant_config/install.env

echo "******************************************************************************"
echo "Configure network scripts." `date`
echo "******************************************************************************"
cat > ${ORACLE_HOME}/network/admin/tnsnames.ora <<EOF
LISTENER = (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))

${NODE1_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE1_HOSTNAME})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ${ORACLE_SID})
    )
  )

${NODE2_DB_UNIQUE_NAME} =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SID = ${ORACLE_SID})
    )
  )
  
${PDB_NAME} =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PDB_NAME})
    )
  )

${PDB_NAME}_VM1 =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE1_HOSTNAME})(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = ${PDB_NAME})
    )
  )

EOF

cat > ${ORACLE_HOME}/network/admin/listener.ora <<EOF
LISTENER =
  (DESCRIPTION_LIST =
    (DESCRIPTION =
      (ADDRESS = (PROTOCOL = TCP)(HOST = ${NODE2_HOSTNAME})(PORT = 1521))
      (ADDRESS = (PROTOCOL = IPC)(KEY = EXTPROC1521))
    )
  )

SID_LIST_LISTENER =
  (SID_LIST =
    (SID_DESC =
      (GLOBAL_DBNAME = ${NODE2_DB_UNIQUE_NAME})
      (ORACLE_HOME = ${ORACLE_HOME})
      (SID_NAME = ${ORACLE_SID})
    )
  )

ADR_BASE_LISTENER = ${ORACLE_BASE}
INBOUND_CONNECT_TIMEOUT_LISTENER=400
EOF


cat > ${ORACLE_HOME}/network/admin/sqlnet.ora <<EOF
SQLNET.INBOUND_CONNECT_TIMEOUT=400
EOF

cat >> /etc/oratab <<EOF
pdb1:/u01/app/oracle/product/19/dbhome_1:N
EOF

echo "******************************************************************************"
echo "Start listener." `date`
echo "******************************************************************************"
lsnrctl start

echo "******************************************************************************"
echo "Create database." `date`
echo "******************************************************************************"
dbca -silent -createDatabase                                                 \
  -templateName General_Purpose.dbc                                          \
  -gdbname ${ORACLE_SID} -sid ${ORACLE_SID} -responseFile NO_VALUE           \
  -characterSet AL32UTF8                                                     \
  -sysPassword ${SYS_PASSWORD}                                               \
  -systemPassword ${SYS_PASSWORD}                                            \
  -createAsContainerDatabase true                                            \
  -numberOfPDBs 1                                                            \
  -pdbName ${PDB_NAME}                                                       \
  -pdbAdminPassword ${PDB_PASSWORD}                                          \
  -databaseType MULTIPURPOSE                                                 \
  -automaticMemoryManagement false                                           \
  -totalMemory 1024                                                          \
  -storageType FS                                                            \
  -datafileDestination "${DATA_DIR}"                                         \
  -redoLogFileSize 50                                                        \
  -emConfiguration NONE                                                      \
  -ignorePreReqs

echo "******************************************************************************"
echo "Set the PDB to auto-start." `date`
echo "******************************************************************************"
sqlplus / as sysdba <<EOF
ALTER SYSTEM SET db_create_file_dest='${DATA_DIR}';
ALTER SYSTEM SET db_create_online_log_dest_1='${DATA_DIR}';
ALTER PLUGGABLE DATABASE ${PDB_NAME} SAVE STATE;
ALTER SYSTEM SET local_listener='LISTENER';
exit;
EOF

echo "******************************************************************************"
echo "Flip the auto-start flag." `date`
echo "******************************************************************************"
cp /etc/oratab /tmp
sed -i -e "s|${ORACLE_SID}:${ORACLE_HOME}:N|${ORACLE_SID}:${ORACLE_HOME}:Y|g" /tmp/oratab
cp -f /tmp/oratab /etc/oratab

echo "******************************************************************************"
echo "Configure archivelog mode." `date`
echo "******************************************************************************"
sqlplus / as sysdba <<EOF

-- Enable archivelog mode.
SHUTDOWN IMMEDIATE;
STARTUP MOUNT;
ALTER DATABASE ARCHIVELOG;
ALTER DATABASE OPEN;

ALTER DATABASE FORCE LOGGING;
-- Make sure at least one logfile is present.
ALTER SYSTEM SWITCH LOGFILE;

EXIT;
EOF
