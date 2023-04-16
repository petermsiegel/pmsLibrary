∆TDICT← {   
⍝ Minimalist dictionary. 

    ⍺← ⍬ ⋄ ⎕IO ⎕ML← 0 1 ⋄ ns← ⎕NS⍬ ⋄ ns.D←⍺ ⋄ ns.(K V)← 2⍴⊆⍵ 
    
    ns.Get1← { ⍺← D ⋄ (≢K)> p← K⍳ ⊂⍵: p⊃ V ⋄ ⍺ }
  ⍝ ns.Get←  ns.Get1¨
    ns.Get←  { ~0∊ m← (≢K)>p← K⍳ k← ⍵: V[ p ] ⋄ ⍺← ⊂D ⋄ r← ⍺⍴⍨ ≢k ⋄ ~1∊ m: r ⋄ V[ m/ p ]@ (⍸m)⊣ r }
    
    ns.Set1← { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢K)> p← K⍳ ⊂k: (p⊃ V)← v ⋄ (K V),∘⊂← k v ⋄ 1: _← v }
  ⍝ ns.Set←  { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ k Set1¨ v}
    ns.Set←  { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ ~0∊ m← (≢K)> p← K⍳ k: V[ p ]← v 
               V[ m/ p ]← m/ v ⋄  V,← (nm/ v)@ (unk⍳ nk)⊢ 0⍴⍨ ≢unk← K,← ∪nk← k/⍨ nm← ~m 
    }
  
    ns.HasKeys← { K∊⍨ ⍵ } 
    ns.HasKey←  ns.HasKeys⊂

    ns.Del←  { ⍺← 0 ⋄ n← ≢K ⋄ ⍺∨ p=⍥≢ fp← p/⍨ n> p← K⍳ ⍵: _← 1⊣ (K V) /⍨← ⊂0@ fp⊣ n⍴1 ⋄ ⎕SIGNAL 11 } 
    ns.Del1← ns.Del⊂

  ⍝   
    ns.Do1←  { 1: _←  ⍺ Set1 (Get1  ⍺)⍺⍺  ⍵ }
    ns.Do←   { 1: _← ⍺ (⍺⍺ Do1)¨ ⍵ }
    
    ns.Cat1← { 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),  ⊂⍵ }  
    ns.Cat←  { ⍺ {⍺ Cat1 ⍵}¨⍵}
  
  ⍝ Niladic Methods
  ⍝   Not shy: Keys, Vals, Copy
    _Keys←  '_← Keys' '_←K'
    _Vals←  '_← Vals' '_←V'
    _Copy←  '_← Copy' '_←⎕NS ⎕THIS'
  ⍝   Shy: Clear, Hash 
    _Clear← '{_}← Clear' '_←0⊣ K←V←⍬'
    _Hash←  '{_}← Hash' ':IF 0=_←1(1500⌶)K ⋄ K← 1500⌶K ⋄ :ENDIF'
    _← ns.⎕FX¨ _Keys _Vals _Copy _Clear _Hash

    ns 
}
   