#!/bin/bash
#
# this script will install, license and setup SharePlex
#

################################################################################
#
# fill in the following 
# 
################################################################################

SP_ADMIN_GROUP=splex
SP_OPTDIR=/quest/splex-home/frese/script/10/opt
SP_VARDIR=/quest/splex-home/frese/script/10/var
SP_PORT=2100
SP_LICENSE_KEY=kldsjfdlksafjklsdajfdklasjflkjlkdsafj
SP_LICENSE_CUSTOMER="Quest"
SP_ORACLE_SID=orcl11
SP_ORACLE_HOME=/home/oracle/app/oracle/product/19/dbhome_1
SP_ORACLE_DBA_USER=gjf
SP_ORACLE_DBA_PASSWORD=gjf
SP_ORACLE_SPLEX_USER=gjf
SP_ORACLE_SPLEX_PASSWORD=gjf
SP_ORACLE_DEFAULT_TABLESPACE=USERS
SP_ORACLE_TEMP_TABLESPACE=TEMP
SP_ORACLE_INDEX_TABLESPACE=USERS

#
# create response file for install
#
cat > install.rsp <<EOF
the SharePlex Admin group: ${SP_ADMIN_GROUP}
product directory location: ${SP_OPTDIR}
variable data directory location: ${SP_VARDIR}
ORACLE_SID that corresponds to this installation: ${SP_ORACLE_SID}
ORACLE_HOME directory that corresponds to this ORACLE_SID: ${SP_ORACLE_HOME}
TCP/IP port number for SharePlex communications: ${SP_PORT}
the License key: ${SP_LICENSE_KEY}
the customer name associated with this license key: ${SP_LICENSE_CUSTOMER}
Proceed with installation: yes
Proceed with upgrade: no
OK to upgrade: no
update the license: no
EOF

#
# install software
#
./SharePlex-10.2.0-b42-rhel-amd64-m64.tpm -r install.rsp <<EOF
Y
${SP_LICENSE_KEY}
${SP_LICENSE_CUSTOMER}
EOF

#
# setup environment
#
export SP_SYS_VARDIR=${SP_VARDIR}
export SP_COP_TPORT=${SP_PORT}

#
# run ora_setup
#
cd $SP_OPTDIR/bin
./ora_setup <<EOF
Y
${SP_ORACLE_SID}
${SP_ORACLE_DBA_USER}
${SP_ORACLE_DBA_PASSWORD}
n
${SP_ORACLE_SPLEX_USER}
${SP_ORACLE_SPLEX_PASSWORD}
n
${SP_DEFAULT_TABLESPACE}
${SP_TEMP_TABLESPACE}
${SP_INDEX_TABLESPACE}
Y
EOF

./sp_cop &

sleep 2

./sp_ctrl <<EOF
version full
quit
EOF
