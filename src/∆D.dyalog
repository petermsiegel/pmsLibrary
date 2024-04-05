:Namespace ∆DClass

⎕IO ⎕ML←0 1   
⍝ ∆D: Create from items (key-value pairs)       
∆D←{ ⍝ ⍺: default (optional), ⍵: itemlist (i.e. (k1 v1)(k2 v2)...) 
 'help'≡⎕C⍵: _← Help 
 0=⎕NC'⍺':   ⎕NEW Dict (,⊂⍵)       ⍝ ⍺: Dict value default (none if omitted)
             ⎕NEW Dict (⍵ ⍺ 1)      ⍝ Pass items (key-value pairs)  
}
⍝ ∆DL: Create from lists: keylist and vallist
∆DL←{ ⍝ ⍺: default (optional), ⍵: keylist, vallist 
 'help'≡⎕C⍵: _← Help ⋄ 2≠≢⍵: ⎕SIGNAL 11 
 0=⎕NC'⍺':   ⎕NEW Dict (⍵)           
             ⎕NEW Dict (⍵,⍺ 1)       
}
##.∆D←  ⎕THIS.∆D 
##.∆DL← ⎕THIS.∆DL 

∇ {ok}← Help
  ok← (⎕NEW Dict).Help
∇

:Class Dict
  :Field Private  KEYS←       ⍬
  :Field Private  VALS←       ⍬
  :Field Private  DEFAULT
  :Field Private  HAS_DEFAULT← 0  
⍝ Err: Internal helper. Usage:  Err n. Ignored if ⍵ is ⍬.
  Err← ⎕SIGNAL {0=≢⍵: ⍬ ⋄ ⊂⎕←('EM' ('∆D ',⎕EM ⊃⍵)) ('EN' ⍵) }

⍝H d← ∆D ⍬
⍝H d← ∆D (k1 v1)(k2 v2)...
⍝H d← default ∆D ...
⍝H ∘ Create a dictionary with entries (items) (k1 v1)(k2 v2)....
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H 
⍝H ├────────────────────────────────────────────────────────────────────┤
⍝H │         "METHODS" (FNS and OPS) IN ALPHABETICAL ORDER...           │
⍝H ├────────────────────────────────────────────────────────────────────┤  
⍝H │  d[kk]     d[kk]←vv    d.Clear       d.Copy d2   d.Default         │
⍝H │  d.Def[kk] d.Del kk    d.DelIx⁰[ii]  d.Help      d.Import kk vv    │
⍝H │  d.Items   d.Keys      d.HasDefault  d.HasDefault←[1|0]            │
⍝H │  d.Pop n   d.Valsⁱ[ii] d.Valsⁱ[ii]←vv                              │
⍝H ├────────────────────────────────────────────────────────────────────┤ 
⍝H │  ⁰DelIx: ⎕IO=0, ⁱVals: Indices in Index Origin (⎕IO) of caller     │  
⍝H │  kk: list of keys, vv: list of vals, ii: list of indices           │    
⍝H ├────────────────────────────────────────────────────────────────────┤

  ∇ makeFill                     ⍝ Create an empty dict with no defaults
  :Implements constructor 
  :Access Public 
  ∇ 
  ∇ makeII (ii)                  ⍝ Create from Items 
  :Implements constructor
    :Access Public
    KEYS VALS← II2KKVV ii 
  ∇
  ∇ makeKKVV (kk vv)             ⍝ Create from Keylist Valuelist 
  :Implements constructor
    :Access Public
    KEYS VALS← ,¨kk vv 
  ∇
  ∇ makeIID (ii d h)             ⍝ Create from Items and Default
  :Implements constructor
    :Access Public
    KEYS VALS← II2KKVV ii 
    DEFAULT HAS_DEFAULT← d h
  ∇
  ∇ makeKKVVD (kk vv d h)        ⍝ Create from Keylist Valuelist and Default 
  :Implements constructor
    :Access Public
    KEYS VALS←  ,¨kk vv 
    DEFAULT HAS_DEFAULT← d h
  ∇

⍝ II2KKVV: Convert items (key-val pairs) to lists of keys and values.
⍝          If just one item is presented, enclose and run again.
  II2KKVV← { ∆← ,¨(↓∘⍉↑∘,) ⋄ 2=≢t← ∆ ⍵: t ⋄ ∆ ⊂⍵  }

⍝H d.Help
⍝H Provide help information.
⍝H 
  ∇ {ok}← Help; t 
  :Access Public Shared
    ok← ⎕ED 't'⊣ t← '^\h*⍝H ?(.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
  ∇

