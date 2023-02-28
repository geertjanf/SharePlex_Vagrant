#!/bin/ksh
#
##############################################################################################################
#
#  Program Name:  sp_capreadstats.sh
#  Date Written:  16-Nov-2007
#  Written By:    LooTong Tan
#  Purpose:       To log the capture and reader statistics periodically to 
#                 track what time capture falls behind and also to measure reader key fetching speed
#
##############################################################################################################
#
#  Usage:
#       sp_capreadstats.sh -b binary -v vardir -m mondir -p port number [-e TRUE]
#       where
#           -b specifies the path to the directory for SharePlex binaries.
#           -v specifies the path to the appropriate variable directory for SharePlex.
#           -m specifies the path where the monitoring logs will be stored
#           -p specifies the port number that the sp_cop is replicating on.
#           -e specifies if require to send alert via email, if not omit this parameter.
#            & If the program is not started as a background process then the user
#              will not regain control of the shell.
#
#  Dependencies:
#           The script uses mailx program to send e-mails. Before using the script make
#           sure the mailx is configured on the host on which this script will be deployed
#           and can successfully send mail.
#
#  Bugs:
#           None found or reported
#
##############################################################################################################
#
#  Modification:  
#  1) 21-Dec-07 - LT (lootong.tan@quest.com)
#     - Change file extension of statistic log file to ".csv" instead of ".log" for ease of porting to Excel.
#     - Added function to attach this statistical file to an email and mail out wia mailx to the 
#       designated user
#  2) 13-Dec-11 - LT (lootong.tan@quest.com)
#     - Added monitoring directory to be passed into the script as a parameter
#     - Added new statistics from read internal
#     - Added backlog statistics from qstatus
#
############################################################################################################


# --------------------------------------------------------------------------------
# function to display the usage if insufficient or invalid parameters were entered
# --------------------------------------------------------------------------------
# LT - 6 Nov 2007
function usage
{
    echo "-------------------------------------------------------------------------------"
    echo ""
    echo " sp_capreadstats.sh -b binary -v vardir -m mondir -p port number [-e TRUE]"
    echo ""
    echo "This is a script that will monitor the Capture and Reader details  "
    echo "and log them into a file.  The following options are allowed:"
    echo ""
    echo "   -b specifies the path to the directory for SharePlex binaries."
    echo "   -v specifies the path to the appropriate variable directory for SharePlex."
    echo "   -m specifies the path where the monitoring logs will be stored."
    echo "   -p specifies the port number that the sp_cop is replicating on."
    echo "   -e specifies if require to send alert via email, if not omit this parameter."
    echo "-------------------------------------------------------------------------------"
}
    

# Set up default values for the command line arguments in case not specified
mailopt=FALSE
portnum=2100
interval=60
commandInterval=2

# If more than one person needs to get an e-mail notification than add the names below each separated
# by a space.
MailUserName='geertjan.frese@quest.com'
if [ "$MailUserName" = "yourname@yourcompany" ]
then
    echo "Please modify the script so it has a valid email address"
    exit 0
fi

# validate command line options

while getopts :b:v:p:t:m:e:i: option
do
    case "$option"
    in
        b)  splexbindir="$OPTARG"
            ;;
        v)  splexdatadir="$OPTARG"
            ;;
        m)  splexmondir="$OPTARG"
            ;;    
        p)  portnum="$OPTARG"
            ;;
        t)  interval="$OPTARG"
            ;;
        e)  if [ "$OPTARG" = "TRUE" ] 
            then            
                mailopt=TRUE
            else
                mailopt=FALSE
            fi
            ;;
        \?) echo " "
            # call execute function to display usage message
            usage
            exit 1
            ;;
    esac
done


# set required environmental profile
#. /dks001/shareplex/prod/splex$portnum.profile

