ns← Setup  
  ;opsys; sharedlib; dyalib; apledition; aplwidth
 
⍝ Tweak of ws: 
⍝     quadna.dws
⍝ Returns namespace containing:
⍝    vars: opsys sharedlib dyalib apledition aplwidth
⍝    fns:  strncpy
 
 ns← ⎕NS ''

 :Select 3↑⊃'.'⎕WG'APLversion'
 :Case 'AIX'
     opsys←'AIX'
 :Case 'Mac'
     opsys←'Mac'
 :Case 'Win'
     opsys←'Windows'
 :Case 'Lin'
     :Select 4↑⊃⎕SH'uname -a'
     :Case 'armv'
         opsys←'Pi'
     :Else
         opsys←'Linux'
     :EndSelect
 :EndSelect
 ⍝
 apledition←⊃(80=⎕DR'  ')↓'Classic' 'Unicode'
 aplwidth←{z←⍵ ⋄ 2×⍬⍴⎕SIZE'z'}⍬
 ⍝
 :Select opsys
 :Case 'AIX'               ⍝ Slightly different specification of libc on AIX !
     sharedlib←'libc.a'
     sharedlib,←⊃(aplwidth=64)↓'(shr.o)' '(shr_64.o)'
     dyalib←'dyalog',(⍕aplwidth),'.so'
 :CaseList 'Linux' 'Pi'
     sharedlib←libc ⍬
     dyalib←'dyalog',(⍕aplwidth),'.so'
 :Case 'Mac'
     sharedlib←'/usr/lib/libc.dylib'
     dyalib←'dyalog',(⍕aplwidth),'.dylib'
 :Else
     ('Unknown operating system: ',opsys)⎕SIGNAL 11
 :EndSelect
 sharedlib←' ',sharedlib,'|'
 dyalib←' ',dyalib,'| '

 ns.(opsys sharedlib dyalib apledition aplwidth)← opsys sharedlib dyalib apledition aplwidth
 ns.{ 'strncpy'⎕NA dyalib,'STRNCPY >0T1[] P U4' }⍬
