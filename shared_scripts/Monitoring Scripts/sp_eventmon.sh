#!/bin/ksh
#
# @(#) $Header: /project/splex/RCS/tools_Oracle/sp_eventmon,v 1.10 2002/07/17 12:35:31 toan Exp $ 
# @(#) $Source: /project/splex/RCS/tools_Oracle/sp_eventmon,v $ 
##############################################################################################################
#
#
#  Program Name:  sp_eventmon.sh
#  Date Written:  12-Jan-00
#  Written By:    Chandrika Shivanna
#  Purpose:       To monitor the Shareplex event log and scan for errors and report them 
#
##############################################################################################################
#    
#  Usage:

#            sp_eventmon -t(interval) -p(path) -n(name) -s(sp_cop name) -m &
#            where
#                     -t specifies the time interval between successive scans every n seconds.
#                        This parameter is optional and if not specified defaults to 60 seconds.
#                     -p specifies the path to the SharePlex event log file.
#                        This parameter is mandatory, the script will fail if not specified.
#                     -n specifies the name of the event log file if different from default.
#                        This parameter is optional and if not specified defaults to event_log.
#                     -m specifies that a user should be notified via e-mail.
#                        This parameter is optional and by default no mail will be sent. 
#                     -s specifies the unique name for each instance of sp_cop on the same host.
#                        This parameter is mandatory, the script will fail if not specified.
#                      & If the program is not started as a background process then the user
#                        will not regain control of the shell.

#       sp_eventmon.sh -b binary -v vardir -p port number -u uname
#       where
#           -b specifies the path to the directory for SharePlex binaries.
#           -v specifies the path to the appropriate variable directory for SharePlex.
#           -p specifies the port number that the sp_cop is replicating on.
#           -h specifies the Host name of this server.
#           -o specifies the Oracle instance that SharePlex is replicating from.
#           -u specifies the Unique Identifier given to the sp_cop when it was first executed
#              with the -u notation and typically it is 
#              the port number that particular sp_cop is listening on OR
#              the Oracle SID it is replicating from.
#           -m specifies name of file with list of emails to send alerts to
#              (each separated by a comma e.g. a@quest.com, b@quest.com)
#
#  Dependencies:
#       iwgrep should be installed along with this script and the error_list file which
#       contains a list of errors to be monitored should also be installed in the same
#       directory as the script. A marker file called 'splex.mrk' will be created in the
#       same directory as well and should not be deleted. If deleted the script will start
#       scanning the file from the begining.The script uses mailx program to send e-mails.
#       Before using the script make sure the mailx is configured on the host on which this
#       will be deployed and can successfully send mail.
#
#       Each replicating sp_cop must be assigned an Unique Identifier upon startup 
#       i.e. unix_prompt> sp_cop -uXXXX
#       where XXXX is the given Unique Identifier, usually either 
#       the Source Replicating Database instance name (Oracle_Sid) is used
#       OR
#       the port number of the Replicating Instance
#
#  Bugs:
#            None found or reported  
#
############################################################################################################
#
#  Modification:  
#
#  1) 07-May-09 - LT (lootong.tan@quest.com)
#               - Added SP_SYS_HOST_NAME as required input parameter
#               - Added mailing option that takes list of emails from a flat file
#
############################################################################################################

# --------------------------------------------------------------------------------
# function to display the usage if insufficient or invalid parameters were entered # --------------------------------------------------------------------------------
#

function usage
{
    echo "-------------------------------------------------------------------------------"
    echo ""
    echo " sp_eventmon.sh -b binary -v vardir -m mondir -w utildir -p port number [-e TRUE] "
    echo ""
    echo "This is a script that will monitor the Process Status and check if any of the"
    echo "required processes are not running. The following options are allowed:"
    echo ""
    echo "   -b specifies the path to the directory for SharePlex binaries."
    echo "   -v specifies the path to the appropriate variable directory for SharePlex."
    echo "   -m specifies the path where the monitoring logs will be stored."    
    echo "   -w specifies the path where the iwgrep is, usually the util directory."    
    echo "   -p specifies the port number that the sp_cop is replicating on."
    echo "   -u specifies the Unique Identifier given to the sp_cop when it was first executed"
    echo "      with the -u notation and typically it is "
    echo "      the port number that particular sp_cop is listening on OR"
    echo "      the Oracle SID it is replicating from."
    echo "   -e specifies if require to send alert via email, if not omit this parameter."    
    echo " "
    echo "-------------------------------------------------------------------------------"
}

#echo " sp_eventmon.sh -b binary -v vardir -m mondir -p port number -h SP_SYS_HOSTNAME -o instance -u uname -m mailing list"

# Set up default values for the command line arguments in case not specified

interval=200
eventfile='event_log'
mailopt=FALSE
#myhost=`hostname`
# If more than one person needs to get an e-mail notification than add the names below each separated # by a space.
MailUserName="EricLukita.SUTANTO@Statschippac.com kumar.arumugam1@wipro.com lootong.tan@quest.com Eric.Cahyadi@quest.com"
if [ "$MailUserName" = "yourname@yourcompany" ]
  then
    echo "Please modify the script so it has a valid email address"
    exit 0