#vardir=/dko301/shareplex/data/vardir$portnum
monlogdir=$splexmondir
tmpcapstatus=$monlogdir/sp_capstats_$portnum.tmp
tmpreadstatus=$monlogdir/sp_readstats_$portnum.tmp
tmpqstatus=$monlogdir/sp_qstats_$portnum.tmp
#spmaillog=$monlogdir/sp_readmail_$portnum.txt
spcapstatslog=$monlogdir/sp_capstats_$portnum.csv
spreadstatslog=$monlogdir/sp_readstats_$portnum.csv
spcapreadstatslog=$monlogdir/sp_capreadstats_$portnum.csv

#echo 'splexbindir    :[' $splexbindir ']'
#echo 'vardir         :[' $splexdatadir ']'
#echo 'mondir         :[' $splexmondir ']'
#echo 'portnum        :[' $portnum ']'
#echo 'interval       :[' $interval ']'
#echo 'tmpreadstatus  :[' $tmpreadstatus ']'
#echo 'spmaillog      :[' $spmaillog ']'
#echo 'spcapstatslog  :[' $spcapstatslog ']'


# Now that the validation is complete starting processing the information
#while :
#do

# remember the date
#

logdate=`date`

# collect stats
#
echo -e "port " $portnum  "\nshow capture detail" | $splexbindir/sp_ctrl > $tmpcapstatus 2>&1
#sleep $commandInterval

# 01 -sp_ctrl (apsgp49x:5500)> show capture detail
# 02 -
# 03 -Host: apsgp49x
# 04 -                           Operations
# 05 -Source     Status            Captured Since
# 06 ----------- --------------- ---------- ------------------
# 07 -o.AQ5      Running            5120210 12-Dec-11 18:30:15
# 08 -
# 09 -   Oracle current redo log          : 183109
# 10 -   Capture current redo log         : 183109
# 11 -   Capture log offset               : 241889032
# 12 -   Last redo record processed:
# 13 -        Operation on "SAPR3"."EDIDS" at 12/13/11 12:55:36
# 14 -
# 15 -   Capture state                    : Processing
# 16 -   Activation id                    : 3
# 17 -   Error count                      : 0
# 18 -   Operations captured              : 5120210
# 19 -   Transactions captured            : 387294
# 20 -
# 21 -   Concurrent sessions              : 3
# 22 -   HWM concurrent sessions          : 13
# 23 -   Checkpoints performed            : 569
# 24 -   Total operations processed       : 3975649
# 25 -   Total transactions completed     : 501083
# 26 -   Total Kbytes read                : 9651468
# 27 -
# 28 -   Redo records in progress         : 3
# 29 -   Redo records processed           : 8606137
# 30 -   Redo records ignored             : 4504645
# 31 -   Redo records - last HRID         : AAA2ITAGeAAAUMNAAV
# 32 -

    oralog=`grep 'Oracle current redo log'  $tmpcapstatus | sed -e 's/.*: //'`
    caplog=`grep 'Capture current redo log' $tmpcapstatus | sed -e 's/.*: //'`
    capoffset=`grep 'Capture log offset' $tmpcapstatus | sed -e 's/.*: //'`
    opsdtm=`grep ' Operation on '  $tmpcapstatus`

    actID=`grep 'Activation id' $tmpcapstatus | sed -e 's/.*: //'`
    opsCaptured=`grep 'Operations captured' $tmpcapstatus | sed -e 's/.*: //'`
    txnCaptured=`grep 'Transactions captured' $tmpcapstatus | sed -e 's/.*: //'`
    conSess=`grep 'Concurrent sessions' $tmpcapstatus | sed -e 's/.*: //'`
    HWMconSess=`grep 'HWM concurrent sessions' $tmpcapstatus | sed -e 's/.*: //'`

    # calculate the difference
    #
    logdiff=`expr ${oralog} - ${caplog}`
    captxndate=`echo $opsdtm | awk '{last2=NF-1; print $last2}'`
    captxntime=`echo $opsdtm | awk '{print $NF}'`

