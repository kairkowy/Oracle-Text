 ```sql
conn / as sysdba;
GRANT EXECUTE ON CTXSYS.CTX_CLS TO scott;
GRANT EXECUTE ON CTXSYS.CTX_DDL TO scott;
GRANT EXECUTE ON CTXSYS.CTX_DOC TO scott;
GRANT EXECUTE ON CTXSYS.CTX_OUTPUT TO scott;
GRANT EXECUTE ON CTXSYS.CTX_QUERY TO scott;
GRANT EXECUTE ON CTXSYS.CTX_REPORT TO scott;
GRANT EXECUTE ON CTXSYS.CTX_THES TO scott;
GRANT EXECUTE ON CTXSYS.CTX_ULEXER TO scott;


conn scott/tiger;
drop table search_table;
create table search_table (
 tk number primary key,
 title varchar2(2000),
 text clob);

# sql loader를 통한 데이터 로딩
# 

# result table 생성
CREATE TABLE output_table  (query_id NUMBER, document CLOB);
CREATE TABLE gist_table  (query_id NUMBER, pov VARCHAR2(80), gist CLOB);
CREATE TABLE theme_table  (query_id NUMBER, theme VARCHAR2(2000), weight NUMBER);

# Preference 생성 
exec ctx_ddl.drop_preference('mylexer');
exec ctx_ddl.create_preference('mylexer','KOREAN_MORPH_LEXER');
exec ctx_ddl.set_attribute('mylexer','verb_adjective','true');
exec ctx_ddl.set_attribute('mylexer','number','true');

exec ctx_ddl.create_section_group('mysection','HTML_SECTION_GROUP');
# CTX 인덱스 생성
drop index idx_search_table;
create index idx_search_table on search_table(text)
  indextype is ctxsys.context parameters
  ('datastore ctxsys.default_datastore filter ctxsys.null_filter section group mysection lexer mylexer');

```
exec CTX_DOC.FILTER(index_name=>'idx_search_table', textkey=>'538983217', restab=>'OUTPUT_TABLE', query_id=>0, plaintext=>FALSE,use_saved_copy=>CTX_DOC.SAVE_COPY_FALLBACK );
,
          use_saved_copy IN NUMBER DEFAULT CTX_DOC.SAVE_COPY_FALLBACK);
exec CTX_DOC.FILTER(
          index_name  'IDX_SEARCH_TABLE', 
          textkey     '538983217', 
          restab      IN OUT NOCOPY CLOB, 
          plaintext   IN BOOLEAN DEFAULT FALSE,
          use_saved_copy IN NUMBER DEFAULT CTX_DOC.SAVE_COPY_FALLBACK);
참고 
[참고](http://docs.oracle.com/database/121/CCAPP/acase.htm#CCAPP9374)

exec CTX_DOC.SET_KEY_TYPE('PRIMARY_KEY');

exec ctx_doc.filter( index_name=>'IDX_SEARCH_TABLE', textkey=> '538983217', restab=>'OUTPUT_TABLE', plaintext=>false );
exec ctx_doc.themes( index_name=>'IDX_SEARCH_TABLE', textkey=> '540750129', restab=>'THEME_TABLE', full_themes=>TRUE)


begin
exec ctx_doc.set_key_type('PRIMARY_KEY');
 exec ctx_doc.set_key_type('ROWID');
end

doHighlight
doThemes
doGists

exec ctx_doc.gist(index_name=>'IDX_SEARCH_TABLE', textkey=> '538983217', restab=>'GIST_TABLE', query_id=>1);