fi
# Make sure that the command line parameters are specified 
if (test $# -eq 0) then
    # call execute function to display usage message
    usage
    exit 1             
fi

# Now process the command line options and get the values 
while getopts :b:v:m:w:p:s:t:e: option 
do
    case "$option"
    in
        b)  splexbindir="$OPTARG"
            ;;
        v)  splexdatadir="$OPTARG"
            ;;
        m)  splexmondir="$OPTARG"
            ;;    
        w)  splexutildir="$OPTARG"
            ;;    
        p)  portnum="$OPTARG"
            ;;
        s)  splexname="$OPTARG"
            ;;
        t)  interval="$OPTARG"
            ;;
        e)  mailopt="$OPTARG" 
            ;;
        \?) echo " "
            # call execute function to display usage message
            usage
            exit 1
            ;;
    esac
done

#
# Set the IW_HOME variable so that iwgrep can execute. This variable has to be customized for each machine 
# and needs to be changed if iwgrep is moved.
IW_HOME=${splexutildir}
export IW_HOME

eventfile=event_log
logdate=`date`
eventerrtmp=${splexmondir}/sp_errors_$portnum.tmp
eventerrlog=${splexmondir}/sp_errors_$portnum.log
eventmonlog=${splexmondir}/sp_eventmon_$portnum.log
if [ -f "$eventerrtmp" ]; then
  rm $eventerrtmp
fi
#tmpstatus=${splexmondir}/sp_psmon_${instance}_${portnum}.tmp

                     
# Check to see if the path the Shareplex data directory was specified 
#if (test -z "$splexdatadir" !=0)  then
if (test -z "$splexdatadir")  then
    echo "Error...Please enter a valid SharePlex variable data directory path."
    exit 1
else
    SP_SYS_VARDIR=$splexdatadir
    export SP_SYS_VARDIR
fi

# Check to see if the SharePlex instance name was specified #if (test -z "$splexname" !=0) then
#      echo "Please specify the Shareplex instance name."
#      exit 1
#fi

# Test to see if the file and directory specified exists and is readable by the user executing the script 
eventlog="${SP_SYS_VARDIR}"/log/"$eventfile"

if [ -f "$eventlog" -a -r "$eventlog" ]
then
      
    echo " " >> $eventmonlog 
    # echo "The specified file exists!" > $eventmonlog
  else
     echo "The specified file does not exist"
     echo "or cannot be read. Please verify!"
     exit 1
fi
 
# Now that all the validation is complete build the qualified name of the event_log.

# fullname=$splexdatadir/log/$eventfile
# echo $fullname >> $eventmonlog

mailstring="Errors found in the SharePlex event log for instance: ${portnum}"

#while :
#do

# Now start scanning the file and go to sleep as often as $interval specifies # 
# SR 25519 - change i/o redirection 
echo "The following errors were found in the SharePlex event log for instance: ${portnum} at [$logdate]" > $eventerrlog

#iwgrep -ferror_list -s"${splexname}"  $fullname >> $eventerrlog 
#./iwgrep -ferror_list -s"${splexname}" -m"${splexname}.mrk"  $fullname >> $eventerrlog 
${IW_HOME}/eventgrep -ferror_list -s"${portnum}" -m"$splexmondir/sp_${portnum}.mrk" $eventlog >> $eventerrtmp

#${SP_SYS_UTILDIR}/eventgrep -ferror_list -s"${SP_COP_TPORT}" -m"$SP_MONDIR/${SP_COP_TPORT}.mrk" $SP_SYS_VARDIR/log/event_log >> ${SP_MONDIR}/EVENTERRLOG

# cat $eventerrlog >> $eventmonlog
testlog=`cat $eventerrtmp |wc -l`

# echo "The value for testlog is: " $testlog 
# Send a mail to the designated user if requested 
     if [ "$mailopt" = TRUE ]
     then
     if (test "$testlog" -gt 1) then
          echo "There are [$testlog] more lines" >> $eventerrlog
          echo " " >> $eventerrlog
          echo " " >> $eventerrlog
          cat $eventerrtmp >> $eventerrlog
          cat $eventerrlog >> $eventmonlog

          # email error log out
####          cat $eventerrlog | mailx -s "Errors found in SharePlex Event Log!" ${MailUserName}
echo "if you want to send mail,pls remove '####' above line[search key word tttt in sp_eventmon.sh file]."
          # Debug code follows:
          echo " "    >> $eventmonlog
          echo " "    >> $eventmonlog
          echo "Binary Directory:     ["$splexbindir"]"  >> $eventmonlog
          echo "VarDir Directory:     ["$splexdatadir"]" >> $eventmonlog
          echo "Monitoring Directory: ["$splexmondir"]"  >> $eventmonlog
          echo "iwgrep Directory:     ["$splexutildir"]" >> $eventmonlog
          echo "email error?:         ["$mailopt"]"      >> $eventmonlog
          echo " "    >> $eventmonlog
          echo "###################################### " >> $eventmonlog
     else
          echo "no error on [$logdate]" >> $eventmonlog
     fi
#          rm $eventerrtmp
          if (test $? = 1) then
             echo "Error with your mailx program. Please verfiy that it is functioning properly! "
          exit 1
          fi
     fi
#     sleep $interval

#done

