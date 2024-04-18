:Namespace ∆DClass
⍝H ∆D, ∆DL; ∆DX  "Create and Manage a Dictionary"
⍝H Create a dictionary whose items are in a fixed order based on order of creation
⍝H (oldest first).  Adding new values for existing keys does not change their order.
⍝H Keys and Values may be of any type. 
⍝H 
⍝H ∆D "Dictionary from Items (Key-Value Pairs)"
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d← [default] ∆D ⍬              
⍝H d← [default] ∆D (k1 v1)(k2 v2)…
⍝H ∘ Create a dictionary with items (k1 v1)(k2 v2)….
⍝H ∘ If no items are specified, an empty dictionary is created.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H   
⍝H ∆DL "Dictionary from a KeyList and ValueList"
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d← [default] ∆DL ⍬ ⍬                
⍝H d← [default] ∆DL (k1 k2…)(v1 v2…)
⍝H d← [default] ∆DL (k1 k2…)(v1)         ⍝ I.e. (k1 k2…kN)(v1 v1…vN)
⍝H ∘ Create a dictionary from a list of keys and corresponding values or, if there
⍝H   is a single (enclosed or simple scalar) value, make it the value for each key.
⍝H ∘ For keys KK and values VV, either KK≡⍥≢VV or 1=≢VV. 
⍝H ∘ Both may be empty, resulting in an empty dictionary.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H
⍝H ∆DX "Dictionaries with options"  [∆DX is an operator]
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d← [default] (options ∆DX) initial_values
⍝H     initial_values: defined per options 'Items' vs 'Lists' below
⍝H     options: 
⍝H       ['Items'* | 'Lists'] ['Nohash'* | 'Hash']        
⍝H               * 'Items' 'NoHash' are defaults
⍝H        'Items'   initial_values are key-value pairs (k1 v1)(k2 v2)…
⍝H        'Lists'   initial_values are lists of keys and values (k1 k2…)(v1 v2…)
⍝H                  If the values consists of a single scalar, it is replicated
⍝H                  for all keys. It must be an enclosed or simple scalar.
⍝H        'Hash'    if specified, d.Hash is executed after initialization.
⍝H        'Nohash'  the default, d.Hash is NOT executed automatically.
⍝H     Abbreviations:
⍝H        'Items' => 'I'*, 'Lists' => 'L', 'Nohash' => 'N'*, 'Hash' => 'H'
⍝H         Abbrev. may be indicated in a single string,
⍝H                e.g. 'LH', 'L', or '' (i.e. 'IN') 
⍝H
⍝  *** See additional HELP info below ***

⎕IO ⎕ML←0 1  
_TS← {  ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨('^(∆D\w? )?'⎕R(⍺,' ')⊢EM) EN  Message)} 
TrapSig← ⎕SIGNAL _TS 

⍝ ∆D: Create from items (key-value pairs)   
⍝ ⍺: default (optional), ⍵: itemlist (i.e. (k1 v1)(k2 v2)…)     
∆D←{ hd←2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 0:: '∆D' TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
        ⎕NEW Dict (⍵ ⍺ hd 0)           
}

⍝ ∆DL: Create from two lists: keylist and valuelist
⍝          or from a list and a scalar: keylist (scalar_value)
∆DL←{hd← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 0:: '∆DL'TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
     2≠≢⍵: ⎕SIGNAL/'∆DL DOMAIN ERROR: unexpected right arg' 11 
        ⎕NEW Dict (⍵, ⍺ hd 0)            
}

⍝ ∆DX: See description above.
∆DX← { hd← 2= ⎕NC'⍺' ⋄ ⍺← ⎕NULL ⋄ 0:: '∆DX'TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
        (i l n h)ok← 'ILNH' (∊ ,⍥⊂ ∊⍨) ⊃¨⍺⍺  ⍝ Items, Lists, Nohash, Hash
        (i∧l)∨(n∧h)∨0∊ok: ⎕SIGNAL/ '∆DX DOMAIN ERROR: unknown or conflicting options' 11
      l:  ⎕NEW Dict (⍵, ⍺ hd h) ⋄ ⎕NEW Dict (⍵ ⍺ hd h) 
} 

