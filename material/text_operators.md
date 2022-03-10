
## Oracle Text operators
### List
#### 1. About query
* English 
1. ABOUT Query
2. Logical Operators
3. Section Searching and HTML and XML
4. Proximity Queries with NEAR and NEAR_ACCUM Operators
5. Fuzzy, Stem, Soundex, Wildcard and Thesaurus Expansion Operators
6. Using CTXCAT Grammar
7. Stored Query Expressions
8. Calling PL/SQL Functions in CONTAINS
9. Optimizing for Response Time
10. Counting Hits
11. Using DEFINESCORE and DEFINEMERGE for User-defined Scoringbout   

#### 1.1 About query
* "about" query는 검색어나 구문과 관련된 문서를 반환하는데 사용 됩니다.영어 또는 프랑스어에서는 쿼리의 일부가 아닐지라도 개념을 조회 할수 있습니다. 예를 들어 "about(Califonia)" 일 경우에 "Los Angeles"와 "SanFransisco" 단어들이 포함된 문서들을 반환합니다.
* "about" 쿼리는 CONTAINS와 CATSERCH의 연산자로 사용할 수 있으나 영어, 불어 환경에서만 지원됩니다.
* about(pharse) 형식으로 사용하며, pahrse에는 word, pharse 또는 free text format 단어들을 사용할 수 있으며, 4000자 이상 사용할 수 없습니다.
```sql
select score(1), tk, title from search_table
where contains(text,'about(RAC)', 1) > 0;  --single word 경우

select score(1), tk, title from search_table
where contains(text,'about(soccer rules in international competition)', 1) > 0;  -- parse 경우

select score(1), tk, title from search_table
where contains(text,'about(dogs) and cat', 1) > 0; -- 조합쿼리인 경우

```

* "about" 쿼리는 반환되는 문서의 수가 증가하고 결과들의 정렬 순서를 증가 시킬 수 있습니다.
* 영어, 프랑스어 경우, Index 생성시 INDEX_THEMES 속성에 "YES"를 지정하면 pharse와 관련된 개념들이 포함된 문서들을 반환합니다. 


#### 1.2 ACCUMulate
* 오라클 텍스트 지식 기반으로 하나 이상의 시소러스를 컴파일하여 제공되는 지식 기반을 확장 


select score(1), tk, title from search_table
where contains(text,'about(oracle RAC)', 1) > 0

select score(1), tk, title from search_table
where contains(text,'Oracle or RAC', 1) > 0
