ssh -t oracle@${TARGET_HOST} 'echo -e "stop post\n" | /u01/app/quest/prod/bin/sp_ctrl'
