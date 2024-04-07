:Namespace ∆DClass
⍝H ∆D, ∆DL, ∆DK -                "Create and Manage a Dictionary"
⍝H Create a dictionary whose entries are in a fixed order based on order of creation
⍝H (oldest first).  Adding new values for existing keys does not change their order.
⍝H Keys and Values may be of any type. 
⍝H 
⍝H d← ∆D ⍬                       "Dictionary from Items (Key-Value Pairs)"
⍝H d← ∆D (k1 v1)(k2 v2)…
⍝H d← default ∆D (⍬ | (k1 v1)…)
⍝H ∘ Create a dictionary with entries (items) (k1 v1)(k2 v2)….
⍝H ∘ If no items arespecified, an empty dictionary is created.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H 
⍝H d← ∆DL ⍬ ⍬                    "Dictionary from a KeyList and ValueList"
⍝H d← ∆DL (k1 k2…)(v1 v2…)
⍝H d← default ∆D …
⍝H ∘ Create a dictionary from a list of keys and corresponding values.
⍝H ∘ The list of keys and the corresponding list of values must be identical. 
⍝H   Both may be empty, resulting in an empty dictionary.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H
⍝H d← default ∆DK k1 k2…         "Dictionary from a KeyList and Initial Value"
⍝H
⍝H ∘ Create a dictionary from a list of keys and assign each the initial value ¨default¨.
⍝H ∘ A default must be specified (it will continue as the default for queries of the dictionary).
⍝H ∘ This form is equivalent to 
⍝H     d← default {nK←≢⍵ ⋄ ⍺ ∆DL ⍵ (nK⍴⊂⍺) } k1 k2….
⍝H
⍝  *** See additional HELP info below ***

⎕IO ⎕ML←0 1   
⍙Sig← ⎕SIGNAL {⊂⎕DMX.(('EM' EM) ('EN' EN) ('Message' Message))} 

⍝ ∆D: Create from items (key-value pairs)       
∆D←{ ⍝ ⍺: default (optional), ⍵: itemlist (i.e. (k1 v1)(k2 v2)…) 
    0:: ⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
    0=⎕NC'⍺': ⎕NEW Dict (⍵ ⎕NULL 0)        ⍝ See MakeI  
              ⎕NEW Dict (⍵ ⍺ 1)           
}

⍝ ∆DL: Create from lists: keylist and vallist
∆DL←{ ⍝ ⍺: default (optional), ⍵: keylist, vallist 
    0:: ⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
     2≠≢⍵: '∆DL DOMAIN ERROR: unexpected right arg' ⎕SIGNAL 11 
    0=⎕NC'⍺': ⎕NEW Dict (⍵, ⎕NULL 0)       ⍝ See MakeL   
              ⎕NEW Dict (⍵, ⍺ 1)              
}

⍝ ∆DK: Create a dictionary from a list of keys with the value ⍺.
∆DK←{ ⍝ ⍺: default (required), ⍵: keylist 
    0:: ⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help   
    0=⎕NC'⍺': ⎕SIGNAL/'∆DK DOMAIN ERROR: missing left arg (default)' 11  
              vals← (≢⍵)⍴ ⊂⍺                 
              ⎕NEW Dict ((⍵ vals),⍺ 1)      ⍝ See MakeL
}
##.∆D←  ⎕THIS.∆D 
##.∆DL← ⎕THIS.∆DL 
##.∆DK← ⎕THIS.∆DK

∇ {ok}← Help; t
  ok← ⎕ED 't'⊣ t← '^\h*⍝H ?(.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
∇

:Class Dict
⍝H ├─────────────────────────────────────────────────────────────────────────┤
⍝H │                 "METHODS"  IN ALPHABETICAL ORDER…                       │
⍝H ├─────────────────────────────────────────────────────────────────────────┤  
⍝H │  d[kk],d[]       d[kk]← vv    d.Clear    d2← d.Copy   d.Default         │
⍝H │  d.Default←any   d.Def[kk]    d.ⁱDel kk  d.⁲DelIx[ii] d.DelIx[]         │ 
⍝H │  d.Get kk        d.HasDefault d.HasDefault←[1|0]      d.Help            │
⍝H │  d.Import kk vv  d.Items      d.Keys     d.Pop n      d.⁲Vals[ii]       │     
⍝H │  d.⁲Vals[ii]← vv                                                        │
⍝H ├─────────────────────────────────────────────────────────────────────────┤ 
⍝H │  kk: list of keys, vv: list of vals, ii: list of indices, any: any val. │  
⍝H ├─────────────────────────────────────────────────────────────────────────┤ 
⍝H │  ⁱ Del: If a left arg is present and 1, all keys MUST exist.            │
⍝H │  ⁲ DelIx, Vals: Uses Index Origin (⎕IO) of caller as expected.          │     
⍝H ├─────────────────────────────────────────────────────────────────────────┤
⍝H 
  :Field Private  KEYS←        ⍬
  :Field Private  VALS←        ⍬
  :Field Private  DEFAULT
  :Field Private  HAS_DEFAULT← 0  
