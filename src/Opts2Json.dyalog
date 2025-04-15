 Opts2Json←{
   ⍝ (size jsonOut)← [jsonIn←''] (sizeDef ∇) opt1 [opt2 ...]
   ⍝ jsonIn:
   ⍝   a JSON5 list of key-value pairs or null.
   ⍝ sizeDef:
   ⍝   the default size variable for use in an HTMLRenderer call.
   ⍝   The size has two elements: height and width.
   ⍝   It will be the value of ¨size¨ returned, unless an option overrides it.
   ⍝ optN:
   ⍝   an APL-style key-value pair of the form ('Name' value).
   ⍝   A value of 1 or 0 will be replaced by ⊂'true' or ⊂'false', respectively.
   ⍝   Special case: a key of 'size' will have its value replace the default size.
   ⍝       The size value must be of the scalar form (height width):
   ⍝       ('size' (1000 600))
   ⍝   It will be the value returned as ¨size¨ above.
   ⍝ jsonOut:
   ⍝   The 2nd element returned; a char. string representing the udpated
   ⍝   JSON5 key-value pairs.

     T F←⊂∘⊂¨'true' 'false'   ⍝ JSON true (1) and false (0)

     JDefs←{0=≢⍵:⎕NS ⍬ ⋄ Json ⍵}
     Json←⎕JSON⍠'Dialect' 'JSON5'
     Opts←{,∘⊂⍣(2≥|≡⍵)⊢⍵}
     MergeNs←{⍺ ⍺⍺.{⍎⍺,'←⍵'}⊃T F ⍵/⍨1,⍨1 0≡¨⊂⍵}
     GetSize←'ns.size'∘{0≠⎕NC ⍺:(⎕EX ⍺)⊢⎕OR ⍺ ⋄ ⍵}

     ⍺←'{}' ⋄ sizeDef←⍺⍺
     0=≢⍵:sizeDef,⍥⊂⍺
     ns←JDefs ⍺
     _←(ns MergeNs)/¨Opts ⍵
     (Json ns),⍨⍥⊂GetSize sizeDef

 }
