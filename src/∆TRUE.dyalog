 ∆TRUE←{
 ⍝ Returns 1 if <expr> is true-ish, i.e. isn't null ('' ⍬ or ⎕NULL) or a single 0 (of whatever shape).
 ⍝ More complex items like (⍬ ⍬) or ('' '') are ∆TRUE, as are namespaces and classes.
 ⍝ An expression ⍵ is ∆TRUE if
 ⍝    (It is not a simple variable in ⎕NC 2) OR
 ⍝    (It has more than one element, i.e. neither 1 nor 0 elements) OR
 ⍝    (Its one element is either exactly 0 or ⎕NULL)
 ⍝ ⎕CT, ⎕DCT are implicit (i.e. numbers very near 0 are treated as ~∆TRUE)
     2≠⎕NC'⍵':1
     0∊⍴⍵:0
     ~0 1∊⍨≢∊⍵:1
     ~⊃0 ⎕NULL∊⍨∊⍵       ⍝ ⊃ ensures 1= ∆TRUE ⊃⍬⍬⍬
 }