⍝ ⍙E: Internal helper. Usage:  ⍙E n. 
⍝     ⍺: Message (default: ''), ⍵: Error #. 
⍝     No error if ⍵ is ⍬.
  ⍙E← ⎕SIGNAL {0=≢⍵: ⍬ ⋄ ⍺←'' ⋄ ⊂⎕DMX.('EM' ('∆D ',⎕EM ⊃⍵)) ('EN' ⍵) ('Message' ⍺) }
⍝ ⍙I2KV: Convert items (key-val pairs) to lists of keys and values.
⍝          If just one item is presented, it must be enclosed…
  ⍙I2KV← { 0=≢⍵: ⍬ ⍬ ⋄ 2=≢t← ,¨(↓∘⍉↑∘,) ⍵: t ⋄ ⎕SIGNAL 11 }

  ∇ makeFill                     ⍝ Create an empty dict with no defaults
  :Implements constructor 
  :Access Public 
  ∇ 
  ∇ MakeI (ii d h)             ⍝ Create from Items and opt'l Default
    ;kk; vv
  :Implements constructor
    :Access Public
    :Trap 11 
       kk vv← ⍙I2KV ii ⋄ ValuesByKey[kk]←vv 
    :Else 
       'A list of items is required' ⍙E 11 
    :EndTrap
    :IF HAS_DEFAULT← h ⋄ DEFAULT← d ⋄ :Endif 
  ∇
  ∇ makeL (kk vv d h)        ⍝ Create from Keylist Valuelist and opt'l Default 
  :Implements constructor
    :Access Public
    ValuesByKey[kk]←vv  
    :IF HAS_DEFAULT← h ⋄ DEFAULT← d ⋄ :Endif 
  ∇

⍝H d[k1 k2 …], 
⍝H d[k1 k2 …]← v1 v2 …
⍝H d[]
⍝H Retrieve or set specific values of the dictionary by key.
⍝H You can also retrieve all values via d[]. See also d.Values[]
⍝H 
  missKeyEM← 'At least 1 key is missing and no default is active'
  :Property Default Keyed ValuesByKey 
  :Access Public
    ∇ r←get args; ii; kk; new; old 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          r← VALS                            ⍝ Grab all values if d[] is specified.
      :Else 
          ii← KEYS⍳ kk
          :If 0∊ old← ii≠ ≢KEYS   
              missKeyEM ⍙E 3/⍨ ~HAS_DEFAULT
              r← (≢kk)⍴ ⊂DEFAULT 
              r[ ⍸old ]← VALS[ old/ ii ]
          :Else 
              r← VALS[ ii ]
          :Endif 
          r← ⊂⍣ (0= ⊃⍴⍴kk)⊢ r                  ⍝ Tweak if kk is a scalar
      :Endif  
    ∇
    ∇ set args; ii; kk; vv; o; n; kn; vn  
      ii← KEYS⍳ kk← ⊃args.Indexers ⋄ vv← args.NewValue 
      VALS,← 0⍴⍨ ≢KEYS,← ∪kn← kk/⍨ n← ~o← ii≠ ≢KEYS    
      VALS[ (o/ii), KEYS⍳ kn]←  (o/vv), n/vv  
    ∇
  :EndProperty

  ⍝H {r}← d.Clear
  ⍝H Remove all entries (keys and values) from the dictionary.
  ⍝H Do not change any default value (Default).
  ⍝H Shyly returns the # of entries deleted.
  ⍝H 
    ∇{r}← Clear 
      :Access Public 
      r← ≢KEYS 
      KEYS←VALS← ⍬
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

⍝H d.Def[k1 k2 …], 
⍝H Returns a 1 for each key (k1, etc.) defined in Keys and a 0 otherwise.
⍝H 
  :Property Keyed Defined, Def 
  :Access Public
    ∇ bb←get args; bb; kk 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
        ⍙E 11 
      :Else 
        bb← (≢KEYS)≠ KEYS⍳ kk
        bb← ⊂⍣ (0= ⊃⍴⍴kk)⊢ bb
      :Endif  
    ∇
  :EndProperty

⍝H [0] d.Del k1 k2…     ⍝ Missing keys are ignored.
⍝H  1  d.Del k1 k2…     ⍝ Missing keys are not allowed.
⍝H Delete items from the dictionary by key.
⍝H ∘ Returns 1 for each item in range, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
    delMissE←   'Attempting to delete a missing item with REQUIRED option specified'
    ∇ r← {required} Del kk; ii; old; nK 
       :Access Public
      :If 0=≢kk 
          r←⍬
      :ELse 
          nK← ≢KEYS ⋄ old← nK≠ ii← KEYS⍳ kk  
          :If 0∊ old ⋄ :AndIf ~900⌶⍬ ⋄ :AndIf required 
              delMissE ⍙E 3 
          :EndIf 
          KEYS VALS/⍨← ⊂~(⍳nK)∊ old/ ii
          r← old⍴⍨ ⍴kk
      :EndIf 
    ∇
  ⍝ DelByKey: Alias for Del 
    ∇ r←DelByKey kk 
       :Access Public
       r← Del kk
    ∇
    