##.∆D←  ⎕THIS.∆D 
##.∆DL← ⎕THIS.∆DL 
##.∆DX← ⎕THIS.∆DX 

∇ {ok}← Help; t
  ok← ⎕ED 't'⊣ t← '^\h*⍝H ?(.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS 
∇

:Class Dict
⍝H ├─────────────────────────────────────────────────────────────────────────┤
⍝H │                 "METHODS"  IN ALPHABETICAL ORDER…                       │
⍝H ├─────────────────────────────────────────────────────────────────────────┤  
⍝H │  d[kk],d[]       d[kk]← vv    d.Clear    d2← d.Copy   d.Default         │
⍝H │  d.Default←any   d.Def[kk]    d.ⁱDel kk  d.⁲DelIx[ii] d.DelIx[]         │ 
⍝H │  d.Get/1 kk      d.HasDefault d.HasDefault←[1|0]      d.Help            │
⍝H │  d.Import kk vv  d.Items      d.Keys     d.Pop n      d.⁲Vals[ii]       │     
⍝H │  d.⁲Vals[ii]← vv                                                        │
⍝H ├─────────────────────────────────────────────────────────────────────────┤ 
⍝H │  kk: list of keys, vv: list of vals, ii: list of indices, any: any val. │  
⍝H ├─────────────────────────────────────────────────────────────────────────┤ 
⍝H │  ⁱ Del: If a left arg is present and 1, all keys MUST exist.            │
⍝H │  ⁲ DelIx, Vals: Uses Index Origin (⎕IO) of caller as expected.          │     
⍝H ├─────────────────────────────────────────────────────────────────────────┤
⍝H 
                  KEYS←        ⍬   ⍝ Avoid Field, since it seems to disrupt hashing!
  :Field Private  VALS←        ⍬
  :Field Private  DEFAULT
  :Field Private  HAS_DEFAULT← 0  
  :Field Private  HASH_SET←    0   ⍝ If 1, set hash where required. See d.Hash, internal HashIfSet
⍝ Error Msgs: Format: [EN@I Message@CV], where Message may be ''.
  :Namespace error ⍝ em message
      itemsBad←    11 'A list of items (key-value pairs) is required (enclose if just one)'
      keyNotFnd←    3 'Key(s) not found and no default is active'
      noKeys←      11 'No keys were specified'
      noDef←        6 'Default not set or active'
      delLeftBad←  11 'Left arg to Del is invalid'
      delKeyBad←    3 'Key(s) not found (nothing deleted)'
      delIxBad←     3 'Nothing deleted'
  :EndNamespace
 
⍝ ErrIf: Internal helper. Usage:  en msg ErrIf bool 
⍝     ⍺: Message (default: ''), ⍵: Error #. 
⍝     No error if ⍵ is ⍬.
  ErrIf← ⎕SIGNAL {~⍵: ⍬ ⋄ e m← ⍺ ⋄ ⊂('EM' ('∆D ',⎕EM e)) ('EN' e) ('Message' m) }

  ∇ makeFill                   ⍝ Create an empty dict with no defaults
  :Implements constructor 
  :Access Public 
  ∇ 

  ∇ MakeI (ii d hd hash)             ⍝ Create dict from Items and opt'l Default
    ;kk; vv; kkvv                    ⍝ If hd (HAS_DEFAULT)=0, the DEFAULT is NOT set.
    :Implements constructor
    :Access Public
    :If 0= ≢ii 
        ⍝ no values
    :Elseif 2=≢kkvv← ,¨(↓∘⍉↑∘,) ii
        kk vv← kkvv 
        ValuesByKey[kk]←vv 
    :Else 
        error.itemsBad ErrIf 1 
    :EndIf  
    :IF HAS_DEFAULT← hd ⋄ DEFAULT← d ⋄ :Endif 
    :IF hash ⋄ Hash  ⋄ :Else ⋄ ⎕DF '∆D:[Dict]' ⋄ :Endif 
