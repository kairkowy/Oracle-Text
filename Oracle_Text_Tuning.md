### Oracle Text Tuning
Oracle Text는 쿼리와 색인의 성능 향상을 위한 방법을 제공합니다.  

#### 통계정보 수집을 통한 쿼리 최적화  
쿼리 성능 향상을 위하여 테이블 및 인덱스의 통계정보 수집으로 효율적인 실행계획 수립이 필요합니다. "CONTAINS" 조건절에 대한 정확한 selectivity, Cost를 얻고 더 나은 실행계획 수립을 위해 통계정보 수집을 권고합니다.  

Oracle Optimizer는 아래 조건을 기준으로 최적화 실행계획을 수립합니다.  

   - CONTAINS의 조건절에 의한 선택도 기준
   - 쿼리의 다른 조건절에 의한 선택도 기준  
   - CONTAINS 조건절을 처리하기 위한 CPU,I/O 비용 기준

##### 통계정보 수집 
Oracle text는 CBO를 기본적으로 사용합니다. 더 Cost를 얻기 위해 text가 둘어 있는 Table과 Context Index(색인 DB)의 통계정보를 수집하기 위한 예는 아래와 같습니다.

```sql
ANALYZE TABLE <table_name> COMPUTE STATISTICS;
or
ANALYZE TABLE <table_name> ESTIMATE STATISTICS 1000 ROWS;
or
ANALYZE TABLE <table_name> ESTIMATE STATISTICS 50 PERCENT;
or
begin
DBMS_STATS.GATHER_TABLE_STATS('owner', 'table_name',
                                       estimate_percent=>50,
                                       block_sample=>TRUE,
                                       degree=>4) ;
end  ;
```

#### 통계정보 재 수집

```sql
ANALYZE INDEX <index_name> COMPUTE STATISTICS;
or
ANALYZE INDEX <index_name> ESTIMATE STATISTICS SAMPLE 50 PERCENT;
```

#### 통계정보 삭제
```sql
ANALYZE TABLE <table_name> DELETE STATISTICS;
or
ANALYZE INDEX <index_name> DELETE STATISTICS;
```

#### Response time을 위한 최적화 쿼리  
Oracle Text는 기본적으로 가능한 짧은 시간에 모든 row들을 반환하는 'throughput'을 기준으로 쿼리들을 최적화 합니다. 그러나 일반적으로 많은 Application에서는 Response time 향상을 위해서 반환되는 전체 Rows 중에 처음 몇 개의 Row들을 사용하는 경우가 있습니다.  

이런 경우를 위해서 Oracle Text는 아래와 같이 CONTAINS 쿼리의 Response Time 향상을 위한 몇 가지 방법을 제공합니다.  
```
1. ORDER BY 쿼리를 위한 "FIRST_ROW(N)" 힌트를 이용하는 방법
2. Local Partititoned Context index를 이용하는 방법
3. ORDER BY Score를 위한 Local Partitioned Index를 이용하는 방법
4. Query Filter Cache 방법
5. CONTEXT Index의 BIG_IO option 이용하는 방법
6. CONTEXT Index의 SEPARATE_OFFSETS Option 이용하는 방법
7. CONTEXT Index의 STAGE_ITAB Option 이용하는 방법
```

- Response time에 영향을 주는 다른 Factor들
    - Collection of table statistics
    - Memory allocation
    - Sorting
    - Presence of LOB columns in your base table
    - Partitioning
    - Parallelism
    - The number term expansions in your query

##### ORDER BY 쿼리를 위한 "FIRST_ROWS" 힌트를 이용하는 방법
 이 방법은 'ORDER BY' 쿼리에서 처음 몇 개의 Row가 필요한 경우에 'FIRST_ROWS(N)' 사용을 권장합니다. hint가 없는 경우에는 조건절에 부합하는 Text index의 모든 row들을 정렬이 않된 상태로 반환한 후에 Rowid로 소팅을 하게 되어 Response time에는 부정인 결과가 나타날 수 있습니다. 

