. /vagrant_config/install.env

cat >> /home/foglight/.bash_profile <<EOF
PS1="[\u@\h:\[\033[33;1m\]\w\[\033[m\] ] $ "
EOF

echo ""
echo "******************************************************************************"
echo "Foglight install" `date`
echo "******************************************************************************"
cd $FOGLIGHT_BINARIES_INSTALL
unzip -o $FOGLIGHT_SOFTWARE_ZIP

cd $FOGLIGHT_BINARIES_INSTALL/CoreServer/CoreFoglightServer*
export FOGLIGHT_BINARY=`ls -t Foglight*.bin`

./$FOGLIGHT_BINARY -f ./fms_silent_install.properties -i silent

cat >> /home/foglight/Quest/Foglight/state/postgresql-data/pg_hba.conf <<EOF
host    all             all             10.0.2.2/32             password
EOF

cat >> /home/foglight/Quest/Foglight/state/postgresql-data/postgresql.conf <<EOF
listen_addresses = '*'
EOF

echo ""
echo "******************************************************************************"
echo "Cartridges" `date`
echo "******************************************************************************"
cp $FOGLIGHT_CARTRIDGES/*.car /home/foglight/Quest/Foglight/upgrade/cartridge

echo ""
echo "******************************************************************************"
echo "Foglight startup" `date`
echo "******************************************************************************"
cd /home/foglight/Quest/Foglight/bin
./fmsStartup.sh
count=0

while [ "$count" -eq 0 ]
do
  count=`ps -ef | grep -E "Quest Application Watchdog" | grep -v grep | wc -l`
  count_sec=`expr $count_sec + 30`

  echo "Waiting for Agent Manager start... $count_sec"
  sleep 30
done;
sleep 30

echo ""
echo "******************************************************************************"
echo "Licenses" `date`
echo "******************************************************************************"

yourfilenames=`ls $FOGLIGHT_LICENSES/*.license`
for eachfile in $yourfilenames
do
   echo "License: $eachfile"
   ./fglcmd.sh -usr foglight -pwd foglight -cmd license:import -f $eachfile
done


echo ""
echo "******************************************************************************"
echo "Cartridges" `date`
echo "******************************************************************************"
./fglcmd.sh -usr foglight -cmd cartridge:enable -n DB_Oracle -v 6.1.0.10
./fglcmd.sh -usr foglight -cmd cartridge:enable -n DB_Oracle_UI -v 6.1.0.10
#./fglcmd.sh -usr foglight -cmd cartridge:enable -n DB_SQL_Server -v 6.1.2.10
#./fglcmd.sh -usr foglight -cmd cartridge:enable -n DB_SQL_Server_UI -v 6.1.2.10
#./fglcmd.sh -usr foglight -cmd cartridge:enable -n PostgreSQLAgent -v 6.1.0.10

echo ""
echo "******************************************************************************"
echo "Database monitoring" `date`
echo "******************************************************************************"
#. /vagrant_config/install.env

fglam=`./fglcmd.sh -cmd agent:list | grep "Host:" | tail -1 | awk '{ print $2 }'`

#-f /home/foglight/Quest/Foglight/bin/oracle_cli_installer.groovy \
#            instances_file_name /vagrant/scripts/cartridges/DB_Oracle_CLI_Installer/oracle_cli_installer_input_template.csv
./fglcmd.sh -srv 127.0.0.1 \
            -port 8080 \
            -usr foglight \
            -pwd foglight \
            -cmd script:run \
            -f $FOGLIGHT_CARTRIDGES/DB_Oracle_CLI_Installer/oracle_cli_installer.groovy \
            fglam_name ${fglam} \
            instances_file_name $FOGLIGHT_CARTRIDGES/DB_Oracle_CLI_Installer/oracle_cli_installer_input_template.csv
#MSSQL
# fglam=`./fglcmd.sh -cmd agent:list | grep "Host:" | tail -1 | awk '{ print $2 }'`
# ./fglcmd.sh -srv 127.0.0.1 \
            # -port 8080 \
            # -usr foglight \
            # -pwd foglight \
            # -cmd script:run \
            # -f $FOGLIGHT_CARTRIDGES/DB_SQL_Server_CLI_Installer/mssql_cli_installer.groovy \
            # fglam_name ${fglam} \
            # instances_file_name $FOGLIGHT_CARTRIDGES/DB_SQL_Server_CLI_Installer/silent_installer_input_template.csv
