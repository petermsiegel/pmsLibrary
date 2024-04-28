:Namespace ∆DClass
⍝H ∆D, ∆DL; ∆DX  "Create and Manage a Dictionary"
⍝H Create a dictionary whose items are in a fixed order based on order of creation
⍝H (oldest first).  Adding new values for existing keys does not change their order.
⍝H Keys and Values may be of any type. 
⍝H 
⍝H ∆D "Dictionary from  (Key-Value Pairs)"
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d← [default] ∆D ⍬              
⍝H d← [default] ∆D (k1 v1)(k2 v2)…
⍝H ∘ Create a dictionary with items (k1 v1)(k2 v2)….
⍝H ∘ If no items are specified, an empty dictionary is created.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H ∘ If AUTOHASH←1 in the ∆D.Dict namespace (default),
⍝H   d.Hash will be applied at dictionary creation.
⍝H   Currently, AUTOHASH←$AUTOHASH 
⍝H ==========
⍝H Note: ∆D 'help' will display this help information.
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
⍝H ∘ If AUTOHASH=1 in the ∆D.Dict namespace (default),
⍝H   d.Hash will be applied at dictionary creation.
⍝H   Currently, AUTOHASH←$AUTOHASH 
⍝H ==========
⍝H Note: ∆DL'help' will display this help information.
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
⍝H        'Hash'    if specified, d.Hash (q.v.) is executed after initialization.
⍝H        'Nohash'  the default, d.Hash is NOT executed automatically.
⍝H     Abbreviated Form (single char vec):
⍝H         '[I*|L][N*|H]'
⍝H        'Items' => 'I'*, 'Lists' => 'L', 'Nohash' => 'N'*, 'Hash' => 'H'
⍝H         Example:  'LH' <== 'Lists' 'Hash'
⍝H Note 1: AUTOHASH has no effect on ∆DX. Hashing must be explicitly requested using
⍝H         the 'Hash' option.
⍝H Note 2: ⍬∆DX'help' will display this help information.
⍝H
⍝  *** See additional HELP info below ***

⎕IO ⎕ML←0 1  
_TS← { ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨('^(∆D\w? )?'⎕R(⍺,' ')⊢EM) EN  Message) } 
TrapSig← ⎕SIGNAL _TS 

⍝ ∆D: Create from items (key-value pairs)   
⍝ dict← [default] ∇ (k1 v1)(k2 v2)…
∆D←{ 
  dFlag←2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 0:: '∆D' TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
  ⎕NEW Dict (⍵ ⍺ dFlag Dict.AUTOHASH)           
}

⍝ ∆DL: Create from two lists: keylist and valuelist
⍝          or from a list and a scalar: keylist (scalar_value)
⍝ dict← [default] ∇ keylist valuelist
∆DL←{
    dFlag← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 0:: '∆DL'TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
  2≠≢⍵: ⎕SIGNAL/'∆DL DOMAIN ERROR: invalid right arg shape' 11 
    ⎕NEW Dict (⍵, ⍺ dFlag Dict.AUTOHASH)            
}

⍝ ∆DX: See description above.
⍝ dict← [default] (opts ∇) ((k1 v1)(k2 v2)… | keylist valueList)
⍝    opts: 'Items'|'Lists', 'Nohash'|'Hash') or  (SQt I|L N|H SQt)
∆DX← { 
    dFlag← 2= ⎕NC'⍺' ⋄ ⍺← ⎕NULL ⋄ 0:: '∆DX'TrapSig⍬ ⋄ 'help'≡⎕C⍵: _← Help 
    (i l n h)ilnh← 'ILNH' (∊ ,⍥⊂ ∊⍨) ⊃¨⍺⍺  ⍝ Items*|Lists, Nohash*|Hash
    (i∧l)∨(n∧h)∨0∊ilnh: ⎕SIGNAL/ '∆DX DOMAIN ERROR: unknown or conflicting options' 11
  l: ⎕NEW Dict (⍵, ⍺ dFlag h) ⋄ ⎕NEW Dict (⍵ ⍺ dFlag h) 
} 

