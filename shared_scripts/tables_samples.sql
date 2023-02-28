select * from test.test;

drop table test.test;

create table test.test (id number not null, constraint pk_test primary key (id));
insert into test.test values (1);
insert into test.test values (2);
insert into test.test values (3);
insert into test.test values (4);
insert into test.test values (5);
insert into test.test values (6);
commit;

create table test2 (id number not null, description varchar2(100), constraint pk_test2 primary key (id));
truncate table test.test;