예제)
``` sql
select /*+ FIRST_ROWS(10) */ article_id from articles_tab
   where contains(article, 'Omophagia')>0 order by pub_date desc;
```
- 참고 : 'DOMAIN_INDEX_SORT' Hint 사용  
DOMAIN_INDEX_SORT Hint는 'First_rows'와 유사한 hint이지만 Rule base 기반의 hint입니다. Oracle은 성능 향상을 위한 방법으로 cost-based 기반의 hint 사용을 권장합니다.  
 
예제) 
```sql
select /*+ DOMAIN_INDEX_SORT */ pk, score(1), col from ctx_tab 
            where contains(txt_col, 'test', 1) > 0 
            order by score(1) desc;
```

##### Local Partititoned Context index를 이용하는 방법
데이터를 파티셔닝하고 Local partitioned index를 만든 것은 쿼리 성능 향상을 가능하게 합니다. 
파티션된 Table에서 각 파티션은 자신의 index table을 가지고 있지만 최종결과는 통합된 결과로 나타납니다. 
 이 방법을 사용하기 위해서는 아래와 같이 Context index(색인)를 만들 때 'LOCAL' 키워드를 사용하여 색인 DB를 만들어 주면 됩니다.
 
```sql
CREATE INDEX index_name ON table_name (column_name) 
INDEXTYPE IS ctxsys.context
PARAMETERS ('...')
LOCAL
```

파티션 table과 인덱스를 이용하는 것은 다음 2개 형태의 쿼리들에서 성능 향상을 기대할 수 있습니다.

- Partition key 컬럼으로 Range search 경우

예제)
```sql
SELECT storyid FROM storytab WHERE CONTAINS(story, 'oliver')>0 
and pub_date BETWEEN '1-OCT-93' AND '1-NOV-93';
```

- 파티션 키 column으로 ORDER BY 하는 경우  
이 방법은 아래 예제(price로 파티션된 table)와 같이 파티션 키를 ORDER BY 절에 사용하여 첫 n 개를 필요로 하는 쿼리에 사용하는 방법입니다. 

예제)
```sql
SELECT itemid FROM item_tab WHERE CONTAINS(item_desc, 'cd player')
  >0 ORDER BY price)  WHERE ROWNUM < 20;
```

#####  ORDER BY Score를 위한 Local Partitioned Index를 이용하는 방법
ORDER BY Score를 사용하여 DOMAIN_INDEX_SORT hint 사용할 경우에 쿼리 결과가 정렬되어지기 전에 모든 파티션에서 결과를 가져와야 하기 때문에 좋지 않은 성능 결과를 얻을 수 있습니다. 

DOMAIN_INDEX_SORT hint를 사용할 경우에는 Inline view를 사용하여 성능 문제를 해결 할 수 있는 방법이 있습니다.

```sql
select * from 
          (select /*+ DOMAIN_INDEX_SORT */ doc_id, score(1) from doc_tab 
              where contains(doc, 'oracle', 1)>0 order by score(1) desc) 
      where rownum < 21;
```

##### Query Filter Cache 방법
Oracle text는 Query 결과를 캐시할 수 있는 'Query Filyter Cache'라는 cache를 제공합니다. 'Query Filyter Cache'는 쿼리간에 공유가 가능함에 따라 다른 캐시된 쿼리결과를 다른 쿼리에서 재사용를 할 수 있습니다. 
방법은 아래 예제와 같이 'Ctxfiltercache'연산자를 사용해야 합니다.

예제)
```
select * from docs where contains(txt, 'ctxfiltercache((common_predicate), FALSE)')>0;

select * from docs where contains(txt, 'new_query & ctxfiltercache((common_predicate), FALSE)')>0; 
```

*ctxfiltercache에 대한 자세한 내용은 Oracle Text Reference*를 참조하십시오.

