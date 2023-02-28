
. ./config.env

cd $SP_SYS_BINDIR
echo "shutdown" | $SP_SYS_BINDIR/sp_ctrl
sleep 5

echo -e "Y" | ora_cleansp pdb1/splex/splex
cd -
$SP_SYS_BINDIR/sp_cop -u2100 &
sleep 7

ssh oracle@${TARGET_HOST} '. /home/oracle/.bash_profile;cd $SP_SYS_BINDIR;echo "shutdown" | $SP_SYS_BINDIR/sp_ctrl;sleep 5;echo -e "Y" | ora_cleansp pdb1/splex/splex;'
sleep 2

ssh oracle@${TARGET_HOST} '. /home/oracle/.bash_profile;$SP_SYS_BINDIR/sp_cop -u2100' &
sleep 5

echo "activate config my_config_oracle.cfg" | $SP_SYS_BINDIR/sp_ctrl
sleep 5

echo "show config" | $SP_SYS_BINDIR/sp_ctrl
sleep 5
