∆FⓇ← {∆FⓄ} ∆Fc ∆FⒻ ; ⎕TRAP 
⍝ ∆F: Calling Information and Help Documentation is at the bottom of this function 
  ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
  :If 0=⎕SE.⎕NC '⍙F.∆F4'
      ⎕SE.⎕FIX 'file://∆F_c/∆F_LIBRARY.dyalog'  ⍝ Creates library ⎕SE.⍙F
  :Endif  
  :If 900⌶0                                   ⍝ Options omitted. Default options processed below.
        ∆FⓄ← ⍬                               ⍝ We distinguish omitted left arg and 0=≢∆FⓄ
  :ElseIf 0=≢∆FⓄ                             ⍝ 0=≢∆FⓄ
        ∆FⓇ← 1 0⍴⍬                           ⍝   This is a quick (NOP) exit where user wants to skip ∆F processing altogether.
        :Return 
  :Elseif 'help'≡4↑⎕C ∆FⓄ                    ⍝ 'help' (show help info & examples) or 'helpx' (show help examples)
        ∆FⓇ← ⎕SE.⍙F.Help ∆FⓄ 
        :Return  
  :EndIf 

  ∆FⓄ← ∆FⓄ ⎕SE.⍙F.FStr2Code ∆FⒻ← ,⊆∆FⒻ  
  :IF   ~⊃∆FⓄ                                 ⍝ ~dfn:  evaluate code and return display form
        ∆FⓇ← (⊃⌽∆FⓄ)((⊃⎕RSI){                ⍝   NB: String ⍺ has a reference to ⍵ (∆FⒻ)   
            ⍺⍺⍎ ⍺⊣ ⎕EX '∆FⒻ' '∆FⓄ'
        })∆FⒻ   
  :Else ⍝ dfn                                  ⍝ dfn: evaluate code and return the dfn
        ∆FⓇ← (⊃⎕RSI)⍎ ⊃⌽∆FⓄ                       
  :EndIf 
  :Return 


