:Class TestDict
   ⎕IO ⎕ML←0 1 
  :Field Private  KEYS← ⍬       
  :Field Private  VALS← ⍬
  
  ErrIf← ⎕SIGNAL {⍵: ⍺,' in test mode!' ⎕SIGNAL 11  ⋄ _←⍬ }

  ∇ Make1 (kk vv)             ⍝ Create dict from (list of keys, list of vals)                   
    :Implements constructor
    :Access Public
    KEYS← ,kk ⋄ VALS← ,vv 
     (↑'KEYS' 'VALS'),KEYS,[-0.1]VALS 
  ∇

⍝ Our one "test" property-- a default keyed property called "ValsByKey"
  :Property Default Keyed ValsByKey 
  :Access Public
    ∇ vv←get args; ii; kk 
      'Explicit indices required' ErrIf ⎕NULL≡ kk← ⊃args.Indexers   
      ii← KEYS⍳ kk
      'No new keys' ErrIf 0∊ ii≠ ≢KEYS  
      ⎕← '** ValsByKey Get: keys=',kk,'source indices=',ii,'vals were=',VALS[ ii] 
      vv← ⊂⍣ (0= ⊃⍴⍴kk)⊢ VALS[ ii ]       ⍝ Grab existing vals and scalarize if necc.
    ∇
  ⍝ ValsByKey "set" function
    ∇ set args; kk; vv; ii 
      kk← ⊃args.Indexers 
      vv←  args.NewValue   
      ii← KEYS⍳ kk                       ⍝ Search for keys 
      'No new keys!' ErrIf 0∊ ii≠ ≢KEYS                 ⍝ Refuse new keys in test mode
      ⎕← '** ValsByKey Set: keys=',kk,'target indices=',ii,' vals now=',vv 
      VALS[ ii ]← vv                     ⍝ Update existing and new vals (see Note 1)
    ∇ 
  :EndProperty

  :EndClass 