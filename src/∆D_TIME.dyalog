 TIME
 ;dfns;ii;jj;kk;a;b;c;n;scale;t;kk;vv
 'cmpx'⎕CY'dfns'

 :Trap 1000
     'Starting'
     {}UCMD'load ∆D'
    ⍝   1000000 130000 180000 ¯27.8%  AAAAAAAAAAAAAAAAAAAAAAAAAAAA
     ⎕←'    N     A(us)  B(us)   T    '
     ⎕←' ¯¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯ '
     :For n :In 10 50 75 100 250 500 750 1000 ⍝ 10000 100000

         ii←↓⍉↑(⍕¨⍳n)(n⍴⊂'test')
         kk←⍕¨1,n-1 ⋄ vv←'45' '90'

         {}⎕EX¨'AB' ⋄ {}⎕WA
         A←'xx'∆D ii ⋄ A.Hash
         a←1000000×⍎cmpx'A[kk]←vv⊣ A.Del ⍕1'
         {}⎕EX¨'AB' ⋄ {}⎕WA
         B←'xx'∆D ii
         b←1000000×⍎cmpx'B[kk]←vv⊣ B.Del ⍕1'
         scale←0.5
         :If a<b
             t←100×b÷⍨a-b
             c←'A'⍴⍨⌊scale×0.5+|t
         :Else
             t←100×b÷⍨a-b
             c←'B'⍴⍨⌊scale×0.5+|t
         :EndIf
         (,'I8,⊂ ⊃,I6,⊂ ⊃,I6,⊂ ⊃,F5.1,⊂%⊃'⎕FMT,¨n a b t),'  ',c
     :EndFor
 :Else
     'Done'
 :EndTrap
