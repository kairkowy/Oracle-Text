load data
infile 'load_blob.txt'
  into table blob_tab
  fields terminated by ','
  (number_content char(10),
   var_content char(1000),
   date_content date "DD-MON-YYYY" ":date_content",
   blob_filename  filler char(1000),
   content_data  lobfile(blob_filename) terminated by eof)
