 BITest
 ; big; nats; cmpx
 ; BI; BII; BIM
 ; BIGR; SMALLR 
 ; L; R 
 ; LENL; LENR; OP 

⍝ BI, BIM, BII: Global 
 UCMD'load BigInt' 
 UCMD'load Cmpy'
 'big' 'nats' 'cmpx' ⎕CY'dfns'

 BIGR←   '+-×|<≤=≥>≠'
 SMALLR← '*' 'ROOT'

 SameBig← {  aa←⍎⍺⍺ ⋄ ok← (⍕⍺ (aa big) ⍵ )  ≡ ⍕⍺ (aa BI) ⍵ ⋄ ok⊃ 'Different' 'Same'}
 SameNats← { aa←⍎⍺⍺ ⋄ ok← (⍕⍺ (aa nats) ⍵ ) ≡ ⍕⍺ (aa BI) ⍵ ⋄ ok⊃ 'Different' 'Same'}
 TBig← {  L R⊢← ⍺ ⍵ ⋄  w ∆¯10↑'%',⍨0⍕w← 100×÷⍨/⍎∘cmpx¨'⍺⍺' ⎕R ⍺⍺⊢ '(L (⍺⍺ BI) R)' '(L (⍺⍺ big) R)' }
 TNats← { L R⊢← ⍺ ⍵ ⋄  w ∆¯10↑'%',⍨0⍕w← 100×÷⍨/⍎∘cmpx¨'⍺⍺' ⎕R ⍺⍺⊢ '(L (⍺⍺ BI) R)' '(L (⍺⍺ nats) R)'}
 ∆← { 
     ⍺<100:  ⍵,' < ',(k⍴'⌷'),(0⌈15-k)⍴'.'   ⊣ k← ⌈⍺÷10
             ⍵,' < ', (15⍴'∘'),'+',(15⌊⌈10⍟⍺÷10)⍴'⎕'
  }

 ⎕TRAP←1000 'C' '→0⊣⎕←''Interrupted. Bye!'''

 :FOR LENL LENR  :ineach  (1000 1000 100 100) (999 10 99 10)
       L← LENL⍴'5',⎕D
       R← LENR⍴'9',⎕D
       ⎕←'LENL=',LENL,' LENR=',LENR 
       :FOR OP :in BIGR 
            '  OP=',OP 
            '    Values vs big:  ',L (OP SameBig)R
            '    Values vs nats: ',L (OP SameNats)R
            '    Perf over big:  ',L (OP TBig)R
            '    Perf over nats: ',L (OP TNats)R
       :ENDFOR
    :ENDFOR
:ENDFOR 