#    echo 'line09                    [' $oralog ']'
#    echo 'line10                    [' $caplog ']'
#    echo '-> line9-line10 lag       [' $logdiff ']'
#    echo 'Log Offset #              [' $capoffset ']'
#    echo 'line13 Current Ops        [' $opsdtm ']'
#    echo '- Current Ops Date        [' $captxndate ']'
#    echo '- Current Ops Time        [' $captxntime ']'
#    echo 'line16 Activation ID      [' $actID ']'
#    echo 'line18 Ops Captured       [' $opsCaptured ']'
#    echo 'line19 Txn Captured       [' $txnCaptured ']'
#    echo 'line21 Concurrent Sessions[' $conSess ']'
#    echo 'line22 HWM Conc Sessions  [' $HWMconSess ']'

    #date "+%a %b %e %H:%M:%S %Z %Y"

    xlsdate=`date "+%Y-%b-%e %H:%M:%S" `
    #echo 'xlsdate [' $xlsdate ']'
    xlsyymmdd=`date "+%Y%m%d"`
    xlstime=`date "+%H:%M:%S"`

#echo "$xlsdate,$captxndate,$captxntime,$oralog,$caplog,$capoffset,$logdiff,$actID,$opsCaptured,$txnCaptured,$conSess,$HWMconSess,$xlsyymmdd,$xlstime"
if [ -f $spcapstatslog ]; then
   echo "$xlsdate,$captxndate,$captxntime,$oralog,$caplog,$capoffset,$logdiff,$actID,$opsCaptured,$txnCaptured,$conSess,$HWMconSess,$xlsyymmdd,$xlstime" >> $spcapstatslog 2>&1
else
   echo "xlsdate,captxndate,captxntime,oralog,caplog,capoffset,logdiff,actID,opsCaptured,txnCaptured,conSess,HWMconSess,xlsyymmdd,xlstime" >> $spcapstatslog 2>&1 
   echo "$xlsdate,$captxndate,$captxntime,$oralog,$caplog,$capoffset,$logdiff,$actID,$opsCaptured,$txnCaptured,$conSess,$HWMconSess,$xlsyymmdd,$xlstime" >> $spcapstatslog 2>&1
fi

echo -e "port " $portnum  "\nshow read internal" | $splexbindir/sp_ctrl > $tmpreadstatus 2>&1
#sleep $commandInterval


# 01 -sp_ctrl (apsgp49x:5500)> show read internal
# 02 -
# 03 -Host: apsgp49x
# 04 -                           Operations
# 05 -Source     Status           Forwarded Since              Total      Backlog
# 06 ----------- --------------- ---------- ------------------ ---------- ----------
# 07 -o.AQ5      Running            5430592 12-Dec-11 18:30:16       1078       1078
# 08 -
# 09 -   Last operation forwarded:
# 10 -        Redo log: 183110     Log offset: 296477336
# 11 -        INSERT in SHAREPLEX internal table at 12/13/11 13:12:33
# 12 -
# 13 -   Read state                       : Idle
# 14 -   Activation id                    : 3
# 15 -   Snapshot too old count           : 0
# 16 -   Number of pass cycles            : 57003
# 17 -   Operations in last pass          : 102
# 18 -   Peak operations in a pass        : 118443
# 19 -
# 20 -   Operations forwarded             : 5430592
# 21 -   Transactions forwarded           : 393535
# 20 -
# 22 -   Full rollbacks                   : 68710
# 23 -   Full rollback operations skipped : 155526
# 24 -
# 25 -   Updates with complete key        : 726904
# 26 -   Updates with key in cache        : 0
# 27 -   Updates with key from Oracle     : 0
# 28 -
# 29 -   Cursor cache hit count           : 0
# 30 -   Cursor cache miss count          : 0
# 31 -   Number of open cursors           : 0
# 32 -
# 33 -   Number of active batches         : 5
# 34 -   Batch message total              : 1597013

    # grab the values from each line:
    line07=`grep 'Running'  $tmpreadstatus`
    line10=`grep 'Redo log:' $tmpreadstatus`
    line11=`grep ' at '  $tmpreadstatus`
    line20=`grep 'Operations forwarded             :' $tmpreadstatus | sed -e 's/.*: //'`
    line21=`grep 'Transactions forwarded           :' $tmpreadstatus | sed -e 's/.*: //'`
    line22=`grep 'Full rollbacks                   :' $tmpreadstatus | sed -e 's/.*: //'`
    line23=`grep 'Full rollback operations skipped :' $tmpreadstatus | sed -e 's/.*: //'`
    line25=`grep 'Updates with complete key        :' $tmpreadstatus | sed -e 's/.*: //'`
    line26=`grep 'Updates with key in cache        :' $tmpreadstatus | sed -e 's/.*: //'`
    line27=`grep 'Updates with key from Oracle     :' $tmpreadstatus | sed -e 's/.*: //'`
    line29=`grep 'Cursor cache hit count           :' $tmpreadstatus | sed -e 's/.*: //'`
    line30=`grep 'Cursor cache miss count          :' $tmpreadstatus | sed -e 's/.*: //'`
    line31=`grep 'Number of open cursors           :' $tmpreadstatus | sed -e 's/.*: //'`
    line33=`grep 'Number of active batches         :' $tmpreadstatus | sed -e 's/.*: //'`
    line34=`grep 'Batch message total              :' $tmpreadstatus | sed -e 's/.*: //'`

 
    totalmsg=`echo $line07 | awk '{print $6}'`
    backlogmsg=`echo $line07 | awk '{print $7}'`
    instance=`echo $line07 | awk '{print $1}'`
    redolog=`echo $line10 | awk '{print $3}'`
    readoffset=`echo $line10 | awk '{print $6}'`