##### CONTEXT Index의 BIG_IO option 이용하는 방법
이 방법은 광범위한 I/O 연산이 일어 나는 Context Index의 성능 향상(response time)을 위한 방법이며, Disk 방식의 스토리지를 사용하는 DB 환경에서 성능 향상을 얻기 위한 방법입니다.

BIG_IO option을 사용한 CONTEXT Index들은 SecureFile LOB에 토큰이 저장 되고, 이 SecureFile LOB의 데이터는 멀티 블럭에 시쿼셜하게 저장된다. 이렇게 저장된 것은 많은 짧은 Read 작업 대신에 긴 시퀀셜 read를 실행하여 쿼리들의 response time을 향상시킵니다.

  * Note :  
    SecureFile은 11.0 이상으로 COMPATIBLE 설정이 필요하며, ASSM tablespace를 사용해야함.

BIG_IO option 사용 방법은 아래와 같이 BIG_IO 속성을 "YES"로 지정하고 CONTEXT index를 생성합니다.
```sql
exec ctx_ddl.create_preference('mystore', 'BASIC_STORAGE');
exec ctx_ddl.set_attribute('mystore', 'BIG_IO', 'YES');
```

BIG_IO option Disable 방법은 아래와 같이 BIG_IO 속성을 "NO"로 지정한 후에 Index를 rebuild 해주면 됩니다.
```sql
exec ctx_ddl.set_attribute('mystore', 'BIG_IO', 'NO');
alter index idx rebuild('replace storage mystore');
```

Index 재생성 없이 파티션 인덱스의 BIG_IO 지정은 아래와 같은 방법으로 수행해줍니다.
```sql
exec ctx_ddl.set_attribute('mystore', 'BIG_IO', 'YES');
exec ctx_ddl.replace_index_metadata('idx', 'replace storage mystore');
exec ctx_ddl.optimize_index('idx', 'rebuild', part_name=>'part1');
```


##### CONTEXT Index의 SEPARATE_OFFSETS Option 이용하는 방법

이 방법은 주로 Single-word 또는 Boolean 쿼리 I/O operaion이 광범위 하게 일어나는 Context Index의 성능 향상(response time)을 위한 방법으로 사용합니다.이 'SEPARATE_OFFSETS' option은 TEXT 형식의 토큰들을 위하여 다른 포스팅 목록 구조를 만듭니다.  

'SEPARATE_OFFSETS Option'은 포스팅 리스트에 docid,Frequencies, Info-length(오프셋 정보 길이)와 오프셋을 산재시키는 대신에 포스팅 목록의 시작 부분에 모든 docid, frequencies를 함께 저장하고, 포스팅의 끝 부분에 모든 Info-lenght와 offset을 저장한다. 

포스팅의 시작 header에는 docid 및 Offset에 대한 정보를 포함하고 있고, 이렇게  docid들과 frequencies를 offset들과 분리한 것은 데이터를 읽는 시간을 단축시킴으로써 쿼리 reponsee time을 향상시키기 위함입니다. 이 Option의 성능은 BIG_IO option과 함께 사용하면 최상의 효과를 얻습니다.  

'SEPARATE_OFFSETS Option' 사용하는 방법은 다음과 같습니다.
```sql
exec ctx_ddl.create_preference('mystore', 'BASIC_STORAGE');
exec ctx_ddl.set_attribute('mystore', 'SEPARATE_OFFSETS', 'T');
```

SEPARATE_OFFSETS Option' Disable 방법은 다음과 같습니다.

```sql
exec ctx_ddl.set_attribute('mystore', 'SEPARATE_OFFSETS', 'F');
alter index idx rebuild('replace storage mystore');
```