∇
  ∇ makeL (kk vv d h hash)     ⍝ Create dict from Keylist Valuelist and opt'l Default 
    ; Conform 
    :Implements constructor    ⍝ If h (HAS_DEFAULT)=0, the DEFAULT is NOT set.
    :Access Public
    :Trap 11
        :If 1=≢vv ⋄ vv⍴⍨← ⍴kk ⋄ :EndIf    ⍝ Conform vv to kk, if vv is a singleton.
        ValuesByKey[kk]←vv  
    :Else
        11 '' ErrIf 0
    :EndTrap 
    :IF HAS_DEFAULT← h ⋄ DEFAULT← d ⋄ :Endif 
    :IF hash ⋄ Hash  ⋄ :Else ⋄ ⎕DF '∆D:[Dict]' ⋄ :Endif 
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
  :Property Default Keyed ValuesByKey 
  :Access Public
    ∇ vv←get args; ii; kk; bb 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          vv← VALS                            ⍝ Grab all values if d[] is specified.
      :Else 
          ii← KEYS⍳ kk
          :If ~0∊ bb← ii≠ ≢KEYS               ⍝ All keys old? 
               vv← VALS[ ii ]                 ⍝ … Just grab existing values.
          :Else                               ⍝ Some old and some new keys.
              error.keyNotFnd ErrIf ~HAS_DEFAULT   ⍝ … error unless we have a DEFAULT;
            ⍝ >40% slower: vv← VALS[bb/ii]@(⍸bb)⊣ (≢kk)⍴⊂DEFAULT
              vv← (≢kk)⍴ ⊂DEFAULT             ⍝ … where new, return DEFAULT;
              vv[ ⍸bb ]← VALS[ bb/ ii ]       ⍝ … where old, return existing value.
          :Endif 
          vv← ⊂⍣ (0= ⊃⍴⍴kk)⊢ vv               ⍝ If kk is a scalar, return vv as a scalar.
      :Endif  
    ∇
  ⍝ ValuesByKey "set" function
  ⍝ Note 1: Regarding which values to use when there are duplicate keys being set:
  ⍝   we add new keys keeping the leftmost duplicate (as expected for dict ordering);
  ⍝   we add new values keeping the rightmost duplicate (consistent with APL indexing).
  ⍝ Note 2: If we find new keys, we search all keys twice, rather than simply searching new keys
  ⍝   for duplicates. While the performance impact is nil when keys are hashed, there
  ⍝   may be a performance penalty on larger dictionaries otherwise.
    ∇ set args; kk; n; pp; vv  
      kk← ⊃args.Indexers 
      vv←  args.NewValue   
      error.noKeys ErrIf ⎕NULL≡ kk     ⍝ d[]← ... NOT ALLOWED.
      pp← KEYS⍳ kk                     ⍝ Search for keys, existing and new.
      :If 1∊ n← (≢KEYS)= pp            ⍝ New keys?
          VALS,← 0⍴⍨ ≢KEYS,← ∪n/ kk    ⍝ ...Add new unique keys and new value placeholders
          pp← KEYS⍳ kk                 ⍝ ...Recalculate where keys found (see Note 2 above)
      :EndIf 
      VALS[ pp ]← vv                   ⍝ Update existing and new vals (see Note 1)
    ∇ 
  :EndProperty

  ⍝H {n}← d.Clear
  ⍝H Remove all items (keys and values) from the dictionary.
  ⍝H Do not change any default value (Default).
  ⍝H Shyly returns the # of items deleted.
  ⍝H 
    ∇{n}← Clear 
      :Access Public 
      n← ≢KEYS ⋄ KEYS←VALS← ⍬ ⋄ HashIfSet 
    ∇

  ⍝H d2← d.Copy
  ⍝H Make a copy of the Keys, Vals, and Default of dictionary d.
  ⍝H Also if d.Hash is active, d2.Hash will be as well.
  ⍝H 
  ∇ d2← Copy; def  
    :Access Public 
    def← {6:: ⎕NULL ⋄ DEFAULT} ⍬
    d2← ⎕NEW Dict (KEYS VALS def HAS_DEFAULT HASH_SET)  
    d2.⎕DF '∆D.[Dict', ']',⍨ HASH_SET/'+hash'
  ∇