##.∆D←  ⎕THIS.∆D 
##.∆DL← ⎕THIS.∆DL 
##.∆DX← ⎕THIS.∆DX 

⍝ Provide help information. See also Dict.Help.
∇ {ok}← Help; t; R; S 
  R← '\$AUTOHASH'   ⎕R (⍕Dict.AUTOHASH)
  S← '^\h*⍝H\h?(.*)' ⎕S '\1'
  ok← ⎕ED 't'⊣ t← R S ⊣ ⎕SRC ⎕THIS 
∇
 
:Class Dict
⍝H ┌───────────────────────────────────────────────────────────────────────────────┐
⍝H │                 "METHODS"  IN ALPHABETICAL ORDER…                             │
⍝H ├───────────────────────────────────────────────────────────────────────────────┤  
⍝H │  d[kk],d[]     d[kk]← vv    vv← [nums] d.AddTo kk  d.Default  d.Default←any   │
⍝H │  d.Def[kk]     d.ⁱDel kk    d.⁲DelIx[ii]           d.DelIx[]  d.Default←any   │ 
⍝H │  vv← d.Get kk  d.Get1 k │   d.HasDefault  d.HasDefault←[1|0]  d.Help          │
⍝H │  d.⁲Items[ii]  d.⁲Keys[…]   d.Pop n       d.⁲Vals[ii]         d.⁲Vals[ii]←vv  │
⍝H ├───────────────────────────────────────────────────────────────────────────────┤ 
⍝H │  {d}← d.Clear  {d}← d.Hash  {d}← d.Import kkvv                                │
⍝H │  d2←  d.Copy   d2 ← d.⁳Sort [1|¯1|0]                                          │
⍝H ├─────────────────────┬──────────────────────┬──────────────────────────────────┤ 
⍝H │  kk: list of keys   │  vv: list of vals    │   ii: list of indices            │  
⍝H │  kkvv: kk vv        │  any: any val.       │   nums: 1 or more numbers        │  
⍝H ├─────────────────────┴──────────────────────┴──────────────────────────────────┤ 
⍝H │  ⁱ Del: If a left arg is present and 1, all keys MUST exist.                  │
⍝H │  ⁲ DelIx, Items, Keys, Vals: Use Index Origin (⎕IO) of caller when indexing   │   
⍝H │  ⁳ Sort: n is: 1=ascending, ¯1=descending, 0=no change.                       │     
⍝H └───────────────────────────────────────────────────────────────────────────────┘
⍝H 
⍝ Error Msgs: Format: [EN@I Message@CV], where Message may be a null string ('').
  :Namespace error ⍝ em message
      badRightArg← 11 'Method right arg is invalid'
      badLeftArg←  11 'Method left arg is invalid'
      delKeyBad←    3 'Key(s) not found (nothing deleted)'
      delIxBad←     3 'Nothing deleted'      
      itemsBad←    11 'A list of items (key-value pairs) is required (enclose if just one)'
      keyNotFnd←    3 'Key(s) not found and no default is active'
      mismatch←     5 'Mismatched left and right argument shapes'
      noKeys←      11 'No keys were specified'
      noDef←        6 'Default not set or active'
  :EndNamespace
  :Namespace def  ⍝ Default states.
      active←       1
      quiesced←    ¯1
      none←         0
  :EndNamespace 
⍝ 
  :Field PUBLIC SHARED DBG←0           ⍝ 1 to debug
  :Field Public Shared AUTOHASH← 1     ⍝ If 1, ∆D and ∆DL will enable hashing for new dicts
                  KEYS←          ⍬     ⍝ Avoid Field, since it seems to disrupt hashing!
  :Field Private  VALS←          ⍬
  :Field Private  DEF_VAL←       ⎕NULL ⍝ Placeholder: ignored if DEF_STATUS=def.none.
  :Field Private  DEF_STATUS←    def.none  ⍝ See namespace <def>
  :Field Private  HASH_SET←      0     ⍝ If 1, set hash where required. See d.Hash, internal HashIfSet
 