Index rebuild없이 파티션 Index에 적용하는 방법은 다음과 같습니다.
```sql
exec ctx_ddl.set_attribute('mystore', 'SEPARATE_OFFSETS', 'T');
exec ctx_ddl.replace_index_metadata('idx', 'replace storage mystore');
exec ctx_ddl.optimize_index('idx', 'rebuild', part_name=>'part1');
```

##### CONTEXT Index의 STAGE_ITAB Option 이용하는 방법
이 방법은 광범위 하게 DML 작업이 많은 경우 Near real-time Indexing을 위한 방법을 제공합니다.

이 Option을 사용하지 않는 다면, 새로운 문서가 추가 될때마나 문서 검색이 가능하도록 SYNC_INDEX를 해야 하고, 문서가 추가되는 것은 $I Table에 새로운 row를 추가하는 것인데, 이 경우 $I table의 fragmentation이 심해지면서 성능이 떨어집니다.

이 Option을 사용하면 새로 추가된 문서의 정보는 $I table에 저장되지 않고 $G 스태이징 table에 저장됩니다. 또한, 이 Option 하에서는 $H b-tree Index도 $G table에 저장됩니다. $G table과 $H B-tree index는 $I table과 $X B-tree Index에 해당합니다.

MERGE optimizer mode를 사용해서 $G Table의 Row들을 $I Table로 이동합니다.

이 Optiom을 적용하는 방법은 아래와 같이 스토리지 속성을 지정해주고 파티션 유무에 따라 해당하는 방법으로 Index를 Rebuild를 해줍니다.
```sql
exec ctx_ddl.create_preference('mystore', 'BASIC_STORAGE');
exec ctx_ddl.set_attribute('mystore', 'STAGE_ITAB', 'YES');
```

파티션이 없는 경우는 아래와 같은 방법으로 이 Option을 적용합니다.
```sql
alter index IDX rebuild parameters('replace storage mystore');
```

파티션된 경우는 아래와 같은 방법으로 이 Option을 적용합니다.
```sql
alter index idx parameters('add stage_itab');
```

파티션이 없는 경우는 해제 하는 방법은 다음과 같습니다.
```sql
exec ctx_ddl.set_attribute('mystore', 'STAGE_ITAB', 'NO');
alter index idx rebuild('replace storage mystore');
```

파티션된 경우 해제하는 방법은 다음과 같습니다. 
```sql
alter index idx parameters('remove stage_itab');
```

#### Throughput을 위한 최적화 쿼리
Thtoughput 쿼리 최적화는 가능한 짧은 시간 내에 모든 Hit 리스트들을 반환하는 방법으로 deafult 로 작동됩니다.

다음은 명시적으로 처리량을 최적화 방법을 기술합니다.
#####  CHOOSE and ALL ROWS Modes
쿼리들은 기본적으로 'CHOOSE'와 'ALL_ROWS' mode 작동합니다. 

##### FIRST_ROWS(n) Mode
이 모드에서 옵티마이저는 빠른 response time을 위하여 'FIRST_ROWS(n)' 힌트를 사용할 때 기본으로 작동하여 score로 정렬된 Rows들을 반환합니다. 

'FIRST_ROWS(n)' 하에서 더 좋은 Throughput을 얻기 위한다면 'DOMAIN_INDEX_NO_SORT' 힌트를 사용할 수 있습니다. 

예제)
```sql
select /*+ FIRST_ROWS(10) DOMAIN_INDEX_NO_SORT */ pk, score(1), col from ctx_tab 
            where contains(txt_col, 'test', 1) > 0 order by score(1) desc;
```

#### Composite Domain Index (CDI)
Composite Domain Index(CDI)는 단순하게 색인과 지정된 text column만을 처리 하지 않고, 색인이 만들어 지는 동안 구조화된 Column들을 Filter by와 Order by 처리를 하고 인덱싱을 합니다. 다음은 CDI 환경에서 성능 향상을 위한 방법입니다. 

* WHERE절 Text 쿼리
* ORDER BY Text 쿼리
* 두가지 방법을 조합하여 사용하는 방법

