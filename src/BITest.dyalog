 BITest
 ;a;m;p10;p100;pN;pList;m;op;t;vs
 ;i10;i100;iN;iList  
 ;big;nats;Cmpy
 ;VALUE_TEST;TIME_TEST; GIANT 
 ;⎕IO;⎕TRAP

 UCMD'load BigInt'
 UCMD'load Cmpy'

 'big' 'nats' ⎕CY'dfns'

 ⎕TRAP←1000 'C' '→0,⎕←''Interrupted. Bye!'''

 p100←100⍴'1',⎕D
 p10←10⍴p100
 m←'¯',p100 
 a←1234
 i100← →BI p100
 i10← →BI p10

 :If VALUE_TEST←1
     :For t :In '+-×÷∨∧⌈⌊|<≤=≥>≠'
         op←⍎t
         :Trap 0
             :If (p100 op nats p10)≡p100 op BI p10
                 t,' BI vs nats test ok'
             :EndIf
         :Else
             t,' BI vs nats test failed'
         :EndTrap
     :EndFor

     :If (p10*nats a)≡(p10*BI a)
         '* BI vs nats test ok'
     :EndIf

     :For t :In '+-×÷|<≤=≥>≠'
         op←⍎t
         :Trap 0
             :If (p100 op big p10)≡p100 op BI p10
                 t,' BI vs big  test ok'
             :EndIf
         :Else
             t,' BI vs big  test failed'
         :EndTrap
     :EndFor
 :EndIf

:if GIANT←0 
    pList← (10*6)⍴¨ ⊂p100
:Else 
    pList←(10*1 2 3 4 5)⍴¨⊂p100
:EndIf 
iList← →BII¨pList 

 :If TIME_TEST←1
     :For t :In '+-×÷'
         ⎕←'*** OP IS ',t
         :For pN iN :InEach pList iList 
             ⎕←'    ≢pN=',(⍕≢pN),' vs ≢p100=100'
             vs← 'iN op BII i100' 'pN op BII p100'  'pN op BI p100' 'pN op nats p100' 'pN op big p100'
             vs←  'op' ⎕R t⊣ vs
             1 Cmpy vs           ⍝ Like cmpx, but 1 Cmpy... sorts the results by time.
         :EndFor
         ⎕←''
     :EndFor
 :EndIf
