
3. Re: Length of TOKEN_INFO column
Barbara Boehmer Guru
Barbara Boehmer Feb 6, 2007 1:33 AM (in response to 437599)
The token_info column of the dr$...$i table is a blob, so once again any limitations depend upon how you display it. I provided an example below. Can you provide a little more detail about what you are trying to do and how?

SCOTT@10gXE> CREATE TABLE test_tab (test_col VARCHAR2 (30))

  2  /



Table created.



SCOTT@10gXE> INSERT ALL

  2  INTO test_tab VALUES ('test1')

  3  INTO test_tab VALUES ('test2')

  4  INTO test_tab VALUES ('test3')

  5  SELECT * FROM DUAL

  6  /



3 rows created.



SCOTT@10gXE> CREATE INDEX test_idx ON test_tab (test_col)

  2  INDEXTYPE IS CTXSYS.CONTEXT

  3  /



Index created.



SCOTT@10gXE> DESC dr$test_idx$i

 Name                                                  Null?    Type

 ----------------------------------------------------- -------- ------------------------------------

 TOKEN_TEXT                                            NOT NULL VARCHAR2(64)

 TOKEN_TYPE                                            NOT NULL NUMBER(3)

 TOKEN_FIRST                                           NOT NULL NUMBER(10)

 TOKEN_LAST                                            NOT NULL NUMBER(10)

 TOKEN_COUNT                                           NOT NULL NUMBER(10)

 TOKEN_INFO                                                     BLOB



SCOTT@10gXE> SELECT token_text, token_type FROM dr$test_idx$i

  2  /



TOKEN_TEXT                                                       TOKEN_TYPE

---------------------------------------------------------------- ----------

TEST1                                                                     0

TEST2                                                                     0

TEST3                                                                     0



SCOTT@10gXE> SELECT CTX_REPORT.TOKEN_INFO ('test_idx', 'test2', 0)

  2  FROM   DUAL

  3  /



CTX_REPORT.TOKEN_INFO('TEST_IDX','TEST2',0)

--------------------------------------------------------------------------------

===========================================================================

                       TOKEN INFO FOR TEST2 (0:TEXT)

===========================================================================



index:      "SCOTT"."TEST_IDX"

base table: "SCOTT"."TEST_TAB"

$I table:   "SCOTT"."DR$TEST_IDX$I"



---------------------------------------------------------------------------

                    ROW 1 ($I ROWID AAANCWAABAAAKu6AAB)

---------------------------------------------------------------------------

  DOCID COUNT: 1           FIRST: 2           LAST: 2



  DOCID: 2 (AAANCUAABAAAKuiAAB)  BYTE: 1  LENGTH: 3  FREQ: 1

    AT POSITIONS:  1





===========================================================================

                             TOKEN STATISTICS

===========================================================================



Total $I rows:                       1

Total docids:                        1

Total occurrences:                   1

Total token_info size:               3

Total garbage size:                  0 (0.00%)

Optimal $I rows:                     1

Row fragmentation:                   0.00%



                              MIN            MAX          AVERAGE

                         -------------  -------------  -------------

Docids per $I row       :            1              1           1.00

Bytes per $I row        :            3              3           3.00

Occurrences per docid   :            1              1           1.00

Bytes per docid         :            3              3           3.00

Occ bytes per docid     :            1              1           1.00





SCOTT@10gXE> VARIABLE g_ref REFCURSOR

SCOTT@10gXE> DECLARE

  2    v_clob CLOB;

  3  BEGIN

  4    CTX_REPORT.INDEX_STATS ('test_idx', v_clob);

  5    OPEN :g_ref FOR SELECT v_clob FROM DUAL;

  6  END;

  7  /



PL/SQL procedure successfully completed.



SCOTT@10gXE> PRINT g_ref



:B1

--------------------------------------------------------------------------------

===========================================================================

                     STATISTICS FOR "SCOTT"."TEST_IDX"

===========================================================================



indexed documents:                                                      3

allocated docids:                                                       3

$I rows:                                                                3



---------------------------------------------------------------------------

                             TOKEN STATISTICS

---------------------------------------------------------------------------



unique tokens:                                                          3

average $I rows per token:                                           1.00

tokens with most $I rows:

  TEST3 (0:TEXT)                                                        1

  TEST2 (0:TEXT)                                                        1

  TEST1 (0:TEXT)                                                        1



average size per token:                                                 3

tokens with largest size:

  TEST3 (0:TEXT)                                                        3

  TEST2 (0:TEXT)                                                        3

  TEST1 (0:TEXT)                                                        3



average frequency per token:                                         1.00

most frequent tokens:

  TEST3 (0:TEXT)                                                        1

  TEST2 (0:TEXT)                                                        1

  TEST1 (0:TEXT)                                                        1



token statistics by type:

  token type:                                                      0:TEXT

    unique tokens:                                                      3

    total rows:                                                         3

    average rows:                                                    1.00

    total size:                                                         9

    average size:                                                       3

    average frequency:                                               1.00

    most frequent tokens:

      TEST3                                                             1

      TEST2                                                             1

      TEST1                                                             1





---------------------------------------------------------------------------

                         FRAGMENTATION STATISTICS

---------------------------------------------------------------------------



total size of $I data:                                                  9



$I rows:                                                                3

estimated $I rows if optimal:                                           3

estimated row fragmentation:                                          0 %



garbage docids:                                                         0

estimated garbage size:                                                 0



most fragmented tokens:

  TEST3 (0:TEXT)                                                      0 %

  TEST2 (0:TEXT)                                                      0 %

  TEST1 (0:TEXT)                                                      0 %









SCOTT@10gXE> 