⍝H d.Import keylist vallist 
⍝H Add new (or existing) entries via lists of keys and values.
⍝H This is equivalent to d[ keylist ]← vallist
⍝H This is an alternative to entering them as pairs at dictionary creation.
⍝H 
  ∇ {vv}← Import (kk vv)
    :Access Public
    ValuesByKey[kk] ← vv 
  ∇

  ⍝H d2← d.Copy
  ⍝H Make a copy of the Keys, Vals, and Default of dictionary d.
  ⍝H 
  ∇ d2← Copy
    :Access Public 
    :If HAS_DEFAULT 
         d2← ⎕NEW Dict (KEYS VALS DEFAULT HAS_DEFAULT)
    :Else  
         d2← ⎕NEW Dict (KEYS VALS) 
    :Endif 
  ∇

⍝H kk← d.Keys
⍝H Retrieve all the keys of the dictionary. (Keys are read-only)
⍝H 
  :Property Simple Keys 
  :Access Public
    ∇ kk←Get
      kk← KEYS  
    ∇
  :EndProperty

  ⍝ For Vals, see "ValsByIx, Vals" below

⍝H ii← d.Items
⍝H Retrieve all the items of the dictionary as key-value pairs. (Items are read-only)
⍝H 
    :Property Simple Items,Item  
    :Access Public
      ∇ ii← Get
        ii← ↓⍉↑ KEYS VALS
      ∇
    :EndProperty

⍝H d[k1 k2 ...], 
⍝H d[k1 k2 ...]← v1 v2 ...
⍝H d[]
⍝H Retrieve or set specific values of the dictionary by key.
⍝H You can also retrieve all values via d[]. See also d.Values[]
⍝H 
  :Property Default Keyed ValuesByKey 
  :Access Public
    ∇ r←get args; ii; kk; new; old 
      ⍝ ⎕←'args' args ' ⊃args.Indexers' (⊃args.Indexers)
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          r← VALS   
      :Else 
        ii← KEYS⍳ kk
        :If 0∊ old← ii≠ ≢KEYS   
            Err 3/⍨ ~HAS_DEFAULT
          ⍝ r← (⊂DEFAULT)@ (⍸new)⊣ 0⍴⍨ ≢kk 
            r← (≢kk)⍴ ⊂DEFAULT 
            :If 0∊ new  
                r[ ⍸old ]← VALS[ ii/⍨ old ]
              ⍝  r← VALS[ old/ii ]@ (⍸old← ~new)⊣ r 
            :Endif 
        :Else 
            r← VALS[ ii ]
        :Endif 
        r← ⊂⍣ (0= ⊃⍴⍴kk)⊢ r
      :Endif  
    ∇
    ∇ set args; ii; kk; old; new 
      ii← KEYS⍳ kk← ⊃args.Indexers 
      old← ~new← ii= ≢KEYS 
      VALS[ old/ii ]← old/ args.NewValue
      :If 1∊ new 
          KEYS VALS,← (⊂new)/¨ kk args.NewValue 
      :EndIf 
    ∇
  :EndProperty

⍝H d.Def[k1 k2 ...], 
⍝H Returns a 1 for each key kN defined in Keys and a 0 otherwise.
⍝H 
  :Property Keyed Defined, Def 
  :Access Public
    ∇ bb←get args; bb; kk 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
           Err 11 
      :Else 
        bb← (≢KEYS)≠ KEYS⍳ kk
        bb← ⊂⍣ (0= ⊃⍴⍴kk)⊢ bb
      :Endif  
    ∇
  :EndProperty

⍝H d.Vals[ ix1 ix2 ...], 
⍝H d.Vals[ ix1 ix2...]← val1 val2...
⍝H d.Vals[]
⍝H Retrieve or set specific values in the dictionary by index.
⍝H You may also retrieve all the values via d.Vals[]. See also d[].
⍝H 
  :Property Numbered ValsByIx, ValsIx, Vals  
  :Access Public
    ∇ r←get args; ii 
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          r← VALS
      :Else   
        Err 3/⍨ 0∊ ii< ≢KEYS 
        r← VALS[ii]
        ⍝r← ⊂⍣ (0=⊃⍴⍴ii)⊢ r 
      :EndIf 
    ∇
    ∇ set args; ii 
      ii← ⊃args.Indexers 
      Err 3/⍨ 0∊ ii< ≢KEYS 
      VALS[ ii ]← args.NewValue 
    ∇
    ∇ r←Shape
      r← ⍴KEYS 
    ∇
  :EndProperty