⍝H d.Default
⍝H d.Default← any_value 
⍝H Retrieve or set/redefine the default value for missing dictionary items
⍝H (those requested by key that do not exist).
⍝H If you set a default, HasDefault is automatically set to 1.
⍝H 
  :Property Simple Default
  :Access Public
    ∇ d←get 
      error.noDef ErrIf ~HAS_DEFAULT 
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
      error.noKeys ErrIf ⎕NULL≡ kk← ⊃args.Indexers 
      b← ⊂⍣ (0= ⊃⍴⍴kk)⊢ (≢KEYS)≠ KEYS⍳ kk 
    ∇
  :EndProperty

⍝H bb← [0] d.Del k1 k2…     ⍝ Missing keys are allowed, but ignored.
⍝H bb←  1  d.Del k1 k2…     ⍝ Missing keys are not allowed.
⍝H Delete items from the dictionary by key.
⍝H ∘ Duplicate keys allowed.
⍝H ∘ Returns 1 for each entry found and deleted, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
⍝ Del: Alias for DelByKey 
    ∇ bb←{required} DelByKey kk 
       :Access Public
       :Trap 0
          bb← kk Del⍨ {⍵: 0 ⋄ required}900⌶⍬ 
       :Else
          ⎕SIGNAL⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨EM EN Message)
       :EndTrap 
    ∇
    ∇ {bb}← {required} Del kk; ii; err; msg  
       :Access Public
      :If 0=≢kk 
          bb←⍬
      :Else 
          bb← (≢KEYS)≠ ii← KEYS⍳ kk     
          :If 0∊ bb ⋄ :AndIf ~900⌶⍬ 
              error.delLeftBad  ErrIf ~required∊0 1
              error.delKeyBad   ErrIf required             
          :EndIf 
          :IF 1∊ bb                         
              ErrIf/ 0 ⍙DelIx ∪bb/ ii     ⍝ Delete...
          :EndIf 
          bb⍴⍨← ⍴kk                       ⍝ If a scalar input key, return a scalar result.
      :EndIf 
    ∇
    
