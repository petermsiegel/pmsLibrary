 Opts2Json←{
     ⍺←⎕NS ⍬ ⋄ ns defSize←⍺ ⍺⍺

     T F←⊂∘⊂¨'true' 'false'   ⍝ JSON true and false
     Opts←{,∘⊂⍣(2≥|≡⍵)⊢⍵}
     MergeNs←{⍺ ns.{⍎⍺,'←⍵'}⊃F T ⍵/⍨(⍵≡0)(⍵≡1)1}/¨
     Json←⎕JSON⍠'Dialect' 'JSON5'
     GetSize←'size'∘ns.{0≠⎕NC ⍺:(⎕EX ⍺)⊢⎕OR ⍺ ⋄ ⍵}

     0=≢⍵:defSize,⍥⊂Json ns
     _←MergeNs Opts ⍵
     (Json ns),⍨⍥⊂GetSize defSize
 }
