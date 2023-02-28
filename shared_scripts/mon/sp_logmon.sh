#!/bin/ksh
#
# @(#) $Header: /project/splex/RCS/tools_Oracle/sp_logmon,v 1.9 2002/04/19 14:29:23 cshivann Exp $
# @(#) $Source: /project/splex/RCS/tools_Oracle/sp_logmon,v $
##############################################################################################################
#
#
#  Program Name:  sp_logmon
#  Date Written:  23-Jan-00
#  Written By:    Chandrika Shivanna
#  Enhanced By:   Lootong Tan - 14-Nov-2007
#
#  Purpose: To monitor the redo log that Oracle is writing to and Shareplex is reading from and report it 
#
##############################################################################################################
#
#  Variables:
#       SP_SYS_BINDIR - generic SharePlex binary directory variable pointing to the binary directory
#       SP_SYS_VARDIR - generic SharePlex data directory variable pointing to the data directory
#       instance      - Oracle Database SID
#       portnum       - the TPC/IP port number that a particular SharePlex sp_cop is attached to
#       logthreshold  - number of redo logs that capture is lagging behind
#
#  Usage:
#       sp_logmon.sh -b binary -v vardir -p port number -h SP_SYS_HOSTNAME -o instance -m mailing list [-r integer]
#       where
#           -b specifies the path to the directory for SharePlex binaries."
#           -v specifies the path to the appropriate variable directory for SharePlex."
#           -h specifies the Host name of this server.
#           -o specifies the Oracle instance that SharePlex is replicating from.
#           -p specifies the port number that the sp_cop is replicating on."
#           -r specifies the value for the number of Oracle redo logs (default=2)."
#           -m specifies name of file with list of emails to send alerts to
#              (each separated by a comma e.g. a@quest.com, b@quest.com)
#
#  Dependencies:
#             The script uses mailx program to send e-mails. Before using the script make
#             sure the mailx is configured on the host on which this script will be deployed
#             and can successfully send mail.
#
#  Bugs:
#             None found or reported
#
############################################################################################################
#
#  Modification:  1) 06-Sep-06 - LT (lootong.tan@quest.com)
#                    - Changing hardcoded output file to variables and direct to centralized location
#                      "/log/monitor"
#                    - By removing all hardcoded path, this script can be ran from any directory
#                    - The most recent errors, if any, will be retained in the ".tmp" file and will not
#                      be removed
#                 2) 06-Nov-07 - LT (lootong.tan@quest.com)
#                    - Created a USAGE function to display usage if insufficient or incorrect parameters
#                      has been entered
#                 3) 14-Nov-07 - LT (lootong.tan@quest.com)
#                    - Replacing the mailx function to writing errors into a status file and a centralized
#                      histroy log
#                 4) 08-May-09 - LT (lootong.tan@quest.com)
#                    - Added ability to monitor for Oracle RAC, one node at a time
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
    echo " sp_logmon.sh -b binary -v vardir -p port number -h SP_SYS_HOSTNAME -o instance -m logdir -e TRUE -r number "
    echo ""
    echo "This is a script that will monitor the qstatus and look for backlogs in the "
    echo "poster and capture queues.  The following options are allowed:"
    echo ""
    echo "   -b specifies the path to the directory for SharePlex binaries."
    echo "   -v specifies the path to the appropriate variable directory for SharePlex."
    echo "   -p specifies the port number that the sp_cop is replicating on."
    echo "   -h specifies the Host name of this server."
    echo "   -o specifies the Oracle instance that SharePlex is replicating from."
    echo "   -r specifies the value for the number of Oracle redo logs (default=10)."
    echo "   -m specifies the path where the monitoring logs will be stored." 
    echo "   -e to email or not"
    echo "-------------------------------------------------------------------------------"
}


# Set up default values for the command line arguments in case not specified

mailopt=FALSE
portnum=2500
interval=60
logthreshold=10
MAILCMD=/usr/bin/mailx
MailUserName='geertjan.frese@quest.com gjfrese@gmail.com'


# Make sure that the command line parameters are specified
if (test $# -eq 0)
then
    # call execute function to display usage message
    usage
    exit 1
fi


# get input from user or from another script
while getopts :b:v:h:o:p:r:m:e: option
do
    case "$option"
    in
        b)  splexbindir="$OPTARG"
            ;;
        v)  splexdatadir="$OPTARG"
            ;;
        h)  splexhostname="$OPTARG"
            ;;
        o)  instance="$OPTARG"
            ;;
        p)  portnum="$OPTARG"
            ;;
        r)  logthreshold="$OPTARG"
            ;;
        e)  if [ "$OPTARG" = "TRUE" ] 
            then            
                mailopt=TRUE
            else
                mailopt=FALSE
            fi
            ;;
	m)  splexmondir="$OPTARG"
            ;;
        \?) echo " "
            # call execute function to display usage message
            usage
            exit 1
            ;;
    esac
