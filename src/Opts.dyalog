 Opts←{
  0::⎕SIGNAL/ 'Opts DOMAIN ERROR: Invalid default or user option(s)' ⎕DMX.EN 
      ns←⎕NS⍬ ⋄ w a← {⊂⍣(0=80|⎕DR ⊃⍵)⊢⍵}¨⍵ ⍺ ⋄ ns.⍙PARMS← ∪∘⊃¨a 
      ns⊣ { ns⍎⍺,'←⍵' }¨/ ns.(⍙VARS ⍙VALS)← {⍵⌷⍨¨ ⊂⊂(⍳∘∪)⍨⊃⍵} ↓⍉↑⊃,/ ⌽¨ w a
 }
