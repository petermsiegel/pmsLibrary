 RadixCmp
 ;_ ;cod;dataV;fnNm;min; myFns;title;sorted;test;testFns;testS;time;timing_abort;ctl
 ;cmpx;Radix_fn
⍝ Does demo and exports <RadixSort>
⍝ Based on Radix Sort in C++ Programming
 timing_abort←0
 'cmpx'⎕CY'dfns'
 
 testFns← 1/ (⊂'Radix'),¨'1' '2'  '3' '4' '4d'   
 ⎕←'>>> Loading ',¯2↓∊testFns,¨⊂', '
 myFns←{⎕SE.UCMD'Load ',⍵}¨testFns
 dataV←121 ¯232 432 564 2432342 0 ¯233 23 1 233 45 788 ¯2432341 32444
 title←↑'Data' 'Sorted',¨':'
 :Trap 1000
     ctl←dataV[⍋dataV]
     ⎕←title,↑dataV ctl
     :For fnNm :In myFns
         Radix_fn←⍎fnNm
         sorted←Radix_fn dataV
         :If sorted≡ctl
             ⎕←'Sort successful: ',fnNm
         :Else
             ⎕←'Whoops. Sort failed: ',fnNm
             timing_abort←1
         :EndIf
     :EndFor
     :If timing_abort
         ⎕←'Timing tests could not be executed'
         :Return
     :EndIf

     :For testS :In '100' '1E3' '1E6'
         ⍞←'* Let dataV← ¯50+{ ⍵? 10+⍵ } ',testS
         test←⊃⌽⎕VFI testS
         dataV←¯50+test?10+test
         time← ⊃⌽⎕VFI ∊' ',⍨¨cmpx¨cod←'dataV[⍋dataV]',⍥⊆(⊂'10 '),¨testFns,¨⊂' dataV'
         min←⌊/time
         _←time{o←⍋⍺ ⋄ ⍺[o]{⎕←(8 1⍕⍺÷min),'×  ',(1↓¯3⍕⍺),' => ',⍵}¨⍵[o] }cod
     :EndFor
 :Else
     ⎕←'*** Interrupted. Bye'
 :EndTrap
