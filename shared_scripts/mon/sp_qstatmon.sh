#!/bin/ksh
#
# @(#) $Header: /project/splex/RCS/tools_Oracle/sp_qstatmon,v 1.9 2002/07/03 12:43:09 mike Exp $ 
# @(#) $Source: /project/splex/RCS/tools_Oracle/sp_qstatmon,v $
##############################################################################################################
#
#
#  Program Name:  sp_qstatmon.sh
#  Date Written:  17-Jan-2000
#  Written By:    Chandrika Shivanna
#  Enhanced By:   Peter Hom 
#                 Lootong Tan - 06-Nov-2007
#
#  Purpose: To monitor the Shareplex qstatus and report the backlog if it crosses the threshold 
#
##############################################################################################################
#
#  Usage:
#       sp_qstatmon.sh -b binary -v vardir -p port number -m mondir -o instance [-x integer] [-y integer] [-z integer]  [-e TRUE]
#
#       This is a script that will monitor the qstatus and look for backlogs in the "
#       poster and capture queues.  The following options are allowed:"
#
#       -b specifies the path to the directory for SharePlex binaries.
#       -v specifies the path to the appropriate variable directory for SharePlex.
#       -m specifies the path where the monitoring logs will be stored
#       -o specifies the Oracle instance that SharePlex is replicating from.
#       -p specifies the port number that the sp_cop is listening to on.
#       -x specifies the threshold of messages for capture queue.
#          This parameter is optional and if not specified defaults to 100.
#       -y specifies the threshold of messages for post queue (default=100).
#          This parameter is optional and if not specified defaults to 100.
#       -z specifies the threshold of messages for export queue (default=100).
#          This parameter is optional and if not specified defaults to 100.
#       -e specifies if require to send alert via email, if not omit this parameter.
#       &  If the program is not started as a background process then the user
#          will not regain control of the shell.
#
#  Dependencies:
#
#  Bugs:
#             None found or reported
#
##############################################################################################################
#
#  Modification:  
#  1) 06-Sep-2006 - LT (lootong.tan@quest.com)
#     - Changing hardcoded output file to variables and direct to centralized location "/log/monitor"
#     - By removing all hardcoded path, this script can be ran from any directory
#     - The most recent errors, if any, will be retained in the ".tmp" file and will not be removed
#  2) 06-Nov-2007 - LT (lootong.tan@quest.com)
#     - Created a USAGE function to display usage if insufficient or incorrect parameters has been entered
#  3) 14-Nov-2007 - LT (lootong.tan@quest.com)
#     - Added function to write errors into a status file and a centralized history log
#       beside just sending email
#  4) 13-Dec-2011 - LT (lootong.tan@quest.com)
#     - Added monitoring directory to be pass into the script as a parameter
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
    echo " sp_qstatmon.sh -b binary -v vardir -p port number -o instance [-x integer] [-y integer] [-z integer] [-e TRUE]"
    echo ""
    echo "This is a script that will monitor the qstatus and look for backlogs in the "
    echo "poster and capture queues.  The following options are allowed:"
    echo ""
    echo "   -b specifies the path to the directory for SharePlex binaries."
    echo "   -v specifies the path to the appropriate variable directory for SharePlex."
    echo "   -m specifies the path where the monitoring logs will be stored."
    echo "   -p specifies the port number that the sp_cop is replicating on."
    echo "   -o specifies the Oracle instance that SharePlex is replicating from."
    echo "   -x specifies the threshold of messages for capture queue (default=10,000)."
    echo "   -y specifies the threshold of messages for post queue (default=10,000)."
    echo "   -z specifies the threshold of messages for export queue (default=10,000)."
    echo "   -e specifies if require to send alert via email, if not omit this parameter."
    echo "-------------------------------------------------------------------------------"
}


# -----------------------------------------------------------------------

# Set up default values for the command line arguments in case not specified

mailopt=FALSE
portnum=2100
interval=60
capthreshold=10000
postthreshold=10000
expthreshold=10000


# If more than one person needs to get an e-mail notification than add the names below each separated
# by a space.
MailUserName='geertjan.frese@quest.com'
if [ "$MailUserName" = "yourname@yourcompany" ]
then
    echo "Please modify the script so it has a valid email address"
    exit 0
fi


# Make sure that the command line parameters are specified
if [ $# -eq 0 ]
then
    # call execute function to display usage message
    usage
    exit 1
fi


while getopts :b:v:o:m:p:x:y:z:e: option
do
    case "$option"
    in
        b)  splexbindir="$OPTARG"
            ;;
        v)  splexdatadir="$OPTARG"
            ;;
        m)  splexmondir="$OPTARG"
            ;;                
        o)  instance="$OPTARG"
            ;;
        p)  portnum="$OPTARG"
            ;;
        x)  capthreshold="$OPTARG"
            ;;
        y)  expthreshold="$OPTARG"
            ;;
        z)  postthreshold="$OPTARG"
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

# LT - 6 Nov 2007
# Check to see if the path the Shareplex binary directory was specified
if (test -z "$splexbindir" != 0)  then
    echo "Error...Please enter a valid SharePlex binary data directory path."
    exit 1
else
    SP_SYS_PRODDIR=$splexbindir
    export SP_SYS_PRODDIR
fi

# LT - 6 Nov 2007
splexbindir=$SP_SYS_PRODDIR

# Check to see if the path the Shareplex data directory was specified
if (test -z "$splexdatadir" !=0)  then
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
#if [ -z "$instance" ] 
#then
#    echo "Error...Please enter a valid Oracle SID."
#    exit 1
#fi

