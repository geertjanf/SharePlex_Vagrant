CREATE TABLE test.TESTSPX1
(
 ID  NUMBER,
 A   VARCHAR2(20 BYTE),
 B   VARCHAR2(20 BYTE)
) ;

CREATE UNIQUE INDEX TEST.IDX_TESTSPX1 ON test.TESTSPX1
(ID)
LOGGING
TABLESPACE USERS
NOPARALLEL;

SET DEFINE OFF;
Insert into test.TESTSPX1
  (A, B)
Values
  ('1', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('2', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('3', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('4', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('5', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('6', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('7', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('8', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('9', '1');
Insert into test.TESTSPX1
  (A, B)
Values
  ('10', '1');
COMMIT;

Source :
update test.TESTSPX1 set B='10' where rownum<5 ;