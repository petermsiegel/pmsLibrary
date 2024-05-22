:Namespace DictTest
⍝ GenUKeys
⍝ ¯¯¯¯¯¯¯¯
⍝ l← GenUKeys count    
⍝    Generate <count> 8-character keys, all unique!
⍝    Keys are 7 chars in length and of the form:  
⍝          ACCCCCCC, where A∊⎕A and C∊⎕A,⎕D.
⍝    Note: If count ≥ approx. 2E12 keys, an infinite loop on GenUKeys becomes certain.
⍝          That said, a WS Full will happen long before!
⍝ GenKeys
⍝ ¯¯¯¯¯¯¯
⍝ l← {unique←total} GenKeys total 
⍝    Generate unique 8-char keys and distribute randomly
⍝    in a list of total keys, where unique and total are numbers:
⍝      ∘ unique ≤ total. If omitted, unique← total. 
⍝    If unique=total, there are no duplicate keys!
GenUKeys←{ ⍺←⍬ ⋄ 0≥∆← ⍵-≢⍺: ⍵↑⍺ ⋄ ⍵∇⍨ ∪⍺, (⎕A,⎕D)∘{ ⎕A[?≢⎕A], ⍺[?7⍴≢⍺] }¨⍳∆ }
GenKeys←{ ⍺←⍵ ⋄ ⍺=⍵: GenUKeys ⍵ ⋄ (⍵⍴GenUKeys ⍺)[?⍨⍵] }
:EndNamespace 
