:Class DictClass
⍝ Documentation is provided in detail at the bottom of this class.

⍝ Initialization of APL System Variables
⍝ Right now, ⎕CT, ⎕DCT left as same as in #
    (⎕IO ⎕ML)←0 1 ⋄ (⎕CT ⎕DCT)←#.(⎕CT ⎕DCT)  ⋄ ⎕PP←34  ⋄ ⎕RL←#.⎕RL
 
⍝ Export key utilities to the parent environment (hard-wiring ⎕THIS namespace)?
⍝ If exportSelection[n]=1, item [n] will be exported to ##
⍝  n     Is exported to ##
⍝ [0]    Dict   
⍝ [1]    ∆DICT   
⍝ [2]    ∆JDICT 
  exportSelection← (1∊'⍙⍙'⍷⍕⎕THIS)⊃ (1 1 1)(1 1 1)     ⍝ Copy all utilities to ## in each case...
  :Field Private Shared EXPORT_LIST← exportSelection/ 'Dict' '∆DICT' '∆JDICT'   ⍝ See EXPORT_FUNCTIONS below
 
  ⍝ IDs:  Create Display form of form:
  ⍝       DictDDHHMMSS.dd (digits from day, hour, ... sec, plus increment for each dict created).
  :Field Public         ID 
  :Field Private Shared ID_COMMON←  2147483647 | 31  24 60 60 1000⊥¯1 0 0 0 0+¯5↑⎕TS 

  ⍝ Instance Fields and Related
  ⍝ A. TRAPPING
    :Field Private ∆TRAP←                   0 'C' '⎕SIGNAL/⎕DMX.((EM,Message,⍨'': ''/⍨0≠≢Message) EN)'
     unmangleJ←                             1∘(7162⌶)        ⍝ APL strings <--> JSON strings
     mangleJ←                               (0∘(7162⌶))∘⍕
  ⍝ B. Core dictionary fields
                   keysF←                   ⍬        ⍝ Variable to avoid Dyalog bugs (catenating/hashing)
    :Field Private valuesF←                 ⍬
    :Field Private hasdefaultF←             0
    :Field Private defaultF←                ''        ⍝ Default value (hidden until hasdefaultF is 1)
    :Field Private baseclassF←              ⊃⊃⎕CLASS ⎕THIS
  ⍝ C. ERROR MESSAGES:  ⎕SIGNAL⊂('EN' 200)('EM' 'Main error')('Message' 'My error')
    :Field Private Shared eBadUpdate←       11 '∆DICT: invalid right argument (⍵) on initialization or update.'
    :Field Private Shared eBadDefault←      11 '∆DICT: hasdefault must be set to 1 (true) or 0 (false).'
    :Field Private Shared eDelKeyMissing←   11 '∆DICT.del: at least one key was not found and ⍺:ignore≠1.'
    :Field Private Shared eIndexRange←       3 '∆DICT.delbyindex: An index argument was not in range and ⍺:ignore≠1.'
    :Field Private Shared eKeyAlterAttempt← 11 '∆DICT.keys: item keys may not be altered.'
    :Field Private Shared eHasNoDefault←     3 '∆DICT.index: key does not exist and no default was set.'
    :Field Private Shared eHasNoDefaultD←   11 '∆DICT: no default has been set.'
    :Field Private Shared eQueryDontSet←    11 '∆DICT: querydefault may not be set; Use Dict.(default or hasdefault).'
    :Field Private Shared eBadInt←          11 '∆DICT.(inc dec): increment (⍺) and value for each key in ⍵ must be numeric.'
    :Field Private Shared eKeyBadName←      11 'Dict.namespace: Unable to convert key to valid APL variable name'

  ⍝ General Local Names
    ∇ ns←Dict                      ⍝ Returns this namespace. Searchable via ⎕PATH. 
      :Access Public Shared        ⍝ Usage:  a←⎕NEW Dict [...]
      ns←⎕THIS
    ∇

    ∇dict←{def} ∆DICT initial      ⍝ Creates ⎕NEW Dict via cover function
    :Access Public Shared
     :TRAP 0
        dict←(⊃⎕RSI).⎕NEW ⎕THIS initial 
        :IF ~900⌶1 ⋄ dict.default←def ⋄ :Endif 
     :Else
        ⎕SIGNAL ⊂⎕DMX.(('EN' 11)('EM' ('∆DICT ',EM)) ('Message' Message))
     :EndTrap
    ∇
    
    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Constructors...
    ⍝ New1: "Constructs a dictionary and updates*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Alternatively, sets the default value."
    ⍝ Uses update/import, which will handle duplicate keys (the last value quietly wins), and so on.
    ⍝ *** See update for conventions for <initial>.
    ∇ new1 struct
      :Implements Constructor
      :Access Public
      :Trap 0
          importObjs struct      
          ⎕DF 'Dict:',SET_ID
      :Else  
          ⎕SIGNAL ⎕DMX.((⊂'EN' EN)('EM' EM) ('Message' Message))
      :EndTrap
    ∇

    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
       ⎕DF 'Dict:',SET_ID
    ∇
    ⍝ SET_ID: Every dictionary has a unique ID included in its display form (see new1, new0).)
    ⍝         Initial # set based on current day, hr, min, sec, ms when Dict class is first ⎕FIXed.
    ⍝ Returns ⍕ID, after incrementing by 1.
    ∇ idStr←SET_ID
      idStr ← ⍕ID ← ID_COMMON ← 2147483647 | ID_COMMON + 1
    ∇

    ∇ destroy
      :Implements Destructor
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)
    ⍝-------------------------------------------------------------------------------------------
    ⍝ keyIndex: "Using standard vector indexing and assignment, set and get the value for each key. 
    ⍝           New entries are created automatically"
    ⍝ SETTING values for each key
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING values for each key
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property default keyed keyIndex 
    :Access Public
        ∇ vals←get args;found;ix;shape;⎕TRAP
          ⎕TRAP←∆TRAP
          :If ⎕NULL≡⊃args.Indexers ⋄ vals←valuesF ⋄ :Return ⋄  :EndIf
          shape←⍴ix←keysF⍳⊃args.Indexers  
          :If ~0∊found←ix<≢keysF
              vals←valuesF[ix]                
          :ElseIf hasdefaultF
             vals← found \fillZero valuesF[found/ix]    ⍝ Insert slot(s) for values of new keys. See Note [Special Backslash]
              ((~found)/vals)←⊂defaultF                 ⍝ Add default values for slots just inserted.
              vals⍴⍨←shape                              ⍝ Ensure vals is scalar, if the input parm args.Indexers is.
          :Else
               THROW eHasNoDefault
          :EndIf
        ∇
        ∇ set args;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          keys←⊃args.Indexers ⋄ vals←args.NewValue
          importVecs keys vals
        ∇
    :EndProperty

 ⍝ valIndex, valIx: 
 ⍝    "Using standard vector indexing and assignment, get the keys for each value, parallel to keyIndex.
 ⍝     Since each many keys may have the same value, 
 ⍝     returns a list (vector) of 0 or more keys for each value sought.
 ⍝     ⍬ is returned for each MISSING value."
 ⍝     Setting is prohibited!
 ⍝ keys ← dict.valIndex[]         ⍝ Return keys for all values
    :Property keyed valIndex,valIx
    :Access Public
        ∇ keys←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          ix←{⎕NULL≡⍵: valuesF ⋄ ⍵}⊃args.Indexers
          keys←{k ⍬⊃⍨0=≢k←keysF/⍨valuesF≡¨⊂⍵}¨ix   ⍝ Ensure 0-length ⍬ when vals missing.
          keys⍴⍨←⍴ix     ⍝ Ensure scalar index means scalar is returned.
        ∇
    :EndProperty
    
    ⍝ dict.get      Retrieve values for keys ⍵ with optional default value ⍺ for each missing key
    ⍝ --------      (See also dict.get1)
    ⍝         dict.get keys   ⍝ -- all keys must exist or have a (class-basd) default
    ⍝ default dict.get keys   ⍝ -- keys which don't exist are given the (fn-specified) default
    ∇ vals←{def} get keys;d;nd;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1 
          vals←keyIndex[keys]
      :ELSE 
          nd←~d←defined keys
          vals← d \fillZero keyIndex[d/keys]  ⍝ See Note [Special Backslash] above
          (nd/vals)←⊂def
      :ENDIF
    ∇
    ⍝ dict.get1    Retrieve value for key ⍵ with optional default value ⍺
    ⍝ ---------   (See also dict.get AND dict[o1 o2 ...])
    ⍝         dict.get1 key   ⍝ -- the key must exist or have a default
    ⍝ default dict.get1 key   ⍝ -- if key doesn't exist, it's given the specified default
    ∇ val←{def} get1 key;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1  ⋄ def←⊢ ⋄ :ENDIF
      val←⊃def get ⊂key
    ∇

    ⍝ dict.set  --  Set keys ⍺ to values ⍵ OR set key value pairs: (k1:⍵11 v1:⍵12)(k2:⍵21 v2:⍵22)...
    ⍝ dict.import-  Set keys to values ⍵
    ⍝ --------      (See also dict.set1)
    ⍝ {vals}←keys dict.set values
    ⍝ {vals}←     dict.set (k v)(k v)...
    ⍝ {dict}←     dict.import keys values    
    ∇ {vals}←{keys} set vals;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ keys vals←↓⍉↑vals ⋄ :EndIf
      importVecs keys vals
    ∇
    ∇{dict}←import (keys vals);⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      importVecs keys vals
      dict←⎕THIS
    ∇

    ⍝ dict.set1  -- set single key ⍺ to value ⍵ OR set key value pair: (k1:⍵1 v1:⍵2)
    ⍝ ---------     (See also dict.set)
    ⍝ {val}←k1 dict.set1 v1    
    ⍝ {val}←   dict.set1 k1 v1    
    ∇ {val}←{key} set1 val;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ key val←val ⋄ :EndIf
      importVecs ,∘⊂¨key val
    ∇

    ⍝ dict.update ⍵:  
    ⍝ update data into dictionary and/or set default for values of missing keys.
    ⍝ Workhorse for adding objects to dictionaries: 
    ⍝           dictionaries, vectors of (keys values), and key-value pairs.
    ⍝ Determines the argument types and calls importVecs as needed. 
    ⍝   NOTE: Use dict.import to efficiently add a (key_vector value_vector) vector pair 
    ⍝         (e.g. one exported via dict1.export)
    ⍝ 
    ⍝ importObjs ⍵: Internal utility to be called from top-level routines."
    ⍝ update accepts either a SCALAR or VECTOR right argument ⍵.           
    ∇ {dict}←update initial;⎕TRAP
      :Access Public
      :TRAP 0 
          importObjs initial  
      :Else
          THROW ⎕DMX.EN ((⎕UCS 10),⎕DMX.Message)
      :EndTrap
      dict←⎕THIS
    ∇
    ⍝ importObjs objects: used only internally.
    ⍝ Used in initialization of ∆DICTs or via ⎕NEW Dict...
    ⍝ objects: 
    ⍝        (⍪keys vals [default]) OR (key1 val1)(key2 val2)(...) OR dictionary
    ⍝    OR  (key1 val1) dict2 (key3 val3) dict4...      ⍝ A mix of key-value pairs and dictionaries
    ⍝ Special case:
    ⍝        If a scalar is passed which is not a dictionary, 
    ⍝        it is assumed to be a default value instead.
    ⍝ Returns: NONE
    isDict←{9.2≠⎕NC⊂,'⍵':0 ⋄ baseclassF∊⊃⊃⎕CLASS ⍵} 
    ∇ importObjs objects;k;v;o 
      :If 0=≢objects                            ⍝ EMPTY?  NOP
      :Elseif 0=⍴⍴objects                       ⍝ SCALAR? FAST PATH
          defaultF hasdefaultF←(⊃objects) 1 
      :Elseif 2=⍴⍴objects                       ⍝ COLUMN VECTOR KEYVEC/VALUEVEC? 
          importMx objects                      ⍝ ... FAST PATH
      :Elseif 2∧.=≢¨objects                     ⍝ K-V PAIRS? FAST PATH
          importVecs ↓⍉↑objects 
      :Else   
          :For o :in objects⊣k←v←⍬ 
              :IF 2=⍴⍴o        ⋄ importMx o                      ⍝ MATRIX. Handle en masse
              :Elseif 2=≢o     ⋄ k v,←⊂¨o                        ⍝ K-V Pair. Collect 
              :Elseif 1≠≢o     ⋄ THROW eBadUpdate                ⍝ Not Scalar. Error.
              :Elseif isDict o ⋄ importVecs o.export             ⍝ Import Dictionary
              :Elseif 2∧.=≢¨o  ⋄ importVec ↓⍉↑o                  ⍝
              :Else            ⋄ defaultF hasdefaultF←(⊃o) 1     ⍝ Set Defaults 
              :Endif 
          :EndFor
          :IF ×≢k  ⋄ importVecs k v ⋄ :Endif
      :Endif 
    ∇

    ⍝ {keys}←importVecs (keyVec valVec) 
    ⍝ keyVec must be present, but may be 0-len list [call is then a nop].
    ⍝ From vectors of keys and values, keyVec valVec, 
    ⍝ updates instance vars keysF valuesF, then calls OPTIMIZE to be sure hashing enabled.
    ⍝ Returns: shy keys
    ∇ {k}←importVecs (k v)
          ;ix;kp;old;nk;nv;uniq     
      →0/⍨0=≢k                    ⍝      No keys/vals? Return now.
      ix←keysF⍳k                  ⍝ I.   Process existing (old) keys
      old←ix<≢keysF               ⍝      Update old keys in place w/ new vals;
      valuesF[old/ix]←old/v       ⍝      Duplicates? Keep only the last val for a given ix.
      →0/⍨~0∊old                  ⍝      All old? No more to do; shy return.
      nk nv←k v/¨⍨⊂~old           ⍝ II.  Process new keys (which may include duplicates)
      uniq←⍳⍨nk                   ⍝      For duplicate keys,... 
      nv[uniq]←nv                 ⍝      ... "accept" last (rightmost) value
      kp←⊂uniq=⍳≢nk               ⍝      Keep: Create and enclose mask...
      nk nv←kp/¨nk nv             ⍝      ... of those to keep.
      (keysF valuesF),← nk nv     ⍝ III. Update keys and values fields based on umask.
      OPTIMIZE                    ⍝      New entries: Update hash and shyly return.
    ∇
    ⍝ importMx: Imports ⍪keyvec valvec [default]
    importMx←importVecs{2=≢⍵: ⍵ ⋄ 3≠≢⍵: THROW eBadUpdate ⋄ defaultF hasdefaultF⊢←(2⊃⍵) 1⋄ 2↑⍵}∘,

    ⍝ copy:  "Creates a copy of an object including its current settings (by copying fields).
    ⍝         Uses ⊃⊃⎕CLASS in case the object is from a class derived from Dict (as a base class).
    ∇ {newDict}←copy
      :Access Public
      newDict←⎕NEW (⊃⊃⎕CLASS ⎕THIS) 
      newDict.import keysF valuesF
      :IF hasdefaultF ⋄ newDict.default←defaultF ⋄ :ENDIF 
    ∇

    ⍝ export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←export
      :Access Public
      k v←keysF valuesF
    ∇

    ⍝ items: "Returns ALL key-value pairs as a vector, one pair per vector element. ⍬ if none."
    :Property items,item 
    :Access Public
        ∇ r←get args
          :If 0=≢keysF ⋄ r←⍬
          :Else ⋄ r←↓⍉↑keysF valuesF
          :EndIf
        ∇
    :EndProperty

    ⍝ print/hprint: "Returns all the key-value pairs as a matrix, one pair per row/column."
    ⍝ disp/hdisp:   "Returns results of print/hprint formatted via dfns.disp (⎕SE.Dyalog.Utils.disp)"
    ⍝ If no items,   returns ⍬.
    :Property print,hprint,disp,hdisp
    :Access Public
    ∇ r←get args;show;disp 
      :If 0=≢keysF ⋄ r←⍬ ⋄ :Return ⋄ :EndIf
      disp←⎕SE.Dyalog.Utils.disp    
      r←↑keysF valuesF  
      :SELECT args.Name    
         :Case 'print'   ⋄ r←           ⍉r
         :Case 'disp'    ⋄ r← 0 1 disp  ⍉r 
         :Case 'hdisp'   ⋄ r← 0 1 disp   r  
         :Case 'hprint'  ⍝ r returned as is
      :EndSelect
    ∇
    :EndProperty

    ⍝ len:  "Returns the number of key-value pairs."
    :Property len 
    :Access Public
        ∇ r←get args
          r←≢keysF
        ∇
    :EndProperty

    ⍝ keys|key:  "Get Keys by Index."
    ⍝     "For efficiency, returns the keysF vector, rather than one index element
    ⍝      at a time. Keys may be retrieved, but not set.
    ⍝      In contrast, Values/Vals works element by element to allow direct updates (q.v.)."
    ⍝ k ← d.keys              returns all Keys in entry order
    ⍝ k ← d.keys[ix1 ix2...]  returns zero or more keys by index (user origin).
    :Property keys,key
    :Access Public
        ⍝ get: retrieves keys
        ∇ k←get args 
          k←keysF
        ∇
        ∇ set args
          THROW eKeyAlterAttempt 
        ∇
    :EndProperty

    ⍝ values,value, vals,val:
    ⍝   "Get or Set values by index, in active order (creation order, or, if sorted, sort order).
    ⍝    Indices are in caller ⎕IO (per APL).
    ⍝    Note: sets/retrieves element-by-element, as a Dyalog numbered property.
    :Property numbered values,value,vals,val  
    :Access Public
        ⍝ get: retrieves values, not keysF
        ∇ vals←get args;ix
          ix←⊃args.Indexers
          vals←valuesF[ix]     ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ⍝ set: sets Values, not keysF
        ∇ set args;newval;ix
          ix←⊃args.Indexers
          newval←args.NewValue
          valuesF[ix]←newval
        ∇
        ∇ r←shape
          r←⍴valuesF
        ∇
    :EndProperty

    ⍝ hasdefault,querydefault,default
    ⍝    "Sets or queries a default value for missing keys.
    ⍝     By default, hasdefault=0, so the initial Default ('') or previously set Default is ignored,
    ⍝     i.e. a VALUE ERROR is signalled. Setting hasdefault←1 will make the current Default available.
    ⍝     Setting Default to a new value always turns on hasdefault as well."
    ⍝                SETTING    GETTING
    ⍝ hasdefault        Y          Y
    ⍝ default           Y          Y
    ⍝ querydefault      N          Y
    ⍝
    ⍝ hasdefault:    "Sets the dictionary property ON (1) or OFF (0). If ON, activates current Default value.
    ⍝                 Alternatively, retrieves the current status (1 or 0)."
    ⍝ default:       "Sets the default value for use when retrieving missing values, setting hasdefault←1.
    ⍝                 Alternatively, retrieves the current default."
    ⍝ querydefault:  "Combines hasdefault and default in a single command, returning the current settings from
    ⍝                 hasdefault and Default as a single pair. querydefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property default,hasdefault,querydefault
    :Access Public
        ∇ r←get args
          :Select args.Name
          :Case 'default'      ⋄ :If ~hasdefaultF ⋄ THROW eHasNoDefaultD ⋄ :EndIf
                                 r←defaultF
          :Case 'hasdefault'   ⋄ r←hasdefaultF
          :Case 'querydefault' ⋄ r←hasdefaultF defaultF
          :EndSelect
        ∇
        ∇ set args
          :Select args.Name
          :Case 'default'
              defaultF hasdefaultF←args.NewValue 1
          :Case 'hasdefault'
              :If ~0 1∊⍨⊂args.NewValue ⋄ THROW eBadDefault ⋄ :EndIf
              hasdefaultF←⍬⍴args.NewValue   ⍝ defaultF unchanged...
          :Case 'querydefault'
              THROW eQueryDontSet
          :EndSelect
        ∇
    :EndProperty

    ⍝ inc, dec:
    ⍝    ⍺ inc/dec ⍵:  Adds (subtracts) ⍺ from values for keys ⍵
    ⍝      inc/dec ⍵:  Adds (subtracts) 1 from values for key ⍵
    ⍝    ⍺ must be conformable to ⍵ (same shape or scalar)
    ⍝    Processes keys left to right: If a key is repeated, increments accumulate.
    ⍝  Returns: Newest values (will be incremental, if a key is repeated).
    ⍝  NOTE: Forces a default value of 0, for undefined keys.
    ∇ {newvals}←{∆} inc keys;add2;⎕TRAP 
      :Access Public
      ⎕TRAP←∆TRAP
      add2← { nv←⍺+0 get ⍵ ⋄ nv⊣importVecs ⍵ nv }
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :TRAP 11 
          :IF (≢∪keys)=≢keys
            newvals←∆ add2 keys
          :Else 
            newvals←∆ add2¨⊂¨keys
          :Endif
      :Else
          THROW eBadInt
      :EndTrap 
    ∇

    ∇ {newval}←{∆} dec keys;⎕TRAP
      :Access Public
       ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :IF 0≠1↑0⍴∆ ⋄ THROW eBadInt ⋄ :ENDIF 
      newval←(-∆)inc keys
    ∇

    ⍝ defined: Returns 1 for each key found in the dictionary
    ∇ exists←defined keys
      :Access Public
      exists←(≢keysF)>keysF⍳keys
    ∇

    ⍝ del:  "Deletes key-value pairs from the dictionary for all keys found in a dictionary.
    ⍝        If ignore is 1, missing keys quietly return 0.
    ⍝        If ignore is 0 or omitted, missing keys signal a DOMAIN error (11)."
    ⍝ b ← {ignore←1} ⍵.del key1 key2...
    ⍝ Returns a vector of 1s and 0s: a 1 for each key kN deleted; else 0.
    ∇ {b}←{ignore} del keys;ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      b←(≢keysF)>ix←keysF⍳keys
    ⍝ (Unless ignore=1) Signal error if not all k-v pairs exist
      eDelKeyMissing THROW⍨ (0∊b)∧~ignore 
      diFast b/ix
    ∇

    ⍝ delbyindex | di:    "Deletes key-value pairs from the dict. by index. See del."
    ⍝     If ignore is 1, indices out of range quietly return 0.
    ⍝     If ignore is 0 or omitted, indicates out of range signal an INDEX ERROR (7).
    ⍝ b ← {ignore←1} ⍵.delbyindex ix1 ix2...
    ⍝ b ← (ignore←1} ⍵.di           ix1 ix2...
    ⍝
    ∇ {b}←{ignore} di ix;keys 
      :Access Public
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      :TRAP 0 
         b←ignore delbyindex ix
      :Else
         THROW 11 ⎕DMX.Message   
      :EndTrap
    ∇

    ∇ {b}←{ignore} delbyindex ix;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf    
      b←ix{⍵:0=0(≢keysF)⍸⍺ ⋄ 0⍴⍨≢⍺}×≢keysF
      eIndexRange THROW⍨ (0∊b)∧~ignore           ⍝ At least 1 index out of range                     
      diFast b/ix                                ⍝ Consider only those in index range
    ∇

    ⍝ diFast: [INTERNAL UTILITY] 
    ⍝ Delete items by ix, where ix (if non-null) in range of keysF.
    ∇ diFast ix;count;endblock;uix;∆
      → 0/⍨ 0=count←≢uix←∪ix                ⍝ Return now if no indices refer to active keys.
      endblock←(¯1+≢keysF)-⍳count           ⍝ All keys contiguous at end?
      :IF  ∧/uix∊endblock                   ⍝ Fast path: delete contiguous keys as a block
          keysF↓⍨←-count ⋄ valuesF↓⍨←-count ⍝ No need to OPTIMIZE hash.
      :Else  
          ∆←1⍴⍨≢keysF ⋄ ∆[uix]←0            ⍝ ∆: Delete items with indices in <ix>
          keysF←∆/keysF ⋄ valuesF←∆/valuesF 
          OPTIMIZE 
      :EndIf 
    ∇

    ⍝ clear:  "Clears the entire dictionary (i.e. deletes every key-value pair)
    ⍝          and returns the dictionary."
    ∇ {dict}←clear
      :Access Public
      keysF←valuesF←⍬                            
      dict←⎕THIS ⋄ OPTIMIZE
    ∇

    ⍝ popitems:  "Removes and returns last (|n) items (pairs) from dictionary as if a LIFO stack.
    ⍝             Efficiently updates keysF to preserve hash status. 
    ⍝             If there are insufficient pairs left, returns only what is left (potentially none)"
    ⍝ kv1 kv2... ← d.pop count   where count is a non-negative number.
    ⍝     If count≥≢keysF, all items will be popped (and the dictionary will have no entries).
    ⍝     If count<0, it will be treated as |count.
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove |n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs. 
    ⍝ If no pairs, returns simple ⍬.

    ∇ {poppedItems}←popitems count ;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      count←-(≢keysF)⌊|count                               ⍝ Treat ∇¯5 as if ∇5 
      :If count=0                                          ⍝ Fast exit if nothing to pop
         poppedItems←⍬                           
      :Else
        poppedItems←↓⍉↑count↑¨keysF valuesF
        keysF↓⍨←count ⋄ valuesF↓⍨←count
      :ENDIF 
    ∇

    ∇{vals}←{default}pop keys;⎕TRAP 
      :Access Public 
      ⎕TRAP←∆TRAP
      :If 900⌶1  
         vals←get keys ⋄ 0 del keys 
      :Else 
         vals←default get keys ⋄ 1 del keys
      :Endif 
    ∇

    ⍝ sort/sorta (ascending),
    ⍝ sortd (descending)
    ⍝ Descr:
    ⍝    "Sort a dictionary IN PLACE:
    ⍝     ∘ Sort keys in (Sort/A: ascending (D: descending) 
    ⍝     ∘ Keys may be any array in the domain of ⍋, using TAO (total array ordering).
    ⍝ Returns: the dict
    ⍝
    :Property sort,sorta,sortd
    :Access Public
        ∇ dict←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If 'd'=¯1↑args.Name   ⍝ sortd
              ix←⊂⍒keysF
          :Else                  ⍝ sorta, sort
              ix←⊂⍋keysF
          :EndIf
          keysF   ⌷⍨←ix  
          valuesF ⌷⍨←ix 
          OPTIMIZE ⋄ dict←⎕THIS
        ∇
    :EndProperty

  ⍝ reorder:  
  ⍝     "Reorder a dictionary in place based on the new indices specified. 
  ⍝      All the indices of the dictionary must be specified exactly once in the caller's ⎕IO."
  ⍝ Allows sorting externally by keys, values, or whatever, without losing any keys...
    ∇{dict}←reorder ix
     :Access Public
      ix-←(⊃⎕RSI).⎕IO      ⍝ Adjust indices to reflect caller's index origin, if needbe
      (ix[⍋ix]≢⍳≢keysF) THROW 11 'Dict.reorder: at least one index value is out of range, missing, or duplicated.'
      keysF ⌷⍨←⊂ix ⋄ valuesF ⌷⍨←⊂ix 
      OPTIMIZE ⋄ dict←⎕THIS
    ∇

  ⍝ namespace: See documentation. Enables a namespace that 
  ⍝            replicates the dictionaries keys as variable names and
  ⍝            whose values, if changed, are reflected on the fly in the dictionary itself.
    ∇ns←namespace
      :Access Public
      ns←⎕NS ''   
      :TRAP 0  ⍝ 4 if rank error
        ⍝ If it's not a valid name, use ⎕JSON mangling (may not be useful). If it is valid, mangle is a NOP.
          :IF ×≢keysF ⋄ (mangleJ¨ keysF) ns.{⍎⍺,'←⍵'}¨valuesF  ⋄ :ENDIF
          ns.⎕FX '⍝ACTIVATE⍝' ⎕R '' ⊣ ⎕NR '__namespaceTrigger__'
      :ELSE
          THROW eKeyBadName
      :ENDTRAP
    ∇

    ⍝ __namespaceTrigger__: helper for d.namespace above ONLY.
    ⍝ Don't enable trigger here: only in subsidiary namespaces!
    ∇__namespaceTrigger__ args;eTrigger;unmangleJ
      ⍝ACTIVATE⍝ :Implements Trigger *             ⍝ Don't touch this line!
      ⍝ Use ⎕JSON unmangling for argument name!
      unmangleJ←1∘(7162⌶)                          ⍝ Convert APL key strings to JSON format
      :TRAP 0
          (unmangleJ args.Name) ##.set1 (⍎args.Name)
      :Else  ⍝ Use ⎕SIGNAL, since used in user namespace, not DictClass.
          eTrigger←11 'Dict.namespace: Unable to update key-value pair from namespace variable' 
          ⎕SIGNAL⍨/eTrigger
      :ENDTrap
    ∇

  ⍝ Dict.help/Help/HELP  - Display help documentation window.
    ∇ {h}←help;ln 
      :Access Public Shared
      ⍝ Pick up only ⍝⍝ comments!
      :Trap 0 1000  
           ⍝ h←⊃⎕NGET '/Users/petermsiegel/MyDyalogLibrary/pmslibrary/docs/Dict.help' 0
           h←⎕SRC ⎕THIS 
           h←3↓¨h/⍨(⊂'⍝⍝')≡¨2↑¨h 
           h←⎕PW↑[1]↑h ⋄ ⎕ED&'h' ⋄ ⎕DL 60
      :Else ⋄ ⎕SIGNAL/'Dict.help: No help available' 911
      :EndTrap
    ∇
    _←⎕FX 'help'⎕R'Help'⊣⎕NR 'help'
    _←⎕FX 'help'⎕R'HELP'⊣⎕NR 'help'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ INTERNAL UTILITIES
    ⍝ ----------------------------------------------------------------------------------------

    ⍝ Note [Special Backslash]
    ⍝ fillZero: an operator that uses 0 as its fill item, rather than the first element.
    ⍝    out ← bool \fillZero in          
            ⍝ We use expand in providing DEFAULT values for as yet unseen keys; it requires that ⍵ have a fill value.
            ⍝ valuesF[...] may include namespaces or other items w/o a fill value. 
            ⍝ If the first item in  ⍵, during an expand operation ⍺\⍵, contains such an item, a NONCE ERROR occurs,
            ⍝ We resolve this using the equivalent of: 
            ⍝       fillZero←{fi←0 ⋄ 1↓(1,⍺)⍺⍺ fi,⍵}, where fi is the fill item, ⍵ a vector, ⍺ a selection suitable for ⍺\⍵
            ⍝ effectively replacing \ with \fill0 where required as in:
            ⍝       vals←found \fillZero valuesF[found/ix]  
      fillZero←{fi←0 ⋄ 1↓(1,⍺)⍺⍺ fi,⍵}
      
    ∇ {status}←OPTIMIZE 
    ⍝ Set keysF to be hashed whenever keysF changed-- added or deleted. (If valuesF changes, this is never called).
    ⍝ While it is usually of no benefit to hash small key vectors of simple integers or characters,
    ⍝ it takes about 25% longer to check datatypes and ~15% simply to check first whether keysF is already hashed. 
    ⍝ So we just hash keysF whenever it changes!
      keysF←1500⌶keysF                                                               
    ∇
    
    ⍝ THROW:    [cond:1] THROW (en message), where en and message are ⎕DMX fields EN and Message.
    ⍝          Field EM is determined by EN.
    ⍝          If cond is omitted or 1, returns an alternate-format error msg suitable for ⎕SIGNAL.
    ⍝          If cond is 0, returns null.
    THROW←⎕SIGNAL {⍺←1 ⋄ e m←⍵ ⋄ ⍺: ⊂('EN' e)('Message'  m) ⋄ ⍬}
    
⍝⍝
⍝⍝ =========================================================================================
⍝⍝ =========================================================================================
⍝⍝    ∆JDICT function   
⍝⍝ =====================
⍝⍝  {minorOpt} ∆JDICT json
⍝⍝   Converts between a JSON string or APL ns equivalent and a DictClass dictionary (or vice versa).
⍝⍝   Assumes that JSON null is mapped onto APL ⎕NULL and vice versa: minorOpt ('Null'⎕NULL).
⍝⍝   The user can select either compact or non-compact JSON output; both are valid on input.
⍝⍝ 
⍝⍝  I. If argument <json> is a string or namespace,  
⍝⍝    ∘ Convert a Json object string or its equivalent APL namespace
⍝⍝      to dictionary. 
⍝⍝    ∘ Keys will be in JSON (non-mangled) format.
⍝⍝    ∘ If the JSON string refers to an array with multiple items 
⍝⍝      or if multiple namespaces are presented, returns a vector of dictionaries;
⍝⍝      Otherwise, returns a single dictionary.
⍝⍝    ∘ If in namespace form, only objects of classes 2.1 and 9.1 are evaluated,
⍝⍝      as expected for JSON.
⍝⍝    ∘ Here, the {minorOpt} parameter is ignored.
⍝⍝ 
⍝⍝  II. If argument <json> is a dictionary,  
⍝⍝  A...if minorOpt is 0 (returns compact JSON); if 1 (returns non-compact JSON)
⍝⍝  B...and if minorOpt is 2 (returns namespace) 
⍝⍝    ∘ Names are mangled via JSON (APL) protocols, so APL variable names are valid.
⍝⍝  
⍝⍝  NOTE: inverses are only partial, since all JSON keys MUST be strings and
⍝⍝        values must be those that ⎕JSON can deal with. Otherwise an error occurs.
⍝⍝  EXAMPLE: 
⍝⍝      d←∆JDICT '{"123": 5, "⍴5":1}'
⍝⍝      d.table
⍝⍝  123  5
⍝⍝  ⍴5   1
⍝⍝       n←2 ∆JDICT d
⍝⍝       )cs n
⍝⍝  #.[Namespace]
⍝⍝       )vars
⍝⍝  ⍙123    ⍙⍙9076⍙5      ⍝ From keys: "123"   "⍴5"   
⍝⍝      ⍙123
⍝⍝  5
⍝⍝      ⍙⍙9076⍙5
⍝⍝  1
⍝⍝ ---------------------------------------------------------------
⍝⍝
⍝⍝ ⍝ Simple JSON test case! Generates 3 top-level dictionaries.
⍝⍝ ⍝ Use DictClass object DictClass.JSONsample
⍝⍝  
⍝⍝       ⎕←DictClass.JSONsample
⍝⍝ [{"id":"001", "name":"John Smith", "phone":"999-1212"},{"id":"002", "name":"Fred Flintstone", 
⍝⍝   "phone":"254-5000"},{"id":"003","name":"Jack Sprat","phone":"NONE"}]
⍝⍝      ⎕←(d e f)← ∆JDICT  ⎕←DictClass.JSONsample
⍝⍝ Dict[]  Dict[]  Dict[]         ⍝ 3 dictionaries
⍝⍝      1 ∆JDICT d e f
⍝⍝ [                             
⍝⍝   {                           
⍝⍝     "id": "001",              
⍝⍝     "name": "John Smith",     
⍝⍝     "phone": "999-1212"       
⍝⍝   },                          
⍝⍝   {                           
⍝⍝     "id": "002",              
⍝⍝     "name": "Fred Flintstone",
⍝⍝     "phone": "254-5000"       
⍝⍝   },                          
⍝⍝   {                           
⍝⍝     "id": "003",              
⍝⍝     "name": "Jack Sprat",     
⍝⍝     "phone": "NONE"           
⍝⍝   }                           
⍝⍝ ]  
⍝⍝     (d e f).table            ⍝   Show the contents of the 3 dictionaries
⍝⍝  id     001           id     002                id     003         
⍝⍝  name   John Smith    name   Fred Flintstone    name   Jack Sprat  
⍝⍝  phone  999-1212      phone  254-5000           phone  NONE        
⍝⍝
    :Field Public  Shared JSONsample←'[{"id":"001", "name":"John Smith", "phone":"999-1212"},{"id":"002", "name":"Fred Flintstone", "phone":"254-5000"},{"id":"003","name":"Jack Sprat","phone":"NONE"}]'

    ∇ result ← {minorOpt} ∆JDICT json
      ;TRAP;THROW11;keys;majorOpt;mangleJ;unmangleJ;ns;optNull;vals;⎕IO;⎕TRAP   
      :Access Public Shared
      unmangleJ←                 1∘(7162⌶)   ⍝ Convert APL key strings to JSON format
      mangleJ←                  (0∘(7162⌶))∘⍕ 
      TRAP←0 ⋄ ⎕IO←0 ⋄ optNull←('Null'⎕NULL)
      ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(((''∆JDICT: '',EM),Message,⍨'': ''/⍨0≠≢Message) EN)'
      THROW11←⎕SIGNAL {⍺←1 ⋄ ⍺: ⊂('EN' 11)('Message'  ⍵) ⋄ ⍬}
    ⍝ Major opt (majorOpt) automatically set based on type of <json>.
    ⍝ If several namespaces or strings OR converts from string to namespaces, majorOpt=2.
    ⍝ If majorOpt=0, minor option is checked; otherwise ignored.
      minorOpt←{⍵: 0 ⋄ minorOpt} 900⌶1    
      ns majorOpt←json{
        badStrE←'At least one invalid ⎕JSON input string found in arg ⍵.'  
        badObjE←'At least one object in arg ⍵ not a JSON string or compatible APL namespace or dictionary.' 
        0::  THROW11 badStrE
        ⍵=2.1: json{
          ⍵: ns (1+1<≢ns) ⊣ ns←⎕JSON ⍠optNull ⊣⍺ 
          1<≢⍺: ⍺ 2 
          THROW11 badObjE
        }0=80|⎕DR ⍺
        ⍵=9.1: ⍺ 1
        ⍵=9.2: ⎕NULL 0    ⍝ Object is a class instance; expected to be a dict.
        THROW11 badObjE
      }⎕NC⊂'json'

      :Select majorOpt
      :Case 2      ⍝ several objects: json strings, namespaces, or dicts
          result←minorOpt (⍎⊃⎕XSI)¨ns       ⍝ Call ∆JDICT on each object...
      :Case 1      ⍝ ns from ⎕JSON obj or directly from user
           dict←∆DICT ⍬
          ns dict∘{
              TRAP:: THROW11 'Valid JSON object ⍵ could not be converted to dictionary.' 
                ns dict←⍺ ⋄ itemA itemJ←⍵ (unmangleJ ⍵) ⋄ val←ns⍎itemA
              2=ns.⎕NC itemA:_←itemJ dict.set1 val
                dict2←∆DICT ⍬ ⋄ ns2←val
                _←itemJ dict.set1 dict2
              1:_←ns2 dict2∘∇¨ns2.⎕NL-2.1 9.1
          }¨ns.⎕NL-2.1 9.1
          result←dict  ⍝ Return a single dictionary
      :Else           ⍝ User passed a dictionary to convert
          (~minorOpt∊0 1 2) THROW11 'Option ⍺ was invalid: Must be 0, 1, 2.'  
          scan←{
              isDict←{9.2≠⎕NC⊂,'⍵':0 ⋄ ⎕THIS∊⊃⊃⎕CLASS ⍵} 
              ns←⍺⍺ ⋄ k v←⍺ ⍵
              ~isDict v: _←k ns.{⍎⍺,'←⍵'}  v
              _←k ns.{⍎⍺,'←⍵'} ns2←ns.⎕NS ''
              1: ⍬⊣(mangleJ¨ v.keys)(ns2 ∇∇)¨v.vals
          }
          dict←json
          :TRAP TRAP 
              ns←⎕NS ''
              (mangleJ¨ dict.keys) (ns scan)¨dict.vals
          :Else 
              THROW11 'Dictionary ⍵ could not be converted to ⎕JSON.' 
          :EndTrap
        ⍝ Use a compact ⎕JSON format if minorOpt is 0.
        ⍝ minorOpt∊0 1: result is a  JSON string 
        ⍝ minorOpt=2:   result is a namespace.
          result ← minorOpt{⍺=2: ⍵ ⋄ ⎕JSON ⍠ optNull('Compact' (⍺=0))⊣⍵ }ns
      :EndSelect 
    ∇
     

     ∇{list}←EXPORT_FUNCTIONS list;fn;ok
      actual←⍬
      :FOR fn :IN list
          ok←##.⎕FX '⎕THIS\b' ⎕R (⍕⎕THIS)⊣⎕NR fn  
          :IF 0=1↑0⍴ok
              ⎕←'EXPORT_GROUP: Unable to export fn "',fn,'". Error in ',fn,' line',ok
          :ENDIF
      :EndFor
      ∇
      EXPORT_FUNCTIONS EXPORT_LIST

