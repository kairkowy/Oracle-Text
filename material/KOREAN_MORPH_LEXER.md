## KOREAN_MORPH_LEXER 상세 ##

- "KOREAN_MORPH_LEXER"는 Oracle Text Index를 생성하기 위해 한글 text 내에서 토큰들을 추출할때 사용되는 lexer입니다.  
- 관련 Dictionaries  
     * Grammar, User-defined, Stopword 사전은 KSC5601 or MSWIN949 문자 셋을 사용하여 작성해야 하며, 정의된 룰을 참조하여 수정 가능합니다.
     * system(drk2sdic.dat) 사전은 수정이 불가합니다.
     * 미등록 단어들은 User-defined dictionary file에 추가하여 사용할 수 있습니다.

>>>Dictionary | File | remark
>>>----|---- |
>>>System | $ORACLE_HOME/ctx/data/kolx/drk2sdic.dat| -
>>>Grammar| $ORACLE_HOME/ctx/data/kolx/drk2gram.dat|아래 샘플 참조
>>>Stopword | $ORACLE_HOME/ctx/data/kolx/drk2xdic.dat|아래 샘플 참조
>>>User-defined | $ORACLE_HOME/ctx/data/kolx/drk2udic.dat|아래 샘플 참조

- 지원되는 DB character set은 KO16KSC5601, KO16MSWIN949, UTF8, AL32UTF8 4종 입니다.
- Unicode 지원
    * Unicode에 정의된 단어들   
      * KOREAN_MORPH_LEXER에서 Non-KSC5601 11,172개의 한글 문자들을 인식할 수 있고, 이러한 문서는 UTF8 이나 AL32UTF8 문자 세트를 사용하여 해석 될 수 있습니다.
      * Unicode 한글 제약사항  : 한자를 한글로 변환시 KSC5601에 정의된 한자 4,888지원

    * Supplementary characters  
![](imges/Unicode_Character_Code_Ranges_for_UTF-16_Character_Codes.png)
![](images/Unicode_Character_Code_Ranges_for_UTF-8_Character_Codes.png)

* KOREAN_MORPH_LEXER 제한사항 : 문장, 단락 미지원  
         
* KOREAN_MORPH_LEXEX 속성  

Attribute|Attribute value  
----------|-------------  
    verb_adjective| 동사, 형용사, 부사 인덱싱 여부 지정. TRUE or False, Default is FALSE.
    one_char_word| 음절 인덱싱 여부 지정, TRUE or False,Default is FALSE.
    number|숫자 인덱싱 여부 지정. TRUE or False, Default is FALSE.
    user_dic|User dictionary 인덱싱 여부 지정. TRUE or False, Default is TRUE.
    stop_dic|stop-word dictionary 사용 여부. TRUE or False, Default is TRUE. .
    composite|복합명사 스타일 지정. COMPOSITE_ONLY : 복합명사만 인덱싱. NGRAM : 복합명사를 구성한 모든 단어를 인덱싱. COMPONENT_WORD : 단일명사와 해당 복합명사 인덱싱. Default is COMPONENT_WORD.
    morpheme|형태소 분석 여부 지정. TRUE or False, "False" 경우 공백과 같은 구분자에 의해 구분된 단어들로 토큰 생성. Default is TRUE.
    to_upper|영어 대문자로 변환 여부 지정. TRUE or False, Default is TRUE.
    hanja|한자들에 대한 인덱싱 여부 지정. TRUE or False, "FALSE" 경우 한글로 변환. Default is FALSE.
    long_word|한글에서 16 음정 이상의 긴 단어에 대한 인덱싱 여부 지정. TRUE or False, Default is FALSE.
    japanese|Unicode에 있는 일본 문자들의 인덱싱 여부 지정.(only in the 2-byte area). TRUE or False, Default is FALSE.
    english|alphanumeric strings 인덱싱 여부 지정. TRUE or False, Default is TRUE.

 
* KOREAN_MORPH_LEXER 예제 - NGRAM 예제  
```sql
begin
ctx_ddl.create_preference('my_lexer','KOREAN_MORPH_LEXER');
ctx_ddl.set_attribute('my_lexer','COMPOSITE','NGRAM');  

create index koreanx on korean(text) indextype is ctxsys.context
parameters ('lexer my_lexer');
end

'정보처리학회' 경우 6개의 단어로 Token을 분리함.   
'정보','처리','학회','정보처리','처리학회','정보처리학회'
```
  
