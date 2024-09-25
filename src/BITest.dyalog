 BITest
 ;a;m;p10;p100;pN;pList;p_1List;pS;m;op;t;vs
 ;i10;i100 
 ;big;nats;Cmpy;cmpx;STD_TIME; TIME 
 ;ADHOC; VALUE_TEST;QUIET; TIME_TEST
 ;⎕IO;⎕TRAP

 UCMD'load BigInt'
 UCMD'load Cmpy'

 'big' 'nats' 'cmpx' ⎕CY'dfns'

 ⎕TRAP←1000 'C' '→0⊣⎕←table⊣⎕←''Interrupted. Bye!'''

 p100←100⍴'1',⎕D
 p10←10⍴p100
 m←'¯',p100 
 a←1234
 i100← →BI p100
 i10← →BI p10

 STD_TIME← 0
 :IF STD_TIME
     TIME← cmpx   
:Else 
     TIME← 1∘Cmpy 
:EndIF 
 QUIET←1 
 :If VALUE_TEST←1
      failures←0
      :IF FASTER_TEST←0
          ⎕←'How much faster are BI and nats than big on N+N and N×N?'
          table←1 4⍴(↑'' 'op') (↑'nelem' '(N)') (↑'   BI' 'vs big') (↑'  nats' 'vs big')
          ⍞←'+'
          :FOR N :IN 100 10000  
              ⍞←(⍕N),' '
              pN← N⍴'1',⎕D 
              B n b← ⍎∘cmpx¨ 'pN +BI pN' 'pN +nats pN' 'pN +big pN'
              table⍪←'+' N (⍎0 1⍕B÷⍨b) (⍎0 1⍕n÷⍨b)
          :EndFor 
          ⍞←⎕UCS 13 
          ⍞←'×'
          :FOR N :IN 100 1000
              ⍞←(⍕N),' '
              pN← N⍴'1',⎕D 
              B n b← ⍎∘cmpx¨ 'pN ×BI pN' 'pN ×nats pN' 'pN ×big pN'
              table⍪←'×' N (⍎0 1⍕B÷⍨b) (⍎0 1⍕n÷⍨b)
          :EndFor
          ⎕←''
          ⎕←table
          ⎕←'' 
      :EndIf 
      v1←500⍴'1',⎕D
      v2←400⍴'9',⎕D 
      OPCODES←'+-×÷|<≤=≥>≠'
      ⎕←'Evaluate (a +big b) vs (a +BI b), '
      ⎕←'    where + represents ', OPCODES
      ⎕←'and where v1: 500-digit number; v2: 400-digit number'
      ⎕←'***** timing_BIG÷timing_BI *****'
      :For t :IN OPCODES 
         (5⍴t), ' big is ',' times slower than BI',⍨ 1⍕¨÷⍨/⍎∘cmpx¨ ('v1 ',t,'BI v2') ('v1 ',t,'big v2')
      :EndFor 
     :For t :In '+-×÷∨∧⌈⌊|<≤=≥>≠'
         op←⍎t
         :Trap 0
             :If (p100 op nats p10)≡p100 op BI p10
               :IF ~QUIET ⋄  t,' BI vs nats test ok' ⋄ :ENDIF 
             :EndIf
         :Else
             failures+← 1 
             t,' BI vs nats test failed'
         :EndTrap
     :EndFor

     :If (p10*nats a)≡(p10*BI a)
         :If ~QUIET ⋄ '* BI vs nats test ok' ⋄ :ENDIF 
     :EndIf

     :For t :In '+-×÷|<≤=≥>≠'
         op←⍎t
         :Trap 0
             :If (p100 op big p10)≡p100 op BI p10
               :IF ~QUIET ⋄  t,' BI vs big  test ok' ⋄ :Endif 
             :EndIf
         :Else
             failures+← 1
             t,' BI vs big  test failed'
         :EndTrap
     :EndFor
      ⎕←'*** There were',failures,'failures'
 :EndIf

:if ADHOC←1 
    pList← (10*1 2 3 4)⍴¨ ⊂p100
:Else 
    pList←(10*1 2 3 4 5)⍴¨⊂p100
:EndIf 
p_1List← ¯2↓¨ pList 
pS← ⍕314159265 

⎕←'*** Relative speed of BI vs nats on a variety of object sizes and op codes ***'
⎕←'¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨'
 table← 1 3⍴ 'Type' 'N' 'BI÷nats'
 :If TIME_TEST←1
     :For t :In '+-×÷'
         ⎕←'*** OP IS ',t
         :For pN pN_1 :InEach pList p_1List  
             x←¯30↑,⎕FMT'    ≢pN=',(⍕≢pN),' vs ≢p_N1=',(⍕≢pN_1 )
             vs← 'pN op BI pN_1' 'pN op nats pN_1'  
             vs←  'op' ⎕R t⊣ vs
             ⍞←x 
             table⍪←('N',t,'N') (≢pN)  (⍎2⍕÷/⌽⍎∘cmpx¨ vs) 
             ⍞←⎕UCS 13 
         :EndFor
         ⎕←''
     :EndFor
     :For t :In '+-×÷'
         ⎕←'*** OP IS ',t
         :For pN :In pList  
             x←¯30↑,⎕FMT'    ≢pN=',(⍕≢pN),' vs pS=',pS 
             vs← 'pN op BI pS' 'pN op nats pS'  
             vs←  'op' ⎕R t⊣ vs
             ⍞←x 
              table⍪←('N',t,'small') (≢pN)  (⍎2⍕÷/⌽⍎∘cmpx¨ vs) 
              ⍞←⎕UCS 13 
         :EndFor
         ⎕←''
     :EndFor
     ⎕←'**** pN vs 1E4 (division by power of 10)'
     :For pN  :In pList  
          x←¯30↑,⎕FMT'÷    ≢pN=',(⍕≢pN) 
          vs← 'pN ÷BI 1E4' 'pN ÷nats 1E4'
           ⍞←x 
           table⍪←('N÷1E4') (≢pN)  (⍎2⍕÷/⌽⍎∘cmpx¨ vs) 
           ⍞←⎕UCS 13 
     :EndFor
     ⎕←table 
 :EndIf