⍝ ErrIf: Internal helper. Usage:  en msg ErrIf bool 
⍝     ⍺: Message (default: ''), ⍵: Error #. 
⍝     No error if ⍵ is ⍬.
  ErrIf← ⎕SIGNAL {~⍵: ⍬ ⋄ e m← ⍺ ⋄ ⊂('EM' ('∆D ',⎕EM e)) ('EN' e) ('Message' m) }
⍝ Dbg:    { debug_action_on_⍵ } Dbg ⍵
  Dbg← { ~DBG: _←⍬ ⋄ 1: ⎕← ⍺⍺ ⍵}

  ∇ makeFill                   ⍝ Create an empty dict with no DEF_VAL 
    :Implements constructor 
    :Access Public 
  ∇ 

  ∇ MakeI (ii dVal dFlag hFlag)      ⍝ Create dict from Items and opt'l Default
    ;kk; vv; kkvv                   
    :Implements constructor
    :Access Public
    :If 0= ≢ii 
        ⍝ no values
    :Elseif 2=≢kkvv← ,¨(↓∘⍉↑∘,) ii
        kk vv← kkvv 
        ValsByKey[kk]←vv 
    :Else 
        error.itemsBad ErrIf 1 
    :EndIf  
    DEF_VAL DEF_STATUS ← dVal dFlag 
    :IF hFlag ⋄ Hash  ⋄ :Else ⋄ ⎕DF '∆D=[Dict]' ⋄ :Endif 
∇
  ∇ makeL (kk vv dVal dFlag hFlag)     ⍝ Create dict from Keylist Valuelist and opt'l Default  
    :Implements constructor    ⍝ If h=0, the DEF_VAL is NOT set.
    :Access Public
    :Trap 11
        :If 1=≢vv ⋄ vv⍴⍨← ⍴kk ⋄ :EndIf    ⍝ Conform vv to kk, if vv is a singleton.
        ValsByKey[kk]←vv  
    :Else
        11 '' ErrIf 0
    :EndTrap 
    DEF_VAL DEF_STATUS← dVal dFlag 
    :IF hFlag ⋄ Hash  ⋄ :Else ⋄ ⎕DF '∆D=[Dict]' ⋄ :Endif 
  ∇


⍝H d[k1 k2 …], 
⍝H d[k1 k2 …]← v1 v2 …
⍝H d[]
⍝H Retrieve or set specific values of the dictionary by key.
⍝H You can also retrieve (but not set) all values via d[]. 
⍝H See also 
⍝H    d.Vals[]              ⍝ Retrieve values by Index
⍝H    d.Get, and d.Get1.    ⍝ Retrieve values by key with an optional ad hoc default.
⍝H 
  :Property Default Keyed ValsByKey 
  :Access Public
    ∇ vv←get args; ii; kk; old 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          vv← VALS                            ⍝ Grab all values if d[] is specified.
      :Else 
          old← (≢KEYS)≠ ii← KEYS⍳ kk
          :If ~0∊ old                         ⍝ All keys old? 
              vv← VALS[ ii ]                  ⍝ … Just grab existing values.
          :Else                               ⍝ Some old and some new keys.
              ⋄ error.keyNotFnd ErrIf DEF_STATUS≠ def.active  ⍝ … error unless we have a DEF_VAL;
              vv← (≢kk)⍴ ⊂DEF_VAL             ⍝ … where new, return DEF_VAL;
              vv[ ⍸old ]← VALS[ old/ ii ]     ⍝ … where old, return existing value.
          :Endif 
          vv ⍴⍨← ⍴kk 
      :Endif  
    ∇
  ⍝ ValsByKey "set" function
  ⍝ Note: Regarding which values to use when there are duplicate keys being set:
  ⍝   we add new keys keeping the leftmost duplicate (as expected for dict ordering);
  ⍝   we add new values keeping the rightmost duplicate (consistent with APL indexing).
    ∇ set args; kk; ii; new; vv; nKEYS   
      kk← ⊃args.Indexers ⋄ vv← args.NewValue 
      ⋄ error.noKeys ErrIf ⎕NULL≡ kk           ⍝ d[]← ... NOT ALLOWED.
      nKEYS← ≢KEYS    
      :IF 1∊ new← nKEYS= ii← KEYS⍳ kk 
          VALS,← 0⍴⍨ ≢ukk← KEYS,← ∪nkk← new/ kk   
          (new/ ii)← nKEYS + ukk⍳ nkk 
      :EndIf 
      VALS[ ii ]← vv 
    ∇ 
  :EndProperty

