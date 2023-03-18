∆DICT← { 
  ⍝H 
  ⍝H ┌───────────────────────────────────────────────────────────────┐
  ⍝H │   ∆DICT: An Ordered Dictionary utility                         │
  ⍝H │         Keys and values may have any shape and type           │
  ⍝H │         The keys are hashed for performance (see Hashing)     │
  ⍝H │         The dictionary maintains items in order of creation*  │
  ⍝H ├───────────────────────────────────────────────────────────────┤
  ⍝H │ * Or as sorted (see SortBy).                                  │
  ⍝H └───────────────────────────────────────────────────────────────┘
  ⍝H
  ⍝H [a] d← [default←⍬] ∆DICT kList vList        where vectors of keys and values: kList ≡⍥≢ vList
  ⍝H                          ⊂(k1 v1)(k2 v2)... where kvN is an "item" (a key-value pair), 
  ⍝H                                             e.g. ('name' 'Terry Dactyl') or ((○1) (⍳ 2 3))
  ⍝H [b] d← [default←⍬] ∆DICT ⍬                  generates an empty dictionary (with default value ⍬)
  ⍝H [c] ∆DICT 'Help'                            shares this help information (see also Methods below)
  ⍝H
  ⍝H For cases [a] and [b]:
  ⍝H   Returns a dictionary namespace <d> containing a hashed, ordered list of items and a set of service functions.
  ⍝H   ○ The dictionary may be initialized via a key list and a corresponding value list (each the same length)
  ⍝H     or remain empty, pending additions via Set1, Set, etc.;
  ⍝H   ○ Items are maintained in the order in which they were created or sorted (changing values has no effect);
  ⍝H   ○ If a default is specified, it will be returned  as the "placeholder" values for missing keys
  ⍝H     (unless a temporary default is specified: see Get1, Get).
  ⍝H     If no left arg (⍺) is specified, ⍬ is used as the "default" default value.   
  ⍝H     See SetDef, GetDef.
  ⍝H   ○ Each key in a dictionary is unique. 
  ⍝H     If a key is repeated during initialization, the rightmost value is retained for that key.
  ⍝H     At the same time, new keys are entered into the dictionary left to right as expected.
  ⍝H     Note that Set and Set1 (q.v.) work the very same way, retaining the rightmost value.
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
  ⍝H    Creating Dictionaries: newD← [v] [d.]∆DICT kk vv 
  ⍝H                                 [v] [d.]∆DICT (⊂k1 v1)(k2 v2)...
  ⍝H                                 [v] [d.]∆DICT ⍬
  ⍝H       [Cloning Dict d]      newD← d.Copy
  ⍝H    Setting and Getting: 
  ⍝H       [Single Item]        v*←  d.Set1 k  v        v←  d.Get1   k      
  ⍝H       [Items]              vv*← d.Set  kk vv       vv← d.Get    kk  
  ⍝H       [Indices]                                    i←  d.Find1  k 
  ⍝H                                                    ii← d.Find   kk
  ⍝H       [Default Values]    old*← d.SetDef a         a←  d.GetDef 
  ⍝H    Validating Items
  ⍝H                             b←  d.HasKey k                        Faster: (⊂k)∊ d.Keys 
  ⍝H                             bb← d.HasKeys kk                      Faster: kk∊ d.Keys           
  ⍝H    Sorting Items:        newD*← [newD←d] d.SortBy ss              If newD not specified as ⍺, newD←d
  ⍝H    Deleting Items:          
  ⍝H       [Single Item by Key] b*←  [b]  d.Del1  k
  ⍝H       [Items by Key]       bb*← [bb] d.Del   kk
  ⍝H       [Items by Index]     bb*← [b]  d.DelI  ii                   ⎕IO=0
  ⍝H    [Last N items in Dict]   kv← [up_to←0] PopItems N              Efficiently pops (returns and removes
  ⍝H                                                                   (⍺=0: exactly, ⍺=1: up to) N items...
  ⍝H       [Last item in Dict]   kv← PopItem                           Efficiently returns and removes last item in dict.
  ⍝H       [All]               old*← d.Clear                           old: Returns former number of keys
  ⍝H    Displaying All           
  ⍝H       [Keys]                kk← d.Keys              
  ⍝H       [Vals]                vv← d.Vals      
  ⍝H       [Items]               kv← d.Items                           kv:  Returns key-value pairs
  ⍝H       [Number of Items]    nni← d.Tally                           nni: Non-neg integer
  ⍝H Advanced:
  ⍝H    Modifying Values:         
  ⍝H       [Apply <op a>]        new← k  (op d.Do1)  a                 new: Result of applying <op a> to the value at <k>
  ⍝H                             new← kk (op d.Do  ) aa                "
  ⍝H       [Catenate <a>]        new← k  d.Cat1 a                      "
  ⍝H                             new← kk d.Cat  aa                     "
  ⍝H   Hashing [See "Hashing" below]
  ⍝H      [Automatic; no functions/methods]
  ⍝H For Help:                   ∆DICT 'Help' 
  ⍝H                             d.Help 
  ⍝H 
    ⎕IO ⎕ML←0 1 
    d←(calr←⊃⎕RSI).⎕NS''  ⋄ _←d.⎕DF (⍕calr),'.[∆DICT]'
  
  ⍝  ======================================
  ⍝  =======   Internal Utils    ==========
  ⍝  ======================================

  ⍝ _Err: (Internal) Error Signaller
    d._Err← ⎕SIGNAL { 
      ⍺← ⎕DMX.(11 EN⊃⍨(×EN)∧0=≢⍵)  ⋄ ⊂⎕DMX.(('EM' ('∆DICT: ',EM ⍵⊃⍨0≠≢⍵))('EN' ⍺)('Message' Message))
    }
      
  ⍝ ⍙: "Validate"
  ⍝ Useful solely to validate hash logic... Remove any calls to ⍙ once testing is complete.
  ⍝ Checks that hashing is on for keysG or signals a logic error.
  ⍝ Returns shy ⍵
    d.⍙← { 
      0=≢keysG: _←⍵ ⋄ ×1(1500⌶)keysG: _←⍵ ⋄ '∆DICT: Logic Error. Hash not established for keysG' ⎕SIGNAL 999  
    }

  ⍝ _SetNew (Internal). 
  ⍝    nv← kk _SetNew vv
  ⍝    kk: keys, vv: values
  ⍝    Adds unique keys to keysG in order of appearance (leftmost first).
  ⍝    Adds to valsG the the rightmost (or only) value for each key, ordered by key.
  ⍝    Returns nv= rightmost value for each key presented 
  ⍝  When there are duplicate new keys, this ensures 
  ⍝  ○ the first (leftmost) appearance of each key in order is associated 
  ⍝    with the last (rightmost) value assigned, consistent with the semantics for existing keys with new values.
  ⍝  ○ that Set produces the same behavior as Set1¨ 
  ⍝  See Set.
    d._SetNew← {                                              
          nk nv← ⍺ { ⍺=⍥≢uk←∪⍺: ⍺⍵ ⋄ uv←0⍴⍨≢uk ⋄ uv[uk⍳⍺]←⍵ ⋄ uk uv } ⍵    ⍝ Faster than using ⌸ (key) function!
          keysG,← nk  ⋄ valsG,← nv  
          ×1(1500⌶)keysG: nv ⋄ keysG∘← 1500⌶keysG ⋄ nv 
    }  

  ⍝H ======================================
  ⍝H =======    BASIC METHODS    ==========
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
  ⍝H 
  ⍝  Calling ∆DICT to clone is faster than (⎕NS ⎕THIS) for smallish ≢keysG...
     _←d.⎕FX 'd2←Copy'  ':IF 300≤≢keysG ⋄ d2← ⎕NS ⎕THIS ⋄ :ELSE ⋄ d2←defaultG ∆DICT keysG valsG ⋄ :ENDIF'

  ⍝H d.Del1  (Delete one item by Key)
  ⍝H   {[1|0]}← [quiet←0] d.Del key
  ⍝H   key:   an object of any shape
  ⍝H   quiet: scalar 1 or 0
  ⍝H If the key <key> exists, deletes the entry (key value pair).
  ⍝H If quiet=0, and the key does NOT exist, 
  ⍝H   signals an error (⎕EN=3, Index Error).
  ⍝H Returns (shyly)
  ⍝H    1, if the key exists;           
  ⍝H    0, if the key does not exist (quiet=1).
  ⍝H 
    d.Del1←  d.⍙ { 
          ⍺← 0 ⋄ p← keysG⍳ ⊂k← ⍵ ⋄ nf← p=≢keysG  
      nf∧⍺: _←0 ⋄ nf: 3 _Err 'Key not found'
      (keysG valsG) /⍨← ⊂ 0@ p⊢ 1⍴⍨ ≢keysG 
      keysG∘←1500⌶keysG
      1: _← 1 
    }

  ⍝H d.Del   (Delete Items by Key)
  ⍝H   {[1|0]...}← [quiet←0] d.Del keys
  ⍝H   keys:  vector of keys, each of any shape
  ⍝H   quiet: scalar 1 or 0
  ⍝H Functional Equivalent to: 
  ⍝H   [[1|0]...]← [quiet←0] d.Del1¨ keys
  ⍝H If quiet=0 and at least one key is not found, 
  ⍝H    signals an error (taking no other action).
  ⍝H Otherwise, 
  ⍝H   shyly returns a boolean vector containing:
  ⍝H      a 1 for each key found and deleted, and 
  ⍝H      a 0 for each key not found and ignored (quiet=1).
  ⍝H  
    d.Del←  d.⍙ { 
          ⍺← 0 ⋄ pp← keysG⍳ kk← ⍵ ⋄ fm← pp< ≢keysG 
        (0∊fm)∧~⍺: 3 _Err 'Key(s) not found'
          (keysG valsG) /⍨← ⊂0@ (fm/ pp)⊣ 1⍴⍨ ≢keysG 
          keysG∘←1500⌶keysG 
        1: _← fm 
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
    d.DelI←  d.⍙ {  
        0:: _Err ⍬
            ⍺← 0 ⋄ pp← ⍵ ⋄ fm← 0= ⍵⍸ ⍨0, ≢keysG
        (0∊fm)∧~⍺:  3 _Err 'Index Error'
            (keysG valsG) /⍨← ⊂0@ (fm/pp)⊣ 1⍴⍨ ≢keysG
            keysG∘←1500⌶keysG 
        1: _← fm
    }

  ⍝H d.Find1  (Find 1 Key), 
  ⍝H d.Find   (Find Keys)
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
     d.Find← { ⍺←0 
         pp← keysG⍳ ⍵ 
      ⍺: pp 
      1∊ pp= ≢keysG: 3 _Err 'Key(s) not found'
         pp                                                
    }
    d.Find1← d.Find⊂
 
  ⍝H d.Get1 (Get by Single Key)
  ⍝H val← [def← GetDef] d.Get1 key
  ⍝H   Retrieves the specified key or <def> if not found.
  ⍝H Returns: 
  ⍝H - the value <val> for <key>, if <key> defined.
  ⍝H - Otherwise, the "default" is returned.
  ⍝H
    d.Get1← { 
        ⍺← defaultG ⋄ p← keysG⍳ ⊂k←  ⍵ 
      p< ≢keysG: p⊃ valsG ⋄ ⍺
    }

  ⍝H d.Get (Get-Values by Keys)
  ⍝H  val← [defs← GetDef] d.Get keys
  ⍝H      defs: vector of defaults;  defs must be conformable to keys.
  ⍝H      keys: vector of keys
  ⍝H   Logically equivalent to: [defs] d.Get1¨ keys
  ⍝H Retrieves the specified keys or <def>, for those not found.
  ⍝H Returns: 
  ⍝H     - a vector containing the value <val> for each key in <keys>, if <key> defined.
  ⍝H     - Otherwise, returns a default (if not specified, defs← GetDef)
  ⍝H       - defs must be conformable with keys.
  ⍝H If not explicitly specified by the user, the default is the "default" default [*].
  ⍝H -----------------------
  ⍝H * Default default: From left-arg (⍺) of d← ... ∆DICT ... or an explicit d.SetDef....
  ⍝H
    d.Get← {
        pp← keysG⍳ kk←   ⍵  ⋄ fm← pp< ≢keysG
      ~0∊ fm: valsG[ pp ]                            ⍝ All keys found: fast return
        ⍺← ⊂defaultG                                  
      (1≠ ≢⍺) ∧ kk ≠⍥≢ ⍺: 5 _Err 'Length Error: Mismatched left and right argument lengths'
        rr← ⍺⍴⍨ ≢kk                                  ⍝ Prepopulate result with default
      ~1∊ fm: rr                                     ⍝ No keys found: fast return
       valsG[ fm/ pp ]@ (⍸fm)⊣ rr               ⍝ Enter values for existing keys
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
    d.HasKey← { ⍵∊ keysG }⊂

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
  ⍝H   Alternatively, execute:   ∆DICT 'Help'
  ⍝H Returns: nothing
  ⍝H
    _←d.⎕FX 'Help' '_Help ⍬'
    d._Help←{0=≢_h←'^\h*⍝H(.*)' ⎕S '\1'⊣⎕NR '∆DICT': 'No help available' ⋄ ⎕ED '_h'}

  ⍝H d.Items
  ⍝H   ii← d.Items
  ⍝H Returns all the keys and their values as key-value pairs.
  ⍝H
    _←d.⎕FX 'ii←Items' 'ii←↓⍉↑keysG valsG'

  ⍝H d.Keys
  ⍝H   kk← d.Keys (R/O)
  ⍝H Returns the list of keys
  ⍝H
  _← d.⎕FX 'kk← Keys' 'kk←keysG'

  ⍝H ii← [up_to← 0] d.PopItems n
  ⍝H ○ Deletes and returns (up_to=0: EXACTLY; up_to=1: UP TO) <n> most recently added items from
  ⍝H   the dictionary.  Items returns are based on the order of addition 
  ⍝H   (or the LAST items in the currently sorted order if SortBy is used).
  ⍝H   If up_to=1 and no items are in the dictionary, ⍬ is returned.
  ⍝H ○ If there are insufficient items AND up_to=0, an INDEX ERROR is triggered.
  ⍝H Note:  d.PopItem is equiv. to (⊃d.PopItems 1).
  ⍝H 

  ⍝ n: desired number, a: actual (n⌊t, if n>t AND ⍺=1), t: keysG tally
  d.PopItems←{ 
      ⍺←0 ⋄ n←⍵ 
      (~⍺)∧ n> t← ≢keysG: 3 _Err 'INDEX ERROR: Insufficient items in dictionary'
      ii← ↓⍉↑keysG valsG↑⍨¨ a← -n⌊t 
      keysG ↓⍨← a ⋄ valsG ↓⍨← a ⋄ 
      0=≢ii: ⍬ ⋄ ii
  }

  ⍝H  i← d.PopItem
  ⍝H ○ Deletes and returns exactly one item from the dictionary, if there is at least one item.
  ⍝H ○ If not, an INDEX error is triggered. 
  ⍝H The item <i> is disclosed, so the key is (⊃i) and the value is (⊃⌽i). See d.PopItems.
  ⍝H
  _← d.⎕FX 'i← PopItem' ':Trap 3 ⋄ i←_PopItem ⍬ ⋄ :Else ⋄ _Err ⍬ ⋄ :EndTrap'
  d._PopItem← { 0= ≢keysG: 3 _Err 'INDEX ERROR: Dictionary is empty'
        i← ⊃∘⌽¨keysG valsG ⋄ keysG ↓⍨← ¯1 ⋄ valsG ↓⍨← ¯1 ⋄ i 
  }
  ⍝H d.Set1
  ⍝H   {val}← d.Set1 key val    OR:   {val}← key d.Set1 val
  ⍝H   Sets value for one key to value val. 
  ⍝H If it exists, it is overwritten.
  ⍝H Shyly returns the value <val> just set.
  ⍝H ------------
  ⍝H ∘ Handy: Set entries specified as items (kN vN):
  ⍝H   d.Set1¨ (k1 v1)(k2 v2)...
  ⍝H ∘ Handy: Set entries specified as separate lists (k1 k2 k3) and (v1 v2 v3)
  ⍝H   k1 k2 k3 d.Set1¨ v1 v2 v3
  ⍝H
    d.Set1←  d.⍙ {   
          ⍺←⊢ ⋄ k v←⍺ ⍵ 
      0=≢keysG: _← v ⊣ (keysG∘←1500⌶keysG) ⊣ valsG,← ,⊂v ⊣ keysG,← ,⊂k
      (≢keysG)> p← keysG⍳ ⊂k: _← (p⊃ valsG)← v  
          keysG,← ⊂k ⋄ valsG,← ⊂v 
      ×1(1500⌶)keysG: _←v ⋄ keysG∘←1500⌶keysG 
      1: _← v
    }

  ⍝H d.Set
  ⍝H   {vals}← d.Set keys vals    OR:   {vals}← keys d.Set vals
  ⍝H Sets values for keys <keys> to <vals>.
  ⍝H ∘ The number of keys and values must be the same.
  ⍝H ∘ If a key is repeated, the LAST value set is retained, as expected.
  ⍝H Shyly returns the values <vals> passed.
  ⍝H -----------
  ⍝H ∘ Handy: To set entries specified as items (key value pairs):
  ⍝H    d.Set ↓⍉↑(k1 v1)(k2 v2)....
  ⍝H  
    d.Set←  d.⍙ {  
          ⍺←⊢ ⋄ nargs← ≢kv←⍺ ⍵
      1=nargs: ∇ ↓⍉↑⊃kv 
      2≠nargs: 11 _Err 'DOMAIN ERROR: Invalid arguments'
          kk vv←,¨kv
      kk ≢⍥≢ vv: 3 _Err 'LENGTH ERROR: Keys and Values Differ in Length'
      0= ≢kk: _← ⍬
      0:: _Err ⍬     
      ⍝  Handle duplicate new key-value pairs. See _SetNew
      ⍝ 0=≢keysG: _← kk _SetNew vv          ⍝ Empty dict. All new keys  ⍝ ← No perf. benefit: Fall through to (B) below.                                                                  
          pp← keysG⍳ kk ⋄ fm← pp< ≢keysG    ⍝ Identify old, new keys    ⍝   Update old Keys | Add New Keys.
      ~0∊fm: valsG[ pp ]← vv                ⍝ All old keys              ⍝ A.      +               -
      ~1∊fm: _← kk _SetNew vv               ⍝ All new keys              ⍝ B.      -               +
          ov← valsG[ fm/ pp ]← fm/ vv       ⍝ Mixed:  Updt old keys     ⍝ C.      +               +
          nk nv← (⊂~fm)/¨ kk vv             ⍝   "     nk nv: new        ⍝ ↓
      1:  _←  ov, nk _SetNew nv             ⍝   "     Add  new keys     ⍝ ↓                                          
    }

  ⍝H d.SetDef
  ⍝H   {oldDef}← d.SetDef newDef
  ⍝H Sets the default value to use when keys are absent from the dictionary.
  ⍝H Shyly returns the old default.
  ⍝H Note: the default is typically set when the dictionary is created:
  ⍝H     myfault← ...
  ⍝H     d← myDefault ∆DICT ⍬ 
  ⍝H  
    d.SetDef←{ 1: _← (defaultG⊢← ⍵)⊢ defaultG }

  ⍝H d.SortBy
  ⍝H   {theDict} ← [theDict←d] d.SortBy sortFields sortField
  ⍝H      sortField: a list of vectors, with the same length as d.Keys 
  ⍝H        If ⍬,    d.Keys is used.
  ⍝H      theDict:   a reference to a dictionary (created via ∆DICT or d.Copy).
  ⍝H                 If omitted or a reference to <d> itself, sorts in place, rather than making a copy.
  ⍝H If sortField is empty, sorts using d.keys. 
  ⍝H   Otherwise, if (≢sortField)≢(d.keys), an error is signaled.
  ⍝H Shyly returns theDict (by default: d).
  ⍝H Examples: 
  ⍝H ∘ SORT IN PLACE
  ⍝H     d.SortBy ⍬                  - Sorts d by keys  
  ⍝H     d.(SortBy Keys)             - Sorts d by keys  
  ⍝H     d.(SortBy ⎕C Keys)          - Sorts d by keys, ignoring case  
  ⍝H     d.(SortBy ⌽Vals)            - Sorts d by values in descending order  
  ⍝H ∘ SORT INTO NEW DICTIONARY (ORIGINAL UNCHANGED)
  ⍝H     newD← (∆DICT ⍬) d.SortBy ⍬   - Sorts d by keys. newD has ⍬ as default.   
  ⍝H     newD← d.(Copy SortBy Vals)  - Sorts d by values. newD takes on d's default value.
  ⍝H 
    d.SortBy←  d.⍙ { 
        ⍺←⎕THIS ⋄ flds← ⍵ keysG⊃⍨ 0=≢⍵
        keysG ≢⍥≢ flds: _Err 'SortBy: Sort field has incorrect length.'
        ⍺.(keysG valsG)← keysG valsG    ⍝ This essentially does nothing if ⍺ and ⎕THIS are the same...
        ⍺.(keysG valsG)⌷⍨← ⊂⊂⍋flds
        ⍺.(keysG∘←1500⌶keysG) 
      1: _←  ⍺
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

  ⍝H =========================================
  ⍝H =======    ADVANCED METHODS    ==========
  ⍝H =========================================
  ⍝H
  ⍝H d.Cat1 
  ⍝H   {newVal}← key d.Cat1 item
  ⍝H   Treats the existing value for one <key> as a list (vector of vectors) and 
  ⍝H   appends <item> itself to the end of that list, conceptually:
  ⍝H       value← value,⊂item
  ⍝H Shyly returns the new value.
  ⍝H Note: If the entry for <key> doesn't exist, the default default of ⍬ is most suitable.
  ⍝H ----------------------------------------------
  ⍝H ∘ Example: Create a dictionary of word lists:
  ⍝H     french← ∆DICT ⍬
  ⍝H   Let's create list 'one'  in our dictionary <french> and append to it:
  ⍝H                                  | Before exec'n   |  After exec'n
  ⍝H     'one' french.Cat1 'un'   ==> | ⍬               |   un             
  ⍝H     'one' french.Cat1 'une'  ==> | ⊂'un            |   un  une       
  ⍝H     'one' french.Cat1 '1'    ==> | 'un' 'une'      |   un  une  1    
  ⍝H ∘ Example: Add a list of items to wordlist 'french'            
  ⍝H   french← ∆DICT ⍬                                  french2← ∆DICT ⍬                             
  ⍝H ⍝ Appends three items to list, one at a time.   ⍝ This appends one item containing 3 elements!
  ⍝H   ('two'french.Cat1)¨ '2' 'deux' 'dos'            'two' french.Cat1 '2' 'deux' 'dos'     
  ⍝H    french.Get1 'two'                              french2.Get1'two'
  ⍝H    ┌─┬────┬───┐                                   ┌────────────┐
  ⍝H    │2│deux│dos│                                   │┌─┬────┬───┐│
  ⍝H    └─┴────┴───┘                                   ││2│deux│dos││
  ⍝H                                                   │└─┴────┴───┘│
  ⍝H                                                   └────────────┘
  ⍝H
    d.Cat1←  { 0:: _Err ⍬ ⋄ 1: _← ⍺ Set1 (Get1 ⍺),⊂⍵     }  

  ⍝H d.Cat
  ⍝H   {newVals}← keys d.CatX items
  ⍝H   Equiv. to:  
  ⍝H    {newVals}← keys d.Cat¨ items
  ⍝H See d.Cat for more.
  ⍝H
    d.Cat← d.Cat1¨

  ⍝H d.Do1
  ⍝H   {newVal}← key (op d.Do1) val       ⍝  key=⍺, op=⍺⍺, val=⍵
  ⍝H   Performs:    key Set1 (Get1 key) op ⍵   
  ⍝H Shyly returns: the new value
  ⍝H ∘ Example: Dictionary <counter>
  ⍝H   Increment a counter (initially 0) named 'jack' to 1
  ⍝H      counter← 0 ∆DICT ⍬                  ⍝ Set defaults to 0
  ⍝H     'jack' +counter.Do1 1               ⍝ Sets entry jack to 0+1  => 1
  ⍝H     'jack' +counter.Do1 2               ⍝ Sets entry jack to 1+2  => 3
  ⍝H     'jack' *counter.Do1 2               ⍝ Sets entry jack to 3*2  => 9...
  ⍝H 
    d.Do1←  { 0:: _Err ⍬ ⋄ 1: _←⍺ Set1 (Get1  ⍺) ⍺⍺  ⍵ }
    
  ⍝H d.Do
  ⍝H   {newVals}← keys (op d.Do) vals       ⍝  key=⍺, op=⍺⍺, val=⍵
  ⍝H   Performs:    newVals← keys Set (Get keys) op¨ ⍵   
  ⍝H Shyly returns: newVals
  ⍝H See d.Do for details, examples
  ⍝H
   d.Do← {0:: _Err ⍬ ⋄ 1: _← ⍺ (⍺⍺ Do1)¨ ⍵ }

  ⍝H Hashing  
  ⍝H Hashing ensures that searching of dictionary keys is as fast as possible.
  ⍝H There are no hashing methods/functions; hashing is done automatically.
  ⍝H Performance improvements range from 3x on up for char. array searches (⍳ in Get/X).
  ⍝H Hashing is done automatically:
  ⍝H - When the array is created (d← ∆DICT...)
  ⍝H - After deleting items (d.Del/X, d.DelI/X)
  ⍝H - After sorting (d.SortBy)
  ⍝H Advanced: To check status of hashing for dictionary d:
  ⍝H        r← 1(1500⌶)d.Keys 
  ⍝H   r=2: active, r=1: established; r=0: not in use.
  ⍝H

  ⍝ Executive 
      ⍺← ⍬
      d.∆DICT← ∇
  'help'≡⎕C ⍵: d.Help  
      d.( defaultG keysG valsG )← ⍺ ⍬ ⍬
  0= ≢⍵: d ⋄ d ⊣ d.Set ⍵                                
 }