# LT - 6 Nov 2007
logmondir=$splexmondir
#tmpstatus=$splexmondir/sp_qstatusmon_${instance}_${portnum}.tmp
tmpstatus=$splexmondir/sp_qstatusmon_${portnum}.tmp

# Test to see if a number was specified for the capture threshold
echo $capthreshold |grep [A-Z]
# echo "The value for tstcap is" $?
if (test $? = 0) then
#    echo "This program expects the capture threshold to be a number."
#    echo "Please try again by specifying a number for capture threshold."
    capthreshold=10000
fi

# Test to see if a number was specified for the poster threshold
echo $postthreshold |grep [A-Z]
# echo "The value for tstport is" $?
if (test $? = 0) then
#    echo "This program expects the poster threshold to be a number."
#    echo "Please try again by specifying a number for poster threshold."
    postthreshold=10000
fi

# Test to see if a number was specified for the export threshold
echo $expthreshold |grep [A-Z]
# echo "The value for tstport is" $?
if (test $? = 0) then
#    echo "This program expects the export threshold to be a number."
#    echo "Please try again by specifying a number for the export threshold."
    expthreshold=10000
fi
# setting up history file and alert file
alertFile=${logmondir}/sp_qstatusmon_${portnum}_alert.log
portHistFile=${logmondir}/sp_alert_${portnum}_history.log
centralHistFile=${logmondir}/sp_alert_history.log

# ======================================================================

    # LT - 6 Nov 2007 - add path for temporary status file
    echo -e "port " $portnum  "\nqstatus" | $splexbindir/sp_ctrl > $tmpstatus 2>&1
 #tmpstatus=test.log
    porterror=`grep "Backlog" $tmpstatus`
    if (test "$porterror" = "")
    then
        echo "The port specified is incorrect or the sp_cop is not running on port" $portnum 
        echo "Please verify the port number and start the program again!"
        exit 1
    else

        # ++++++++++++++++++++++++++++++++++++++++++++++++++
        alert=0
        correctQ=0
        cat $tmpstatus |while read line1
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
                                
                # if d is non-zero, then it is a Poster line
                if [ -n "$d" ]
                then
                    s2t=`echo $line1 | awk '{print $3}'`
                    src2target=`echo $s2t | tr -d '()'`
                    source=`echo $src2target | awk -F'-' '{print $1}'`
                    target=`echo $src2target | awk -F'-' '{print $2}'`
		else
		    continue
                fi            
            fi

            case $d in
            Export*|Capture*|Post*|MTPost*)
		correctQ=0
                qtype=`echo $d |cut -d' ' -f1`
                qname=`echo $line1 |awk '{print $2}'`
                ;;
            
            messages*)
		correctQ=1
                msg=`echo $d | cut -d: -f2 |tr -d ' '`
                case $qtype in 
          	    Export)
                        threshold=$expthreshold
                        ;;
          	    Post|MTPost)
                        threshold=$postthreshold
                        ;; 
          	    Capture)
                        threshold=$capthreshold 
                 	;;
          	    esac    # end of determining what messages those are for
                ;;

            esac    # end of filter messages from qstatus

            if [ $correctQ -eq 1 ]
            then
                if [ $msg -gt $threshold ] 
                then
                    ((alert+=1))
                    # getting and formatting current date
                    xlsdate=`date "+%Y-%b-%e %H:%M:%S" `
                    xlsccyymmdd=`date "+%Y%m%d"`
                    xlstime=`date "+%H:%M:%S"`

                    # Preparing specific error messages for Capture-Export Q OR Poster Q
                    case $qtype in
                    Export*|Capture*)
                        errMsg="[$xlsccyymmdd $xlstime] $qtype queue (queue name=$qname) has $msg backlog messages which exceeded the predefined threshold of $threshold for SharePlex on port $portnum!"
                            ;;

                    Post*|MTPost*)
                        errMsg="[$xlsccyymmdd $xlstime] $qtype queue (queue name=$qname, $source replicating to $target) has $msg backlog messages which exceeded the predefined threshold of $threshold for SharePlex on port $portnum!"
                        ;;
                    esac    # end of preparing message for Capture-Export Q or Poster Q

                    # overwrite alert file if 1st alert during this round of check
                    # otherwise append subsequent error into the same alert file
                    # e.g. if Capture and Poster exceeded thresholds at the same time
		    #echo $errMsg
                    if [ $alert -eq 1 ]
                    then
                        echo $errMsg > $alertFile
                    else
                        echo $errMsg >> $alertFile
                    fi


                    echo $errMsg >> $portHistFile
                    echo $errMsg >> $centralHistFile

                    # output to both alert file (only one line) and history file (appended)
                    # please note that history file will grow significantly when the backlog
                    # exceeded the threshold, there will be one alert line every # seconds
                    # depending on the polling frequencies

                fi  # end of if backlog is > threshold
                

            fi  # end of if we can get an alert status

        done    # 

    fi  # end of if there's error executing qstatus

if [ -f "$alertFile" ]
then
  if [ "$mailopt" = "TRUE" ]
  then
##### mailx -s"SharePlex on $portnum ,$qtype Queue's backlog threshold exceeded!" $MailUserName < $alertFile
    echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_qstatmon.sh file]."
    if (test $? = 1) then
        echo "Error with your mailx program. Please verfiy that it is functioning properly! " >> $alertFile
        exit 1
    fi
  fi  # end of if need to send email
  rm $alertFile
fi
# end of script