#     numberofRecs=`echo $line11 | awk '{print NF}'`
if [ -n "$line11" ]; then
     readtxndate=`echo $line11 | awk '{last2=NF-1; print $last2}'`
     readtxntime=`echo $line11 | awk '{print $NF}'`
fi
#    readtxndate=`echo $line11 | awk '{print $5}}'`
#    readtxntime=`echo $line11 | awk '{print $6}'`
    opsfwdcnt=$line20
    txnfwdcnt=$line21
    fullrollback=$line22
    fullrollbackskipped=$line23    
    updfullkey=$line25
    updcachekey=$line26
    updoraclekey=$line27
    curhitcnt=$line29
    curmisscnt=$line30
    opencursors=$line31
    activebatch=$line33
    batchtotal=$line34

#echo 'line07                     [' $line07 ']'
#echo '- Total Msgs               [' $totalmsg ']'
#echo '- Backlog Msgs             [' $backlogmsg ']'
#echo 'line10 Redo                [' $line10 ']'
#echo '- Redo Log #               [' $redolog ']'
#echo '- Offset #                 [' $readoffset ']'
#echo 'line11 Current Ops         [' $line11 ']'
#echo '- Current Ops Date         [' $readtxndate ']'
#echo '- Current Ops Time         [' $readtxntime ']'
#echo '- NF                       [' $numberofRecs ']'
#echo 'line20 Ops Fwd             [' $opsfwdcnt ']'
#echo 'line21 Txn Fwd             [' $txnfwdcnt ']'
#echo 'line22 Full Rollback       [' $fullrollback ']'
#echo 'line23 Full Rollback Skip  [' $fullrollbackskipped ']'
#echo 'line25 Upd Full key        [' $updfullkey ']'
#echo 'line26 Upd Key Cache       [' $updcachekey ']'
#echo 'line27 Upd Key Oracle      [' $updoraclekey ']'
#echo 'line29 Cursor hit count    [' $curhitcnt ']'
#echo 'line30 Cursor miss count   [' $curmisscnt ']'
#echo 'line31 Open cursors        [' $opencursors ']'
#echo 'line33 Active batches      [' $activebatch ']'
#echo 'line34 Batch Message Total [' $batchtotal ']'

#echo "$xlsdate,$readtxndate,$readtxntime,$totalmsg,$backlogmsg,$redolog,$readoffset,$opsfwdcnt,$txnfwdcnt,$updfullkey,$updcachekey,$updoraclekey,$curhitcnt,$curmisscnt,$opencursors,$xlsyymmdd,$xlstime"