* KOREAN_MORPH_LEXER 예제 - COMPONENT_WORD 예제  
```sql
begin
ctx_ddl.create_preference('my_lexer','KOREAN_MORPH_LEXER');
ctx_ddl.set_attribute('my_lexer','COMPOSITE','COMPONENT_WORD');
end  

create index koreanx on korean(text) indextype is ctxsys.context
parameters ('lexer my_lexer');

'정보처리학회' 경우 4개의 단어로 Token을  분리함.  
'정보','처리','학회','정보처리학회'
```

Reference 문서
[Oracle® Text Reference 12c Release 1 \(12.1\) E41399-05](http://docs.oracle.com/database/121/CCREF/cdatadic.htm#CCREF0200) http://docs.oracle.com/database/121/CCREF/cdatadic.htm#CCREF0200  
----


#### Text Dictionary 파일 sample
##

1. Grammer Dictionary(drk2sdic.dat)
```
;===========================[ 기분석 사전 ]============================
;
; 1. 한 line에 한 단어에 대한 분석결과 한 개만 나열하며,
;    각 line은 '단어' 뒤에 <형태소, 품사 tag>쌍들로 구성.
;    단어와 품사열의 delimiter로 blank와 tab < > , +를 사용.
; 2. 형태소
;    어근      : 기본형으로 기술
;    조사/어미 : 단어에 나타난 대로 기술하거나 또는 기본형으로 기술 가능
;                사용 목적에 맞춰 기술하여 ?
玲淪玖?자동 변환이 안됨.
;                (예) '은/는', '이/가' 등
;    선어말어미: '시/었(았)/었/겠'만 허용
;    접미사    : 'hdic/sfx-n.h'와 'header/sfx-v.h'에 있는 것만
: 허용
; 3. 형태소 품사 tag
;    어근(명사, 동사, 부사 등) : 문자열 -- 'hdic2/dicpos.h' 참조
;    문법형태소(조사, 어미, 접미사 등) : 1 문자 -- 'header/tag-snu.h' 참조
;
;    <<주의>> 서술격 조사 '이'의 품사는 't'(접미사)로 기술해야 함.
;
; 4. Text editor로 삽입/삭제시에 반드시 sorting 순서를 지켜야 함.
; 5. 이 파일은 KS C 5601-1987 한글코드로 작성되어야 합니다.
; 6. line의 첫문자가 ';'이면 comment로 간주하여 무시됨.
; 7. HAM이 성공적으로 분석한 결과를 기분석 사전에 수록하면,
;    동일한 분석결과가 2개 출력되는 문제가 발생함.
; 8. 이 사전에 수록될 수 있는 최대 단어수는 5,000단어까지이며,
;    또한 총 40,000bytes를 넘지 않아야 합니다. comment는 제외하고.
;
거다re--<것, P> + <이, c> + <다, e>
거란    <것, P> + <이, c> + <란, e>
거로군요        <것, P> + <이, c> + <로군요, e>
건      <것, P> + <은, j>
걸      <것, P> + <을, j>
게      <것, P> + <이, j>
고걸로  <고것, P> + <으로, j>
고게    <고것, P> + <이, j>
그거야  <그것, P> + <이, c> + <야, e>
그건    <그것, P> + <은, j>
그걸    <그것, P> + <을, j>
그걸로  <그것, P> + <으로, j>
그게    <그것, P> + <이, j>
난      <나, P> + <는, j>
날      <나, P> + <를, j>
내      <나, P> + <의, j>
;내게   <나, P> + <에게, j>
넌      <너, P> + <는, j>
널      <너, P> + <를, j>
네      <너, P> + <의, j>
;네게   <너, P> + <에게, j>
누가    <누구, P> + <가, j>
누구    <누구, P> + <의, j>
누군가  <누구, P> + <이, c> + <ㄴ가, e>
누군가는        <누구, P> + <이, c> + <ㄴ가는, e>
누군가도        <누구, P> + <이, c> + <ㄴ가도, e>
누군가를        <누구, P> + <이, c> + <ㄴ가를, e>
누군데  <누구, P> + <이, c> + <ㄴ데, e>
누군지  <누구, P> + <이, c> + <ㄴ지, e>
누군지를        <누구, P> + <이, c> + <ㄴ지를, e>
누굴    <누구, P> + <를, j>
마라    <말, V> + <어라, e>
마라고  <말, V> + <어라고, e>
무어라  <무엇, P> + <이, c> + <라, e>
무어라고        <무엇, P> + <이, c> + <라고, e>
무언가--<무엇, P> + <이, c> + <ㄴ가, e>
무언가가        <무엇, P> + <이, c> + <ㄴ가가, e>
무언가는        <무엇, P> + <이, c> + <ㄴ가는, e>
무언가도        <무엇, P> + <이, c> + <ㄴ가도, e>
무언가를        <무엇, P> + <이, c> + <ㄴ가를, e>
무언데  <무엇, P> + <이, c> + <ㄴ데, e>
무얼    <무엇, P> + <을, j>
무얼로  <무엇, P> + <으로, j>
뭐가    <무엇, P> + <이, j>
뭐냐    <무엇, P> + <이, c> + <냐, e>
뭐니    <무엇, P> + <이, c> + <니, e>
뭐든지  <무엇, P> + <이, c> + <든지, e>
뭐라    <무엇, P> + <이, c> + <라, e>
뭐라고  <무엇, P> + <이, c> + <라고, e>
뭐람    <무엇, P> + <이, c> + <람, e>
뭐지    <무엇, P> + <이, c> + <지, e>
뭔지    <무엇, P> + <이, c> + <ㄴ지, e>
뭔지가  <무엇, P> + <이, c> + <ㄴ지가, e>
뭔지는  <무엇, P> + <이, c> + <ㄴ지는, e>
뭔지도  <무엇, P> + <이, c> + <ㄴ지도, e>
뭔지를  <무엇, P> + <이, c> + <ㄴ지를, e>
뭘      <무엇, P> + <을, j>
뭘로    <무엇, P> + <으로, j>
뭣에    <무엇, P> + <에, j>
얘는    <이아이, P> + <는, j>
얘를    <이아이, P> + <를, j>
어디론가        <어디, P> + <론가, j>
어딜    <어디, P> + <를, j>
여긴    <여기, P> + <는, j>
여길    <여기, P> + <를, j>
요거야  <요것, P> + <이, c> + <야, e>
요건    <요것, P> + <은, j>
요걸    <요것, P> + <을, j>
요걸로  <요것, P> + <으로, j>
요게    <요것, P> + <이, j>
요걸    <요것, P> + <을, j>
요걸로  <요것, P> + <으로, j>
요게    <요것, P> + <이, j>
이거야--<이것, P> + <이, c> + <야, e>
이건    <이것, P> + <은, j>
이걸    <이것, P> + <을, j>
이걸로  <이것, P> + <으로, j>
이게    <이것, P> + <이, j>
이젠    <이제, A> + <는, j>
쟤는    <저아이, P> + <는, j>
쟤를    <저아이, P> + <를, j>
쟨      <저아이, P> + <는, j>
저거야  <저것, P> + <이, c> + <야, e>
저건    <저것, P> + <은, j>
저걸    <저것, P> + <을, j>
저걸로  <저것, P> + <으로, j>
저게    <저것, P> + <이, j>
저긴    <저기, P> + <는, j>
저길    <저기, P> + <를, j>
전      <저, P> + <는, j>
절      <저, P> + <를, j>
제      <저, P> + <의, j>
;제게   <저, P> + <에게, j>
조거야  <조것, P> + <이, c> + <야, e>
조건    <조것, P> + <은, j>
조걸    <조것, P> + <을, j>
조걸로  <조것, P> + <으로, j>
;죽어라고       <죽, I> + <어라고, e>
테니    <터, P> + <이, c> + <니, e>
테니까  <터, P> + <이, c> + <니까, e>
테다    <터, P> + <이, c> + <다, e>
텐데    <터, P> + <이, c> + <ㄴ데, e>
;
;===========================[ 기분석 사전 끝 ]==========================
```

2. Stopword Dictionary(drk2xdic.dat)
```
;
;
;====================[ 불용어 및 특수색인어 사전 ]======================
;
; 불용어(stopword)는 자동색인시에 색인어로 추출되지 않도록 하고 싶은
; 명사들입니다. 즉, 이 파일에 등록된 stopword들은 색인어로
; 출력되지 않습니다.
;
; 특수색인어는 자동색인시에 1 음절 명사 혹은 숫자로 시작되는
; 용어가 누락되는 것을 방지하기 위한 것으로 특수색인어로 등록되면
; 항상 색인어로 추출해 줍니다.
;
;
; 1. 이 파일은 반드시 KS 완성형(KS C 5601-1987) 한글코드로 작성되어야 합니다.
;
; 2. line의 첫문자가 ';'이면 comment로 간주하여 무시됩니다.
;
; 3. line의 첫문자가 '0'이면 불용어로서 색인어로 출력되지 않습니다.
;
; 4. line의 첫문자가 '1'이면 특수색인어로서 항상 색인어로 출력됩니다.
;    1 음절 명사(예: 꽃, 핵)나 숫자로 시작되는 용어(예: 3.1절) 등
;    default로 불용어로 간주되는 용어가 누락되지 않게 할 때 사용합니다.
;
; 5. 색인어로 추출되지 않는 한글 명사를 특수색인어로 등록해도
;    여전히 누락되는 경우가 있습니다. 이러한 용어는 특수색인어로
;    등록하지 말고 사용자 정의사전(hangul.usr)에 등록하면 됩니다.
;
; 6. 한 line에 하나의 단어(명사)만 허용되며, line 중간에 blank 문자를
;    허용하지 않습니다.
;
; 7. Text editor로 삽입/삭제할 때 반드시 sorting 순서를 지켜야 합니다.
;    sorting 순서가 틀리면 실행할 때 error message를 출력합니다.
;
; 8. 이 사전에 수록될 수 있는 최대 단어수는 10,000단어까지이며,
;    또한 총 60,000bytes를 넘지 않아야 합니다. comment는 제외함.
;
;
;
112-12
112-12사태
112.12
112.12사태0%)
13-1절
13.1절
1386
1386PC
14-19
14-19혁명
14.19
14.19혁명
1486
1486PC
15-16
15-16혁명
15.16
15.16혁명
15.17
15.18
1586
1586PC
16.25
16.25사변
; 1IBM연구소
0가
0가급적
0가능
0가능성
0가량
0가로
0가로세로
0가리
0가면
0가운데
0가장
0가지
0가하
0각급
0각도
0각자
0각종
0각지
0간격
0간단
0간소화
0간주
0갈
0감안
0갑
0갑자
0강약점
0강의
0강하
0개개
0개개인
0개국
0개당
0개량
0개별
0개비
0개월
0개의
0걔
0거
0거개
0거금
0거기
0거기대로
0거긴
0거대
0거두
0거두게
0거론
```

3. User defined Dictionary(drk2udic.dat)
```
;=========================[ 사용자 정의사전 ]==========================
;
; 1. 이 파일은 KS C 5601-1987 한글코드로 되어 있습니다.
;
; 2. line의 첫문자가 ';'이면 comment로 간주하여 무시됩니다.
;
; 3. 한 line에 하나의 단어만 허용되며, 각 line은
;    <단어, 품사열>쌍으로 구성됩니다.
;    '단어'가 동사/형용사 등 용언이면, '-다'를 삭제한 원형을 써야 합니다.
;    단어와 품사열을 구분하는 delimiter는 blank입니다.
;
; 4. 품사열은 각 단어에 대하여 'hdic2/dicpos.h'에 나열된 것 중에서
;    하나를 명시해야 합니다.
;
; 5. Text editor로 삽입/삭제할 때 반드시 sorting 순서를 지켜야 합니다.
;
; 6. 이 사전에 수록될 수 있는 최대 단어수는 50,000단어까지이며,
;    또한 총 300,000bytes를 넘지 않아야 합니다. comment는 제외함.
;
; <<주의>> 사용자 정의사전 수천 or 수만 개의 단어를 수록하면
;          초기화할 때 사전을 load하는 시간이 많이 걸립니다.
;
;
가득차 I
강원대 N
; '개마'는 '개마 고원' 분석시에 '개마'가 명사로 출력되도록 한 것임.
개마 N
거란 N
걷어올리 T
걸프만 N
경수로 N
; '전자계산소'를 '전자+계산소'로 분해하기 위한 것
계산소 N
고려가 N
고려대 N
고해상도 N
골드만 N
공헌도 N
관심도 N
그것 P
그러기 A
그리하여 A
기여도 N
깊이 A
꼽히 S
남북한 N
다시말하 T
도매가 N
들어올리 T
등 NX
등등 X
디즈니 N
때려죽이 CT
떠올리 CT
; 로 --> furnace for HPMT
로 N
마라도 N
만하 K
모아들 I
모아들이 C
못하 TKVJ
무브러시 N
무용과 N
미디 N
미인도 N
미카엘 N
미테랑 N
받아들 T
법제도 N
법학과 N
```
