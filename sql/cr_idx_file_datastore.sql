# Example for File_datastore type
# 색인 DB 삭제
drop index file_store_idx;
# 색인 대상 파일 리스트 삭제 
truncate table file_data_store;
# table create for file list
create table file_data_store
(id number primary key,
 docs varchar2(2000));

# 색인대상 파일 리스트 등록
insert into file_data_store values(1,'Analytics_PT.pdf');
insert into file_data_store values(2,'Document_1916469.pdf');
insert into file_data_store values(3,'hwp2007_RFP_sample.hwp');
insert into file_data_store values(4,'hwp97_sample.hwp');
insert into file_data_store values(5,'ppt2010_sample_Text.pptx');
insert into file_data_store values(6,'hadoop_reference_sk.pdf');
insert into file_data_store values(7,'2014_IT_ProspectReport_DD.pdf');
insert into file_data_store values(8,'dbm_configurator2.xls');

commit;

# 색인 대상 타입 생성
exec ctx_ddl.create_preference('my_file_datastore','FILE_DATASTORE');
exec ctx_ddl.set_attribute('my_file_datastore','PATH','/home/oracle/text/data');

# text filter 및 Lexer 지정
exec ctx_ddl.create_preference('my_filter','AUTO_FILTER');
exec ctx_ddl.create_preference('my_lexer','KOREAN_MORPH_LEXER');

# connect as sysdba
# SQL> exec ctxsys.ctx_adm.set_parameter('file_access_role', 'public')

# 색인 DB 생성
create index file_store_idx on file_data_store(docs)
indextype is ctxsys.context
parameters('datastore my_file_datastore
filter my_filter
lexer my_lexer');

# Index sync after DML operation of doc table 
exec ctx_ddl.sync_index('file_store_idx','1M');

# drop preference
#exec ctx_ddl.drop_preference('my_file_datastore')
#exec ctx_ddl.drop_preference('my_filter')
#exec ctx_ddl.drop_preference('my_lexer')

select count(*) from DR$FILE_STORE_IDX$I;

# DR$FILE_STORE_IDX$I // index data table
# DR$FILE_STORE_IDX$K // keymap table
# DR$FILE_STORE_IDX$N // nevative list table
# DR$FILE_STORE_IDX$R  // rowid table

# SQL 쿼리
select score(1), id, docs from file_data_store where contains(docs,'Oracle',1) > 0;
select score(1), id, docs from file_data_store where contains(docs,'Oracle and Analytics',1) > 0;
select score(1), id, docs from file_data_store where contains(docs,'문서 or Oracle or Analytics or 전투',1) > 0;
select score(1), id, docs from file_data_store where contains(docs,'SW»ç¾÷ | Feature',1) > 0;
select score(1), id, docs from file_data_store where contains(docs,'트랜드 and 전투',1) > 0;



##### end of demo
# near real time index update example
# exec ctx_ddl.create_preference('mystore', 'BASIC_STORAGE');
# exec ctx_ddl.set_attribute('mystore', 'STAGE_ITAB', 'YES');
# alter index file_store_idx rebuild parameters('replace storage mystore');