if [ -f $spreadstatslog ]; then
    echo "$xlsdate,$readtxndate,$readtxntime,$totalmsg,$backlogmsg,$redolog,$readoffset,$opsfwdcnt,$txnfwdcnt,$fullrollback,$fullrollbackskipped,$updfullkey,$updcachekey,$updoraclekey,$curhitcnt,$curmisscnt,$opencursors,$activebatch,$batchtotal,$xlsyymmdd,$xlstime" >> $spreadstatslog 2>&1
else
    echo "xlsdate,readtxndate,readtxntime,totalmsg,backlogmsg,redolog,readoffset,opsfwdcnt,txnfwdcnt,fullrollback,fullrollbackskipped,updfullkey,updcachekey,updoraclekey,curhitcnt,curmisscnt,opencursors,activebatch,batchtotal,xlsyymmdd,xlstime" >> $spreadstatslog 2>&1 
    echo "$xlsdate,$readtxndate,$readtxntime,$totalmsg,$backlogmsg,$redolog,$readoffset,$opsfwdcnt,$txnfwdcnt,$fullrollback,$fullrollbackskipped,$updfullkey,$updcachekey,$updoraclekey,$curhitcnt,$curmisscnt,$opencursors,$activebatch,$batchtotal,$xlsyymmdd,$xlstime" >> $spreadstatslog 2>&1
fi
    echo -e "port " $portnum  "\nqstatus" | $splexbindir/sp_ctrl > $tmpqstatus 2>&1
    porterror=`grep "Backlog" $tmpqstatus`

    if (test "$porterror" = "")
    then
        echo "The port specified is incorrect or the sp_cop is not running on port" $portnum 
        echo "Please verify the port number and start the program again!"
        exit 1
    else

        # ++++++++++++++++++++++++++++++++++++++++++++++++++
        alert=0
        correctQ=0
        linecount=0

        cat $tmpqstatus |while read line1
        do  
            # LT - 06 Nov 2007
            # Added MTPost into the string of strings to AWK
    	    d=`echo $line1 | awk -F'(' '/Export|Capture|Backlog/ {print $2}'`

            # if d is zero in length
            if [ -z "$d" ]
            then
                # if it is not Export or Capture or Backlog status line, 
                # check if it is a Post status line

                d=`echo $line1 | awk -F'(' '/Post|MTPost/ {print $3}'`
                                
                # f d is non-zero, then it is a Poster line
                if [ -n "$d" ]
                then
                    s2t=`echo $line1 | awk '{print $3}'`
                    src2target=`echo $s2t | tr -d '()'`
                    source=`echo $src2target | awk -F'-' '{print $1}'`
                    target=`echo $src2target | awk -F'-' '{print $2}'`
                fi            
            fi

            case $d in
            Export*|Capture*|Post*|MTPost*)
                qtype=`echo $d |cut -d' ' -f1`
                qname=`echo $line1 |awk '{print $2}'`
                ;;
            
            messages*)
                backlogmsg=`echo $d | cut -d: -f2 |tr -d ' '`

                case $qtype in 
          	    Export)
                        threshold=$expthreshold

                        # LT - 6 Nov 2007
                        # got the instance that we want so quit
                        if [ "$qname" = "$instance" ]
                        then
                            correctQ=1
                        fi
                        ;;
          	    Post|MTPost)
                        threshold=$postthreshold

                        # LT - 6 Nov 2007
                        # got the instance that we want so quit

                        if [ "$qname" = "$instance" ]
                        then
                            correctQ=1
                        fi
                        ;; 
          	    Capture)
                        threshold=$capthreshold 

                        # LT - 6 Nov 2007
                        # got the instance that we want so quit
                        # e.g 
                        # Name:  o.ql_prdhk (Capture queue)
                        # Name:  o.qlprdhk1 (Capture queue)
                        # Name:  o.qlstarss (Capture queue)

                        if [ "$qname" = "o.${instance}" ]
                        then
                            correctQ=1
                        fi
                 	;;
          	    esac    # end of determining what messages those are for
                ;;

            esac    # end of filter messages from qstatus
        done    #  end of checking which queue
    fi  # end of if there's error executing qstatus

