#!/bin/ksh
##############################################################################################################
#
#   Program Name:  sp_mon.source.sh
#   Date Written:  28-Nov-2012
#   Written By:    Lootong Tan
#   Enhanced By:   
#
#   Purpose: To allow specification of generic environment variables and to spawn off other monitoring scripts
#            This script can be cron to allow periodic monitoring
#
##############################################################################################################
#
#   Variables:
#       SP_SYS_BINDIR - generic SharePlex binary directory variable pointing to the binary directory
#       SP_SYS_VARDIR - generic SharePlex data directory variable pointing to the data directory
#       SP_MONDIR     - generic SharePlex Monitoring logs directory
#       SP_SCRIPTS    - generic director where all monitoring scripts are stored
#       INTERVAL      - interval between each check
#
#  Dependencies:
#
##############################################################################################################
#
#  Modification:  
#
############################################################################################################
## if this script is cron, the sleep-n-wake-up loop will not be required
#INTERVAL=1800   # 30 minutes
#INTERVAL=600     # 10 minutes
#while :
#do
# Environment Variables to setup before executing monitoring scripts
export SP_COP_TPORT=2200
export SP_COP_UPORT=$SP_COP_TPORT
export SP_HOME=/quest/splex
export SP_SYS_VARDIR=$SP_HOME/vardir22
export SP_SYS_BINDIR=$SP_HOME/bin
export SP_MONDIR=$SP_HOME/script/log
export SP_SCRIPTS=$SP_HOME/script
export SP_SYS_UTILDIR=$SP_HOME/util
export SP_SYS_HOST_NAME=linuxa
export SRC_ORACLE_SID=orcl
export SPLEX_UNAME=$SP_COP_TPORT
export PLS_MAIL=TRUE
export NO_MAIL=FALSE
export INTERVAL=600

############################################################
# C A P T U R E   A N D   R E A D E R   S T A T I S T I C S
############################################################
$SP_SCRIPTS/sp_capreadstats.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -p $SP_COP_TPORT -e $PLS_MAIL

############################################################
# P R O C E S S   S T A T U S   M O N I T O R
############################################################
$SP_SCRIPTS/sp_psmon.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -p $SP_COP_TPORT -u $SPLEX_UNAME -o $SRC_ORACLE_SID -e $PLS_MAIL

############################################################
# E V E N T   L O G   M O N I T O R
############################################################
$SP_SCRIPTS/sp_eventmon.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -w $SP_SYS_UTILDIR -p $SP_COP_TPORT -e $PLS_MAIL

######################
#### log gap monitor
######################
$SP_SCRIPTS/sp_logmon.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -p $SP_COP_TPORT -e $PLS_MAIL


###########################
#### queue backlog  monitor
###########################
$SP_SCRIPTS/sp_qstatmon.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -p $SP_COP_TPORT -e $PLS_MAIL


# end of script
