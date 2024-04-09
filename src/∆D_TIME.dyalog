 TIME
 ;dfns;ii;n;a;b;t;c
 'cmpx'⎕CY'dfns'

 :Trap 1000
     ii←5⍴(1 10)(2 20)(3 30)(4 40)(5 50)
     'Starting'
     :For n :In 10 100 500 1000 5000 10000 100000 1000000
         {}UCMD'load ∆D'
         jj←((n-5)⍴ii),((?1000)¯1),((?1000)¯2),((?1000)¯3),((?1000)¯4),((?1000)¯5)
         #.ALG←1
         a←1000000×⍎cmpx'∆D jj'
         #.ALG←0
         b←1000000×⍎cmpx'∆D jj'
         :If a<b
             t←100×b÷⍨a-b
             c←'A'⍴⍨⌊|t
         :Else
             t←100×b÷⍨a-b
             c←'B'⍴⍨⌊|t
         :EndIf
         (50↑∊⎕FMT' n ',(8 0⍕n),' a=',(6 0⍕a),' b=',(6 0⍕b),' a:b=',(8 1⍕t),'% '),c
     :EndFor
 :Else
     'Done'
 :EndTrap
