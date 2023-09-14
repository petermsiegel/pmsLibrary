RadixCmp 
  ; dataV; fnNm; list; myFns; title; sorted; test; testS; timing_abort; ctl; cmpx
  ; Radix_fn
⍝ Does demo and exports <RadixSort>
⍝ Based on Radix Sort in C++ Programming
  timing_abort←0
  'cmpx'  ⎕CY 'dfns'
  list← 'Radix1' 'Radix2' 'Radix3' 'Radix4'
  ⎕←'>>> Loading ',¯2↓∊list,¨⊂', '
  myFns← {⎕SE.UCMD 'Load ',⍵}¨list
    dataV←  121 ¯232 432 564 2432342 0 ¯233 23 1 233 45 788 ¯2432341 32444
    title←  ↑'Data' 'Sorted',¨ ':'
    :TRAP 1000
        ctl←    dataV[ ⍋dataV ]
        ⎕←title, ↑dataV ctl
       :FOR fnNm :IN myFns
            Radix_fn← ⍎fnNm 
            sorted← Radix_fn dataV 
            :IF sorted≡ ctl
              ⎕←'Sort successful: ',fnNm
            :ELSE
              ⎕←'Whoops. Sort failed: ',fnNm
              timing_abort←1
            :ENDIF 
        :ENDFOR 
        :IF timing_abort 
             ⎕←'Timing tests could not be executed' 
             :Return
        :ENDIF 

        :FOR testS :IN '1E3' '1E4' '1E5'  
            ⍞← '* Let dataV← ¯50+{ ⍵? 10+⍵ } ',testS
            test← ⊃⌽⎕VFI testS
            dataV← ¯50+test?10+test
            cmpx 'dataV[⍋dataV]',⍥⊆  (⊂'10 '),¨list,¨⊂' dataV'
        :ENDFOR 
    :ELSE 
         ⎕←'*** Interrupted. Bye'
    :ENDTRAP 
