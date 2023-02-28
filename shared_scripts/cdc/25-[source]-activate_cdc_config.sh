
. ./config.env
. ./common.sh

info "Deactivate config oracle"
echo "deactivate config my_config_oracle.cfg" | $SP_SYS_BINDIR/sp_ctrl
sleep 10

info "Activate config cdc"
echo "list config" | $SP_SYS_BINDIR/sp_ctrl
echo "show" | $SP_SYS_BINDIR/sp_ctrl
echo "activate config cdc.cfg" | $SP_SYS_BINDIR/sp_ctrl
sleep 15
echo "list config" | $SP_SYS_BINDIR/sp_ctrl
echo "show config" | $SP_SYS_BINDIR/sp_ctrl
echo "show" | $SP_SYS_BINDIR/sp_ctrl
