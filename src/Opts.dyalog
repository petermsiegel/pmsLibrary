 Opts←{
  5:: 5 ⎕SIGNAL⍨'Opt: Invalid options'
     ↓⍉↑ o⌷⍨¨ ⊂⊂(⍳∘∪)⍨⊃o← ↓∘⍉∘↑⍵,⍺
 }
