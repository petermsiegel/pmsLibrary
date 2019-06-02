  ∆TRUE←{
 ⍝ Returns 1 if <expr> is true-ish, i.e. isn't simply a null vector or a data value 0 of any shape
 ⍝ Returns 1 if expr is "true"
 ⍝ An expression is "true" iff:
 ⍝     ~   0∊⍴expr
 ⍝     ~ (,0)≡∊expr and (≢ expr)∊0 1
     2≠⎕NC'⍵':1
     0∊⍴⍵:0
     ~0 1∊⍨≢⍵:1
     (,0)≢∊⍵
 }