done    # end of processing inputs


if (test -z "$splexhostname")  then
   splexhostname=`hostname`
fi

if (test -z "$MailUserName")  then
    echo "Error...Please enter a valid list of emails."
    exit 1
fi

# LT - 6 Nov 2007
# Check to see if the path the Shareplex binary directory was specified
#if (test -z "$splexbindir" !=0)  then
if (test -z "$splexbindir")  then
    echo "Error...Please enter a valid SharePlex binary data directory path."
    exit 1
else
    SP_SYS_PRODDIR=$splexbindir
    export SP_SYS_PRODDIR
fi

# LT - 6 Nov 2007
splexbindir=$SP_SYS_PRODDIR

# Check to see if the path the Shareplex data directory was specified
#if (test -z "$splexdatadir" !=0)  then
if (test -z "$splexdatadir")  then
    echo "Error...Please enter a valid SharePlex variable data directory path."
    exit 1
else
    SP_SYS_VARDIR=$splexdatadir
    export SP_SYS_VARDIR 
fi


# Test to see if a number was specified for the SharePlex port number
echo $portnum |grep [A-Z]
# echo "The value for tstport is" $?
if (test $? = 0) then
    echo "Error...This program expects the port number to be a number."
    echo "Please try again by specifying a number for the SharePlex port."
    exit 1
fi

# LT - 6 Nov 2007
# Check to see if the Oracle Instance was specified

# LT - 6 Nov 2007
logmondir=$splexmondir
tmpstatus=${logmondir}/sp_logmon_${portnum}.tmp

# Test to see if a number was specified for the redo log threshold
echo $logthreshold |grep [A-Z]
# echo "The value for tstcap is" $?
if (test $? = 0) 
then
    echo "This program expects the logthreshold to be a number."
    echo "Please try again by specifying a number for the redo log threshold."
    logthreshold=2 
fi

# ======================================================================

    # Start checking for Capture status

    #datasource=o.${instance}

    # LT - 6 Nov 2007 - add path for sp_ctrl
    # LT - 8 May 2009 - add command for Oracle RAC
    # for Oracle non-RAC
    # echo "port " $portnum  "\nshow capture detail for $datasource" | $splexbindir/sp_ctrl > $tmpstatus 2>&1
    # for Oracle RAC
    echo -e "port " $portnum  "\nshow capture detail" | $splexbindir/sp_ctrl > $tmpstatus 2>&1
    
    grep "Your tcp port is not set properly" $tmpstatus >/dev/null 2>&1

    if (test $? = 0)
    then
        echo
        echo "The port specified is incorrect or the sp_cop is not running on port" $portnum 
        echo "Please verify the port number and start the program again!"
        exit 1
    fi

    # The lines we care about look like this for a non-RAC Oracle:
    #
    #   Oracle current redo log          : 2710
    #   Capture current redo log         : 2700
    #
    # grab the values from each line:

    # The lines we care about look like this for an Oracle RAC
    #
    # sp_ctrl (igsap1:2500)> show capture detail
    # 
    # Host: igsap1.apis.dhl.com
    #                            Operations
    # Source     Status            Captured Since
    # ---------- --------------- ---------- ------------------
    # o.IGSAP    Running           10215248 06-May-09 17:59:20
    # 
    #    Log reader threads:
    # 
    #    Thread  Instance      Host          Oracle Log  Redo Log  Log Offset   Kbytes Read
    #    ------  ------------  ------------  ----------  --------  ------------  ------------
    #         1  IGSAP1        igsgbp05           12653     12652      71168744      20684908
    #         2  IGSAP2        igsgbp06           12261     12261      34881784      28260313
    # 
    #    Last redo record processed:
    #         Operation on "HPPROD"."YFS_ORDER_HEADER" at 05/08/09 08:30:10

# setting up history file and alert file
alertFile=${logmondir}/sp_logmon_${portnum}_alert.log
portHistFile=${logmondir}/sp_alert_${portnum}_history.log
centralHistFile=${logmondir}/sp_alert_history.log

# temporary testing file
#tmpstatus=test.log
isRAC=0
tmpstring=`cat $tmpstatus|grep -i thread|grep -i instance`
if [ -n "$tmpstring" ]; then
  isRAC=1  
