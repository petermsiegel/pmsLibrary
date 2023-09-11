Radix 
  ; dataV; title; sorted; ctl; cmpx
⍝ Does demo and exports <RadixSort>
⍝ Based on Radix Sort in C++ Programming
  ⎕←'>>> Exporting RadixSort to active namespace.'
  'cmpx'  ⎕CY 'dfns'
RadixSort← {  
  ⍝ For efficiency, externs: place, base, inV, cntV, outV
    DIV← ⌊÷
    CSortByPlace←{ 
        IX← {base| ⍵ DIV place}   
        place← ⍵ 
        cntV[]←0 ⋄ n← ≢inV
        _← { ⍵≥n: cntV⊢← +\cntV 
                  cntV[ IX inV[⍵] ]+←1 
                  ∇ ⍵+ 1
        }0     
        { ⍵<0: inV⊢← outV ⋄ aw← inV[⍵] ⋄ sel← IX aw 
               outV[ cntV[ sel ]← cntV[ sel ]- 1 ]← aw 
               ∇ ⍵- 1 
        } ¯1+ ≢inV                    
    }   ⍝ End CSortByPlace  
    ⍺← 256
    cntV← 0⍴⍨ base← ⍺                                      ⍝ Base should be multiple of 256 
    max← ⌈/ |outV← inV←,⍵ 
    _← { CSortByPlace ⍵ }¨ base* ⍳⌈base⍟max 
    (lt0/ inV), inV/⍨ ~lt0← inV<0                   ⍝ One more pass for negative nums
} ⍝ End RadixSort

    dataV←  121 ¯232 432 564 2432342 0 ¯233 23 1 233 45 788 ¯2432341 32444
    title←  ↑'Data' 'Sorted',¨ ':'
    :TRAP 1000
        sorted← RadixSort dataV 
        ctl←    dataV[ ⍋dataV ]
        ⎕←title, ↑dataV sorted 
        :IF sorted≡ ctl
          ⎕←'Successful sort. Timing test (dfns::cmp) next.'
        :ELSE
          ⎕←'Whoops. Data sorted incorrectly. Timing test aborted.'
          :Return 
        :ENDIF 
        ⎕SHADOW 'test' 'testS'
        :FOR testS :IN '1E3' '1E4' '1E5'  
            ⍞← '* Let dataV← ¯50+{ ⍵? 10+⍵ } ',testS
            test← ⊃⌽⎕VFI testS
            dataV← ¯50+test?10+test
            cmpx 'dataV[⍋dataV]' 'RadixSort dataV' 
        :ENDFOR 
    :ELSE 
         ⎕←'*** Interrupted. Bye'
    :ENDTRAP 
