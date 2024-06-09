GenC←{
   Ucmd← { ⎕←']',⍵ ⋄ ⎕SE.UCMD ⍵ }
   SetNew← {
      ⍺,'← ⎕NEW Conundrum ',(⍕⍵),' ⋄ '
   }
   SetTests← {
      qt←'''' ⋄ qtsp←⊂qt,' '
      qtsp,⍨¨qt,¨(⍺,'.GetSlow[0]') (⍺,'.GetFast[0]') 
   }
   cmpy←{  
      ⍬{
        0=≢⍵: ⍺{
          time← ⍺ 
          p← ⍋time
          code← code[p]
          time← time[p]
          transform← time 
          rel← transform÷ ⌈/transform
          wid← ⌈/ ≢¨code 
          dif← (100⌊⎕PW)- wid+ 6+ 5
          (⍳≢code){ 
            ⊢⎕← (wid↑ ⍺⊃code),' ', (¯2⍕⍺⊃time),' ',('⎕'⍴⍨ ⌈dif×rel[⍺])
          }¨code 
        }code 
        first← ⊃⍵
        t←⍎cmpx first
        (⍺,t) ∇ 1↓⍵ 
      } (code← ⍵)
   }

  ⍵ >⍥≢ ⎕A: ⎕SIGNAL 11 

   exec← (⊃⎕RSI)∘⍎
   alf← (≢⍵)⍴ ⎕A 
   _← {0=⎕NC ⍵: Ucmd 'Load ',⍵ ⋄ ⍬}'Conundrum'
   _← {0≠⎕NC ⍵: ⍬ ⋄  ⎕←')copy dfns ',⍵  ⋄ ⍵ ⎕CY 'dfns'}'cmpx'

   setupCode← ∊ ' ⍬',⍨    alf SetNew¨⍵
   timeCode←  ∊ 'cmpy ', alf SetTests¨⍵
   
   ⎕←''
   ⎕←30⍴'_'
   ⎕←'Hit ENTER to execute the following...'
   ⎕←'  ', setupCode 
   ⎕←'  ', timeCode  
   'n'∊⎕C ⍞↓⍨≢⍞←'Run? ': 'Terminated w/o executing...'
   ⎕←'Executing setup code...' 
   _← exec setupCode
   ⎕←'Executing timing Code...'
   _←exec timeCode 
}