⍝⍝ DictClass: A fast, ordered, and simple dictionary for general use.
⍝⍝            A dictionary is a collection of ITEMS (or pairs), each consisting of 
⍝⍝            one key and one value, each an arbitrary shape and  
⍝⍝            in nameclass 2 or 9 (value or namespace-related).
⍝⍝
⍝⍝ ∆DICT:     Primary function for creating new dictionaries.
⍝⍝            Documented immediately below.
⍝⍝ ∆JDICT:    Convert between dictionaries and {⎕JSON strings and/or ⎕JSON-compatible namespaces}.
⍝⍝            Documented later.
⍝⍝
⍝⍝ ∆DICT: Creating a dict, initializing items (key-value pairs), setting the default for missing values.
⍝⍝ TYPE       CODE                          ITEMS                                 DEFAULT VALUE
⍝⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝⍝ empty      a←∆DICT ⍬                     ⍝ None                                none
⍝⍝ items      b←∆DICT (1 10)(2 20)(3 30)    ⍝ (1 10)(2 20)(3 30)                  none
⍝⍝ items+     c←0 ∆DICT (1 10)(2 20)(3 30)  ⍝ (1 10)(2 20)(3 30)                  0
⍝⍝ lists+     d←⍬ ∆DICT ⍪(1 2 3)(10 20 30)  ⍝ (1 10)(2 20)(3 30)                  ⍬ (numeric null)
⍝⍝ dict       e←∆DICT d (4 40)              ⍝ (1 10)(2 20)(3 30)  (4 40)          none
⍝⍝ 
⍝X Dict:      A utility fn that returns the full name of the dictionary class, often #.DictClass.
⍝X            To enable, put #.DictClass in your ⎕PATH.
⍝X            d←⎕NEW Dict            ⍝ Create a new, empty dictionary with no default values.
⍝X            d←⎕NEW Dict (struct)   ⍝ Initialize dictionary with same call as for ∆DICT or d.update.
⍝⍝ Hashes keys for efficiently searching and updating items in large dictionaries.
⍝⍝ For HELP information, call 'dict.HELP'.
⍝⍝
⍝⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝⍝ ---------------------------------------------------
⍝⍝    Quick List of ∆DICT calls and methods (abridged)
⍝⍝ ---------------------------------------------------
⍝⍝    [default]: An optional default for missing keys of most any value or shape.
⍝⍝    kN, a key (of most any value); vN, a value of most any value;  iN (an index, ⎕IO dependent).
⍝⍝    keys, a list of keys; vals, a list of values; indices, a list of indices (integer positions, per ⎕IO)
⍝⍝ CREATE
⍝⍝    d        ← [default] ∆DICT ⍬                        ⍝ Create empty dictionary
⍝⍝    d        ← [default] ∆DICT (k1 v1)(k2 v2)...        ⍝ Create dict with initial key-value pairs.
⍝⍝    d        ← [default] ∆DICT ⍪keys vals               ⍝ Create dict with initial keys in keylist and values in valuelist
⍝⍝ GET
⍝⍝    v1 v2 v3 ←           d[k1 k2 k3]                    ⍝ Get value list by key list
⍝⍝    v1       ← [default] d.get1 k1                      ⍝ Get a value disclosed by key
⍝⍝    v1 v2 v3 ← [default] d.get  keys                    ⍝ Get value list by key list, else default
⍝⍝    keys vals ←          d.export                       ⍝ Get key list followed by value list
⍝⍝    keys     ←           d.keys                         ⍝ Get all keys in active order
⍝⍝    k1 k2 k3 ←           d.keys[indices]                ⍝ Get keys by index (position in active key order)
⍝⍝    vals     ←           d.vals                         ⍝ Get all values in active (key) order
⍝⍝    v1 v2 v3 ←           d.vals[indices]                ⍝ Get values by index (position in active key order)
⍝⍝    (k1 v1)...        ←  d.items                        ⍝ Get all items (key-val pairs) in active order
⍝⍝    (k1 v1)(k2 v2)... ←  d.items[indices]               ⍝ Get all items in active (key) order
⍝⍝ SET  
⍝⍝                   d[keys] ←  vals                      ⍝ Set values for arbitrary keys
⍝⍝                   k1 d.set1 v1                         ⍝ Set value for one key
⍝⍝                   keys d.set  vals                     ⍝ Set values for keys
⍝⍝                   d.import keys vals                   ⍝ Set values for arbitrary keys
⍝⍝                   d.update (k1 v1)(k2 v2)(k3 v3)...    ⍝ Set key-value pairs, new or old
⍝⍝                   d.update dict1 (k1 v1) dict2 (k2 v2) ⍝ Add dictionaries and key-value pairs to dict <d>
⍝⍝                   d.sort                               ⍝ Set active order, sorting by ascending keys 
⍝⍝                   d.sortd                              ⍝ Set active order, sorting by descending keys
⍝⍝ STATUS
⍝⍝    len      ←     d.len                                ⍝ Return # of items
⍝⍝    b1 b2 b3 ←     d.defined keys                       ⍝ Return 1 for each key in list that exists
⍝⍝                   d.print                              ⍝ Show (⎕←) keys, values by columns  
⍝⍝                   d.hprint                             ⍝ Show keys, values by rows (⍪d.print)
⍝⍝                   d.disp                               ⍝ Print by columns via dfns disp (variant of display) 
⍝⍝                   d.hdisp                              ⍝ Print by rows via dfns disp
⍝⍝ DELETE
⍝⍝    b1 b2 b3 ←  [ignore←0] d.del keys                   ⍝ Delete items by specific key
⍝⍝    b1 b2 b3 ←  [ignore←0] d.delbyindex indices         ⍝ Delete items by specific index
⍝⍝ INC/DEC
⍝⍝    n1 n2 n3 ←  [incr←1] d.inc keys                     ⍝ Increment values for specific keys
⍝⍝    n1 n2 n3 ←  [decr←1] d.dec keys                     ⍝ Decrement values for specific keys
⍝⍝ POP
⍝⍝    (k1 v1)(k2 v2)... ←  d.popitem count                ⍝ Remove/return <count> items from end of dictionary.
⍝⍝    vals  ←              d.pop keys                     ⍝ Remove/return values for specific keys from dictionary.
⍝⍝ MISC
⍝⍝                  ns  ←  d.namespace                    ⍝ Create a namespace with dictionary values, 
⍝⍝                                                        ⍝ whose changes are reflected back in the dictionary.
⍝⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝⍝ --------------------------
⍝⍝    CREATION
⍝⍝ --------------------------
⍝⍝ d← ∆DICT ⍬
⍝⍝    Creates a dictionary <d> with no items and no default. Items may be added via d[k1 k2...]←v1 v2...
⍝⍝    A default value may be added via d.default← <any object>.
⍝⍝
⍝⍝ d← [default] ∆DICT objs
⍝⍝    Creates dictionary <d> with optional default <default> and calls 
⍝⍝       d.update objs   ⍝ See below
⍝⍝    to set keys and values from key-value pairs, (keys values) vectors, and dictionaries.
⍝⍝
⍝⍝ d←∆DICT ⊂default      OR    d←default ∆DICT ⍬
⍝⍝    default must be a simple scalar, like 5, or it must be enclosed.
⍝⍝        e.g. ∆DICT 10         creates an empty dictionary with default value 10.
⍝⍝             ∆DICT ⊂⍬         creates an empty dictionary with default value ⍬ (not ⊂⍬).
⍝⍝             ∆DICT ⊂'Missing' creates an empty dictionary with default value 'Missing'.
⍝⍝
⍝⍝ newDict ← d.copy             ⍝ Make a copy of dictionary <d> as <newDict>, including defaults.
⍝⍝
⍝⍝ --------------------------------
⍝⍝    SETTING/GETTING ITEMS BY KEY
⍝⍝ --------------------------------
⍝⍝ d[⊂k1] or d[k1 k2...]
⍝⍝    Return a value for each key specified. Raises an error any key is not in the dictionary, 
⍝⍝    unless a default is specified.
⍝⍝    See also get, get1 
⍝⍝
⍝⍝ d[⊂k1] ← (⊂v1) OR d[k1 k2...]←v1 v2 ...
⍝⍝     Assign a value to each key specified, new or existing.
⍝⍝
⍝⍝ -----------------------------------------------------------------------------
⍝⍝     GETTING (LISTING) OF ALL KEYS / KEYS BY INDEX OR VALUE (REVERSE LOOK-UP)
⍝⍝ -----------------------------------------------------------------------------
⍝⍝ keys ← d.keys                     [alias: key]
⍝⍝     Return a list of all the keys used in the dictionary d.
⍝⍝
⍝⍝ keys ← d.keys[indices]            [alias: key]
⍝⍝     Return a list of keys by numeric indices i1 i2 ...
⍝⍝
⍝⍝ keys  ←  d.valIndex[vals]  OR  d.valIx[vals]
⍝⍝ keys  ←  d.valIndex[]  OR  d.valIx[]
⍝⍝ "Return lists of keys indexed by values <vals>, as if a 'reverse' lookup." 
⍝⍝ "Treating values as indices, find all keys with given values, if any.
⍝⍝  Returns a list of 0 or more keys for each value sought; ⍬ is returned for each MISSING value.
⍝⍝  Unlike dict.keyIndex keys, aka dict[keys], dict.valIndex[] may return many keys for each value." 
⍝⍝  If an index expression is elided,
⍝⍝       keys←d.valIndex[] or keys←d.valIx[],
⍝⍝  it is treated as requesting ALL values:
⍝⍝       keys←d.valIndex[d.values],
⍝⍝  returning a keylist for each value in d.values (which need not be unique).
⍝⍝  (These need not be unique; for only 1 copy of each keylist, do: ukeys←∪d.valIx[]).
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    SETTING/GETTING ALL VALUES / VALUES BY INDEX
⍝⍝ ------------------------------------------------
⍝⍝ vals ← d.values                     [alias: value, vals, val]
⍝⍝     Returns the list of values  in entry order for  all items; suitable for iteration
⍝⍝         :FOR v :in d.values ...
⍝⍝
⍝⍝ vals ← d.values[indices]            [aliases as above]
⍝⍝     Returns a list of item values by numeric indices i1 i2 ...
⍝⍝
⍝⍝ d.values[indices]←newvals           [aliases as above]
⍝⍝     Sets new values <newvals> for existing items by indices.
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    COMMON MISCELLANEOUS METHODS
⍝⍝ ------------------------------------------------
⍝⍝ d2 ← d.copy
⍝⍝     Return a shallow copy of the dictionary d, including its defaults
⍝⍝
⍝⍝ bool ← d.defined (⊂k1) OR d.defined k1 k2 ...
⍝⍝     Return 1 for each key that is defined (i.e. is in the dictionary)
⍝⍝
⍝⍝ nitems ← d.len  
⍝⍝     Return the number of items in the dictionary d.
⍝⍝
⍝⍝ bool ← [ignore←0] d.del (⊂k1) OR d.del k1 k2 ...
⍝⍝     Remove keys from d.
⍝⍝     Ignore=0: Shyly returns 1 for each key; signals an error of any key is not in the dictionary
⍝⍝     Ignore=1: Shyly returns 1 for each key found, 0 otherwise.
⍝⍝     Efficient if the items to delete are contiguous at the end of the dictionary
⍝⍝
⍝⍝ bool ← [ignore←0] d.delbyindex i1 i2 ...               
⍝⍝ bool ← [ignore←0] d.di i1 i2 ...              ⍝ Alias to delbyindex
⍝⍝     Removes items from d by indices i1 i2 .... 
⍝      Ignore=0: Returns 1 for each item removed. Signals an error if any item does not exist.
⍝⍝     Ignore=1: Returns 1 for each item removed; else 0.
⍝⍝     Efficient if the items to delete are contiguous at the end of the dictionary
⍝⍝
⍝⍝ d.clear
⍝⍝     Remove all items from the dictionary.
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    DEALING WITH VALUE DEFAULTS
⍝⍝ ------------------------------------------------
⍝⍝ d←[DEFAULT] ∆DICT objs
⍝⍝   Set DEFAULT values at creation (no default is created if objs is null)
⍝⍝
⍝⍝ d.default←value
⍝⍝     Sets a default value for missing keys. Also sets d.hasdefault←1
⍝⍝
⍝⍝ d.hasdefault←[1 | 0]
⍝⍝     Activates (1) or deactivates (0) the current default.
⍝⍝     ∘ Initially, by default:  hasdefault←0  and default←'' 
⍝⍝     ∘ If set to 0, referencing new entries with missing keys cause a VALUE ERROR to be signalled. 
⍝⍝     ∘ Setting hasdefault←0 does not delete any existing default; 
⍝⍝       it is simply inaccessible until hasdefault←1.
⍝⍝
⍝⍝ d.querydefault
⍝⍝      Returns a vector containing the current default and 1, if defined; else ('' 0)
⍝⍝
⍝⍝ vals ← [default] d.get  k1 k2 ...
⍝⍝ val  ← [default] d.get1 k1
⍝⍝     Return the value for keys in the dictionary, else default. 
⍝⍝     If <default> is omitted and a key is not found, returns the existing default.
⍝⍝
⍝⍝ (k1 k2 ... d.set v1 v2) ... OR (d.set1 (k1 v1)(k2 v2)...)
⍝⍝ (k1 d.set1 v1) OR (d.set1 k1 v1)
⍝⍝     Set one or more items either with 
⍝⍝          a keylist and valuelist: k1 k2 ... ∇ v1 v2 ...
⍝⍝     or as
⍝⍝          key-value pairs: (k1 v1)(k2 v2)...
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    BULK LOADING OF DICTIONARIES
⍝⍝ ------------------------------------------------
⍝⍝ d.update  [obj1 | obj2 | obj3 | ⊂default] [obj1 | obj2 | obj3 | ⊂default] ...
⍝⍝    For dictionary d, sets keys and values from objs of various types or set value defaults:
⍝⍝         ∘ ITEMS:     key-value pairs (each pair specified one at a time), 
⍝⍝         ∘ DICTS:     dictionaries (nameclass 9.2, with ⎕THIS∊⊃⊃⎕CLASS dict)
⍝⍝         ∘ LISTS:     key-value lists (keys in one vector, values in another), and 
⍝⍝         ∘ DEFAULTS:  defaults (must be a scalar or namespace-class, 
⍝⍝                      as long as not a Dict
⍝⍝    Any defaults are not loaded.
⍝⍝    obj1:  (key1 val1)(key2 val2)...
⍝⍝           objects passed as key-value pairs; keys and vals may be of any type...
⍝⍝    obj2:  dict
⍝⍝           A dict is an existing instance (scalar) of a DictClass object.   
⍝⍝    obj3:  ⍪keys vals [default] 
⍝⍝           keys and values are each scalars, structured in table form (as a column matrix).
⍝⍝           The default, if present, may be any shape or nameclass.
⍝⍝    default: any APL object of any shape (as long as not a dict), but must be enclosed to be recognized. 
⍝⍝           Note: a default would normally be specified once. Those to the right take precedence.
⍝⍝           E.g.  5   OR   ⊂'John'   OR  (⊂2 3⍴⍳6)  OR  (⊂'')   OR  (⊂⍬)  
⍝⍝
⍝⍝ d ← d.import (k1 k2 ...) (v1 v2 ...)
⍝⍝     Set one or more items from a K-V LIST (⍵1 ⍵2)
⍝⍝         ⍵1: a vector of keys
⍝⍝         ⍵2: a vector of values.
⍝⍝     To set a single key-value pair (k1 v1), use e.g.:
⍝⍝         k1 d.set1 v1 
⍝⍝         d.import (,k1)(,v1)
⍝⍝
⍝⍝ keys vals ← d.export
⍝⍝     Returns a K-V LIST consisting of a vector of keys.
⍝⍝     Efficient way to export ITEMS from one dictionary to another:
⍝⍝          d2.import d1.export 
⍝⍝     Does not export defaults.
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    MANAGING ITEMS (K-V PAIRS)
⍝⍝ ------------------------------------------------
⍝⍝ items ← d.items [k1 k2 ...]
⍝⍝     Return a list of all OR the specified dictionary’s items ((key, value) pairs).  
⍝⍝
⍝⍝ items ← d.popitems n
⍝⍝     Shyly returns and deletes the n (n≥0) most-recently entered key-value pairs.
⍝⍝     This is done efficiently, so that the dictionary is not rehashed.
⍝⍝
⍝⍝ keys ← [default] d.pop key1 key2 ...
⍝⍝     Shyly returns the values for keys key1..., while deleting each found item.
⍝⍝     If default is NOT specified and there is no dictionary default, then
⍝⍝     if any key is not found, d.pop signals an error; otherwise,
⍝⍝     it returns the default for each missing item.
⍝⍝
⍝⍝ namespace ← d.namespace
⍝⍝     Creates a namespace whose names are the dictionary keys and the values are the dictionary values.
⍝⍝     Changes to <namespace> variables are reflected back to the dictionary as they are made.
⍝⍝   NOTE: variable names must be valid APL variable names to be useful.
⍝⍝       ∘ If not, we attempt to convert to variable names via ⎕JSON name mangling.  
⍝⍝         Numbers, in particular, will convert silently to mangled character strings.
⍝⍝         E.g. APL 0.03811950614 ends up as name '⍙0⍙46⍙03811950614'.
⍝⍝       ∘ If any name cannot be converted, an error will be signalled.
⍝⍝       ∘ Once the namespace is created, changes to the dictionary will NOT be reflected
⍝⍝         to it; i.e. the tracking (via TRIGGER) is from namespace to the parent dictionary only.

⍝⍝ ------------------------------------------------
⍝⍝    COUNTING OBJECTS AS KEYS
⍝⍝ ------------------------------------------------
⍝⍝ nums ←  [amount ← 1] d.inc k1 k2 ...
⍝⍝     Increments the values of keys by <amount←1>. If undefined and no default is set, 0 is assumed.
⍝⍝     If any referenced key's value is defined and non-numeric, an error is signalled.
⍝⍝
⍝⍝ nums ← [amount] d.dec k1 k2 ...
⍝⍝      Identical to d.inc (above) except decrements the values by <amount←1>.
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    SORTING KEYS
⍝⍝ ------------------------------------------------
⍝⍝ d ← d.sort OR d.sorta
⍝⍝     Sort a dictionary in place in ascending order by keys, returning the dictionary
⍝⍝
⍝⍝ d ← d.sortd
⍝⍝     Sort a dictionary in place in descending order by keys, returning the dictionary 
⍝⍝
⍝⍝ d ← d.reorder indices
⍝⍝     Sort a dictionary in place in order by indices.
⍝⍝     Indices depend on ⎕IO in the caller environment.
⍝⍝     All indices of <d> must be present w/o duplication:
⍝⍝           indices[⍋indices] ≡ ⍳d.len
⍝⍝     Example: Equivalent of d.sortd; sort dictionary by keys
⍝⍝           d.reorder ⍋d.keys
⍝⍝     Example: Sort dictionary by values
⍝⍝           d.reorder ⍋d.values
⍝⍝     Example: Make a copy of <d>, but sorted in reverse order by values:
⍝⍝           d_prime ← d.copy.reorder ⍋d.values
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    Fancy Example
⍝⍝ ------------------------------------------------
⍝⍝ Reorganize a dictionary ordered by vals in descending order, rather than original entry or keys
⍝⍝      OK       a←a.copy.clear.update a.items[⍒a.vals]
⍝⍝      BETTER   a.reorder ⍒a.vals
⍝⍝ ------------------------------------------------
⍝⍝    [NOTES]
⍝⍝ ------------------------------------------------
⍝⍝ Dictionaries are ORDERED: they preserve insertion order unless items are sorted or deleted. 
⍝⍝ ∘ Updating an item's key does not affect its order. 
⍝⍝ ∘ New keys are always added at the end, in the last positions in order, so updates are fast.
⍝⍝ ∘ Existing items are updated in place, so updates are fast.
⍝⍝ ∘ Getting items by key or index is quite fast, as is checking if they are defined. 
⍝⍝ ∘ To force an  existing item to the last position in order, 
⍝⍝   it must be deleted and re-entered.
⍝⍝
⍝⍝ Dictionaries are hashed according to their keys (using APL hashing: 1500⌶).
⍝⍝ ∘ Hashing is preserved when updating items, adding new items, searching for items, etc.
⍝⍝ ∘ Hashing is preserved when popping items (which is therefore fast)
⍝⍝ ∘ Hashing is NOT usually preserved when deleting objects (del or di).
⍝⍝   ∘ If all keys to delete are a contiguous set of the last (rightmost) keys, hashing is preserved.
⍝⍝   ∘ If at least one key is not part of a contiguous set at the right end, the hash is rebuilt.
⍝⍝   ∘ Deleting a set of keys at once is efficient; the dictionary is rehashed all at once.
⍝⍝   ∘ Deleting items one at a time reequires rebuilding and rehashing each time. Avoid!
⍝⍝ ∘ If the same key is updated in a single call with multiple values 
⍝⍝       dict[k1 k1 k1]←v1 v2 v3
⍝⍝   only the last entry (v3) is kept.
:EndClass
