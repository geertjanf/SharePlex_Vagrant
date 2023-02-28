. /vagrant_config/install.env

echo "******************************************************************************"
echo "Create environment scripts." `date`
echo "******************************************************************************"
mkdir -p /home/oracle/scripts

cat > /home/oracle/scripts/setEnv.sh <<EOF
# Oracle Settings
export TMP=/tmp
export TMPDIR=\$TMP

export ORACLE_EDITION=${NODE1_ORACLE_EDITION}
export ORACLE_VERSION=${NODE1_ORACLE_VERSION}
export ORACLE_HOSTNAME=${NODE1_FQ_HOSTNAME}
export ORACLE_BASE=${ORACLE_BASE}
export ORA_INVENTORY=${ORA_INVENTORY}
export ORACLE_HOME=\$ORACLE_BASE/${ORACLE_HOME_EXT}
export ORACLE_SID=${ORACLE_SID}
export DATA_DIR=${DATA_DIR}
export ORACLE_TERM=xterm
export BASE_PATH=/usr/sbin:\$PATH
export PATH=\$ORACLE_HOME/bin:\$BASE_PATH

export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/JRE:\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
EOF

cat >> /home/oracle/.bash_profile <<EOF
. /home/oracle/scripts/setEnv.sh
PS1="[\u@\h:\[\033[33;1m\]\w\[\033[m\] ] $ "
alias s='sqlplus / as sysdba'
alias sr='rlwrap sqlplus / as sysdba'
alias sqlplus='rlwrap sqlplus'
alias dgmgrl='rlwrap dgmgrl'
alias rman='rlwrap rman'
alias lsnrctl='rlwrap lsnrctl'
alias asmcmd='rlwrap asmcmd'
alias adrci='rlwrap adrci'
alias impdp='rlwrap impdp'
alias expdp='rlwrap expdp'
EOF

echo "******************************************************************************"
echo "Create directories." `date`
echo "******************************************************************************"
. /home/oracle/scripts/setEnv.sh
mkdir -p ${ORACLE_HOME}
mkdir -p ${DATA_DIR}

echo "Oracle version    : ${ORACLE_VERSION}"
echo "Oracle edition    : ${ORACLE_EDITION}"
echo "Oracle binary path: $ORACLE_BINARIES_INSTALL"
echo "Oracle Home Dir   : $ORACLE_HOME"