fi

if [ $isRAC -eq 1 ]; then
    isbegin=0
    cat $tmpstatus |while read line1
    do
       #oraInstance=`echo $line1 | awk '{print $2}'`
       oraInstance=`cat $tmpstatus|grep "o\."|awk '{print $1}'`
       tmpstring=`echo $line1|grep -i thread|grep -i instance`
      if [ -z "$tmpstring" -a $isbegin -eq 0 ]; then
	  continue	
       else
	  isbegin=`expr $isbegin + 1`
	  if [ $isbegin -lt 3 ]; then
	     continue	
	  fi
       fi
       if [ ${#line1} -lt 5 -a $isbegin -gt 1 ]; then
         break
       fi
       # if [ "$oraInstance" = "$instance" ]
       # then
            currOraLog=`echo $line1 | awk '{print $4}'`
            captureLog=`echo $line1 | awk '{print $5}'`
            tmpinstance=`echo $line1 | awk '{print $2}'`
            tmphost=`echo $line1 | awk '{print $3}'`

#            echo "CurrOraLog [$currOraLog]  CaptureLog [$captureLog]"

            # calculate the difference
            #
            logdiff=`expr ${currOraLog} - ${captureLog}`

            if (test "$logdiff" -gt "$logthreshold")
            then
                # getting and formatting current date
                xlsdate=`date "+%Y-%b-%e %H:%M:%S" `
                xlsccyymmdd=`date "+%Y%m%d"`
                xlstime=`date "+%H:%M:%S"`

                #errMsg="[$xlsccyymmdd $xlstime] Capture process has fallen behind in capturing information from the Oracle redo log by ${logdiff} files, which exceeded the threshold of ${logthreshold} files for SharePlex on port ${portnum} on ${splexhostname} for database ${oraInstance}.  Corrective action is needed before the SharePlex falls too far behind and resynchronization will be necessary."
                errMsg="[$xlsccyymmdd $xlstime] Capture process has fallen behind Oracle redo log by ${logdiff} file  on port ${portnum} on ${tmphost} for database ${tmpinstance}."

                ####
                # if require to change format
                #        errMsg="$xlsccyymmdd,$xlstime,$portnum,$instance,$currOraLog,$captureLog,$logdiff,$threshold"

                echo $errMsg >> $alertFile
                echo $errMsg >> $portHistFile
                echo $errMsg >> $centralHistFile

            fi  # end of if SharePlex Capture falls behind Oracle > logthreshold

       # fi  # end of checking if we got the correct instance/nodes
    
    done  # end of processing capture details temp file
else
  # echo "is single node"
    oralog=`grep 'Oracle current redo log' $tmpstatus | sed -e 's/.*: //'`
    caplog=`grep 'Capture current redo log' $tmpstatus| sed -e 's/.*: //'`
    
    if [[ -z $oralog ]]; then
      oralog=0
    fi
    
    if [[ -z $caplog ]]; then
      caplog=0
    fi
    
    # calculate the difference
    #
    logdiff=`expr ${oralog} - ${caplog}`
    
    if (test "$logdiff" -gt "$logthreshold")
    then
	 oraInstance=`cat $tmpstatus|grep "o\."|awk '{print $1}'`	
	 errMsg="Capture process has fallen behind Oracle redo log by ${logdiff} file on port ${portnum} on $splexhostname for database ${oraInstance}."
	 echo $errMsg >> $alertFile 
	 cat $alertFile >> $portHistFile
	 cat $alertFile >> $centralHistFile
    else
    #    echo "Capture process is not falling behind" 
         rm sp_logmon.log  >/dev/null 2>&1
    fi
fi 


if [ -f "$alertFile" ]
then
   if [ "$mailopt" = "TRUE" ]
   then
      if [ "$MailUserName" = "yourname@yourcompany" ]
      then
          echo "Please modify the script so it has a valid email address"
          exit 0
      fi
      MAILSUBJECT="$xlsccyymmdd-$xlstime: SharePlex (port ${portnum}) may encounter a log wrap!"
####  $MAILCMD -s"$MAILSUBJECT"  $MailUserName < $alertFile
echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_logmon.sh file]."
      if (test $? = 1)
      then
          echo "Error with your mailx program. Please verfiy that it is functioning properly! "
          exit 1
      #else
      #    echo "Mail should be sent"
      fi
    fi
    #remove alert file to prevent false alarm on the next check
    rm $alertFile
else
    doNothing=TRUE
    #echo "Can't find alert file, maybe no errors"
fi


# end of script

