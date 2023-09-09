Radix 
  ; dataV; title; sorted; ctl; cmpx
⍝ Does demo and exports <RadixSort>
⍝ Python alg:  https://www.programiz.com/dsa/radix-sort#google_vignette
  ⎕←'>>> Exporting RadixSort to active namespace.'
  'cmpx'  ⎕CY 'dfns'
⍝ Based on Radix Sort in C++ Programming
RadixSort← { ⍝  outputV@IV ← ∇ arrayV 
    DIV← ⌊÷
    CountingSort←{   
        CountScan←{  
          place← ⍵
          countV[]←0
          (≢arrayV){                                 ⍝ ⍵≥⍺: termination value
            ⍵≥⍺: place⊣ countV[]← +\countV 
              countV[ base| arrayV[ ⍵ ] DIV place]+←1 
              ⍺ ∇ ⍵+1
          }0
        }
        OutScan← {  
          place← ⍵      
          {⍵<0: outV                        
            sel← base| arrayV[⍵] DIV place
            outV[ countV[ sel ]- 1]← arrayV[⍵]
            countV[ sel ]-← 1
            ∇ ⍵- 1 
          } ¯1+ ≢arrayV                     
        }
        place arrayV← ⍺ ⍵
        OutScan CountScan place
    }   ⍝ End CountingSort
    CountByPlace←{ 
      { 0≥ max DIV ⍵: outV 
          arrayV∘← ⍵ CountingSort arrayV
          ∇ ⍵ × base  
      } 1 
    } 
        
    base← 4096                                          ⍝ Base should be multiple of 256 
    arrayV←,⍵ 
    max← ⌈/ |arrayV
    outV←  arrayV
    countV← base⍴0 
    arrayV← CountByPlace ⍬
    lt0← arrayV<0 
    (lt0/ arrayV), arrayV/⍨ ~lt0                        ⍝ One more pass for negative nums
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
