#!/bin/ksh
#
##############################################################################################################
#
#  Program Name:  sp_psmon.sh
#  Date Written:  14-Nov-2007
#  Written By:    Lootong Tan
#
#  Purpose:       To monitor whether all the required SharePlex processes are running
#
##############################################################################################################
#    
#  Usage:
#       - old - sp_psmon.sh -b binary -v vardir -p port number -o instance -u uname
#       sp_psmon.sh -b $SP_SYS_BINDIR -v $SP_SYS_VARDIR -m $SP_MONDIR -p $SP_COP_TPORT -u SPLEX_UNAME -o ORACLE_SID -e $PLS_MAIL
#       where
#           -b specifies the path to the directory for SharePlex binaries.
#           -v specifies the path to the appropriate variable directory for SharePlex.
#           -m specifies the path where the monitoring logs will be stored."    
#           -p specifies the port number that the sp_cop is replicating on.
#           -o specifies the Oracle instance that SharePlex is replicating from.
#           -u specifies the Unique Identifier given to the sp_cop when it was first executed
#              with the -u notation and typically it is 
#              the port number that particular sp_cop is listening on OR
#              the Oracle SID it is replicating from.
#           -e to send email or not
#              (each separated by a comma e.g. a@quest.com, b@quest.com)
#
#  Dependencies:
#       Each replicating sp_cop must be assigned an Unique Identifier upon startup 
#       i.e. unix_prompt> sp_cop -uXXXX
#       where XXXX is the given Unique Identifier, usually either 
#       the Source Replicating Database instance name (Oracle_Sid) is used
#       OR
#       the port number of the Replicating Instance
#
#  Bugs:
#             None found or reported
#
############################################################################################################
#
#  Modification:  
#  
#  1) 24-Dec-12 - LT (lootong.tan@quest.com)
#               - Added Monitoring directory to be passed into this script
#
############################################################################################################

# --------------------------------------------------------------------------------
# function to display the usage if insufficient or invalid parameters were entered
# --------------------------------------------------------------------------------
function usage
{
    echo "-------------------------------------------------------------------------------"
    echo ""
    echo " sp_psmon.sh -b binary -v vardir -m mondir -p port number -u uname -o instance -e email_or_not"
    echo ""
    echo "This is a script that will monitor the Process Status and check if any of the"
    echo "required processes are not running. The following options are allowed:"
    echo ""
    echo "   -b specifies the path to the directory for SharePlex binaries."
    echo "   -v specifies the path to the appropriate variable directory for SharePlex."
    echo "   -m specifies the path where the monitoring logs will be stored."    
    echo "   -p specifies the port number that the sp_cop is replicating on."
    echo "   -o specifies the Oracle instance that SharePlex is replicating from."
#    echo "   -u specifies the Unique Identifier given to the sp_cop when it was first executed"
#    echo "      with the -u notation and typically it is "
#    echo "      the port number that particular sp_cop is listening on OR"
#    echo "      the Oracle SID it is replicating from."
    echo "   -e to email or not"
    echo "      (emails should be separated by a comma e.g. a@quest.com, b@quest.com)"
    echo " "
    echo "-------------------------------------------------------------------------------"
}


# Set up default values for the command line arguments in case not specified
MailUserName='tony.liu@software.dell.com lootong.tan@software.dell.com'

# Check to see if the command line arguments were specified correctly
if (test $# -lt 5)
then
    # call execute function to display usage message
    usage
    exit 1
fi

# get input from user or from another script
while getopts :u:b:v:o:p:m:e: option
do  
    case "$option"
    in
        u)  splexuname="$OPTARG"
            ;;
        b)  splexbindir="$OPTARG"
            ;;
        v)  splexdatadir="$OPTARG"
            ;;
        m)  splexmondir="$OPTARG"
            ;;            
        p)  portnum="$OPTARG"
            ;;
	o)  instance="$OPTARG"
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
done    # end of processing inputs


#echo $mailopt

# Check to see if the path the Shareplex binary directory was specified
if (test -z "$splexbindir" !=0)  then
    echo "Error...Please enter a valid SharePlex binary data directory path."
    exit 1
else
    SP_SYS_PRODDIR=$splexbindir
    export SP_SYS_PRODDIR
fi

MAILCMD=/usr/bin/mailx
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

# Check to see if the Oracle Instance was specified
#if ! test -n "$instance"  
#then
#   echo "Error...Please enter a valid Oracle SID."
#   exit 1
#fi

# Check to see if the SP_SYS_HOST_NAME was specified
#if ! test -n "$splexhostname"  
#then
#   echo "Error...Please enter a valid Oracle SID."
#   exit 1
#else 
#   export SP_SYS_HOST_NAME=$splexhostname
#fi