⍝H {res}← counts|1 d.AddTo kk
⍝H   kk:     1 or more keys, which (a) may be duplicated and (b) may be new to d.
⍝H   counts: numbers to add to d[kk], either a single number or (≢kk) numbers.
⍝H           Defaults to 1, if omitted.
⍝H Adds all corresponding counts to d[kk], where kk may be repeated.
⍝H --------------- 
⍝H ∘ If d.Keys[k] does not exist for k, a key in kk, d[k] will initialize to 0,
⍝H   before any addition, as if 0 were the default value for new entries.
⍝H ∘ Same as Keys[kk]+← Keys[kk] (if it worked), accumulating ALL counts for a specific key,
⍝H   except for defaults and the handling of new values.
⍝H ∘ Shyly returns the new values at Keys[kk].
⍝H 
  ∇ {res}← {counts} AddTo kk; ii; new; nkk; ukk; nKEYS   
    :Access Public
    :IF 900⌶⍬ ⋄ counts← 1 ⋄ :EndIf 
    :Trap 0 
        nKEYS← ≢KEYS 
        :If 1∊ new← nKEYS= ii← KEYS⍳ kk   
            VALS,← 0⍴⍨ ≢ukk← KEYS,← ∪nkk← new/ kk    ⍝ Initialize new values to 0  
            (new/ ii)← nKEYS+ ukk⍳ nkk 
        :EndIf 
        VALS[ ii ]+← counts
        res← VALS[ ii ]    
    :Else 
       '∆D'##.TrapSig⍬
    :EndTrap 
  ∇

  ⍝H {d}← d.Clear
  ⍝H Remove all items (keys and values) from the dictionary.
  ⍝H Do not change any default value (Default).
  ⍝H Shyly returns the dictionary.
  ⍝H 
    ∇{d}← Clear 
      :Access Public 
      d← ⎕THIS ⋄ KEYS←VALS← ⍬ ⋄ HashIfSet 
    ∇

  ⍝H d2← d.Copy
  ⍝H Make a copy of the Keys, Vals, and Default setting of dictionary d.
  ⍝H If d.Hash has been set (implicitly or explicitly), d2.Hash will be as well.
  ⍝H 
  ∇ d2← Copy; def  
    :Access Public 
    d2← ⎕NEW Dict (KEYS VALS DEF_VAL DEF_STATUS HASH_SET)  
    d2.⎕DF ⍕⎕THIS 
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
      ⋄ error.noDef ErrIf DEF_STATUS≠ def.active
      d← DEF_VAL 
    ∇
    ∇ set new  
      DEF_STATUS DEF_VAL← def.active new.NewValue 
    ∇
  :EndProperty 

⍝H bb← d.Def[k1 k2 …]     "Are keys defined in Keys?"
⍝H Returns a 1 for each key (k1, etc.) defined in Keys and a 0 otherwise.
⍝H 
  :Property Keyed Defined, Def 
  :Access Public
    ∇ bb←get args; kk 
      ⋄ error.noKeys ErrIf ⎕NULL≡ kk← ⊃args.Indexers 
      bb← ⊂⍣ (0= ⊃⍴⍴kk)⊢ (≢KEYS)≠ KEYS⍳ kk 
    ∇
  :EndProperty

