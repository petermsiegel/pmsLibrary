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

 BIGR←   '+-×÷|<≤=≥>≠'
 SMALLR← ,'*'  

 SameBig← {  aa←⍎⍺⍺ ⋄ ok← (⍕⍺ (aa big) ⍵ )  ≡ ⍕⍺ (aa BI) ⍵ ⋄ ok⊃ 'Different' 'Same'}
 SameNats← { aa←⍎⍺⍺ ⋄ ok← (⍕⍺ (aa nats) ⍵ ) ≡ ⍕⍺ (aa BI) ⍵ ⋄ ok⊃ 'Different' 'Same'}
 TBig← {  L R⊢← ⍺ ⍵ ⋄  w (⍺⍺∆)¯10↑'%',⍨0⍕w← 100×÷⍨/⍎∘cmpx¨'⍺⍺' ⎕R ⍺⍺⊢ '(L (⍺⍺ BI) R)' '(L (⍺⍺ big) R)' }
 TNats← { L R⊢← ⍺ ⍵ ⋄  w (⍺⍺∆)¯10↑'%',⍨0⍕w← 100×÷⍨/⍎∘cmpx¨'⍺⍺' ⎕R ⍺⍺⊢ '(L (⍺⍺ BI) R)' '(L (⍺⍺ nats) R)'}
 ∆← { L R←20 30 ⋄ L1← L-1 ⋄ f← ' ',' ',⍨6⍴⍕⍺⍺ 
     ⍺≤90:   ⍵,f,(k⍴ '⌷'),(' '⍴⍨ 0⌈L-k),'|' ⊣ k← ⌈L×⍺÷100
     ⍺≤110:  ⍵,f,(L⍴'∘'),'|'
             ⍵,f,(L⍴'∘'),'|', k⍴'⎕' ⊣ k← R⌊⌈10× 10⍟⍺÷100
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
            '    Perf vs big:    ',L (OP TBig)R
            '    Perf vs nats:   ',L (OP TNats)R
       :ENDFOR
:ENDFOR 


:FOR LENL :in  100 10 1
    :FOR R :in '100' '50' '20' '1'  
       L← LENL⍴'5',⎕D
       ⎕←'LENL=',LENL,' R=',R 
       OP← '*'
      '  OP=',OP 
      '    Values vs big:  ','*** NOT AVAILABLE IN big'
      '    Values vs nats: ', L (OP SameNats)R 
      '    Perf vs big:    ','*** NOT AVAILABLE IN big'
      '    Perf vs nats:   ', L (OP TNats)R
    :ENDFOR
:ENDFOR 


