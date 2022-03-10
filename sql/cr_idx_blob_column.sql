# create table include blob column
create table blob_tab
(number_content number(10) primary key,
 var_content varchar2(1000),
 date_content date,
 content_data blob);

# Insert Data 
# reference to sql*loader 
# blob_load.sh, load_blob.txt, blob_load.ctl file 참조

# Direct_datostore type
exec ctx_ddl.create_preference('my_filter','AUTO_FILTER');
exec ctx_ddl.create_preference('my_lexer','KOREAN_MORPH_LEXER');

create index blob_column_idx on blob_tab(content_data)
indextype is ctxsys.context
parameters('datastore ctxsys.DEFAULT_DATASTORE 
filter my_filter
lexer my_lexer');
select score(1), var_content, content_data from blob_tab where contains(content_data,'RAC',1) > 0;
select score(1), var_content from blob_tab where contains(content_data,'RAC | Configuration | 백업',1) > 0;

