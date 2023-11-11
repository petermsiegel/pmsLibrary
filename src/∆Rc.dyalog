 ∆Rc←{  
  ⍝ ⎕R only on code part of each line (or object), skipping comments and quoted strings
  ⍝ res_string@VV← pats@VV  ( (opts@A≡3|⍬)  ∆Rc (UserR@∇|userS@VV) ) input_string@VV
  ⍝    opts: User-passed options override default opts (see <defOpts> below)
  ⍝    UserR: the (user) ⎕R replacement function, with PatternNum=0 the FIRST user option.
  ⍝            ⍵.∆F n will select pcre pattern n (0= ⍵.Match) or, if out of range, ''.
  ⍝ ⎕IO-independent
    defOpts←  ('EOL' 'LF')('UCP' 1)('Mode' 'L')
    skipP← '(?x) ⍝.*$ | (?:''[^'']*'')+'    
    userS← UserR← ⍵⍵
    opts← ⍺⍺ { 0=≢⍺: ⍵ ⋄ o/⍨ ≠⊃¨o← ⍵,⍨ ⊂⍣ (3>|≡⍺)⊢ ⍺ } defOpts
    pats← skipP,⍥⊆ ⍺
  3≠ ⎕NC'UserR':  pats ⎕R replS ⍠opts⊣ ⍵ ⊣ replS← '\0',⍥⊆ userS
    pats ⎕R {
         ⍵.PatternNum=0: ⍵.Match
         ⍵.PatternNum-← 1
         ⍵.∆F← {0::'' ⋄ l o← Lengths Offsets⌷⍨¨ ⍵+⎕IO ⋄ l↑ o↓ Block }
         UserR ⍵
    }⍠opts⊣⍵
 }