#splexmondir=${SP_SYS_VARDIR}/monitor
tmpstatus=${splexmondir}/sp_psmon_${instance}_${portnum}.tmp


# Check to see if the SharePlex Unique Identifier was specified
if ! test -n "$splexuname"  
then
    echo "Error...Please enter a valid SharePlex Unique Identifier."
    echo "It is the value behind the -u when starting up sp_cop process."
    echo "i.e. if sp_cop -u3100, then 3100 is the Unique Identifier required as this parameter."
    exit 1
fi


copname="sp_cop -u${splexuname}"

# Checking for SharePlex parent process sp_cop
coppid=`ps -ef| grep "$copname" |grep -v grep |awk 'NR==1 {print $2}'`

# getting and formatting current date
xlsdate=`date "+%Y-%b-%e %H:%M:%S" `
xlsccyymmdd=`date "+%Y%m%d"`
xlstime=`date "+%H:%M:%S"`

# setting up history file and alert file
alertFile=${splexmondir}/sp_psmon_${instance}_${portnum}_alert.log
portHistFile=${splexmondir}/sp_alert_${portnum}_history.log
centralHistFile=${splexmondir}/sp_alert_history.log


if (test "$coppid" = "")
then
    errMsg="[$xlsccyymmdd $xlstime] The sp_cop process for ${splexname} SharePlex instance is down. Please investigate! Please startup SharePlex before starting this script!"

# if require to change format
#   errMsg="$xlsccyymmdd,$xlstime,$portnum,$instance,$splexname,sp_cop"

    echo $errMsg >  $alertFile
    echo $errMsg >> $portHistFile
    echo $errMsg >> $centralHistFile
    exit 1
fi

# ======================================================================

echo -e "port " $portnum  "\nshow" | $splexbindir/sp_ctrl > $tmpstatus 2>&1

# 01 -sp_ctrl (RG110:5600)> show
# 02 -
# 03 -Process    Source                   Target       State                   PID
# 04 ----------- ------------------------ ------------ -------------------- ------
# 05 -Capture    o.ql_prdhk                            Running              2875524
# 06 -Capture    o.qlstarss                            Running              2584814
# 07 -Capture    o.qlprdhk1                            Running              2572460
# 08 -Read       o.ql_prdhk                            Running              2859198
# 09 -MTPost     o.ql_prdhk-ql_prdhk      o.qlprdhk1   Running              2977966
# 10 -MTPost     o.ql_prdhk-ql_prdhk      o.qlstarss   Stopped - due to error
# 11 -Read       o.qlprdhk1                            Running              2576484
# 12 -MTPost     o.qlprdhk1-qlprdhk1      o.ql_prdhk   Running              2969770
# 13 -Read       o.qlstarss                            Running              2871466
# 14 -MTPost     o.qlstarss-qlstarss      o.ql_prdhk   Running              2965672

#OR

#sp_ctrl (igsdbp07:2500)> show
#
#Process    Source                   Target       State                   PID
#---------- ------------------------ ------------ -------------------- ------
#Import     igsap1                   igsdbp07     Running               11384
#MTPost     o.IGSAP-LOBQ1            o.IGSAP      Running               23623
#MTPost     o.IGSAP-IGSOQ1           o.IGSAP      Running               23622
#MTPost     o.IGSAP-IGSOQ2           o.IGSAP      Running               18665
#MTPost     o.IGSAP-IGSOQ3           o.IGSAP      Running               18666


STOPSTATE=Stop