⍝H bb← d.Del: Delete items by keyword (k1 k2…)
⍝H bb← [required←0*] d.Del k1 k2…     ⍝ If missing keys are seen, they are ignored.
⍝H bb← [required←1]  d.Del k1 k2…     ⍝ If missing key are seen, an error is signaled.
⍝H Delete items from the dictionary by key.
⍝H ∘ Duplicate keys allowed.
⍝H ∘ Returns 1 for each entry found and deleted, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
⍝H Note: DelByKey is an alias for Del.
⍝H
    ∇ bb←{required} DelByKey kk 
       :Access Public
       :Trap 0
           required← {⍵: 0 ⋄ required }900⌶⍬
           bb← required  Del kk
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
              error.badLeftArg ErrIf required(~∊) 0 1
              error.delKeyBad  ErrIf required             
          :EndIf 
          :IF 1∊ bb                         
              ErrIf/ 0 ⍙DelIx ∪bb/ ii     ⍝ Delete...
          :EndIf 
          bb⍴⍨← ⍴kk                       ⍝ If a scalar input key, return a scalar result.
      :EndIf 
    ∇
    
⍝H d.DelIx: Delete items by index (in caller's ⎕IO), returning prior value.
⍝H   items← d.DelIx[i1 i2…]      ⍝ Entries at [i1 i2…] returned and deleted 
⍝H   items← d,DelIx[]            ⍝ All entries returned and deleted
⍝H Delete items in the dictionary by index.
⍝H Returns all items indexed after deleting them from the dictionary.
⍝H ∘ All items must exist at the indices specified. 
⍝H ∘ Duplicate indices ok: items at the indices specified are returned.
⍝H See also: d.Pop N
⍝H 
  :Property Keyed DelByIndex, DelIx 
  :Access Public
    ∇ items←Get args; ii; ei; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          items← Items[] ⋄ Clear   
      :Else 
          items err← 1 ⍙DelIx ii-(⊃⎕RSI).⎕IO   ⍝ Adjust for caller's ⎕IO   
          ⋄ items ErrIf err  
      :Endif 
    ∇
  :EndProperty

  ⍝ ret← ⍙DelIx ii     (Internal helper function)
  ⍝   Delete items for indices specified (which must exist per ⎕IO=0); duplicate items ok.
  ⍝ On success:
  ⍝   ∘ If ⍺=1: returns:   (the items deleted) 0. 
  ⍝   ∘ If ⍺=0: returns:   ii 0.   
  ⍝ If an index error occurs: 
  ⍝   ∘         returns:   (error.object) 1
  ⍝ Note: if all items to delete are in a contiguous trailing block of keys (possibly repeated),
  ⍝       they are deleted via drop (↓); hashing will be maintained automatically (if set).     
  ⍝                    
    ⍙DelIx←{  
      3:: error.delIxBad 1 
          ret← ⍺ { ⍺: ↓⍉↑ KEYS VALS⌷⍨¨ ⊂⊂⍵ ⋄ ⍵ } ii←⍵ 
          blok← -+/∧\⌽bb← 1@ ii⊣ 0⍴⍨ ≢KEYS      ⍝ catches index errors   
    ⍝ If all items are in a contig. trailing block, remove via ↓⍨←, which preserves any hashing.   
      1(~∊) bb↓⍨ blok: ret 0⊣ KEYS↓⍨← VALS↓⍨← blok  
        ⍝ Remove items to delete by indexing (depends on ix errors being caught above)
          KEYS/⍨← VALS/⍨← ~bb                  ⍝ Assign separately to maintain any hashing of KEYS      
          ret 0 ⊣ HashIfSet   
    }

⍝H v1 v2…← d.Get k1 k2…             ⍝ One or more keys (present a list, returns a list)
⍝H v1 v2…← default d.Get k1 k2…    
⍝H Retrieve values for one or more keys. 
⍝H ∘ If a default is not specified, all keys must be currently defined (else Index Error)
⍝H   unless a global default has been set (e.g. when the dictionary was created). 
⍝H ∘ If a default is specified, it will be used for all keys not in the dictionary,
⍝H   independent of any global default value set.
⍝H ---------------
⍝H Note: Like d[xxx] (above), except allows a temporary default either when the dictionary
⍝H       otherwise lacks one or when the general default is not appropriate.
⍝H 
∇ vv← {tempDef} Get kk; noDef; ii; bb 
  :Access Public
  ii← KEYS⍳ kk
  :If 0∊ bb← ii≠ ≢KEYS                         ⍝ If 'tempDef' isn't set, use DEF_VAL (if set).
      :IF noDef← 900⌶⍬ ⋄ :ANDIF DEF_STATUS= def.active   
          tempDef noDef← DEF_VAL def.none      ⍝ Else, there's no tempDef to use.
      :ENDIF   
      ⋄ error.keyNotFnd ErrIf noDef 
      vv← (≢kk)⍴ ⊂tempDef                      ⍝ vv: assume default for each;
      vv[ ⍸bb ]← VALS[ bb/ii ]                 ⍝     use "old" values where defined. 
  :Else 
      vv← VALS[ ii ]
  :Endif 
∇
⍝H v1← [tempDef] d.Get1 k1          ⍝ One key (present a value, returns a value)
⍝H Like d.Get, but retrieves the value* for exactly one key*. 
⍝H    d.Get1 'myKey' <==>  ⊃d.Get ⊂'myKey'                    
⍝H Note: [*] Neither the key passed nor the return value is enclosed.
⍝H    See also the note at d.Get (above).
⍝H
∇ v1← {tempDef} Get1 k1; i1; noDef  
  :Access Public  
  i1← KEYS⍳ ⊂k1
  :IF i1≠ ≢KEYS 
      v1← i1⊃ VALS 
  :ELSE
      :IF noDef← 900⌶⍬ ⋄ :ANDIF DEF_STATUS= def.active
          tempDef noDef← DEF_VAL 0
      :ENDIF
        ⋄ error.keyNotFnd ErrIf noDef 
        v1← tempDef
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
      b← def.active= DEF_STATUS 
    ∇
    ∇ set new; d   
       11 ''ErrIf 0 1 (~∊⍨) d← new.NewValue 
       :If d 
          error.noDef ErrIf def.none= DEF_STATUS 
          DEF_STATUS← def.active 
       :Else 
          DEF_STATUS×← def.quiesced
       :EndIf 
    ∇
  :EndProperty 

⍝H {d}← d.Hash 
⍝H Returns the prior hash status:
⍝H    0: not hashed, 1: hashing active but no search yet, 2: hashed and searched. 
⍝H Set the flag HASH_SET to 1 and mark the vector KEYS as a Dyalog hashtable, 
⍝H so it can be searched faster. This creates some overhead, but searches of (large) 
⍝H key vectors can be done in O(1) time, rather than O(N).
⍝H When set, hashing is established immediately and redone when a delete takes place.
⍝H 
  ∇ {d}← Hash
    :Access Public
    d← ⎕THIS ⋄ HASH_SET← 1 ⋄ KEYS← 1500⌶KEYS ⋄ ⎕DF  '∆D=[Dict+hash]' 
  ∇
  ∇ status← HashStatus
    :Access Public
    status← 'HASH IS ',(HASH_SET⊃'OFF' 'ON'),', STATUS is', (1(1500⌶)KEYS)
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
⍝H See also: ∆D'help', ∆DL'help', and ⍬∆DX'help' for identical information.
⍝H 
  ∇ {ok}← Help
  :Access Public Shared
    ok← ##.Help 
  ∇

⍝H {d}← d.Import keylist vallist 
⍝H Add new (or existing) items via lists of keys and values.
⍝H This is equivalent to d[ keylist ]← vallist
⍝H If the dictionary is empty, Import simply sets the KEYS and VALS to the input args. 
⍝H 
  ∇ {d}← Import (kk vv)
    :Access Public
    :If 1=≢vv ⋄ vv⍴⍨← ≢kk ⋄ Else ⋄ error.mismatch ErrIf kk≠⍥≢vv ⋄ :EndIf  
    d← ⎕THIS 
    :IF 0=≢KEYS 
        KEYS,← kk ⋄ VALS,← vv 
    :Else 
        ValsByKey[kk] ← vv 
    :EndIf 
  ∇

⍝H (a)  items← d.Items                 Caller ⎕IO is honored.
⍝H Retrieve all items of the dictionary as key-value pairs. 
⍝H Note: All items are generated on the fly, so d.Items[ii] can be inefficient for
⍝H       large dictionaries. See d.ItemsIx[ii].
⍝H (Items are read-only)
⍝H 
  :Property Simple Items,Item 
  :Access Public 
    ∇ items← Get
      items← ↓⍉↑KEYS VALS
    ∇
  :EndProperty

⍝H (a)  items← d.ItemsIx[ ii ]          Caller ⎕IO is honored.
⍝H Retrieve selected items of the dictionary by index as key-value pairs. 
⍝H Note: All items are generated on the fly, so d.ItemsIx[ ii ] is a more efficient 
⍝H       way to gather select items from a large dictionary than d.Items[ ii ].
⍝H (Items are read-only)
⍝H 
 :Property Keyed ItemsByIndex,ItemsIx 
  :Access Public
    ∇ items←Get args; ii; ei; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
        :IF 0= ≢KEYS ⋄ items← ⍬
        :Else        ⋄ items← ↓⍉↑KEYS VALS 
        :EndIf    
      :Else 
        :TRAP 3 ⋄ items← ↓⍉↑KEYS VALS⌷⍨¨ ⊂⊂ii-(⊃⎕RSI).⎕IO  
        :Else   ⋄ 3 '' ErrIf 1
        :EndTrap 
      :Endif 
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
⍝H Remove and shyly return the last <n> items from the dictionary;
⍝H if no items to return, returns ⍬.
⍝H   n: a single non-negative integer. 
⍝H If n exceeds the # of items, the actual items are returned (no padding is done).
⍝H 
  ∇{items}← Pop n; p
    :Access Public 
    :Trap 0   ⍝ n must be integer singleton n≥0
      :IF n<0 ⋄ ∘∘error∘∘ ⋄ :EndIf 
      items← ↓⍉↑ KEYS VALS↑⍨¨ p← ⊂- n⌊ ≢KEYS  
      KEYS VALS↓⍨← p ⋄ HashIfSet      
      :If 0= ≢items ⋄ items← ⍬ ⋄ :EndIf 
    :Else
      error.badRightArg ErrIf 1  
    :EndTrap 
  ∇

⍝H d2← d.Sort order
⍝H Create a copy of a dictionary and sort by Keys into (order=1) ascending,
⍝H (order=¯1) descending, or (order=0) the current order.
⍝H Returns the new dictionary d2.
⍝H 
  ∇ {d2}← Sort order; ii 
    :Access Public 
    d2← ⎕THIS.Copy 
    :Select order
       :CASE 1 ⋄ ii← ⍋KEYS
       :CASE¯1 ⋄ ii← ⍒KEYS
       :CASE 0 ⋄ :RETURN   ⍝ Return copy of original dict.
       :Else   ⋄ error.badRightArg ErrIf 1  
    :EndSelect
    d2.Clear.Import KEYS VALS⌷⍨¨ ⊂⊂ii  
  ∇  
 
⍝H d.Vals[ ix1 ix2 …], 
⍝H d.Vals[ ix1 ix2…]← val1 val2…
⍝H d.Vals                     ⍝ Retrieve all vals 
⍝H d.Vals← val1 val2…         ⍝ Obscure, but valid, if (≢val1 val2…)≡≢d.Vals
⍝H Synonym: d.ValsIx, d.ValsByIx
⍝H Retrieve or set specific values in the dictionary by index (caller's ⎕IO).
⍝H You may also retrieve ALL the values using d.Vals[] or simply d[].
⍝H 
  :Property Numbered ValsByIx, ValsIx, Vals  
  :Access Public
    ∇ v←get args; ii
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          v← VALS
      :Else   
          ⋄ 3 ''ErrIf 0∊ ii< ≢KEYS 
          v← VALS[ii]
      :EndIf 
    ∇
    ∇ set args; ii
      ii← ⊃args.Indexers 
      ⋄ 3 '' ErrIf 0∊ ii< ≢KEYS 
      VALS[ii]← args.NewValue 
    ∇
    ∇ s←Shape
      s← ⍴KEYS 
    ∇
  :EndProperty

:EndClass
:EndNamespace
