⍝ namespace: ∆DICT_NS 
⍝ function:  ∆DICT2 

∇ ∆DICT2
  ⍝ Dummy (so the name is reported)
∇

:NameSpace ∆DICT_NS

  ⍝ To remove testing code...  ⊢ ⎕FX  '∆DICT←'  '⍙←'  '(\d∘)?d\.⍙' ⎕R  '∆DICT2←' '\0' ' '⊢⎕SE.⎕NR '∆DICT'
  ⍝H 
  ⍝H ┌─────────────────────────────────────────────────────────────────┐
  ⍝H │               ∆𝗗𝗜𝗖𝗧: 𝗔𝗻 𝗢𝗿𝗱𝗲𝗿𝗲𝗱 𝗗𝗶𝗰𝘁𝗶𝗼𝗻𝗮𝗿𝘆 𝘂𝘁𝗶𝗹𝗶𝘁𝘆                     │
  ⍝H │         Keys and values may have any shape and type.            │
  ⍝H │         The keys are hashed for performance (see Hashing).      │
  ⍝H │         The dictionary maintains items in order of creation.*   │
  ⍝H ├─────────────────────────────────────────────────────────────────┤
  ⍝H │ * Or as sorted (see SortBy).                                    │
  ⍝H └─────────────────────────────────────────────────────────────────┘
  ⍝H
  ⍝H ┌─────────────────────────────────────────────────────────────────┐
  ⍝H │   𝐃𝐢𝐜𝐭𝐢𝐨𝐧𝐚𝐫𝐲 𝐂𝐫𝐞𝐚𝐭𝐢𝐨𝐧                                              │
  ⍝H └─────────────────────────────────────────────────────────────────┘
  ⍝H 
  ⍝H [a] d← [default←⍬] ∆DICT kk vv              where vectors of keys and values: kk ≡⍥≢ vv
  ⍝H                                             ('key1' 'key2') ((○1)(○?1000))
  ⍝H                          ⊂kv1 kv2...        where kvN is an "item" (a key-value pair), 
  ⍝H                                             ('key1' (○1)) ('key2' (○?1000))
  ⍝H [b] d← [default←⍬] ∆DICT ⍬                  generates an empty dictionary (with default value ⍬)
  ⍝H
  ⍝H Returns a dictionary namespace <d> containing a hashed, ordered list of items and a set of service functions.
  ⍝H The default value is set to ⍬. A useful default value for counters is 0.
  ⍝H
  ⍝H [c] ∆DICT 'Help'                            shares this help information (see also Methods below)
  ⍝H
  ⍝H ┌──────────────────────┐
  ⍝H │   𝐃𝐢𝐜𝐭𝐢𝐨𝐧𝐚𝐫𝐲 𝐌𝐞𝐭𝐡𝐨𝐝𝐬   │
  ⍝H └──────────────────────┘
  ⍝H ┌──────────────────────────────   KEY   ────────────────────────────────┐
  ⍝H │   𝐝.𝑴𝒆𝒕𝒉𝒐𝒅: 𝒅 is a dict created via d←∆DICT or d← d0.Copy             │
  ⍝H │            𝑴𝒆𝒕𝒉𝒐𝒅: see 𝒎𝒆𝒕𝒉𝒐𝒅𝒔 below                                   │
  ⍝H │   𝒌𝒌: a (disclosed) key    𝒌𝒌: 1 (enclosed) or more keys              │
  ⍝H │   𝒗: a (disclosed) value   𝒗𝒗: 1 (enclosed) or more values             │
  ⍝H | ⊃𝒌𝒗: a disclosed item      𝒌𝒗: 1 (enclosed) or more items (k-v pairs) │
  ⍝H │   𝒂:  arbitrary data       𝒂𝒂: any (enclosed) list of arbitrary data  │
  ⍝H │   𝒃:  Boolean value        𝒃𝒃: Boolean values                         │
  ⍝H │                            𝒔𝒔: sortable keys                           │
  ⍝H │   𝒊:  an index              𝒊𝒊: 1 or more indices (key locations)       │
  ⍝H │   𝒏:  a non-neg integer                                               │
  ⍝H │   {𝒙𝒙}←   shy return value                                            │
  ⍝H └───────────────────────────────────────────────────────────────────────┘
  ⍝H ┌─────────────────┐
  ⍝H │   𝗕𝗮𝘀𝗶𝗰 𝗠𝗲𝘁𝗵𝗼𝗱𝘀   │
  ⍝H └─────────────────┘                   
  ⍝H    Creating Dictionaries: newD← [v] [d.]∆DICT kk vv                  
  ⍝H                                 [v] [d.]∆DICT ⊂kv kv  
  ⍝H                                 [v] [d.]∆DICT ⍬                      
  ⍝H       [Cloning]            newD← d.Copy
  ⍝H    Setting and Getting: 
  ⍝H       [Items]              {vv}← d.Set  kk vv      vv← d.Get    kk  
  ⍝H       [Single Item]        {v}←  d.Set1 k  v       v←  d.Get1   k      
  ⍝H       [Indices]                                    ii← d.Find   kk   
  ⍝H                                                    i←  d.Find1  k 
  ⍝H       [Exporting and Importing vars from namespaces as items]
  ⍝H                {ns}← [ns←⎕NS ''] d.Export kk     
  ⍝H                    {kk}← [kk←𝐴𝑙𝑙] d.Import ns1 [ns2...]     ⍝ [kk←𝐴𝑙𝑙]. If omitted, imports all found.
  ⍝H       [Default Values]    {old}← d.SetDef a        a←  d.GetDef 
  ⍝H    Popping Values By Key 
  ⍝H    ∘  Getting and Simultaneously Deleting Items by Key
  ⍝H                                         vv←  [default] d.Pop kk                
  ⍝H                                         v←   [default] d.Pop1 k                
  ⍝H    Popping Most Recent (Last-in-order) Item(s)
  ⍝H    ∘  Getting and Simultaneously Deleting Last Items (most recently added or last in SortBy order).
  ⍝H       [Last N items]                     kv←  [⍺←0] d.PopItems N                  
  ⍝H       [Last item]                      (⊃kv)←       d.PopItem                             
  ⍝H    Validating Items               (Good Option)       (Faster Option)
  ⍝H                                   bb← d.HasKeys kk     bb←  kk∊ d.Keys                           
  ⍝H                                   b←  d.HasKey k       b← (⊂k)∊ d.Keys                                                                     
  ⍝H    Sorting Items:        
  ⍝H                {newD}← [newD←d] d.SortBy ss              
  ⍝H    Deleting Items:          
  ⍝H       [Items by Key]       {bb}← [bb] d.Del   kk
  ⍝H       [Single Item by Key] {b}←  [b]  d.Del1  k
  ⍝H       [Items by Index]     {bb}← [b]  d.DelI  ii                  ⎕IO=0
  ⍝H       [All]                {n}←  d.Clear                           
  ⍝H    Returning Dictionary Components          
  ⍝H       [Keys]                      kk← d.Keys                             
  ⍝H       [Vals]                      vv← d.Vals                             
  ⍝H       [Items]                     kv← d.Items                           
  ⍝H       [Number of Items]           n←  d.Tally                           
  ⍝H
  ⍝H ┌────────────────────┐
  ⍝H │   𝗔𝗱𝘃𝗮𝗻𝗰𝗲𝗱 𝗠𝗲𝘁𝗵𝗼𝗱𝘀     │
  ⍝H └────────────────────┘    
  ⍝H    Modifying Values:         
  ⍝H       [Apply <op a>]       vv← kk (op d.Do  ) aa                 Perform (op aa) on value of <kk>: vv← vv op¨ aa
  ⍝H                            v←  k  (op d.Do1)  a                  Ditto: v← v op a 
  ⍝H       [Catenate <a>]           vv← kk d.Cat  aa                  Concat <aa> to value of <kk>: vv← vv,∘⊂¨aa      
  ⍝H                                v←  k  d.Cat1 a                   Ditto: v←v,⊂aa
  ⍝H
  ⍝H ┌───────────────┐
  ⍝H │   𝐎𝐭𝐡𝐞𝐫 𝐈𝐧𝐟𝐨    │
  ⍝H └───────────────┘    
  ⍝H Hashing:
  ⍝H     See "Hashing" below.
  ⍝H Help Info:
  ⍝H                             ∆DICT 'Help' 
  ⍝H                             d.Help 
  ⍝H 
  ⎕IO ⎕ML←0 1 
  ∆DICT_NS←  ⎕THIS             


  ⍝  ======================================
  ⍝  =======   Internal Utils    ==========
  ⍝  ======================================

  ⍝ _Err: (Internal) Error Signaller

  _Err←  { ⍺← ⎕DMX.(11 EN⊃⍨(×EN)∧0=≢⍵)  ⋄ ⊂⎕DMX.(('EM' ('∆DICT: ',EM ⍵⊃⍨0≠≢⍵))('EN' ⍺)('Message' (Message/⍨0=≢⍵)))}
      
  ⍝ ⍙: "Validate"
  ⍝ Useful solely to validate hash logic... 
  ⍝ Checks that hashing is on for keysG or signals a logic error.
  ⍝ 0∘⍙   returns shy ⍵ (default)
  ⍝ 1∘⍙   returns ⍵.
  ⍝ >>> Remove any calls to ⍙ once testing is complete. <<<
  ⍙← { ⍺←0 ⋄ ⍺: 0 ∇ ⍵ ⋄ 0=≢keysG: _←⍵ ⋄ ×1(1500⌶)keysG: _←⍵ 
      '∆DICT: Logic Error. Hash not established for keysG' ⎕SIGNAL 999  
  }

  ⍝H ┌────────────────────────┐
  ⍝H │   BASIC METHODS        │
  ⍝H └────────────────────────┘  
  ⍝H Clear
  ⍝H   {n}← d.Clear
  ⍝H Delete all the items in the dictionary, 
  ⍝H    shyly returning the number of items <n> in the dictionary before clearing.
  ⍝H (Does not affect the default value: defaultG)
  ⍝H
  ∇ {nK}←Clear 
    nK← ≢keysG ⋄ keysG← valsG← ⍬
  ∇   

  ⍝H d.Copy
  ⍝H   d2← d.Copy
  ⍝H Returns a complete, independent copy (clone) of dictionary d.
  ⍝H   (Keys, values, and the default value are copied).
  ⍝H 
  ⍝  Calling ∆DICT to clone is faster than (⎕NS ⎕THIS) for smallish ≢keysG...
  ∇ d2←Copy 
    d2← ⎕NS ⎕THIS 
  ∇

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
  Del1←   { 
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
  Del←   { 
      ⍺← 0 ⋄ pp← keysG⍳ kk← ⍵ ⋄ om← pp< ≢keysG 
    (0∊om)∧~⍺: 3 _Err 'Key(s) not found'
      (keysG valsG) /⍨← ⊂0@ (om/ pp)⊣ 1⍴⍨ ≢keysG 
      keysG∘←1500⌶keysG 
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
  DelI←   {  
    0:: _Err ⍬
      ⍺← 0 ⋄ pp← ⍵ ⋄ om← 0= ⍵⍸ ⍨0, ≢keysG
    (0∊om)∧~⍺:  3 _Err 'Index Error'
      (keysG valsG) /⍨← ⊂0@ (om/pp)⊣ 1⍴⍨ ≢keysG
      keysG∘←1500⌶keysG 
    1: _← om
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
  Find← { ⍺←0 
        pp← keysG⍳ ⍵ 
    ⍺: pp 
    1∊ pp= ≢keysG: 3 _Err 'Key(s) not found'
        pp                                                
  }
  Find1← Find⊂
 
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
  Get← {             
      pp← keysG⍳ kk← ⍵ ⋄ om← pp< ≢keysG ⋄ ~0∊ om: valsG[ pp ]    ⍝ All keys found: fast return                      
      ⍺← ⊂defaultG                                  
    (1≠ ≢⍺) ∧ kk ≠⍥≢ ⍺: 5 _Err 'Length Error: Mismatched left and right argument lengths'
      rr← ⍺⍴⍨ ≢kk                                                ⍝ Prepopulate result vector with defaults
    ~1∊ om: rr                                                   ⍝ No keys found: just return defaults
      valsG[ om/ pp ]@ (⍸om)⊣ rr                                 ⍝ Now, add in values for keys found
  }

  ⍝H d.Get1 (Get by Single Key)
  ⍝H val← [def← GetDef] d.Get1 key
  ⍝H   Retrieves the specified key or <def> if not found.
  ⍝H Returns: 
  ⍝H - the value <val> for <key>, if <key> defined.
  ⍝H - Otherwise, the default is returned.
  ⍝H
    Get1← { p← keysG⍳ ⊂⍵ ⋄ p< ≢keysG: p⊃ valsG ⋄ ⍺← defaultG ⋄ ⍺ }

  ⍝H d.GetDef   
  ⍝H   curDef← d.GetDef
  ⍝H   Gets the current default value.
  ⍝H Returns the default value (used for an item's value when a key is not found)
  ⍝H 
  ∇ curDef← GetDef
    curDef← defaultG
  ∇

  ⍝H d.HasKeys
  ⍝H   [ [1|0]... ]← d.HasKeys keys
  ⍝H Returns 1 for each key k in <keys> which is defined;
  ⍝H Returns 0 for each otherwise.
  ⍝H -----
  ⍝H Note: It is (~2-3 times) faster to use ∊ in place of HasKey/s
  ⍝H    :IF (⊂'cats') ∊ d.Keys ⋄ ... 
  ⍝H    :IF 1∊ 'cats' 'dogs' 'mice' ∊ d.Keys ⋄ ... 
  ⍝H
  HasKeys← { ⍵∊ keysG }
    
  ⍝H d.HasKey
  ⍝H   [1|0]← d.HasKey key
  ⍝H     key: an object of any shape
  ⍝H   Returns 1 if <key> is defined, else 0.
  ⍝H -----
  ⍝H See Note at HasKeys.
  ⍝H
  HasKey← { ⍵∊ keysG }⊂


  ⍝H d.Help
  ⍝H   Provides this helpful information.
  ⍝H   Alternatively, execute:   ∆DICT 'Help'
  ⍝H Returns: nothing
  ⍝H
  ∇ Help
    {0=≢_h←'^\h*⍝H(.*)' ⎕S '\1'⊣⎕SRC ∆DICT_NS: 'No help available' ⋄ ⎕ED '_h'}⍬
  ∇

  ⍝H {kk}← [keys← 𝐴𝑙𝑙] d.Import ns1 [ns2...]
  ⍝H    Import all (or specified) vars from one or more namespaces <ns1>, etc. 
  ⍝H    as keys, along with their values.  
  ⍝H    keys: 
  ⍝H    ○ If not present, all vars found are imported.
  ⍝H    ○ Otherwise, keys must be 1 or more char vectors or scalars;
  ⍝H      char scalars keys are quietly converted to char vectors.
  ⍝H      Only those keys will be imported from ANY namespace listed.
  ⍝H ∘ If a variable appears in more than one namespace listed, the last value seen is stored.
  ⍝H ∘ Var names are automatically "demangled"  via JSON rules when converted to keys.
  ⍝H ∘ 1-char variable names (after demangling) will be imported as (1-char) vector keys, 
  ⍝H   even if originally exported from a 1-char key.
  ⍝H Shyly returns (unique) keys for items (variables) imported.
  ⍝H
  Import←{ Demangle← 1∘(7162⌶) ⋄ Mangle← 0∘(7162⌶) 
    0:: _Err 'DOMAIN ERROR: Invalid key name(s)'
    ⍝  If kf=0, import keys <kk>. kk: list of keys to import.
        kf← ⊃2=⎕NC '⍺' ⋄ ⍺←⍬ ⋄ kk←(Mangle¨⍣kf⊢,¨⍺)  
    0:: _Err ⍬  
    1: _←∪⊃,/ ⍺∘{ 
      9≠⎕NC '⍵': 11 _Err 'DOMAIN ERROR: Invalid namespace(s)' 
      0=≢vars← kk∩⍣kf⊢⍵.⎕NL ¯2: ⍬ ⋄ keys← Demangle¨ vars
        keys⊣ keys Set ⍵.⎕OR¨vars
    }¨ ⍵
  }
  ⍝H {ns←} [ns] d.Export kk
  ⍝H  - Export dictionary entries to namespace <ns> (a new ns, if omitted) 
  ⍝H    given a list of 0 or more keys <kk>.
  ⍝H  - Keys are automatically "mangled" via JSON rules when converted to variable names.
  ⍝H  - Warning: Chars converted to 1-char names will be reimported as char vectors, even if originally 
  ⍝H    scalar keys.
  ⍝H Returns the (existing or new) namespace.
  ⍝H ∘ If any keys don't exist, they are exported with the default.
  ⍝H ∘ If any variables already exist, their values are overwritten.
  ⍝H ∘ Finally, if any keys cannot be converted to valid variable names, a DOMAIN ERROR is signaled.
  ⍝H   Numbers are not automatically converted to their text form (since the key 1 and '1' are different!).
  ⍝H 
  ⍝H Example:   ns←   a.Export 'var1' 'var2'         -- Export just var1 and var2 to new namespace <ns>
  ⍝H            a.Set ('var1' 'NEW1')('var2' 'NEW2') -- Update vals of var1 and var2
  ⍝H            ns←ns a.Export a.Keys~ns.⎕NL ¯2      -- Export everything new to <ns>. Keep old vals for var1 and var2
  ⍝H            
  Export←{ ⍺← ns⊣(ns←⎕NS '').⎕DF '∆DICT[Export]' 
      kk← ⍵ ⋄ Mangle← 0∘(7162⌶) ⋄ SetNsVar← ⍺{ ⍺⍺.⍎ ⍺,'←⍵' }
    0:: _Err ⍬
    1: _←⍺ ⊣ _←(Mangle¨ kk) SetNsVar¨ Get kk
  }

  ⍝H d.Items
  ⍝H   ii← d.Items
  ⍝H Returns all the keys and their values as key-value pairs.
  ⍝H
  ∇ ii←Items
    ii←↓⍉↑keysG valsG
  ∇

  ⍝H d.Keys
  ⍝H   kk← d.Keys (R/O)
  ⍝H Returns the list of keys
  ⍝H
  ∇ kk← Keys
    kk←keysG
  ∇

  ⍝H d.Pop 
  ⍝H    vv← [default] d.Pop kk
  ⍝H    Pops and returns the values/defaults of the keys.
  ⍝H Returns the values of the keys found and defaults for those missing, deleting those found.
  ⍝H
  Pop← { ⍺← defaultG
       kk← ⍵
      0:: _Err ⍬
       ii← 1 Find kk ⋄ om← ii<≢keysG
       vv← (≢kk)⍴ ⊂⍺
       ( om/ vv )← valsG[ om/ ii ]  
       vv⊣ 1 DelI om/ ii            ⍝ Delete actual keys.
  }
  ⍝H d.Pop1
  ⍝H   v← [default] d.Pop1 k
  ⍝H   Pops and returns the value/default of the key.
  ⍝H Returns the value of the key <k> (or its default) and deletes the entry.
  ⍝H
  Pop1← { ⍺←defaultG
    ⊃ ⍺ Pop ⊂⍵
  }

  ⍝H d.PopItems
  ⍝H   kv← [up_to← 0] d.PopItems n
  ⍝H   Pop and return last N items from the dictionary.
  ⍝H   ○ Pops and returns (up_to=0: EXACTLY; up_to=1: UP TO) <n> items (key-value pairs) from the dictionary;
  ⍝H     the items popped are efficiently deleted. 
  ⍝H   ○ Items returned are the most recently added or, if the dictionary has been sorted, the last <n> items. 
  ⍝H   ○ If up_to=1 and there are fewer than n items in the dictionary, the remaining items are returned.
  ⍝H   ○ If up_to=1 and no items are in the dictionary, ⍬ is returned.
  ⍝H   ○ If there are insufficient items AND up_to=0, an INDEX ERROR is triggered.
  ⍝H 

  ⍝ n: desired number, a: actual (n⌊t, if n>t AND ⍺=1), t: keysG tally
  PopItems← { 
    0:: _Err 'DOMAIN ERROR'
      ⍺←0 ⋄ n←⍵ 
      n≠⌊n: _Err 'DOMAIN ERROR'
      (~⍺)∧ n> t← ≢keysG: 3 _Err 'INDEX ERROR: Insufficient items in dictionary'
      ii← ↓⍉↑ keysG valsG↑⍨¨ a← -n⌊t 
      keysG↓⍨← a ⋄ valsG↓⍨← a ⋄ keysG∘←1500⌶keysG
      0=≢ii: ⍬ ⋄ ii
  }

  ⍝H d.PopItem 
  ⍝H   item← d.PopItem
  ⍝H Pops and returns the last item from the dictionary.
  ⍝H ○ Deletes and returns exactly one item from the dictionary, if there is at least one item.
  ⍝H ○ If not, an INDEX error is triggered. 
  ⍝H The item <i> is disclosed, so the key is (⊃i) and the value is (⊃⌽i).  
  ⍝H Note:  d.PopItem is equiv. to (⊃d.PopItems 1). See d.PopItems.
  ⍝H
  ∇ i← PopItem
    :Trap 3 
        i← { 
            0= ≢keysG: 3 _Err 'INDEX ERROR: Dictionary is empty'
            i← ⊃∘⌽¨keysG valsG 
            keysG ↓⍨← ¯1 ⋄ valsG ↓⍨← ¯1 ⋄ keysG∘←1500⌶keysG 
            i 
        } ⍬
    :Else 
        _Err ⍬ 
    :EndTrap
  ∇

  ⍝H d.Set
  ⍝H * Using separate keys and values
  ⍝H     {vals}← d.Set keys vals    OR:   {vals}← keys d.Set vals
  ⍝H   Sets values for keys <keys> to <vals>.
  ⍝H   ∘ The number of keys and values must be the same.
  ⍝H   ∘ If a key is repeated, the LAST value set is retained, as expected.
  ⍝H * Using key-value pairs (items)
  ⍝H    {vals}← d.Set ⊂kv1 kv2...
  ⍝H (In both cases) shyly returns all the values <vals> passed (even duplicates).
  ⍝H  
  Set←   {  
        ⍺←⊢ ⋄ nargs← ≢kv←⍺ ⍵  
    1=nargs: ∇ ↓⍉↑⊃kv   
    2≠nargs: 11 _Err 'DOMAIN ERROR: Invalid arguments'
        kk vv←,¨kv 
    kk ≢⍥≢ vv: 3 _Err 'LENGTH ERROR: Keys and Values Differ in Length' 
    0= ≢kk: _← ⍬
  ⍝  0:: _Err ⍬   
  ⍝  Handle duplicate new and old keys, an empty hash, etc.. 
        pp← keysG⍳ kk ⋄ om← pp< ≢keysG   
    ~0∊om: valsG[ pp ]← vv                ⍝ 1. All Old Keys?            
        valsG[ om/ pp ]← om/ vv           ⍝ 2. Mixed Old and New Keys? (No perf. gain from breaking down further) 
        _← (nm/ kk) { nv← 0↑⍨ ≢unk← ∪⍺ ⋄ nv[unk⍳ ⍺]← ⍵ ⋄ keysG,← unk ⋄  valsG,← nv } (vv/⍨ nm← ~om)
    ×1(1500⌶)keysG: _← vv ⋄ keysG∘← 1500⌶keysG ⋄ 1: _← vv
  }
   
  ⍝H d.Set1  
  ⍝H   {val}← d.Set1 key val    OR:   {val}← key d.Set1 val
  ⍝H   Sets value for one key to value val. 
  ⍝H   If it exists, it is overwritten.
  ⍝H Shyly returns the value <val> just set.
  ⍝H ------------
  ⍝H ∘ Handy: Set entries specified as items (kN vN):
  ⍝H   d.Set1¨ (k1 v1)(k2 v2)...
  ⍝H ∘ Handy: Set entries specified as separate lists (k1 k2 k3) and (v1 v2 v3)
  ⍝H   k1 k2 k3 d.Set1¨ v1 v2 v3
  ⍝H
  Set1←   { ⍺←⊢ ⋄ k v←⍺ ⍵ 
    0=≢keysG: _← v ⊣ (keysG∘←1500⌶keysG) ⊣ valsG,← ,⊂v ⊣ keysG,← ,⊂k ⊣ ⎕←'Hashing'
    (≢keysG)> p← keysG⍳ ⊂k: _← (p⊃ valsG)← v ⋄  keysG,← ⊂k ⋄ valsG,← ⊂v 
    ×1(1500⌶)keysG: _←v ⋄ keysG∘←1500⌶keysG ⋄  ⎕←'Hashing' ⋄ 1: _← v
  }
    
  ⍝H d.SetDef
  ⍝H   {oldDef}← d.SetDef newDef
  ⍝H Sets the default value to use when keys are absent from the dictionary.
  ⍝H Shyly returns the old default.
  ⍝H Note: the default is typically set when the dictionary is created:
  ⍝H     myfault← ...
  ⍝H     d← myDefault ∆DICT ⍬ 
  ⍝H  
  SetDef←{ 1: _← (defaultG⊢← ⍵)⊢ defaultG }

  ⍝H d.SortBy
  ⍝H Sorts a dictionary in place or into another dictionary ordered via a sort vector (default: d.Keys).
  ⍝H   {theDict} ← [theDict←d] d.SortBy sortVec 
  ⍝H      sortVec:   a list of vectors, with the same length as d.Keys 
  ⍝H        If ⍬,    d.Keys is used.
  ⍝H      theDict:   a reference to a dictionary (created via ∆DICT or d.Copy).
  ⍝H                 If omitted or a reference to <d> itself, sorts in place, rather than making a copy.
  ⍝H If sortVec is empty, 
  ⍝H   sorts using d.Keys. 
  ⍝H Otherwise, 
  ⍝Huses sortVec as the sort field; if (≢sortVec)≢(d.keys), an error is signaled.
  ⍝H Shyly returns theDict (by default: d).
  ⍝H Examples: 
  ⍝H ∘ SORT IN PLACE
  ⍝H     d.SortBy ⍬                  - Sorts d by keys  
  ⍝H     d.(SortBy Keys)             - Sorts d by keys  
  ⍝H     d.(SortBy ⎕C Keys)          - Sorts d by keys, ignoring case  
  ⍝H     d.(SortBy ⌽Vals)            - Sorts d by values in descending order  
  ⍝H ∘ SORT INTO NEW DICTIONARY (ORIGINAL UNCHANGED)
  ⍝H     newD← (∆DICT ⍬) d.SortBy ⍬  - Sorts d by keys. newD has ⍬ as default.   
  ⍝H     newD← d.(Copy SortBy Vals)  - Sorts d by values. newD takes on d's default value.
  ⍝H 
  SortBy←   { 
      ⍺←⎕THIS ⋄ sf← ⍵ keysG⊃⍨ 0=≢⍵
      keysG ≢⍥≢ sf: _Err 'SortBy: Sort field has incorrect length.'
      ⍺.(keysG valsG)← keysG valsG    ⍝ This essentially does nothing if ⍺ and ⎕THIS are the same...
      ⍺.(keysG valsG)⌷⍨← ⊂⊂⍋sf
      ⍺.(keysG∘←1500⌶keysG) 
    1: _←  ⍺
  }

  ⍝H d.Tally
  ⍝H   n← d.Tally
  ⍝H Returns the number of items in the dictionary
  ⍝H 
  ∇ n← Tally
    n← ≢keysG
  ∇

  ⍝H d.Vals
  ⍝H   vv← d.Vals (R/O)
  ⍝H Returns the list of values
  ⍝H
  ∇ vv← Vals
    vv←valsG
  ∇

  ⍝H ┌────────────────────────┐
  ⍝H │   Advanced Methods     │
  ⍝H └────────────────────────┘  
  ⍝H
  ⍝H d.Cat1   [operator: ⍺⍺ d.Cat1 ⍵]
  ⍝H   {newVal}← key d.Cat1 val
  ⍝H   Treats the existing value for one <key> as a list (vector of vectors) and 
  ⍝H   appends <item> itself to the end of that list, conceptually:
  ⍝H       value← value,⊂val
  ⍝H Shyly returns the new value.
  ⍝H ∘ Note: If the entry for <key> doesn't exist, the default default of ⍬ is most suitable.
  ⍝H ∘ Note that Cat1 is an operator, allowing 1 or more values (⍵) for each key (⍺⍺) using each (¨),
  ⍝H   as in this example reproduced from below:
  ⍝H      ('two'french.Cat1)¨ '2' 'deux' 'II' 
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
  ⍝H   ('two'french.Cat1)¨ '2' 'deux' 'II'            'two' french2.Cat1 '2' 'deux' 'II'     
  ⍝H    french.Get1 'two'                              french2.Get1'two'
  ⍝H    ┌─┬────┬──┐                                    ┌───────────┐
  ⍝H    │2│deux│II│                                    │┌─┬────┬──┐│
  ⍝H    └─┴────┴──┘                                    ││2│deux│II││
  ⍝H                                                   │└─┴────┴──┘│
  ⍝H                                                   └───────────┘
  ⍝H
  Cat1←  { 0:: _Err ⍬ ⋄ 1: _← ⍺⍺ Set1 (Get1 ⍺⍺),⊂⍵     }  

  ⍝H d.Cat   
  ⍝H   {newVals}← keys d.Cat vals
  ⍝H   Equiv. to:  
  ⍝H    {newVals}← { keys {(⍺ Cat1) ⍵}¨vals}
  ⍝H Unlike <Cat1>, Cat is a function, typically used with several (keys/⍺) and values (⍵).
  ⍝H Shyly returns the new values for each key.
  ⍝H ---------
  ⍝H Examples:
  ⍝H                 french← ∆DICT ⍬
  ⍝H      'two' 'two' 'two' french.Cat '2' 'deux' 'II'
  ⍝H       french.Get1 'two'
  ⍝H ┌─┬────┬──┐
  ⍝H │2│deux│II│
  ⍝H └─┴────┴──┘
  ⍝H                 french← ∆DICT ⍬
  ⍝H        (⊂'two') french.Cat '2' 'deux' 'II'
  ⍝H        french.Get1 'two'
  ⍝H ┌─┬────┬──┐
  ⍝H │2│deux│II│
  ⍝H └─┴────┴──┘
  ⍝H
  ⍝H See Cat1 for more.
  ⍝H
  Cat← { ⍺ {⍺ Cat1 ⍵}¨⍵}

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
  Do1←  { 0:: _Err ⍬ ⋄ 1: _←⍺ Set1 (Get1  ⍺) ⍺⍺  ⍵ }
    
  ⍝H d.Do
  ⍝H   {newVals}← keys (op d.Do) vals       ⍝  key=⍺, op=⍺⍺, val=⍵
  ⍝H   Performs:    newVals← keys Set (Get keys) op¨ ⍵   
  ⍝H Shyly returns: newVals
  ⍝H See d.Do1 for examples
  ⍝H
  Do← {0:: _Err ⍬ ⋄ 1: _← ⍺ (⍺⍺ Do1)¨ ⍵ }

  ⍝H ┌────────────────────────┐
  ⍝H │   HASHING              │
  ⍝H └────────────────────────┘  
  ⍝H Hashing  
  ⍝H Hashing ensures that searching of dictionary keys is as fast as possible.
  ⍝H There are no user-accessible hashing methods; hashing is done automatically.
  ⍝H Performance improvements range from 3x on up for char. array searches (⍳ in Get/X).
  ⍝H Hashing takes place:
  ⍝H - When the array is created (d← ∆DICT...)
  ⍝H - Whenever items are deleted (d.Del/X, d.DelI/X, and so on)
  ⍝H - After sorting (d.SortBy)
  ⍝H Advanced: To check status of hashing for dictionary d:
  ⍝H        r← 1(1500⌶)d.Keys 
  ⍝H   r=2: active, r=1: established; r=0: not in use.
  ⍝H

  ∇ {ok}← INITIALIZE_NS
      _Err← ⎕SIGNAL _Err
      (ok defaultG keysG valsG)← 1 ⍬ ⍬ ⍬
  ∇
  INITIALIZE_NS
  
  ⍝ Primary Function ∆DICT2
  ∆DICT2← {
        ⎕IO ⎕ML←0 1 
        d←(calr←⊃⎕RSI).⎕NS ∆DICT_NS  ⋄ _←d.⎕DF (⍕calr),'.[∆DICT]' 
        ⍺← ⍬ ⋄ d.defaultG ← ⍺ 
    'help'≡⎕C ⍵: d.Help  
    0= ≢⍵: d ⋄ d ⊣ d.Set ⍵ 
  }

  ##.∆DICT2←  ∆DICT2

 :EndNamespace
 