⍝H items← d.DelIx[i1 i2…]      ⍝ Entries at [i1 i2…] returned and deleted 
⍝H items← d,DelIx[]            ⍝ All entries returned and deleted
⍝H   Delete items in the dictionary by index, which must exist (using caller's ⎕IO).  
⍝H   Duplicate items ok.
⍝H   Returns the now deleted items.
⍝H 
  :Property Keyed DelByIndex, DelIx 
  :Access Public
    ∇ items←Get args; ii; ei; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          items← Items ⋄ Clear   
      :Else 
          items err← 1 ⍙DelIx ii-(⊃⎕RSI).⎕IO   ⍝ Adjust for caller's ⎕IO   
          items ErrIf err  
          items← ⊂⍣ (0=⊃⍴⍴ii)⊣ items           ⍝ If input arg is a scalar, then ensure return val is as well.
      :Endif 
    ∇
  :EndProperty

  ⍝ ret← ⍙DelIx ii     (Internal helper function)
  ⍝   Delete items for indices specified (which must exist); duplicate items ok.
  ⍝ On success:
  ⍝   ∘ If ⍺=1: returns:   (the items deleted) 0. 
  ⍝   ∘ If ⍺=0: returns:   ii 0.   
  ⍝ If an index error occurs: 
  ⍝   ∘         returns:   (error.object) 1
  ⍝ Note: if all items to delete are in a contiguous trailing block of keys (possibly repeated),
  ⍝       hashing will be maintained automatically (if set).     
  ⍝                    
    ⍙DelIx←{  
      3:: error.delIxBad 1 
          ret← ⍺ { ⍺: ↓⍉↑ KEYS VALS⌷⍨¨ ⊂⊂⍵ ⋄ ⍵ } ii←⍵ 
          blok← -+/∧\⌽bb← 1@ ii⊣ 0⍴⍨ ≢KEYS      ⍝ catches index errors   
        ⍝ If all items are in a contig. trailing block, remove vai ↓⍨←, which preserves any hashing.   
      1(~∊) bb↓⍨ blok: ret 0⊣ KEYS↓⍨← VALS↓⍨← blok  
        ⍝ Remove items to delete by indexing (depends on ix errors being caught above)
          KEYS/⍨← VALS/⍨← ~bb        
          ret 0 ⊣ HashIfSet   
    }

⍝H v1 v2…← d.Get k1 k2…             ⍝ One or more keys (present a list, returns a list)
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
∇ vv← {default} Get kk; nD; ii; bb 
  :Access Public
  ii← KEYS⍳ kk
  :If 0∊ bb← ii≠ ≢KEYS 
      :IF nD← 900⌶⍬ ⋄ :ANDIF HAS_DEFAULT 
          default nD← DEFAULT 0
      :ENDIF   
      error.keyNotFnd ErrIf nD 
      vv← (≢kk)⍴ ⊂default 
      vv[ ⍸bb ]← VALS[ bb/ii ]
  :Else 
      vv← VALS[ ii ]
  :Endif 
∇
⍝H v1← [default] d.Get1 k1          ⍝ One key (present a value, returns a value)
⍝H Like d.Get, but retrieves the value* for exactly one key*. 
⍝H    d.Get1 'myKey' <==>  ⊃d.Get ⊂'myKey'                    
⍝H Note: [*] Neither the key passed nor the return value is enclosed.
⍝H    See also the note at d.Get (above).
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
        error.keyNotFnd ErrIf nD 
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
       11 ''ErrIf 0 1 (~∊⍨) d← def.NewValue 
       error.noDef ErrIf {~⍵: 0 ⋄ 0:: 1 ⋄ 0⊣DEFAULT}d  ⍝ ⎕NC'DEFAULT' always returns 2!
      HAS_DEFAULT← d 
    ∇
  :EndProperty 

⍝H was← d.Hash 
⍝H Set the flag HASH_SET to 1 and mark the vector KEYS as a Dyalog hashtable, 
⍝H so it can be searched faster. This creates some overhead, but searches of (large) 
⍝H key vectors can be done in O(1) time, rather than O(N).
⍝H When set, hashing is established immediately and redone when a delete takes place.
⍝H 
⍝H Returns the prior hash status:
⍝H    0: not hashed, 1: hashed but not used, 2: hashed and used. 
⍝H 
  ∇ {was}← Hash
    :Access Public
    HASH_SET← 1 ⋄ was← 1(1500⌶)KEYS ⋄ KEYS← 1500⌶KEYS  
    ⎕DF  '∆D=[Dict+hash]' 
  ∇
⍝ d← d.CondHash
⍝ Calls Hash, returning this class instance. 
  ∇ d← CondHash cond 
    :Access Public
    :IF cond ⋄ Hash ⋄ :Endif 
    d← ⎕THIS  
  ∇
  
  ∇ {h}← HashIfSet
    :Access Private
    :IF HASH_SET ⋄ :ANDIF 0=1(1500⌶)KEYS 
        h←1 ⋄ KEYS← 1500⌶KEYS 
    :Else 
        h←0 
    :EndIf
  ∇ 
 
⍝H d.Help
⍝H Provide help information.
⍝H 
  ∇ {ok}← Help
  :Access Public Shared
    ok← ##.Help 
  ∇

⍝H d.Import keylist vallist 
⍝H Add new (or existing) items via lists of keys and values.
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

⍝H items← d.Pop n
⍝H Remove and shyly return the last <n> items from the dictionary.
⍝H n: a single non-negative integer. 
⍝H If n exceeds the # of items, the actual items are returned (no padding is done).
⍝H 
  ∇{items}← Pop n; p
    :Access Public 
    :Trap 0 
        :If 1≠ ≢n ⋄ :OrIf n<0 ⋄ ⋄ :OrIf n≠⌊n ⋄ 11 '' ErrIf 1 ⋄ :EndIf 
        items← ↓⍉↑ KEYS VALS↑⍨¨ p← ⊂- n⌊ ≢KEYS  
        KEYS VALS↓⍨← p ⋄ HashIfSet      
        :If 0= ≢items ⋄ items← ⍬ ⋄ :EndIf 
    :Else 
        '∆D'##.TrapSig⍬
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
          3 ''ErrIf 0∊ ii< ≢KEYS 
          v← VALS[ii]
      :EndIf 
    ∇
    ∇ set args; ii
      ii← ⊃args.Indexers 
      3 '' ErrIf 0∊ ii< ≢KEYS 
      VALS[ii]← args.NewValue 
    ∇
    ∇ s←Shape
      s← ⍴KEYS 
    ∇
  :EndProperty

:EndClass
:EndNamespace
