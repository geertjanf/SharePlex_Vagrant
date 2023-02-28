
. ./config.env

ssh oracle@${TARGET_HOST} 'echo -e "stop post\n" | $SP_SYS_BINDIR/sp_ctrl'

sleep 7

ssh oracle@${TARGET_HOST} 'echo -e "set param SP_OPO_TRACK_PREIMAGE 0\nstart post\n" | $SP_SYS_BINDIR/sp_ctrl'