# check for disk space available
oscheck=`uname|grep -i linux|wc -l`
if [ $oscheck -eq 1 ];then
#  echo "os is linux"
  spaceleftKB=`df | grep sda1 | awk '{print $4}'`
  percentused=`df | grep sda1 | awk '{print $5}'`
fi

oscheck=`uname|grep -i hp-ux|wc -l`
if [ $oscheck -eq 1 ];then
#  echo "os is hp-ux"
  spaceleftKB=`bdf | grep sda1 | awk '{print $4}'`
  percentused=`bdf | grep sda1 | awk '{print $5}'`
fi

oscheck=`uname|grep -i aix|wc -l`
if [ $oscheck -eq 1 ];then
  echo "os is aix"
fi

#spaceleftKB=`bdf | grep lvdata22 | awk '{print $4}'`
#percentleft=`bdf | grep lvdata22 | awk '{print $5}'`

spaceleftMB=`expr $spaceleftKB / 1024` 
spaceleftGB=`expr $spaceleftMB / 1024` 



# Put Capture Stats and Reader Stats into same line in capture-reader log file
if [ -f $spcapreadstatslog ]; then
    echo "$xlsdate,$captxndate,$captxntime,$oralog,$caplog,$capoffset,$logdiff,$actID,$opsCaptured,$txnCaptured,$conSess,$HWMconSess,$readtxndate,$readtxntime,$totalmsg,$backlogmsg,$redolog,$readoffset,$opsfwdcnt,$txnfwdcnt,$fullrollback,$fullrollbackskipped,$updfullkey,$updcachekey,$updoraclekey,$curhitcnt,$curmisscnt,$opencursors,$activebatch,$batchtotal,$backlogmsg,$spaceleftKB,$spaceleftMB,$spaceleftGB,$percentused,$xlsyymmdd,$xlstime" >> $spcapreadstatslog 2>&1
else
    echo "xlsdate,captxndate,captxntime,oralog,caplog,capoffset,logdiff,actID,opsCaptured,txnCaptured,conSess,HWMconSess,readtxndate,readtxntime,totalmsg,backlogmsg,redolog,readoffset,opsfwdcnt,txnfwdcnt,fullrollback,fullrollbackskipped,updfullkey,updcachekey,updoraclekey,curhitcnt,curmisscnt,opencursors,activebatch,batchtotal,backlogmsg,spaceleftKB,spaceleftMB,spaceleftGB,percentused,xlsyymmdd,xlstime" >> $spcapreadstatslog 2>&1 
    echo "$xlsdate,$captxndate,$captxntime,$oralog,$caplog,$capoffset,$logdiff,$actID,$opsCaptured,$txnCaptured,$conSess,$HWMconSess,$readtxndate,$readtxntime,$totalmsg,$backlogmsg,$redolog,$readoffset,$opsfwdcnt,$txnfwdcnt,$fullrollback,$fullrollbackskipped,$updfullkey,$updcachekey,$updoraclekey,$curhitcnt,$curmisscnt,$opencursors,$activebatch,$batchtotal,$backlogmsg,$spaceleftKB,$spaceleftMB,$spaceleftGB,$percentleft,$xlsyymmdd,$xlstime" >> $spcapreadstatslog 2>&1
fi
    if [ "$mailopt" = "TRUE" ] 
    then
        mailBodyMsg="This is the Capture & Reader statistics for $instance on $xlsyymmdd at $xlstime"

##needing uuencode command is available 
####        uuencode $spcapreadstatslog $spcapreadstatslog | mailx -s"Statistics for SharePlex Capture & Reader on $instance on $xlsdate" $MailUserName < $mailBodyMsg
echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_capreadstats.sh file]."

        if (test $? = 1) then
            echo "Error with your mailx program. Please verfiy that it is functioning properly! "
            exit 1
        fi
    fi  # end of if need to send email

#       sleep $interval
#done
