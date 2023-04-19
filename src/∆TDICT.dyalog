∆TDICT← {   
⍝ Minimalist dictionary. 

    ⍺← ⍬ ⋄ ⎕IO ⎕ML← 0 1 ⋄ ns← ⎕NS⍬ ⋄ ns.(D (K V))← ⍺(2⍴⊆⍵) ⋄ ns.(K←1500⌶K)
    
    ns.Get1← { (≢K)> p← K⍳ ⊂⍵: p⊃ V ⋄ ⍺← D ⋄ ⍺ }
  ⍝ ns.Get←  ns.Get1¨
    ns.Get←  { ~0∊ m← (≢K)>p← K⍳ k← ⍵: V[ p ] ⋄ ⍺← ⊂D ⋄ r← ⍺⍴⍨ ≢k ⋄ ~1∊ m: r ⋄ V[ m/ p ]@ (⍸m)⊣ r }

    ns.Set1← { ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ (≢K)> p← K⍳ ⊂k: (p⊃ V)← v ⋄ K,∘⊂← k ⋄ 1: V,∘⊂←  ⍙H v }
  ⍝ ns.Set←  {0::Ê⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ k Set1¨ v}  ⍝ <= very slow...
    ns.Set←  {0::Ê⍬⋄ ⍺←⊢ ⋄ k v← ⍺ ⍵ ⋄ ~0∊ m← (≢K)> p← K⍳ k: V[ p ]← v 
              V[ m/ p ]← m/ v ⋄ 1: V,← ⍙H (nm/ v)@ (ü⍳ ñ)⊢ 0⍴⍨ ≢K,← ü← ∪ñ← k/⍨ nm← ~m  
    }
  
    ns.HasKeys← { K∊⍨ ⍵ } 
    ns.HasKey←  ns.HasKeys⊂  

    ns.Del←  { ⍺← 0 ⋄ n← ≢K ⋄ ⍺∨ p=⍥≢ fp← p/⍨ n> p← K⍳ ⍵: _← ⍙H 1⊣ (K V) /⍨← ⊂0@ fp⊣ n⍴1 ⋄ 61Ê'Key(s) not found' } 
    ns.Del1← ns.Del∘⊂

    ns.Do1←  {0::Ê⍬⋄ 1: _← ⍺ Set1 (Get1 ⍺)⍺⍺  ⍵ }
    ns.Do←   {0::Ê⍬⋄ 1: _← ⍺ (⍺⍺ Do1)¨ ⍵ }
    
    ns.Cat1← {0::Ê⍬⋄ 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),  ⊂⍵ }  
    ns.Cat←  {0::Ê⍬⋄ ⍺ {⍺ Cat1 ⍵}¨⍵ }

  ⍝ Hash utility- used AFTER K is updated.
    ns.⍙H← { ×1(1500⌶)K: ⍵ ⋄ ⍵⊣ K∘← 1500⌶K }    ⍝  Passes thru any args 
  
    ns.Ê← ⎕SIGNAL/ ('∆TDICT: '{0=≢⍵:⎕DMX.((⍺⍺,EM)EN)⋄⍺←11⋄(⍺⍺,⍵)⍺ })
  ⍝ Niladic Methods
  ⍝   Not shy: Keys, Vals, Copy
    _Keys←  '_← Keys' '_←K'
    _Vals←  '_← Vals' '_←V'
    _Copy←  '_← Copy' '_←⎕NS ⎕THIS'
  ⍝   Shy: Clear
    _Clear← '{_}← Clear' '_←⍙H ⎕THIS⊣ K←V←⍬'
    _← ns.⎕FX¨ _Keys _Vals _Copy _Clear  

    ns 
}