⍝H d.Del k1 k2...
⍝H Delete items in the dictionary by key.
⍝H Returns 1 for each item in range, else 0.
⍝H If all items must exist, use d.Validate first.
⍝H 
    ∇ r←Del kk; ii; old 
       :Access Public
      :If 0=≢kk 
          r←⍬
      :ELse 
          ii← KEYS⍳ kk 
          KEYS VALS/⍨← ⊂~(⍳≢KEYS)∊ ii/⍨ old← ii≠ ≢KEYS  
          r← old⍴⍨ ⍴kk
      :EndIf 
    ∇
  ⍝ DelByKey: Alias for Del 
    ∇ r←DelByKey kk 
       :Access Public
       r← Del kk
    ∇
    
⍝H d.DelIx[i1 i2...]  ⎕IO=0 
⍝H Delete items in the dictionary by index.  
⍝H Returns 1 for each item that was deleted, else 0 (item not found).
⍝H 
  :Property Keyed DelByIndex, DelIx 
  :Access Public
    ∇ r←Get args; ii; old 
      ii← ⊃args.Indexers 
      Err 11/⍨ ⎕NULL≡⊃args.Indexers
      old← ii≠ ≢KEYS
      KEYS VALS/⍨← ⊂~(⍳≢KEYS)∊ old/ii 
      r← old⍴⍨ ⍴ii
    ∇
  :EndProperty

⍝H r← d.Validate[k1 k2...]
⍝H Validate that all keys specified are in the dictionary, returning 1 for each.
⍝H (If no keys are specified, does nothing and returns ⍬.
⍝H Signals a VALUE ERROR otherwise.
⍝H
  :Property Keyed Validate, Valid   
  :Access Public
    ∇ r←Get args; kk 
      :If  ⎕NULL≡ kk←⊃args.Indexers
           r← ⍬
      :Else 
           Err 6/⍨ 1∊ (≢KEYS)= KEYS⍳ kk 
          r← 1⍴⍨ ⍴kk  
      :EndIf 
    ∇
  :EndProperty

⍝H {r}← d.Clear
⍝H Remove all entries (keys and values) from the dictionary.
⍝H Shyly returns the # of entries deleted.
⍝H 
   ∇{r}← Clear 
     :Access Public 
     r← ≢KEYS 
     KEYS←VALS← ⍬
   ∇

⍝H {r}← d.Pop n
⍝H Remove and shyly return the last <n> entries from the dictionary.
⍝H n: a single non-negative integer. 
⍝H If n exceeds the # of entries, the actual entries are returned (no padding is done).
⍝H 
   ∇{r}← Pop n; m  
     :Access Public 
     ⎕ERR 6/⍨ n<0 
     m← - n⌊ ≢KEYS 
     :Trap 0 
        r← ↓⍉↑KEYS VALS↑⍨¨ m 
        KEYS VALS ↓⍨← m 
        :If 0= ≢r ⋄ r← ⍬ ⋄ :EndIf 
     :Else 
        ⎕ERR ⊂'EM' 'EN' 'Message',⍥⊂⍨ ⎕DMD.(EM EN Message)
     :EndTrap 
   ∇

⍝H d.Default
⍝H d.Default← any_value 
⍝H Retrieve or set/redefine the default value for missing dictionary entries
⍝H (those requested by key that do not exist).
⍝H If you set a default, HasDefault is automatically set to 1.
⍝H 
  :Property Simple Default
  :Access Public
    ∇ r←get 
      '∆D: Default not set or not active' ⎕SIGNAL 6/⍨ ~HAS_DEFAULT 
      r← DEFAULT 
    ∇
    ∇ set def  
      HAS_DEFAULT DEFAULT← 1 def.NewValue 
    ∇
  :EndProperty 

⍝H d.HasDefault 
⍝H d.HasDefault← [1|0]
⍝H Retrieve or set the current Default status. 
⍝H - If you set HasDefault to 1, the prior default (if any) is restored;
⍝H   if no default exists at that time, HasDefault remains 0 and a VALUE ERROR is generated. 
⍝H - If you set HasDefault to 0, any attempt to access an item that doesn't exist
⍝H   will cause a VALUE ERROR to be signalled, until you reset HasDefault to 1.
⍝H 
  :Property Simple HasDefault 
  :Access Public
    ∇ r←get 
      r← HAS_DEFAULT 
    ∇
    ∇ set def; d   
      ⎕ERR 11/⍨ 0 1 (~∊⍨) d← def.NewValue 
      :IF d 
        '∆D: Default HAS NO VALUE' ⎕SIGNAL {0:: ⍵ ⋄ ⍬⊣ DEFAULT} 6
      :EndIf 
      HAS_DEFAULT← d 
    ∇
  :EndProperty 

:EndClass

:EndNamespace
