∇r←{a} (∆IO iotaIO) n
 ⍝  r ← {∆IO} (∆IO iotaIO) n
   :IF 0=⎕NC 'a' 
     a←⊢
  :Endif
  ∆IO +a ⍳ n
∇
:namespace fred
 ⍝ tests a dyalog file with multiple peer objects.
  a←⍳5
:endNamespace
∇r←iota n
 r←⍳n
∇