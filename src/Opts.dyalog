 Opts←{
  5:: 5 ⎕SIGNAL⍨'Opt: Invalid options'
     ns←⎕NS⍬ ⋄ ns.⍙PARMS← ⊃¨⍺ ⋄  0∧.= ≢¨⍺ ⍵: ns⊣ ns.⍙VARS←⍬  
     ns⊣ {⍺⊣ns⍎⍺,'←⍵'}¨/ ns.(⍙VARS ⍙VALS)←o⌷⍨¨ ⊂⊂(⍳∘∪)⍨⊃o← ↓∘⍉∘↑o← ⊃,/⌽¨⍵⍺
 }
