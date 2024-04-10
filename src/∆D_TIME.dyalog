 TIME
 ;dfns;ii;jj;kk;a;b;n
 'cmpx'⎕CY'dfns'

 :Trap 1000
     'Starting'
     {}UCMD'load ∆D'
    ⍝   1000000 130000 180000 ¯27.8%  AAAAAAAAAAAAAAAAAAAAAAAAAAAA
     ⎕←'    N     A(us)  B(us)   T    '
     ⎕←' ¯¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯ '
     :For n :In 10 100 200 250 300 350 400 450 500 1000 5000 10000 100000 1000000

         ii←n⍴(0 10)(1 20)(2 30)(3 40)(4 50)
         kk←⍕¨0.5+jj←n⍴⍳10
         #.ALGORITHM←'A' ⋄ {}⎕EX¨'ab' ⋄ {}⎕WA
         a←∆D ii
         a←1000000×⍎cmpx'a[jj]←kk'
         #.ALGORITHM←'B' ⋄ {}⎕EX'b' ⋄ {}⎕WA
         b←∆D ii
         b←1000000×⍎cmpx'b[jj]←kk'
         :If a<b
             t←100×b÷⍨a-b
             c←'A'⍴⍨⌊0.5+|t
         :Else
             t←100×b÷⍨a-b
             c←'B'⍴⍨⌊0.5+|t
         :EndIf
         (,'I8,⊂ ⊃,I6,⊂ ⊃,I6,⊂ ⊃,F5.1,⊂%⊃'⎕FMT,¨n a b t),'  ',c
     :EndFor
 :Else
     'Done'
 :EndTrap
