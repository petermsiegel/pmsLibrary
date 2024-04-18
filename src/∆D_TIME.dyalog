 TIME
 ;cmpx;kk;vv;ss
 'cmpx'⎕CY'dfns'

 :Trap 1000
     type←'char vec'
     'Timing (a) hashed vs (b) unhashed table lookups (with defaults)'
     '       ','with existing "left", existing "right", new, and mixed (old/new)'
     '       key type:',type 
     {}UCMD'load ∆D'
     :For n :In  10 50 100 500 1000 10000 100000
         kk← ⍕¨⍳n ⋄ vv← ⍳n  
         a← 'xx' ∆DL kk vv ⋄ b← 'xx' ∆DL kk vv ⋄ a.Hash 
         exL exR nu mx←  ⍕¨¨ (1 2) (n-2 1) (n+0 1) (n+ ¯1 0)
         ⎕←'***** N=',n
         cmpx '_← a[exL]' '_← a[exR]' '_← a[nu]'  '_← a[mx]' '_← b[exL]' '_← b[exR]' '_← b[nu]' '_← b[mx]'
     :EndFor
 :Else
     'Done'
 :EndTrap