⍝H d.DelIx[i1 i2…]   
⍝H d.DelIx[] simply does a clear, returning 1s for each item…
⍝H Delete items in the dictionary by index (caller's ⎕IO).  
⍝H Returns 1 for each item that was deleted, else 0 (item not found).
⍝H 
  :Property Keyed DelByIndex, DelIx 
  :Access Public
    ∇ r←Get args; ii; old; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          r← 1⍴⍨ Clear  
      :Else 
          ii-← (⊃⎕RSI).⎕IO                    ⍝ Adjust for caller's ⎕IO 
          KEYS VALS/⍨← ⊂~(⍳nK)∊ ii/⍨ old← ii< nK← ≢KEYS
          r← old⍴⍨ ⍴ii
      :Endif 
    ∇
  :EndProperty

⍝H v1 v2…← d.Get k1 k2…
⍝H v1 v2…← default d.Get k1 k2…
⍝H Retrieve values for one or more keys. 
⍝H ∘ If a default is not specified, all keys must be currently defined (else Index Error)
⍝H   unless a global DEFAULT has been set (e.g. when the dictionary was created). 
⍝H ∘ If a default is specified, it will be used for all keys not in the dictionary,
⍝H   independent of any global default value set.
⍝H 
∇ vv← {default} Get kk; nD; ii; old 
  :Access Public
  ii← KEYS⍳ kk
  :IF nD← 900⌶⍬ ⋄ :ANDIF HAS_DEFAULT 
      default nD← DEFAULT 0
  :ENDIF 
  :If 0∊ old← ii≠ ≢KEYS   
      missKeyEM ⍙E 3/⍨ nD 
      vv← (≢kk)⍴ ⊂default 
      vv[ ⍸old ]← VALS[ old/ii ]
  :Else 
      vv← VALS[ ii ]
  :Endif 
∇

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
      ⍙E 11/⍨ 0 1 (~∊⍨) d← def.NewValue 
      :IF d 
        '∆D: Default HAS NO VALUE' ⎕SIGNAL {0:: ⍵ ⋄ ⍬⊣ DEFAULT} 6
      :EndIf 
      HAS_DEFAULT← d 
    ∇
  :EndProperty 

⍝H d.Help
⍝H Provide help information.
⍝H 
  ∇ {ok}← Help
  :Access Public Shared
    ok← ##.Help 
  ∇

⍝H d.Import keylist vallist 
⍝H Add new (or existing) entries via lists of keys and values.
⍝H This is equivalent to d[ keylist ]← vallist
⍝H 
  ∇ {vv}← Import (kk vv)
    :Access Public
    ValuesByKey[kk] ← vv 
  ∇


⍝H ii← d.Items
⍝H Retrieve all the items of the dictionary as key-value pairs. (Items are read-only)
⍝H 
    :Property Simple Items,Item  
    :Access Public
      ∇ ii← Get
        :If 0=≢KEYS ⋄ ii← ⍬
        :Else ⋄ ii← ↓⍉↑ KEYS VALS
        :EndIf 
      ∇
    :EndProperty

⍝H kk← d.Keys
⍝H Retrieve all the keys of the dictionary. (Keys are read-only)
⍝H 
  :Property Simple Keys 
  :Access Public
    ∇ kk←Get
      kk← KEYS  
    ∇
  :EndProperty

⍝H {r}← d.Pop n
⍝H Remove and shyly return the last <n> entries from the dictionary.
⍝H n: a single non-negative integer. 
⍝H If n exceeds the # of entries, the actual entries are returned (no padding is done).
⍝H 
  ∇{r}← Pop n; m  
    :Access Public 
    ⍙E 6/⍨ n<0 
    m← - n⌊ ≢KEYS 
    :Trap 0 
        r← ↓⍉↑KEYS VALS↑⍨¨ m 
        KEYS VALS ↓⍨← m 
        :If 0= ≢r ⋄ r← ⍬ ⋄ :EndIf 
    :Else 
        ##.⍙Sig⍬
    :EndTrap 
  ∇

⍝H d.Vals[ ix1 ix2 …], 
⍝H d.Vals[ ix1 ix2…]← val1 val2…
⍝H d.Vals[]
⍝H Also: ValsIx[…]
⍝H Retrieve or set specific values in the dictionary by index (caller's ⎕IO).
⍝H You may also retrieve ALL the values using d.Vals[] or simply d[].
⍝H 
  :Property Numbered ValsByIx, ValsIx, Vals  
  :Access Public
    ∇ r←get args; ii
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          r← VALS
      :Else   
          ⍙E 3/⍨ 0∊ ii< ≢KEYS 
          r← VALS[ii]
      :EndIf 
    ∇
    ∇ set args; ii
      ii← ⊃args.Indexers 
      ⍙E 3/⍨ 0∊ ii< ≢KEYS 
      VALS[ii]← args.NewValue 
    ∇
    ∇ r←Shape
      r← ⍴KEYS 
    ∇
  :EndProperty

:EndClass

:EndNamespace
