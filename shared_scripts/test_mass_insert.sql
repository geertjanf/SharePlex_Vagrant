declare
k INTEGER := 0;
begin
	for i in 1 .. 10000
	loop
		for j in 1 .. 1000
		loop
			k := k+1;
			insert into test.TEST values (k,'pp_'||k,k);
		end loop;
		commit;
--               dbms_lock.sleep(1);
	end loop;
end;
/