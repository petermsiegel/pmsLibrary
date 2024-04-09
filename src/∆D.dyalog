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
⍙Sig← ⎕SIGNAL {⊂⎕DMX.(('EM' ('∆D',⍺,' ',EM)) ('EN' EN) ('Message' Message))} 

⍝ ∆D: Create from items (key-value pairs)       
∆D←{ ⍝ ⍺: default (optional), ⍵: itemlist (i.e. (k1 v1)(k2 v2)…) 
    0:: '' ⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
    0=⎕NC'⍺': ⎕NEW Dict (⍵ ⎕NULL 0)        ⍝ See MakeI  
              ⎕NEW Dict (⍵ ⍺ 1)           
}

⍝ ∆DL: Create from lists: keylist and vallist
∆DL←{ ⍝ ⍺: default (optional), ⍵: keylist, vallist 
    0:: 'L'⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
     2≠≢⍵: '∆DL DOMAIN ERROR: unexpected right arg' ⎕SIGNAL 11 
    0=⎕NC'⍺': ⎕NEW Dict (⍵, ⎕NULL 0)       ⍝ See MakeL   
              ⎕NEW Dict (⍵, ⍺ 1)              
}

⍝ ∆DK: Create a dictionary from a list of keys with the value ⍺.
∆DK←{ ⍝ ⍺: default (required), ⍵: keylist 
    0:: 'K'⍙Sig⍬ ⋄ 'help'≡⎕C⍵: _← Help   
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

  ∇ makeFill                   ⍝ Create an empty dict with no defaults
  :Implements constructor 
  :Access Public 
  ∇ 
  ∇ MakeI (ii d h)             ⍝ Create dict from Items and opt'l Default
    ;kk; vv                    ⍝ If h (HAS_DEFAULT)=0, the DEFAULT is NOT set.
  :Implements constructor
    :Access Public
    :Trap 11 
       kk vv← ⍙I2KV ii 
    :Else 
       'A list of items is required' ⍙E 11 
    :EndTrap
    ValuesByKey[kk]←vv 
    :IF HAS_DEFAULT← h ⋄ DEFAULT← d ⋄ :Endif 
  ∇
  ∇ makeL (kk vv d h)        ⍝ Create dict from Keylist Valuelist and opt'l Default 
  :Implements constructor    ⍝ If h (HAS_DEFAULT)=0, the DEFAULT is NOT set.
    :Access Public
    :Trap 11
        ValuesByKey[kk]←vv  
    :Else
        ⍙E 11
    :EndTrap 
    :IF HAS_DEFAULT← h ⋄ DEFAULT← d ⋄ :Endif 
  ∇

⍝H d[k1 k2 …], 
⍝H d[k1 k2 …]← v1 v2 …
⍝H d[]
⍝H Retrieve or set specific values of the dictionary by key.
⍝H You can also retrieve all values via d[]. 
⍝H See also 
⍝H    d.Vals[]              ⍝ Retrieve values by Index
⍝H    d.Get, and d.Get1.    ⍝ Retrieve values by key with an optional ad hoc default.
⍝H 
  missKeyEM← 'Key(s) not found and no default is active'
  :Property Default Keyed ValuesByKey 
  :Access Public
    ∇ vv←get args; ii; kk; e 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          vv← VALS                            ⍝ Grab all values if d[] is specified.
      :Else 
          ii← KEYS⍳ kk
          :If ~0∊ e← ii≠ ≢KEYS               ⍝ All keys old? 
               vv← VALS[ ii ]                ⍝ … Just grab existing values.
          :Else                              ⍝ Some old and some new keys.
              missKeyEM ⍙E 3/⍨ ~HAS_DEFAULT  ⍝ … error unless we have a DEFAULT;
              vv← (≢kk)⍴ ⊂DEFAULT            ⍝ … where new, return DEFAULT;
              vv[ ⍸e ]← VALS[ e/ ii ]        ⍝ … where old, return existing value.
          :Endif 
          vv← ⊂⍣ (0= ⊃⍴⍴kk)⊢ vv              ⍝ If kk is a scalar, return vv as a scalar.
      :Endif  
    ∇
  ⍝ Timing of Algorithms 
  ⍝   A: separate existing and new keys so existing keys are searched once, new keys twice.
  ⍝   B: new keys are merged with existing, so all keys are searched twice.
   ⍝ Timings:
  ⍝      N  A(ms)  B(ms)   Faster
  ⍝     10  0.074  0.071   B by  4%   BBBB
  ⍝    100  0.079  0.077   B by  3%   BBB
  ⍝   1000  0.1    0.11    A by 10%   AAAAAAAAAA
  ⍝  10000  0.29   0.41    A by 41%   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
  ⍝ 100000  2      3.1     A by 55%   AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
    ∇ set args; kk; n; nk; pp; uk; vv   
      'No keys were specified' ⍙E 11/⍨ ⎕NULL≡ kk← ⊃args.Indexers
      vv← args.NewValue  
      :If ~1∊ n← (≢KEYS)= pp← KEYS⍳ kk 
          VALS[ pp ]← vv      
      :Else ⍝ *** Alg A *** 
          KEYS,← uk← ∪nk← n/ kk 
          VALS,←  (n/ vv)@ (uk⍳ nk)⊢ vv↑⍨ ≢uk 
      :EndIf 
    ⍝ :Else ⍝ *** Alg B ***    
    ⍝     VALS,← 0⍴⍨ ≢KEYS,← ∪n/ kk  
    ⍝     VALS[ KEYS⍳ kk ]← args.NewValue     ⍝ recalculate KEYS⍳ kk for new keys.
    ⍝ :EndIf 
    ∇ 
  :EndProperty

  ⍝H {n}← d.Clear
  ⍝H Remove all entries (keys and values) from the dictionary.
  ⍝H Do not change any default value (Default).
  ⍝H Shyly returns the # of entries deleted.
  ⍝H 
    ∇{n}← Clear 
      :Access Public 
      n← ≢KEYS ⋄ KEYS←VALS← ⍬
    ∇

  ⍝H d2← d.Copy
  ⍝H Make a copy of the Keys, Vals, and Default of dictionary d.
  ⍝H 
  ∇ d2← Copy; df 
    :Access Public 
    df← {⍵: DEFAULT ⋄ ⎕NULL}HAS_DEFAULT
    d2← ⎕NEW Dict (KEYS VALS df HAS_DEFAULT) 
  ∇

⍝H d.Default
⍝H d.Default← any_value 
⍝H Retrieve or set/redefine the default value for missing dictionary entries
⍝H (those requested by key that do not exist).
⍝H If you set a default, HasDefault is automatically set to 1.
⍝H 
  :Property Simple Default
  :Access Public
    ∇ d←get 
      'Default not set or not active' ⍙E 6/⍨ ~HAS_DEFAULT 
      d← DEFAULT 
    ∇
    ∇ set def  
      HAS_DEFAULT DEFAULT← 1 def.NewValue 
    ∇
  :EndProperty 

⍝H d.Def[k1 k2 …]     "Are keys defined in Keys?"
⍝H Returns a 1 for each key (k1, etc.) defined in Keys and a 0 otherwise.
⍝H 
  :Property Keyed Defined, Def 
  :Access Public
    ∇ b←get args; kk 
      'No keys specified' ⍙E 11/⍨  ⎕NULL≡ kk← ⊃args.Indexers 
      b← ⊂⍣ (0= ⊃⍴⍴kk)⊢ (≢KEYS)≠ KEYS⍳ kk 
    ∇
  :EndProperty

⍝H [0] d.Del k1 k2…     ⍝ Missing keys are allowed, but ignored.
⍝H  1  d.Del k1 k2…     ⍝ Missing keys are not allowed.
⍝H Delete items from the dictionary by key.
⍝H ∘ Returns 1 for each item found and deleted, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
    delMissE←   'Required keys were not found'
    ∇ b← {required} Del kk; ii; e; nK 
       :Access Public
      :If 0=≢kk 
          b←⍬
      :ELse 
          nK← ≢KEYS ⋄ e← nK≠ ii← KEYS⍳ kk  
          :If 0∊ e ⋄ :AndIf ~900⌶⍬ ⋄ :AndIf required    ⍝ If required is set,
              delMissE ⍙E 3                             ⍝ … missing keys aren't allowed
          :EndIf 
          KEYS VALS/⍨← ⊂~(⍳nK)∊ e/ ii                   ⍝ Delete keys and vals requested.
          b← e⍴⍨ ⍴kk                                    ⍝ If a scalar key, return a scalar bool.
      :EndIf 
    ∇
  ⍝ DelByKey: Alias for Del 
    ∇ b←DelByKey kk 
       :Access Public
       b← Del kk
    ∇
    
⍝H d.DelIx[i1 i2…]  
⍝H d,DelIx[] 
⍝H Delete items in the dictionary by index (caller's ⎕IO).  
⍝H Returns 1 for each item that was deleted, else 0 (item not found).
⍝H Note: d.DelIx[] simply executes a Clear, returning 1 for every item…
⍝H 
  :Property Keyed DelByIndex, DelIx 
  :Access Public
    ∇ b←Get args; ii; e; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          b← 1⍴⍨ Clear  
      :Else 
          ii-← (⊃⎕RSI).⎕IO                    ⍝ Adjust for caller's ⎕IO 
          KEYS VALS/⍨← ⊂~(⍳nK)∊ ii/⍨ e← ii< nK← ≢KEYS
          b← e⍴⍨ ⍴ii
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
⍝H ---------------
⍝H Note: Like d[xxx] (above), except allows a temporary default either when the dictionary
⍝H       otherwise lacks one or when the general default is not appropriate.
⍝H 
∇ vv← {default} Get kk; nD; ii; e 
  :Access Public
  ii← KEYS⍳ kk
  :If 0∊ e← ii≠ ≢KEYS 
      :IF nD← 900⌶⍬ ⋄ :ANDIF HAS_DEFAULT 
          default nD← DEFAULT 0
      :ENDIF   
      missKeyEM ⍙E 3/⍨ nD 
      vv← (≢kk)⍴ ⊂default 
      vv[ ⍸e ]← VALS[ e/ii ]
  :Else 
      vv← VALS[ ii ]
  :Endif 
∇
⍝H v1← [default] d.Get1 k1
⍝H Like d.Get, but retrieves the value* for exactly one key*. *= key/value not enclosed.
⍝H    d.Get1 'myKey' <==>  ⊃d.Get ⊂'myKey'
⍝H *** See note for d.Get.
⍝H
∇ v1← {default} Get1 k1; i 
  :Access Public  
  i← KEYS⍳ ⊂k1
  :IF i≠ ≢KEYS 
      v1← VALS[i]
  :ELSE
      :IF nD← 900⌶⍬ ⋄ :ANDIF HAS_DEFAULT 
          default nD← DEFAULT 0
      :ENDIF
        'Key not found and no default is active' ⍙E 3/⍨ nD 
        v1← default
  :ENDIF 
∇ 

⍝H d.HasDefault 
⍝H d.HasDefault← [1|0]
⍝H Retrieve or set the current Default status. 
⍝H - If you set HasDefault to 1, 
⍝H   the prior default (if any) is restored;
⍝H   ∘ If no default exists, HasDefault remains 0 and a VALUE ERROR is generated. 
⍝H - If you set HasDefault to 0, 
⍝H   any attempt to access an item that doesn't exist will cause a VALUE ERROR to 
⍝H   be signalled, until you reset HasDefault to 1.
⍝H 
  :Property Simple HasDefault 
  :Access Public
    ∇ b←get 
      b← HAS_DEFAULT 
    ∇
    ∇ set def; d   
      ⍙E 11/⍨ 0 1 (~∊⍨) d← def.NewValue 
      'Default has no value' ⍙E 6/⍨ {~⍵: 0 ⋄ 0:: 1 ⋄ 0⊣DEFAULT}d
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

⍝H {e}← d.Pop n
⍝H Remove and shyly return the last <n> entries from the dictionary.
⍝H n: a single non-negative integer. 
⍝H If n exceeds the # of entries, the actual entries are returned (no padding is done).
⍝H 
  ∇{e}← Pop n; m  
    :Access Public 
    ⍙E 6/⍨ n<0 
    m← - n⌊ ≢KEYS 
    :Trap 0 
        e← ↓⍉↑KEYS VALS↑⍨¨ m 
        KEYS VALS ↓⍨← m 
        :If 0= ≢e ⋄ e← ⍬ ⋄ :EndIf 
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
    ∇ v←get args; ii
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          v← VALS
      :Else   
          ⍙E 3/⍨ 0∊ ii< ≢KEYS 
          v← VALS[ii]
      :EndIf 
    ∇
    ∇ set args; ii
      ii← ⊃args.Indexers 
      ⍙E 3/⍨ 0∊ ii< ≢KEYS 
      VALS[ii]← args.NewValue 
    ∇
    ∇ s←Shape
      s← ⍴KEYS 
    ∇
  :EndProperty

:EndClass

:EndNamespace
