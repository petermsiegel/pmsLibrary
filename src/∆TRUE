 t←∆TRUE expr
 ⍝ Returns 1 if <expr> is true-ish, i.e. isn't simply a null vector or a data value 0 of any shape
 ⍝ Returns 1 if expr is "true"
 ⍝ An expression is "true" iff:
 ⍝     ~   0∊⍴expr
 ⍝     ~ (,0)≡∊expr and (≢ expr)∊0 1
 :If 2≠⎕NC'expr'
     t←1
 :ElseIf 0∊⍴expr
     t←0
 :ElseIf (≢  expr)∊0 1
 :AndIf (,0)≡∊expr
     t←0
 :Else
     t←1
 :EndIf
