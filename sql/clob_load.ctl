load data
infile 'load_clob.txt'
  into table clob_tab
  fields terminated by ','
  (number_content char(10),
   var_content char(1000),
   date_content date "DD-MON-YYYY" ":date_content",
   clob_filename  filler char(1000),
   content_data  lobfile(clob_filename) terminated by eof)
