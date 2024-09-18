 BITest
 ;a;m;p10;p100;pN;pList;p_1List;pS;m;op;t;vs
 ;i10;i100 
 ;big;nats;Cmpy;cmpx;STD_TIME; TIME 
 ;ADHOC; VALUE_TEST;QUIET; TIME_TEST
 ;⎕IO;⎕TRAP

 UCMD'load BigInt'
 UCMD'load Cmpy'

 'big' 'nats' 'cmpx' ⎕CY'dfns'

 ⎕TRAP←1000 'C' '→0,⎕←''Interrupted. Bye!'''

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
      ⎕←'Comparison of results from BI, nats, big?'
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
    pList← (10*1 3 6)⍴¨ ⊂p100
:Else 
    pList←(10*1 2 3 4 5)⍴¨⊂p100
:EndIf 
p_1List← ¯2↓¨ pList 
pS← ⍕314159265 

 :If TIME_TEST←1
     :For t :In '+-×÷'
         ⎕←'*** OP IS ',t
         :For pN pN_1 :InEach pList p_1List  
             x←¯30↑,⎕FMT'    ≢pN=',(⍕≢pN),' vs ≢p_N1=',(⍕≢pN_1 )
             vs← 'pN op BI pN_1' 'pN op nats pN_1'  
             vs←  'op' ⎕R t⊣ vs
              x'→→→ ', (7 3⍕÷/⌽⍎∘cmpx¨ vs)           ⍝ Like cmpx, but 1 Cmpy... sorts the results by time.
         :EndFor
         ⎕←''
     :EndFor
     :For t :In '+-×÷'
         ⎕←'*** OP IS ',t
         :For pN :In pList  
             x←¯30↑,⎕FMT'    ≢pN=',(⍕≢pN),' vs pS=',pS 
             vs← 'pN op BI pS' 'pN op nats pS'  
             vs←  'op' ⎕R t⊣ vs
              x'→→→ ', (7 3⍕÷/⌽⍎∘cmpx¨ vs)           ⍝ Like cmpx, but 1 Cmpy... sorts the results by time.
         :EndFor
         ⎕←''
     :EndFor
     ⎕←'**** pN vs 1E4 (division by power of 10)'
     :For pN  :In pList  
          x←¯30↑,⎕FMT'÷    ≢pN=',(⍕≢pN) 
          vs← 'pN ÷BI 1E4' 'pN ÷nats 1E4'
          x'→→→ ', (7 3⍕÷/⌽⍎∘cmpx¨ vs)  
          ⎕←''
     :EndFor
 :EndIf
