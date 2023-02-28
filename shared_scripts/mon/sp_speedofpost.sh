#!/bin/ksh
#
##############################################################################################################
#
#  Program Name:  sp_speedofpost.sh
#  Date Written:  16-OCT-2016
#  Written By:    tony.liu@quest.com
#  Purpose:       To check the speed at which transactions are filling into the Post Q and Posted  
#
##############################################################################################################
#
#  Usage:
#       sp_speedofpost.sh -b binary -v vardir -m mondir -p port -t interval number [-e TRUE]
#       where
#           -b specifies the path to the directory for SharePlex binaries.
#           -v specifies the path to the appropriate variable directory for SharePlex.
#           -m specifies the path where the monitoring logs will be stored
#           -p specifies the port number that the sp_cop is replicating on.
#           -t specified the interval for checking posted messages
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
#
############################################################################################################


# --------------------------------------------------------------------------------
# function to display the usage if insufficient or invalid parameters were entered
# --------------------------------------------------------------------------------
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
    echo "   -t specified the interval for checking posted messages."
    echo "   -e specifies if require to send alert via email, if not omit this parameter."
    echo "-------------------------------------------------------------------------------"
}
    

# Set up default values for the command line arguments in case not specified
mailopt=FALSE
portnum=2100
interval=60


# If more than one person needs to get an e-mail notification than add the names below each separated
# by a space.
MailUserName='tony.liu@quest.com'
if [ "$MailUserName" = "yourname@yourcompany" ]
then
    echo "Please modify the script so it has a valid email address"
    exit 0
fi


# validate command line options

while getopts :b:v:p:t:m:e: option
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



monlogdir=$splexmondir
sppostqstatslog_csv=$monlogdir/sp_speedofpost_$portnum.csv

#echo 'splexbindir    :[' $splexbindir ']'
#echo 'vardir         :[' $splexdatadir ']'
#echo 'mondir         :[' $splexmondir ']'
#echo 'portnum        :[' $portnum ']'
#echo 'interval       :[' $interval ']'



# Check to see if the path the Shareplex binary directory was specified
if (test -z "$splexbindir" != 0)  then
    echo "Error...Please enter a valid SharePlex binary data directory path."
    exit 1
else
    SP_SYS_PRODDIR=$splexbindir
    export SP_SYS_PRODDIR
fi

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

logmondir=$splexmondir
tmpstatus=$splexmondir/sp_speedofpost_${portnum}.tmp
tmpstatus2=$splexmondir/sp_speedofpost_${portnum}.tmp2

# setting up history file and alert file
alertFile=${logmondir}/sp_speedofpost_${portnum}_alert.log
portHistFile=${logmondir}/sp_alert_${portnum}_history.log
centralHistFile=${logmondir}/sp_alert_history.log

# ======================================================================

    echo -e "port " $portnum  "\nqstatus" | $splexbindir/sp_ctrl > $tmpstatus 2>&1
#tmpstatus=test.log
    porterror=`grep "Post queue" $tmpstatus`
    if (test "$porterror" = "")
    then
        echo "The post queue is not found on port" $portnum 
        echo "Please verify the port number and start the program again!"
        exit 1
    else
        # ++++++++++++++++++++++++++++++++++++++++++++++++++
        correctQ=0
        cat $tmpstatus |while read line1
        do  
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
			if [[ "$qtype" =~ "Post" ]]; then
			   correctQ=1
			   msg=`echo $d | cut -d: -f2 |tr -d ' '`
                        fi
			;;
            esac    # end of filter messages from qstatus
            if [ $correctQ -eq 1 ]
            then
		    # getting and formatting current date
		    xlsdate=`date "+%Y-%b-%e %H:%M:%S" `
		    xlsccyymmdd=`date "+%Y%m%d"`
		    xlstime=`date "+%H:%M:%S"`
                    echo -e "port " $portnum  "\nshow post detail queue $qname" | $splexbindir/sp_ctrl > $tmpstatus2 2>&1
	   	    poststart=`grep Running $tmpstatus2|head -n1|awk '{print $4,$5}'`
                    postedMes=`grep "Operations posted" $tmpstatus2|awk -F':' '{print $2}'`
                    postedTran=`grep "Transactions posted" $tmpstatus2|awk -F':' '{print $2}'`
		    postedrollbacks=`grep "Full rollbacks" $tmpstatus2|awk -F':' '{print $2}'`
                    postedrollbackOpe=`grep "Full rollback operations posted" $tmpstatus2|awk -F':' '{print $2}'`
                    postedsmalltran=`grep "Transactions <= 2" $tmpstatus2|awk -F':' '{print $2}'`
                    postedbigtran=`grep "Transactions > 10000" $tmpstatus2|awk -F':' '{print $2}'`
                    postedmaxtran=`grep "Largest transaction" $tmpstatus2|awk -F':' '{print $2}'`
                    postedInsert=`grep "Insert operations" $tmpstatus2|awk -F':' '{print $2}'`
                    postedUpdate=`grep "Update operations" $tmpstatus2|awk -F':' '{print $2}'`
                    postedDelete=`grep "Delete operations" $tmpstatus2|awk -F':' '{print $2}'`
		    lineTitle="xlsdate,source,target,queueType,queueName,starttime,interval(s),posted_message,posted_transaction,postedrollbacks,postedrollbackOpe,postedsmalltran,postedbigtran,postedmaxtran,postedInsert,postedUpdate,postedDelete,backlog"
		    linedata="$xlsdate,$source,$target,$qtype,$qname,$poststart,$interval,$postedMes,$postedTran,$postedrollbacks,$postedrollbackOpe,$postedsmalltran,$postedbigtran,$postedmaxtran,$postedInsert,$postedUpdate,$postedDelete,$msg"
		    if [ -f $sppostqstatslog_csv ]; then
		       echo "$linedata" >> $sppostqstatslog_csv
		    else
		       echo "$lineTitle" > $sppostqstatslog_csv
		       echo "$linedata" >> $sppostqstatslog_csv
                    fi
		    rm $tmpstatus2


            fi  # end of if we can get an alert status

        done    # 

    fi  # end of if there's error executing qstatus
    rm $tmpstatus

#if [ -f "$alertFile" ]; then
  if [ "$mailopt" = "TRUE" ]
  then
##### mailx -s"SharePlex on $instance $qtype Queue's backlog threshold exceeded!" $MailUserName < $sppostqstatslog_csv
    echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_speedofpost.sh file]."
    if (test $? = 1) then
        echo "Error with your mailx program. Please verfiy that it is functioning properly! " >> $alertFile
        exit 1
    fi
  fi  # end of if need to send email
#  rm $alertFile
#fi