연결된 B-tree index 또는 Bitmap Index 환경의 DML에서 Filter by와 Order by Column이 늘어 날 때 성능이 저하되는 현상이 발생합니다. 

Score-sort시 응답시간을 최적화하는 방법은 Structured Sort 또는 Socre와 Structured Sort의 조합을 사용하는 방법입니다. Throughput이 향상 되는 것은 아니며, 전체 hitlist들을 가져오는 동안 CDI에 푸시시켜 정렬하는 DOMAIN_INDEX_SORT 또는 FIRST_ROWS(N) 힌트 사용하는 것은 Response time 성능에 안좋은 결과를 낼 수 있습니다.

##### CDI 성능 튜닝
MDATA를 위한 FILTER BY column 매핑 지원은 RANGE와 Like 함수 제한을 통한 equality search의 최적화된 쿼리 성능을 지원합니다. 그러나 매우 높은 카디널리티를 가지고 있거나, FILTER BY column에 순차적인 값이 포함된 경우는 MDATA를 위한 FILTER BY column 매핑은 권고하지 않습니다. 매우 길고 좁은 $I 테이블 및 $X 성능이 저하 될 수 있습니다. 대표적인 예는 Date값을 사용한 column일 것입니다.
이러한 Sequential column 매핑은 SDATA에 사용 하는 것이 좋습니다.

다음 힌트들은 SORT를 넣거나 뺴서 사용할 수 있고, CDI FILTER BY 조건에 사용할 수 있습니다. 

* DOMAIN_INDEX_SORT : 옵티마이가 지정 된 Composite domain index로 해당 정렬 기준을 push함.
* DOMAIN_INDEX_NO_SORT : 옵티마이저가 지정 된 Composite domain index로 해당 정렬 기준을 push 하지 않음.
* DOMAIN_INDEX_FILTER(table name index name) : 옵티마이저가 지정된 Composite domain index에 해당 FILTER by를 push함. 
* DOMAIN_INDEX_NO_FILTER(table name index name) : 옵티마이저가 지정된 Composite domain index에 해당 FILTER by를 push 하지 않음.

CDI hint 예제)
```sql
SELECT bookid, pub_date, source FROM
  (SELECT /*+ domain_index_sort domain_index_filter(books books_ctxcdi) */ bookid, pub_date, source
      FROM books
      WHERE CONTAINS(text, 'aaa',1)>0 AND bookid >= 80
      ORDER BY PUB_DATE desc nulls last, SOURCE asc  nulls last, score(1) desc)
 WHERE rownum < 20;
```

#### Solving Index and Query Bottlenecks Using Tracing
Oracle text는 색인과 쿼리의 병목현상을 식별 할 수 있는 선정의된 trace 집합을 제공합니다. 각 trace는 고유의 숫자로 식별이 되고 CTX_OUTPUT으로 표시됩니다.  
Trace 누적 카운트는 다음과 같습니다.

```
1. trace 시작
2. Operation을 실행. Oracel text는 Activity들을 측정하여 trace 결과들을 합산한다. 
3. step2에서 수행한 모든 operation이 수행한 total 값인 trace 값을 검색한다.
4. Trace를 0으로 리셋 한다.
5. step 2부터 시작한다. 
```

예를 들면, step 2에서 쿼리 1은 $I에서 15개의 row는 선택하고, 쿼리 2는 $I에서 17개의 row를 선택하는 2개의 쿼리를 실행 했다면, step 3의 trace의 값은 32가 될 것입니다.

trace는 단일 세션 내에서 발생하는 operation들을 측정할 수 있으나 세션간에는 측정할 수 없습니다. 

trace가 활성화  된 경우에는 parallel sync 또는 최적화 동안에 trace profile은 slave session을 위해 복사 될 것입니다. 각 salve는 자신의 trace를 합산해 갈 것이고, 암시적으로 종료전에 slave logfile에 모든 trace 값을 기록할 것입니다.


