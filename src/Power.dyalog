Power←{ 
  ⍺← ⊢ 
  ns←⎕NS⍬ ⋄ _← ns.⎕DF (⍕⎕THIS),'.[PowerNs]'
  ns.w←⍵
  ns.a← ⊃⍺ ⎕NULL
  ns.count←1
  ns.rc← ⎕NULL 
  ⍺⍺{  
    ns←⍵
    ok← ⍵⍵ ns
    ~ok:  ns.rc 
    ns.rc← ns.a ⍺⍺ ns 
    ns.count+← 1 
    ∇ ns 
  }⍵⍵⊢ ns 
}