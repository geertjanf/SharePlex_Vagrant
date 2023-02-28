function splex
{
        SP_COP_UPORT=2100; export SP_COP_UPORT
        SP_COP_TPORT=2100; export SP_COP_TPORT
        SP_HOME=/u01/app/quest/shareplex; export SP_HOME
        SP_SYS_HOST_NAME=`uname -n`; export SP_SYS_HOST_NAME
        SP_SYS_PRODDIR=$SP_HOME/prod; export SP_SYS_PRODDIR
        SP_SYS_BINDIR=$SP_SYS_PRODDIR/bin; export SP_SYS_BINDIR
        SP_SYS_VARDIR=$SP_HOME/vardir/2100; export SP_SYS_VARDIR
        SP_SYS_SCRIPT=$SP_HOME/scripts; export SP_SYS_SCRIPT

        SP_LIB_PATH=$SP_SYS_PRODDIR/lib; export SP_LIB_PATH
        alias goplex='cd $SP_SYS_BINDIR'
        alias golog='cd $SP_SYS_VARDIR/log'
        alias gocop='$SP_SYS_BINDIR/sp_cop -u$SP_COP_TPORT &'
        alias spprod='cd $SP_SYS_PRODDIR' 
        alias spbin='cd $SP_SYS_BINDIR' 
        alias spvar='cd $SP_SYS_VARDIR'
        alias splog='cd $SP_SYS_VARDIR/log'
        alias spscr='cd $SP_SYS_SCRIPT'
        alias spc='$SP_SYS_BINDIR/sp_ctrl'

        PATH=$SP_SYS_BINDIR:$PATH; export PATH
}
function plex2200
{
        #ORACLE_SID=SIONPS1; export ORACLE_SID
        SP_COP_UPORT=2200; export SP_COP_UPORT
        SP_COP_TPORT=2200; export SP_COP_TPORT
        SP_SYS_HOST_NAME=`uname -n`; export SP_SYS_HOST_NAME
        SP_SYS_HOST_NAME=osboxes; export SP_SYS_HOST_NAME
        SP_SYS_VARDIR=/Quest//vardir/2200; export SP_SYS_VARDIR
        SP_HOME=/Quest/; export SP_HOME
        SP_LIB_PATH=/Quest//lib; export SP_LIB_PATH
        alias goplex='cd $SP_HOME/bin'
        alias golog='cd $SP_SYS_VARDIR/log'
        alias gocop='$SP_HOME/bin/sp_cop -u2200 &'
        PATH=$SP_HOME/bin:$PATH; export PATH
}
splex
