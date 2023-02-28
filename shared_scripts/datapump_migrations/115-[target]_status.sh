sleep 5
ssh -t oracle@${TARGET_HOST} 'echo -e "show\nqstatus\n" | /u01/app/quest/prod/bin/sp_ctrl'