cat $tmpstatus |while read line1
do  
    spprocess=`echo $line1 | awk '/Capture|Read|Export|Import|Post|MTPost/ {print $1}'`

    case $spprocess 
    in
        Capture)
            sourceDB=`echo $line1 | awk '{print $2}'`

            # if this Capture Source is the one we are monitoring
            if [ "$sourceDB" = "o.${instance}" ]
            then
                state=`echo $line1 | awk '{print $3}'`
                stopstate=`echo $state |cut -c1-4`
            
                if [ "$stopstate" = "$STOPSTATE" ]
                then
                    capErr="[$xlsccyymmdd $xlstime] $spprocess process SourceDB:${sourceDB} has $state for SharePlex sp_cop ProcessID $coppid on port $portnum!"
                else
                    capErr=""
                fi
            fi
            ;;

        Read)
            sourceDB=`echo $line1 | awk '{print $2}'`

            # if this Reader Source is the one we are monitoring
            if [ "$sourceDB" = "o.${instance}" ]
            then
                state=`echo $line1 | awk '{print $3}'`

                stopstate=`echo $state |cut -c1-4`
            
                if [ "$stopstate" = "$STOPSTATE" ]
                then
                    readErr="[$xlsccyymmdd $xlstime] $spprocess process of SourceDB:${sourceDB} has $state for SharePlex sp_cop ProcessID $coppid on port $portnum!"
                else
                    readErr=""
                fi
            fi
            ;; 

        Export)
            sourceHost=`echo $line1 | awk '{print $2}'`
            targetHost=`echo $line1 | awk '{print $3}'`
            state=`echo $line1 | awk '{print $4}'`

            stopstate=`echo $state |cut -c1-4`
            
            if [ "$stopstate" = "$STOPSTATE" ]
            then
                expErr="[$xlsccyymmdd $xlstime] $spprocess process replicating from Host:${sourceHost} to Host:${targetHost} has $state for SharePlex sp_cop ProcessID $coppid on port $portnum!"
            else
                expErr=""
            fi
            ;; 

        Import)
            sourceHost=`echo $line1 | awk '{print $2}'`
            targetHost=`echo $line1 | awk '{print $3}'`
            state=`echo $line1 | awk '{print $4}'`

            stopstate=`echo $state |cut -c1-4`
	    #echo "stopstate: $stopstate"
            
            if [ "$stopstate" = "$STOPSTATE" ]
            then
                impErr="[$xlsccyymmdd $xlstime] $spprocess process replicating from Host:${sourceHost} to Host:${targetHost} has $state for SharePlex sp_cop ProcessID $coppid on port $portnum!"
		echo "$impErr"
            else
                impErr=""
            fi
            ;; 

        Post|MTPost)
            targetDB=`echo $line1 | awk '{print $3}'`

            # if this someone is posting to the DB that we are monitoring
            if [ "$targetDB" = "o.${instance}" ]
            then
                sourcestr=`echo $line1 | awk '{print $2}'`
                sourceDB=`echo $sourcestr | awk -F'-' '{print $1}'`
                sourceHost=`echo $sourcestr | awk -F'-' '{print $2}'`

                state=`echo $line1 | awk '{print $4}'`

                stopstate=`echo $state |cut -c1-4`

                if [ "$stopstate" = "$STOPSTATE" ]
                then
                    postErr="[$xlsccyymmdd $xlstime] $spprocess process replicating from Host:$sourceHost SourceDB:${sourceDB} to TargetDB:${targetDB} has $state for SharePlex sp_cop ProcessID $coppid on port $portnum!"
                else
                    postErr=""
                fi
            fi
            ;; 

    esac    # end of preparing message for Capture-Export Q or Poster Q

done


alert=0

if (test -n "$capErr" = TRUE)
then
    ((alert+=1))
    echo $capErr >  $alertFile
    echo $capErr >> $portHistFile
    echo $capErr >> $centralHistFile
fi

if (test -n "$readErr" = TRUE)
then
    ((alert+=1))
    if [ $alert -eq 1 ]
    then
        echo $readErr >  $alertFile
    else
        echo $readErr >> $alertFile
    fi

    echo $readErr >> $portHistFile
    echo $readErr >> $centralHistFile
fi

if (test -n "$impErr" = TRUE)
then
    ((alert+=1))
    if [ $alert -eq 1 ]
    then
        echo $impErr >  $alertFile
    else
        echo $impErr >> $alertFile
    fi

    echo $impErr >> $portHistFile
    echo $impErr >> $centralHistFile
fi

if (test -n "$expErr" = TRUE)
then
    ((alert+=1))
    if [ $alert -eq 1 ]
    then
        echo $expErr >  $alertFile
    else
        echo $expErr >> $alertFile
    fi

    echo $expErr >> $portHistFile
    echo $expErr >> $centralHistFile
fi

if (test -n "$postErr" = TRUE)
then
    ((alert+=1))
    if [ $alert -eq 1 ]
    then
        echo $postErr >  $alertFile
    else
        echo $postErr >> $alertFile
    fi

    echo $postErr >> $portHistFile
    echo $postErr >> $centralHistFile
fi


# If there is at least one error, the alertFile will be generated
# then we need to send out emails/sms       
if [ -f "$alertFile" ]
then

    if [ "$mailopt" = TRUE ]
    then
	if [ "$MailUserName" = "yourname@yourcompany" ]
  	then
             echo "Please modify the script so it has a valid email address"
   	     exit 0
	fi
        MAILSUBJECT="$xlsccyymmdd-$xlstime: Errors in SharePlex Processes on $SP_SYS_HOST_NAME!"

####        $MAILCMD -s"$MAILSUBJECT"  $MailUserName < $alertFile
echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_psmon.sh file]."
        if (test $? = 1) 
        then
            echo "Error with your mailx program. Please verfiy that it is functioning properly! "
            exit 1
        #else
        #    echo "Mail should be sent"
        fi
    
    fi  # if require to email
    
    #remove alert file to prevent false alarm on the next check
    rm $alertFile
else
    doNothing=TRUE
    #echo "Can't find alert file, maybe no errors"
fi

# end of script