#### Parallel 쿼리 사용
##### Parallel Queries on a Local Context Index
parallel 쿼리는 Context Index의 paralleled processing을 참고하여 병렬처리 쿼리를 수행합니다. parallel 쿼리는 색인을 만들때 지정된 parallel degree에 의해 디폴트로 작동합니다.

그러나, 동시 사용자가 많은 heavy한 시스템에서 쿼리가 순차적으로 실행되는 경우 일반적으로 처음 몇 개의 Top-Ndd으로 만족 할 수 있기 때문에 parallel query의  쿼리 throurhput에는 좋지 않을 수 있습니다. 
parallel degree는 다음과 같이 COntext index 에 적용해서 사용할 수 있습니다.
```sql
Alter index <text index name> NOPARALLEL;
Alter index <text index name> PARALLEL 1;
```


##### Parallelizing Queries Across Oracle RAC Nodes
Oracle RAC는 light query load의 Oracle Text 쿼리 성능 향상에 도움을 줍니다.

오라클 RAC 환경에서 Text data와 색인(Logical partitioned index 사용)을 물리적 파티셔닝에 의해 압축되어지고, 파티션들은 각 RAC 노드들에 의해 처리될 수 있기 때문에 오라클 텍스트 성능은 좋아 질수 있습니다.

이 방법은 다중 노드 사이에서 캐시 content의 Dupliacation을 피할 수 있어 캐시 퓨전의 효과를 극대화 할 수 있습니다.

10g R1에서는 RAC의 're-mastering' 특성을 살리기 위해 Text index partition은 인덱스를 만들때 datafile을 분리해서 저장 해야 했습니다. 

10g R2 부터는 Object level 선호도(affinity) 지원으로 특정 노드들에서 $I, $R table 색인 object 할당을 훨씬 쉽게 지원합니다.

데이터가 확장되는 상황에서 RAC가 지속적으로 성능향상과 throughout향상을 제공하는 것은 아닙니다. 데이터량에 따라 SGA cache를 증가시키거나, table  파티션닝을 병행해야 합니다.

#### Blocking operation의 튜닝
아래와 같이 Bitntmap index를 가진 ColA, B, C는 Bit map blocking 연산을 수행합니다. 
```sql
select docid from mytab where contains(text, 'oracle', 1) > 0 
  AND colA > 5 
  AND colB > 1 
  AND colC > 3; 
---------------------
execution plan

TABLE ACCESS BY ROWIDS
  BITMAP CONVERSION TO ROWIDS
    BITMAP AND
      BITMAP INDEX COLA_BMX
      BITMAP INDEX COLB_BMX
      BITMAP INDEX COLC_BMX
      BITMAP CONVERSION FROM ROWIDS
        SORT ORDER BY
          DOMAIN INDEX MYINDEX
```
이 경우 Orace text는 Bitmap blocking map 연산을 수행하기 전에 Oracle text domain index로 부터 얻은 rowid와 score의 정보를 메모리에 임시적으로 저장하게 됩니다.   

만약 이 Rowid와 score pair양이 커져서 'SORT_AREA_SIZE'를 초과 할 경우 메모리에 있던 pair 데이터들을 Disk로 저장하게 되어 성능에 영향을 미칩니다. 

따라서 이 문제를 해결하기 위한 방법으로는 아래와 예와 같이 'SORT_AREA_SIZE'를 증가 시켜주는 방법입니다.
```sql
alter session set SORT_AREA_SIZE = 8300000;
```

-----

### 참고 문서
1. [Oracle® Text Application Developer's Guide 12c Release 1 (12.1)의 7.Tuning Oracle Text](http://docs.oracle.com/database/121/CCAPP/aoptim.htm#CCAPP9247) [http://docs.oracle.com/database/121/CCAPP/aoptim.htm#CCAPP9247]

