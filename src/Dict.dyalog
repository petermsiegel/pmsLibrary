﻿Dict← { 
  ⍝H 
  ⍝H ┌───────────────────────────────────────────────────────────────┐
  ⍝H │   Dict: A small Ordered Dictionary utility                    │
  ⍝H │         Keys and values may have any shape and type           │
  ⍝H │         The keys are hashed for performance (see Hashing)     │
  ⍝H │         The dictionary maintains items in order of creation*  │
  ⍝H ├───────────────────────────────────────────────────────────────┤
  ⍝H │ * Or as sorted (see SortBy).                                  │
  ⍝H └───────────────────────────────────────────────────────────────┘
  ⍝H
  ⍝H [a] d← [default←⍬] Dict keyList valList   where vectors (keyList ≡⍥≢ valList)
  ⍝H                         ↓⍉↑ kv1 kv2 ...   where kvN is an "item" (a key-value pair), 
  ⍝H                                           e.g. ('name' 'Terry Dactyl') or ((○1) (⍳ 2 3))
  ⍝H [b] d← [default←⍬] Dict ⍬ ⍬               generates a dictionary with empty lists of keys and values
  ⍝H                         ⍬                 shortcut for: Dict ⍬ ⍬
  ⍝H [c] Dict 'Help'                           shares this help information (see also Methods below)
  ⍝H
  ⍝H For cases [a] and [b]:
  ⍝H   Returns a dictionary namespace <d> containing a hashed, ordered list of items and a set of service functions.
  ⍝H   ○ The dictionary may be initialized via a key list and a corresponding value list (each the same length)
  ⍝H     or remain empty, pending additions via Set, SetX, etc.;
  ⍝H   ○ Items are maintained in the order in which they were created or sorted (changing values has no effect);
  ⍝H   ○ If a default is specified, it will be returned  as the "placeholder" values for missing keys
  ⍝H     (unless a temporary default is specified: see Get, GetX).
  ⍝H     If no left arg (⍺) is specified, ⍬ is used as the "default" default value.   
  ⍝H     See SetDef, GetDef.
  ⍝H   ○ Each key in a dictionary is unique. 
  ⍝H     If a key is repeated during initialization, the rightmost value is retained for that key.
  ⍝H     At the same time, new keys are entered into the dictionary left to right as expected.
  ⍝H     Note that SetX and Set (q.v.) work the very same way, retaining the rightmost value.
  ⍝H   ○ A useful default for counters is 0, for strings: '' or ⍬, for lists: ⍬.
  ⍝H
  ⍝H ---------------------------------------------------------------------------------
  ⍝H Dictionary "Methods"        k: a key               kk: 1 (enclosed) or more keys          
  ⍝H                             v: a value             vv: 1 (enclosed) or more values
  ⍝H                             a:  arbitrary data     aa: any (enclosed) list of arbitrary data
  ⍝H                             b:  Boolean value      bb: Boolean values
  ⍝H                             ss: a sortable list of objects: (≢ss) ≡ (≢d.Keys)
  ⍝H                             i:  an index           ii: 1 or more indices (key locations)
  ⍝H                             *   shy return value
  ⍝H Basic:                     
  ⍝H    Creating Dictionaries:   newD← v [d.]Dict kk vv 
  ⍝H       [Cloning Dict d]      newD← d.Copy
  ⍝H    Setting and Getting: 
  ⍝H       [Single Item]        v*←  d.Set  k  v        v←  d.Get    k      
  ⍝H       [Items]              vv*← d.SetX kk vv       vv← d.GetX   kk  
  ⍝H       [Indices]                                    i←  d.Find   k 
  ⍝H                                                    ii← d.FindX  kk
  ⍝H       [Default Values]     old*← d.SetDef a        a←  d.GetDef 
  ⍝H    Validating Items
  ⍝H                             b←  d.HasKey k                        Faster: (⊂k)∊ d.Keys 
  ⍝H                             bb← d.HasKeys kk                      Faster: kk∊ d.Keys           
  ⍝H    Sorting Items:        newD*← [newD←d] d.SortBy ss              If newD not specified as ⍺, newD←d
  ⍝H    Deleting Items:          
  ⍝H       [Single Item by Key] b*←  [b]  d.Del   k
  ⍝H       [Items by Key]       bb*← [bb] d.DelX  kk
  ⍝H       [Items by Index]     bb*← [b]  d.DelI  ii                   ⎕IO=0
  ⍝H       [All]               old*← d.Clear                           old: Returns former number of keys
  ⍝H    Displaying All           
  ⍝H       [Keys]                kk← d.Keys              
  ⍝H       [Vals]                vv← d.Vals      
  ⍝H       [Items]               kv← d.Items                           kv:  Returns key-value pairs
  ⍝H       [Number of Items]    nni← d.Tally                           nni: Non-neg integer
  ⍝H Advanced:
  ⍝H    Modifying Values:         
  ⍝H       [Apply <op a>]        new← k  (op d.Do)  a                  new: Result of applying <op a> to the value at <k>
  ⍝H                             new← kk (op d.DoX) aa                 "
  ⍝H       [Catenate <a>]        new← k  d.Cat  a                      "
  ⍝H                             new← kk d.CatX aa                     "
  ⍝H   Hashing [See "Hashing" below]
  ⍝H      [Automatic; no functions/methods]
  ⍝H For Help:                   Dict 'Help' 
  ⍝H                             d.Help 
  ⍝H 
    ⎕IO ⎕ML←0 1 
    d←(calr←⊃⎕RSI).⎕NS''  ⋄ _←d.⎕DF (⍕calr),'.[Dict]'
  
  ⍝ _Err: (Internal) Error Signaller
    d._Err← ⎕SIGNAL { 
      ⍺← ⎕DMX.(11 EN⊃⍨(×EN)∧0=≢⍵)  ⋄ ⊂⎕DMX.(('EM' ('Dict: ',EM ⍵⊃⍨0≠≢⍵))('EN' ⍺)('Message' Message))
    }
  ⍝  Allow duplicate keys: 
  ⍝  Ensure each key is registered in order L to R exactly once, but keeping the rightmost associated value
  ⍝  d._NewKVb← { ⍺=⍥≢uk←∪⍺: ⍺⍵ ⋄ uk (⍺{⊃⌽⍵}⌸⍵) }                   ⍝ +328% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕
  ⍝  d._NewKVa← { ⍺=⍥≢uk←∪⍺: ⍺⍵ ⋄ uk (⍵@(uk⍳⍺)⊢uk    )  }           ⍝  +60% ⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕⎕ 
  ⍝  d._NewKV←  { ⍺=⍥≢uk←∪⍺: ⍺⍵ ⋄ uv←0⍴⍨≢uk ⋄ uv[uk⍳⍺]←⍵ ⋄ uk uv }  ⍝    0% ⎕⎕⎕⎕⎕⎕⎕⎕⎕   
      
  ⍝ _Hash: (Internal) hashes keysG and shyly returns right arg (⍵).
  ⍝        Used with: 
  ⍝             dict creation, item deletion, dictionary sorting, appending to null vector.
  ⍝        SetX handles hashes directly.
    d._Hash← { keysG∘←1500⌶keysG ⋄ 1: _←⍵ }

  ⍝ Keep only to validate hash logic...
    d._Validate← { 
      0=≢keysG: _←⍵ ⋄ ×1(1500⌶)keysG: _←⍵ ⋄ 'Dict: Logic Error. Hash not established' ⎕SIGNAL 999  
    }

  ⍝H ======================================
  ⍝H =======        BASIC        ==========
  ⍝H ======================================

  ⍝H d.Clear
  ⍝H   {nK}← d.Clear'
  ⍝H Delete all the items in the dictionary, 
  ⍝H    shyly returning the number of items in the dictionary before clearing.
  ⍝H (Does not affect the default value)
  ⍝H
     _←d.⎕FX '{nK}←Clear'  'nK← ≢keysG ⋄ keysG← valsG← ⍬'   

  ⍝H d.Copy
  ⍝H   d2← d.Copy
  ⍝H Returns a complete, independent copy (clone) of dictionary d.
  ⍝H   (Keys, values, and the default value are copied).
  ⍝H Calling Dict to clone is faster than (⎕NS ⎕THIS) for smallish ≢keysG...
     _←d.⎕FX 'd2←Copy'  ':IF 300<≢keysG ⋄ d2← ⎕NS ⎕THIS ⋄ :ELSE ⋄ d2←defaultG Dict keysG valsG ⋄ :ENDIF'

  ⍝H d.Del  (Delete-by-Key)
  ⍝H   {[1|0]}← [quiet←0] d.Del key
  ⍝H   key:   an object of any shape
  ⍝H   quiet: scalar 1 or 0
  ⍝H If the key <key> exists, deletes the entry (key value pair).
  ⍝H If not, does nothing.
  ⍝H Shyly returns 
  ⍝H - If the key exists: 
  ⍝H     1 (deleted).
  ⍝H - If it does NOT exist:
  ⍝H    If quiet=1: 
  ⍝H       0 (not found);
  ⍝H    Otherwise (quiet=0): 
  ⍝H       signals an error (⎕EN=3 Index Error).
  ⍝H
    d.Del← d._Hash { 
          ⍺← 0 ⋄ p← keysG⍳ ⊂k← ⍵    
      p< ≢keysG: _← 1⊣ (keysG valsG) /⍨← ⊂ 0@ p⊢ 1⍴⍨ ≢keysG
      ⍺: _← 0  ⋄ 3 _Err 'Key not found'
    }

  ⍝H d.DelX  (Delete-by-Key Extended) 
  ⍝H   {[1|0]...}← [quiet←0] d.DelX keys
  ⍝H   keys:  vector of keys, each of any shape
  ⍝H   quiet: scalar 1 or 0
  ⍝H Functional Equivalent to: 
  ⍝H   [[1|0]...]← [quiet←0] d.Del¨ keys
  ⍝H If quiet=0 and at least one key is not found, 
  ⍝H    signals an error (taking no other action).
  ⍝H Otherwise, shyly returns a boolean vector containing:
  ⍝H     a 1 for each key found and deleted, and 
  ⍝H     a 0 for each key not found and ignored.
  ⍝H See d.Del for details.
  ⍝H  
    d.DelX← d._Hash { 
          ⍺← 0 ⋄ pp← keysG⍳ kk← ⍵ ⋄ om← pp< ≢keysG 
        (0∊om)∧~⍺: 3 _Err 'Key(s) not found'
          (keysG valsG) /⍨← ⊂0@ (om/ pp)⊣ 1⍴⍨ ≢keysG
        1: _← om 
    }

  ⍝H d.DelI   (Delete-by-Indices)
  ⍝H   {[1|0]}←  [quiet←0] d.DelI indices  (⎕IO=0)
  ⍝H      indices: indices for items, where index 0 is the first.
  ⍝H      quiet:   scalar 1 or 0.
  ⍝H Deletes items (key-value pairs) by index. 
  ⍝H If quiet=0 and at least one index is out of range:
  ⍝H    signals an error (taking no other action).
  ⍝H Otherwise, shyly returns a boolean vector containing:
  ⍝H     a 1 for each index in range, whose associated item is deleted, and 
  ⍝H     a 0 for each index not in range and ignored. 
  ⍝H 
    d.DelI←  d._Hash {  
        0:: _Err ⍬
          ⍺←0 ⋄ om← 0= (0, ≢keysG)⍸ pp← ⍵
        (0∊om)∧~⍺:  3 _Err 'Index Error'
          (keysG valsG) /⍨← ⊂0@ (om/pp)⊣ 1⍴⍨ ≢keysG
        1: _← om
    }

  ⍝H d.Find, FindX (Find Keys) / Extended)
  ⍝H   index←    [force←0] d.Find  key
  ⍝H   indices←  [force←0] d.FindX keys
  ⍝H Returns the indices for the keys found (⎕IO=0). 
  ⍝H   For those not found:
  ⍝H     If force=1, returns (≢d.Keys) for each missing key; present keys are in range [0 .. ≢d.Keys-1]
  ⍝H     If force=0 (default), signals an error (⎕EN=3).
  ⍝H Note: This returns indices by keys!
  ⍝H   To return keys or values for specific indices, simply use d.Keys / d.Vals  
  ⍝H     d.Keys[ i1 i2 ... ]
  ⍝H     d.Vals[ i1 i2 ... ]
  ⍝H
     d.FindX←{ ⍺←0 
         pp← keysG⍳ ⍵ 
      ⍺: pp 
      1∊ pp= ≢keysG: 3 _Err 'Key(s) not found'
         pp                                                
    }
    d.Find← d.FindX⊂
 
  ⍝H d.Get (Get-Value)
  ⍝H   val← [def← GetDef] d.Get key
  ⍝H   Retrieves the specified key or <def> if not found.
  ⍝H Returns: 
  ⍝H - the value <val> for <key>, if <key> defined.
  ⍝H - Otherwise, the "default" is returned.
  ⍝H
    d.Get←{ 
        ⍺← defaultG ⋄ p← keysG⍳ ⊂k← _Validate ⍵ 
      p< ≢keysG: p⊃ valsG ⋄ ⍺
    }

  ⍝H d.GetX (Get-Value-by-Key Extended)
  ⍝H   val← [defs← GetDef] d.GetX keys
  ⍝H      defs: vector of defaults;  defs must be conformable to keys.
  ⍝H      keys: vector of keys
  ⍝H   Logically equivalent to: [defs] d.Get¨ keys
  ⍝H Retrieves the specified keys or <def>, for those not found.
  ⍝H Returns: 
  ⍝H     - a vector containing the value <val> for each key in <keys>, if <key> defined.
  ⍝H     - Otherwise, returns a default (if not specified, defs← GetDef)
  ⍝H       - defs must be conformable with keys.
  ⍝H If not explicitly specified by the user, the default is the "default" default.
  ⍝H
    d.GetX←{
        pp← keysG⍳ kk←  _Validate ⍵  ⋄ om← pp< ≢keysG
      ~0∊ om: valsG[ pp ]                            ⍝ All keys found: fast return
        ⍺← ⊂defaultG                                  
      (1≠ ≢⍺) ∧ kk ≠⍥≢ ⍺: 5 _Err 'Length Error: Mismatched left and right argument lengths'
        rr← ⍺⍴⍨ ≢kk                                  ⍝ Prepopulate result with default
      ~1∊ om: rr                                     ⍝ No keys found: fast return
       valsG[ om/ pp ]@ (⍸om)⊣ rr               ⍝ Enter values for existing keys
    }

  ⍝H d.GetDef   
  ⍝H   curDef← d.GetDef
  ⍝H   Gets the current default value.
  ⍝H Returns the default value (used for an item's value when a key is not found)
  ⍝H 
    _← d.⎕FX 'curDef← GetDef' 'curDef← defaultG'

  ⍝H d.HasKey
  ⍝H   [1|0]← d.HasKey key
  ⍝H     key: an object of any shape
  ⍝H   Returns 1 if <key> is defined, else 0.
  ⍝H -----
  ⍝H See Note at HasKeys.
  ⍝H
    d.HasKey← { keysG∊⍨ ⊂⍵ }

  ⍝H d.HasKeys
  ⍝H   [ [1|0]... ]← d.HasKeys keys
  ⍝H Returns 1 for each key k in <keys> which is defined;
  ⍝H Returns 0 for each otherwise.
  ⍝H -----
  ⍝H Note: It is (~2-3 times) faster to use ∊ in place of HasKey/s
  ⍝H    :IF (⊂'cats') ∊ d.Keys ⋄ ... 
  ⍝H    :IF 1∊ 'cats' 'dogs' 'mice' ∊ d.Keys ⋄ ... 
  ⍝H
    d.HasKeys← { ⍵∊ keysG }

  ⍝H d.Help
  ⍝H   Provides this helpful information.
  ⍝H   Alternatively, execute:   Dict 'Help'
  ⍝H Returns: nothing
    _←d.⎕FX 'Help' '_Help ⍬'
    d._Help←{0=≢_h←'^\h*⍝H(.*)' ⎕S '\1'⊣⎕NR 'Dict': 'No help available' ⋄ ⎕ED '_h'}

  ⍝H d.Items
  ⍝H   i← d.Items
  ⍝H Returns all the keys and their values as key-value pairs.
  ⍝H
    _←d.⎕FX 'i←Items' 'i←↓⍉↑keysG valsG'

  ⍝H d.Keys
  ⍝H   kk← d.Keys (R/O)
  ⍝H Returns the list of keys
  ⍝H
  _← d.⎕FX 'kk← Keys' 'kk←keysG'

  ⍝H d.Set
  ⍝H   {val}← d.Set key val    OR:   {val}← key d.Set val
  ⍝H   Sets value for key key to value val. 
  ⍝H If it exists, it is overwritten.
  ⍝H Shyly returns the value <val> just set.
  ⍝H ------------
  ⍝H ∘ Handy: Set entries specified as items (kN vN):
  ⍝H   d.Set¨ (k1 v1)(k2 v2)...
  ⍝H ∘ Handy: Set entries specified as separate lists (k1 k2 k3) and (v1 v2 v3)
  ⍝H   k1 k2 k3 d.Set¨ v1 v2 v3
  ⍝H
    d.Set← d._Validate {   
          ⍺←⊢ ⋄ k v←⍺ ⍵ 
      0=≢keysG: _← _Hash v ⊣ valsG,← ,⊂v ⊣ keysG,← ,⊂k
      (≢keysG)> p← keysG⍳ ⊂k: _← (p⊃ valsG)← v  
          keysG,← ⊂k ⋄ valsG,← ⊂v 
      1: _←  v  
    }

  ⍝H d.SetX
  ⍝H   {vals}← d.SetX keys vals    OR:   {vals}← keys d.Set vals
  ⍝H Sets values for keys <keys> to <vals>.
  ⍝H   <vals> may be a single scalar, in which case all the keys <keys> will be set to that value.
  ⍝H ∘ If a key is repeated, the LAST value set is retained, as expected.
  ⍝H Shyly returns the values <vals> passed.
  ⍝H -----------
  ⍝H ∘ Handy: To set entries specified as items (key value pairs):
  ⍝H    d.SetX ↓⍉↑(k1 v1)(k2 v2)....
  ⍝H  

    d.SetX←  d._Validate {  
          ⍺←⊢ ⋄ kk vv←,¨⍺ ⍵ 
      kk ≢⍥≢ vv: 3 _Err 'LENGTH ERROR: Keys and Values Differ in Length'
      0= ≢kk: _← ⍬
      0:: _Err ⍬     
      ⍝  Allow duplicate keys: 
      ⍝  Ensure each key is registered in order L to R exactly once, but keeping the rightmost associated value                                               
          _SetNew← { ⍝ ⍺= keys(kk), ⍵= vals(vv), returns rightmost new vals                                                
              nk nv← ⍺ { ⍺=⍥≢uk←∪⍺: ⍺⍵ ⋄ uv←0⍴⍨≢uk ⋄ uv[uk⍳⍺]←⍵ ⋄ uk uv } ⍵ 
              keysG,← nk  ⋄ valsG,← nv  
              ×1(1500⌶)keysG: nv ⋄ keysG∘← 1500⌶keysG ⋄ nv 
          }                                                          ⍝  Empty Dict? | Update Keys | Add New Keys.
      0=≢keysG: _← kk _SetNew vv                                     ⍝ A.    +             -            +
          pp← keysG⍳ kk ⋄ om← pp< ≢keysG         ⍝ om: old key mask  ⍝      ...       Scan "Old" Keys  ...
      ~0∊om: valsG[ pp ]← vv                     ⍝ ← All old keys    ⍝ B.    -             +            -
      ~1∊om: _← kk _SetNew vv                    ⍝ ← All new keys    ⍝ C.    -             -            +
          ov← valsG[ om/ pp ]← om/ vv            ⍝ ov: old vals      ⍝ D.    -             +            +
          nk nv← (⊂~om)/¨ kk vv                  ⍝ nv: new vals      ⍝ ↓
      1:  _←  ov, nk _SetNew nv                                      ⍝ ↓                                          
    }

  ⍝H d.SetDef
  ⍝H   {oldDef}← d.SetDef newDef
  ⍝H Sets the default value to use when keys are absent from the dictionary.
  ⍝H Shyly returns the old default.
  ⍝H Note: the default is typically set when the dictionary is created:
  ⍝H     myfault← ...
  ⍝H     d← myDefault Dict ⍬ 
  ⍝H  
    d.SetDef←{ 1: _← (defaultG⊢← ⍵)⊢ defaultG }

  ⍝H d.SortBy
  ⍝H   {theDict} ← [theDict←d] d.SortBy sortFields sortField
  ⍝H      sortField: a list of vectors, with the same length as d.Keys 
  ⍝H        If ⍬,    d.Keys is used.
  ⍝H      theDict:   a reference to a dictionary (created via Dict or d.Copy).
  ⍝H                 If omitted or a reference to <d> itself, sorts in place, rather than making a copy.
  ⍝H If sortField is empty, sorts using d.keys. 
  ⍝H   Otherwise, if (≢sortField)≢(d.keys), an error is signaled.
  ⍝H Shyly returns theDict (by default: d).
  ⍝H Examples: 
  ⍝H ∘ SORT IN PLACE
  ⍝H   d.SortBy ⍬                  - Sorts d by keys  
  ⍝H   d.(SortBy Keys)             - Sorts d by keys  
  ⍝H   d.(SortBy ⎕C Keys)          - Sorts d by keys, ignoring case  
  ⍝H   d.(SortBy ⌽Vals)            - Sorts d by values in descending order  
  ⍝H ∘ SORT INTO NEW DICTIONARY (ORIGINAL UNCHANGED)
  ⍝H   newD← (Dict ⍬) d.SortBy ⍬   - Sorts d by keys. newD has ⍬ as default.   
  ⍝H   newD← d.(Copy SortBy Vals)  - Sorts d by values. newD takes on d's default value.
  ⍝H 
    d.SortBy← d._Validate  { 
        ⍺←⎕THIS ⋄ flds← ⍵ keysG⊃⍨ 0=≢⍵
        keysG ≢⍥≢ flds: _Err 'SortBy: Sort field has incorrect length.'
        ⍺.(keysG valsG)← keysG valsG    ⍝ this does nothing if ⍺ and ⎕THIS are the same...
        ⍺.(keysG valsG)⌷⍨← ⊂⊂⍋flds
      1: _← ⍺._Hash ⍺
    }

  ⍝H d.Tally
  ⍝H   n← d.Tally
  ⍝H   Returns the number of items in the dictionary
  _← d.⎕FX 'n← Tally' 'n← ≢keysG'

  ⍝H d.Vals
  ⍝H   vv← d.Vals (R/O)
  ⍝H Returns the list of values
  ⍝H
  _← d.⎕FX 'vv← Vals' 'vv←valsG'

  ⍝H ======================================
  ⍝H =======    ADVANCED         ==========
  ⍝H ======================================
  ⍝H
  ⍝H d.Cat  
  ⍝H   {newVal}← key d.Cat item
  ⍝H   Treats the value for <key> as a list (vector of vectors) and 
  ⍝H   appends <item> itself to the end of that list, conceptually:
  ⍝H       value← value,⊂item
  ⍝H Shyly returns the new value.
  ⍝H ----------------------------------------------
  ⍝H ∘ Example: Create a dictionary of word lists:
  ⍝H     french← Dict ⍬
  ⍝H   Let's create list 'one'  in our dictionary <french> and append to it:
  ⍝H                                  | Before exec'n   |  After exec'n
  ⍝H     'one' french.Cat  'un'   ==> | ⍬               |   un             
  ⍝H     'one' french.Cat  'une'  ==> | ⊂'un            |   un  une       
  ⍝H     'one' french.Cat  '1'    ==> | 'un' 'une'      |   un  une  1    
  ⍝H ∘ Example: Add a list of items to wordlist 'french'            
  ⍝H   french← Dict ⍬                                  french2← Dict ⍬                             
  ⍝H ⍝ Appends three items to list, one at a time.   ⍝ This appends one item containing 3 elements!
  ⍝H   ('two'french.Cat)¨ '2' 'deux' 'dos'             'two' french.Cat  '2' 'deux' 'dos'     
  ⍝H    french.Get 'two'                               french2.Get 'two'
  ⍝H    ┌─┬────┬───┐                                   ┌────────────┐
  ⍝H    │2│deux│dos│                                   │┌─┬────┬───┐│
  ⍝H    └─┴────┴───┘                                   ││2│deux│dos││
  ⍝H                                                   │└─┴────┴───┘│
  ⍝H                                                   └────────────┘
  ⍝H
    d.Cat←  { 0:: _Err ⍬ ⋄ 1: _← ⍺ Set (Get ⍺),⊂⍵     }  

  ⍝H d.CatX
  ⍝H   {newVals}← keys d.CatX items
  ⍝H   Equiv. to:  
  ⍝H    {newVals}← keys d.Cat¨ items
  ⍝H See d.Cat for more.
  ⍝H
    d.CatX← d.Cat¨

  ⍝H d.Do
  ⍝H   {newVal}← key (op d.Do) val       ⍝  key=⍺, op=⍺⍺, val=⍵
  ⍝H   Performs:    key Set (Get key) op ⍵   
  ⍝H Shyly returns: the new value
  ⍝H ∘ Example: Dictionary <counter>
  ⍝H   Increment a counter (initially 0) named 'jack' to 1
  ⍝H      counter← 0 Dict ⍬                  ⍝ Set defaults to 0
  ⍝H     'jack' +counter.Do 1                ⍝ Sets entry jack to 0+1  => 1
  ⍝H     'jack' +counter.Do 2                ⍝ Sets entry jack to 1+2  => 3
  ⍝H     'jack' *counter.Do 2                ⍝ Sets entry jack to 3*2  => 9...
  ⍝H 
    d.Do←  { 0:: _Err ⍬ ⋄ 1: _←⍺ Set (Get  ⍺) ⍺⍺  ⍵ }
    
  ⍝H d.DoX
  ⍝H   {newVals}← keys (op d.DoX) vals       ⍝  key=⍺, op=⍺⍺, val=⍵
  ⍝H   Performs:    newVals← keys SetX (GetX keys) op¨ ⍵   
  ⍝H Shyly returns: newVals
  ⍝H See d.Do for details, examples
  ⍝H
   d.DoX← {0:: _Err ⍬ ⋄ 1: _← ⍺ (⍺⍺ Do)¨ ⍵ }

  ⍝H Hashing  
  ⍝H Hashing ensures that searching of dictionary keys is as fast as possible.
  ⍝H There are no hashing methods/functions; hashing is done automatically.
  ⍝H Performance improvements range from 3x on up for char. array searches (⍳ in Get/X).
  ⍝H Hashing is done automatically:
  ⍝H - When the array is created (d← Dict...)
  ⍝H - After deleting items (d.Del/X, d.DelI/X)
  ⍝H - After sorting (d.SortBy)
  ⍝H Advanced: To check status of hashing for dictionary d:
  ⍝H        r← 1(1500⌶)d.Keys 
  ⍝H   r=2: active, r=1: established; r=0: not in use.
  ⍝H

  ⍝ Executive 
      ⍺← ⍬
      d.Dict← ∇
  'help'≡⎕C ⍵: d.Help  
      d.( defaultG keysG valsG )← ⍺ ⍬ ⍬
  0=≢⍵: d 
  2≠≢⍵: 3 d._Err 'LENGTH ERROR: Keys and Values Differ in Length'
⍝ Load items (key-value pairs)
        d ⊣ d.SetX ,¨⍵                                    
 }