scn=`head -1 current_scn.log`
((scn++))
#ssh -t oracle@ol7-19-splex2 'echo -e "show\nqstatus\nreconcile queue ol7-19-splex1 for o.pdb1-o.pdb1 scn $scn\nshow\nqstatus\n" | /u01/app/quest//bin/sp_ctrl'
#echo -e "show\\nqstatus\\nreconcile queue ol7-19-splex1 for o.pdb1-o.pdb1 scn '$scn'\\nshow\\nqstatus\\n" | "/u01/app/quest//bin/sp_ctrl"
echo -e "show\\nqstatus\\nreconcile queue ol7-19-splex1 for o.pdb1-o.AWSDB scn $scn\\nshow\\nqstatus\\n" | "/u01/app/quest//bin/sp_ctrl"
