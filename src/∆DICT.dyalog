:Class DictClass
⍝ Documentation is provided in detail at ∆DICT.help

⍝ Initialization of APL System Variables
⍝ Right now, ⎕CT, ⎕DCT, ⎕RL are set to be the same as in # at FIX time (when loaded)
    ⎕IO ⎕ML ⎕PP ←0 1 34 ⋄ (⎕CT ⎕DCT ⎕RL)←##.(⎕CT ⎕DCT ⎕RL)   
 
⍝ Export key utilities to the parent environment (hard-wiring ⎕THIS namespace)?
⍝ If exportSelection[n]=1, item [n] will be exported to ##
⍝  n     Is exported to ##
⍝ [0]    Dict   
⍝ [1]    ∆DICT   
⍝ [2]    ∆JDICT 
  exportSelection← 1 1 1                     ⍝ Copy all EXPORT_LIST utilities to ## in each case...
  :Field Private Shared EXPORT_LIST←    exportSelection/ 'Dict' '∆DICT' '∆JDICT'   ⍝ See EXPORT_FUNCTIONS below
  :Field Private Shared DICT_CLASS←         ⎕THIS   ⍝ Utilities are exported to DICT_CLASS.## 
  
  ⍝ IDs:  Create Display form of form:
  ⍝       DictMMDDHHMMSS.dd (digits from day, hour, ... sec, plus increment for each dict created).
  :Field Public         ID 
  :Field Private Shared ID_COUNT←           0
  :Field Private Shared ID_PREFIX←          ,'<⎕DICT=>,6ZI2,<.>'⎕FMT⍉⍪(6↑¯2000)+¯1↓⎕TS
  :Field Private Shared baseclassF←         ⊃⊃⎕CLASS ⎕THIS
 
  ⍝ Instance Fields and Related
  ⍝ A. TRAPPING
    :Field Private ∆TRAP←                   0 'C' '⎕SIGNAL/⎕DMX.((EM,Message,⍨'': ''/⍨0≠≢Message) EN)'
  ⍝ B. Core dictionary fields
                   keysF←                   ⍬        ⍝ Non-field variable avoids Dyalog bugs with catenating/hashing.
    :Field Private valuesF←                 ⍬        ⍝ Always (≢keysF)≡(≢valuesF)
    :Field Private hasdefaultF←             0
    :Field Private defaultF←                ''       ⍝ Default value (suppressed until hasdefaultF is 1)
  ⍝ mirrorData: see d.namespace
  ⍝ If mirrorData≡⎕NULL, no mirror is currently established.  (See d.mirror 'NEW' and d.mirror 'DEL').
  ⍝ If established (d.mirror 'NEW'), it is mirroring if nsActive=1; else quiet.
    :Field Private mirrorData←              ⎕NULL    
    :Field Private nsActiveF←               0        ⍝ 1 (active, 0 (inactive: temporarily or because no mirrorData)
    
  ⍝ C. ERROR MESSAGES:  [en=11] 'Error Message'
    :Field Private Shared eBadUpdate←       'Unable to update Dictionary due to invalid element in ⍵'
    :Field Private Shared eBadClass←        'Invalid class specification' 
    :Field Private Shared eBadDefault←      'hasdefault must be set to 1 (true) or 0 (false).'
    :Field Private Shared eBadNS←           'Namespace specified is invalid'
    :Field Private Shared eDelKeyMissing←   'd.del: at least one key was not found and ⍺:ignore≠1.'
    :Field Private Shared eImport←          'd.import keys vals. Use dict.update for updating from other objects'
    :Field Private Shared eIndexRange←       3 'd.delbyindex: An index argument was not in range and ⍺:ignore≠1.'
    :Field Private Shared eKeyAlterAttempt← 'd.keys: item keys may not be altered.'
    :Field Private Shared eHasNoDefault←     3 'd.index: key does not exist and no default was set.'
    :Field Private Shared eHasNoDefaultD←   'd.default: no default has been set.'
    :Field Private Shared eQueryDontSet←    'd.querydefault is read-only. Use set d.default and/or d.hasdefault.'
    :Field Private Shared eBadInt←          'd.inc/d.dec: increment (±⍺) and value for each key in ⍵ must be numeric.'
    :Field Private Shared eKeyBadName←      'd.namespace: Unable to convert key to valid APL variable name'
    :Field Private Shared eMirFlag←         'd.mirror: flag (⍵) must be one of NEW | ON | OFF | DEL.'
    :Field Private Shared eMirDel←          'd.mirror: No namespace mirror established (via d.mirror ''NEW'').'
    :Field Private Shared eMirNumKeys←      'd.mirror: preferNumericKeys (⍺), if present, must be 1 (ON) or 0 (OFF)'
    :Field Private Shared eMirLogic←        'd._mirrorOpts LOGIC ERROR'

  ⍝ General Local Names
    ∇ ns←Dict                      ⍝ Returns the dictionary class namespace. Searchable via ⎕PATH. 
      :Access Public Shared        ⍝ Usage:  a←⎕NEW Dict [...]  with ⎕THIS.## in the path!
      ns←DICT_CLASS
    ∇ 

    ∇dict←{default} ∆DICT items_default      ⍝ Creates ⎕NEW Dict via cover function
    :Access Public Shared
     :TRAP 0
        dict←(⊃⎕RSI,#).⎕NEW DICT_CLASS items_default       ⍝ May set the dict.default via <items_default>
        :IF ~900⌶1 ⋄ dict.default←default ⋄ :Endif      ⍝ An explicit <default> overrides any set in <items_default>
     :Else
        ⎕SIGNAL ⊂⎕DMX.(('EN' 11)('EM' ('∆DICT ',EM)) ('Message' Message))
     :EndTrap
    ∇
    
    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Constructors...
    ⍝ New1: "Constructs a dictionary and updates*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Optionally, sets the default value."
    ⍝ Uses update/import, which will handle duplicate keys (the last value quietly wins), and so on.
    ⍝ *** See update for conventions for <items_default>.
    ∇ new1 struct
      :Implements Constructor
      :Access Public
      :Trap 0
          _importObjs struct      
          SET_ID
      :Else  
          ⎕SIGNAL ⎕DMX.((⊂'EN' EN)('EM' EM) ('Message' Message))
      :EndTrap
    ∇
    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
       SET_ID
    ∇
    ⍝ SET_ID: Set unique ID of this dictionary (for fast comparisons) of the form:
    ⍝        ID:   'DICT:',<date-time prefix>,<counter>
    ⍝ Sets the display form and returns the ID.
    ∇ {returning}←SET_ID
      ⎕DF returning ← ID←ID_PREFIX,⍕ID_COUNT ← 2147483647 | ID_COUNT + 1
    ∇
    ∇ destroy
      :Implements Destructor
      _mirrorOpts ¯1      ⍝ If there's any mirroring, remove it. 
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)
    ⍝-------------------------------------------------------------------------------------------
   
    ⍝ keys2Vals: "Using standard vector indexing and assignment, set and get the value for each key. 
    ⍝           New entries are created automatically"
    ⍝ SETTING values for each key
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING values for each key
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property default keyed keys2Vals 
    :Access Public
        ∇ vals←get args;found;ix;shape;⎕TRAP
          ⎕TRAP←∆TRAP
          :If ⎕NULL≡⊃args.Indexers ⋄ vals←valuesF ⋄ :Return ⋄  :EndIf
          shape←⍴ix←keysF⍳⊃args.Indexers  
          :If ~0∊found←ix<≢keysF
              vals←valuesF[ix]                
          :ElseIf hasdefaultF
             vals← found ExpandFill0 valuesF[found/ix]    ⍝ Insert slot(s) for values of new keys. See Note [ExpandFill0]
              ((~found)/vals)←⊂defaultF                   ⍝ Add default values for slots just inserted.
              vals⍴⍨←shape                                ⍝ Ensure vals is scalar, if the input parm args.Indexers is.
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

 ⍝ vals2Keys: 
 ⍝    "Using standard vector indexing and assignment, get the keys for each value, parallel to keys2Vals.
 ⍝     Since many keys may have the same value, 
 ⍝     returns a list (vector) of 0 or more keys for each value sought.
 ⍝     ⍬ is returned for each MISSING value."
 ⍝     Setting is prohibited!
 ⍝ keys ← dict.vals2Keys[]         ⍝ Return keys for all values
    :Property keyed vals2Keys 
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
          vals←keys2Vals[keys]
      :ELSE 
          nd←~d←defined keys
          vals← d ExpandFill0 keys2Vals[d/keys]  ⍝ See ExpandFill0 definition above
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
    ∇{dict}←import keys_vals;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      (2≠≢keys_vals) THROW eImport
      importVecs keys_vals
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
    ⍝ _importObjs ⍵: Internal utility to be called from top-level routines."
    ⍝ update accepts either a SCALAR or VECTOR right argument ⍵.           
    ∇ {dict}←update objectSpecs;⎕TRAP
      :Access Public
      :TRAP 0 
          _importObjs objectSpecs  
      :Else
          THROW ⎕DMX.EN ((⎕UCS 10),⎕DMX.Message)
      :EndTrap
      dict←⎕THIS
    ∇
    ⍝ _importObjs objects: used only internally.
    ⍝ Used in initialization of ∆DICTs or via ⎕NEW Dict...
    ⍝ objects: 
    ⍝        (⍪keys vals [def]) OR (key1 val1)(key2 val2)(...) OR dictionary
    ⍝    OR  (key1 val1) dict2 (key3 val3) dict4...      ⍝ A mix of key-value pairs and dictionaries
    ⍝ Special case:
    ⍝        If a scalar is passed which is not a dictionary, 
    ⍝        it is assumed to be a default value instead.
    ⍝ Returns: NONE
    isDict←{9.2≠⎕NC⊂,'⍵':0 ⋄ baseclassF∊⊃⊃⎕CLASS ⍵} 
    ∇ _importObjs objects;k;v;o 
      :If 0=≢objects                            ⍝ EMPTY?  NOP
      :ELSEIF 0=⍴⍴objects
        :IF isDict objects
           importVecs objects.export
        :Elseif 9.1=⎕NC ⊂'objects'
            1 importNS objects
        :Else 
           defaultF hasdefaultF←(⊃objects) 1   ⍝ SCALAR? FAST PATH
        :Endif 
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
              :ELSEif 9.1=⎕NC⊂,'o'
                                 1 importNS o
              :Elseif 2∧.=≢¨o  ⋄ importVecs ↓⍉↑o                 ⍝
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
          ;ix;kp;old;oix;nk;nv;uniq    
      →0/⍨0=≢k                    ⍝      No keys/vals? Return now.
      ix←keysF⍳k                  ⍝ I.   Process existing (old) keys
      old←ix<≢keysF               ⍝      Update old keys in place w/ new vals;
      valuesF[oix←old/ix]←old/v   ⍝      Duplicates? Keep only the last val for a given ix.
      :IF nsActiveF ⋄ _mirror2NS (keysF[oix]) (valuesF[oix]) 0 ⋄ :ENDIF
      →0/⍨~0∊old                  ⍝      All old? No more to do; shy return.
      nk nv←k v/¨⍨⊂~old           ⍝ II.  Process new keys (which may include duplicates)
      uniq←⍳⍨nk                   ⍝      For duplicate keys,... 
      nv[uniq]←nv                 ⍝      ... "accept" last (rightmost) value
      kp←⊂uniq=⍳≢nk               ⍝      Keep: Create and enclose mask...
      nk nv←kp/¨nk nv             ⍝      ... of those to keep.
      (keysF valuesF),← nk nv     ⍝ III. Update keys and values fields based on umask.
      :IF nsActiveF ⋄ _mirror2NS nk nv 0 ⋄ :ENDIF
      OPTIMIZE                    ⍝      New entries: Update hash and shyly return.
    ∇
    
  ⍝ _mirror2NS
  ⍝    (void)← ∇ (keys vals delF=0|1)
  ⍝    If (delF=0), update values (vals) for keys; If (delF=1), delete keys (vals ignored)
  ⍝ (Local utility used in importVecs)
    ∇_mirror2NS (keys vals delF)
     ;Key2Name;mKeys 
     :IF (0=≢keys) ⋄ :ORIF ~nsActiveF ⋄ :RETURN ⋄ :ENDIF   
     Key2Name← 0⍨7162⌶⍕   ⍝ JSON mangling
     mirrorData.mirrorNS _SuppressTrigger 1
        mKeys←{0:: ⍬ ⋄ Key2Name¨⍵}keys
        (~×≢mKeys) THROW eKeyBadName
        :IF delF 
            mirrorData.mirrorNS.⎕EX mKeys      
        :ELSE 
            mKeys (mirrorData.mirrorNS _AssignVar)¨vals
        :ENDIF
      mirrorData.mirrorNS _SuppressTrigger 0
    ∇

    ⍝ importMx: Imports ⍪keyvec valvec [def]
    importMx←importVecs{ 2=≢⍵: ⍵ ⋄ 3≠≢⍵: THROW eBadUpdate ⋄ defaultF hasdefaultF⊢←(2⊃⍵) 1⋄ 2↑⍵}∘,

    ∇{names}←{preferNumericKeys} importNS ns_classes
      ;classes;hideNS;names;ns;IGNORE
      :Access Public
    ⍝ IGNORE: Names NOT to import from the namespace...
      IGNORE←⊆'__DictTrigger__'
      preferNumericKeys← 0 {900⌶1: ⍺ ⋄ ⎕OR ⍵  }'preferNumericKeys' 
      ns classes←(⍬⍴ns_classes)({0=≢⍵: 2 3 4 9 ⋄  ⍵ }1↓ns_classes)
          (9.1≠⎕NC⊂'ns')      THROW eBadNS
          (0∊classes∊2 3 4 9) THROW eBadClass
    ⍝ Remove (ignore) names in  IGNORE
      names←IGNORE{⍵/⍨⍺∘{(⊂⍵)(~∊)⍺}¨⍵}ns.⎕NL -classes
    ⍝ ⍝⍝⍝ Replace keys, vals with kvPairs
      (ns preferNumericKeys) setKeysFromNames names
    ∇ 

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
    ∇ r←get args
      ;show;disp;⎕PP   
      :If 0=≢keysF ⋄ r←⍬ ⋄ :Return ⋄ :EndIf
      disp←⎕SE.Dyalog.Utils.disp    
      r←↑keysF valuesF 
      ⎕PP←34 
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
      _inc← { nv←⍺+0 ⍺⍺ ⍵ ⋄ nv⊣⍵ ⍵⍵  nv }
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :TRAP 11 
          :IF (≢∪keys)=≢keys
            newvals←∆ (get _inc set) keys
          :Else 
            newvals←∆ (get1 _inc set1)¨ keys
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
         THROW ⎕DMX.Message   
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
    ⍝ Delete items by ix, where indices <ix> (if non-null) guaranteed to be in range of keysF.
    ∇ diFast ix;count;endblock;uix;∆
      → 0/⍨ 0=count←≢uix←∪ix                ⍝ Return now if no indices refer to active keys.
      endblock←(¯1+≢keysF)-⍳count           ⍝ All keys contiguous at end?
      :IF nsActiveF ⋄ _mirror2NS (keysF[ix]) ⎕NULL 1 ⋄ :ENDIF 
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
      ix-←(⊃⎕RSI).⎕IO      ⍝ Adjust indices to reflect caller's index origin, if need be
      (ix[⍋ix]≢⍳≢keysF) THROW 'Dict.reorder: at least one index value is out of range, missing, or duplicated.'
      keysF ⌷⍨←⊂ix ⋄ valuesF ⌷⍨←⊂ix 
      OPTIMIZE ⋄ dict←⎕THIS
    ∇

  ⍝ d.mirror
  ⍝ mirrorNS ← {preferNumericKeys:[0|1]} d.mirror [NEW | ON | OFF | DEL ]
  ⍝ See documentation for details. 
  ⍝ Enables a namespace that 
  ⍝            replicates the dictionaries keys as variable names and
  ⍝            whose values, if changed, are reflected on the fly in the dictionary itself.
  ⍝ A.  On first call with NEW option
  ⍝     1. creates namespace <ns>, setting two fields
  ⍝           mirrorData - the namespace with mirror-related variables, and 
  ⍝           nsActiveF  - 1 when it's active, else 0.
  ⍝        as well as 
  ⍝           mirrorData.mirrorNS (the user-accessible mirrored namespace)
  ⍝     2. creates 
  ⍝           ns.ourDict - points to the active dictionary instance
  ⍝           ns.mirrorNS   - contains user variables and the trigger fn (__DictTrigger__)
  ⍝ B1. On subsequent calls with NEW option
  ⍝     May change the preferNumericKeys(⍺), for future mirroring
  ⍝ B2. On subsequent calls, with
  ⍝     ON            enables real-time mirroring of active namespace (created via NEW)
  ⍝     OFF           temporarily disables ...
  ⍝     DEL           turns off mirroring and severs any connection with the mirroring namespace from NEW
  ⍝     STATUS        shows current mirroring status
  ⍝ RETURNS [shyly] in all cases:
  ⍝    the user-accessible mirror namespace (mirrorData.mirrorNS)
    ∇{mirrorNS}←{preferNumericKeys} mirror flag ;opts 
      :Access Public
      :SELECT flag← ⎕C flag
        :CASE 'status'    ⍝ status
          mirrorNS←mirrorData{⍺≡⎕NULL: 'NONE' ⋄ (⍵/'IN'),'ACTIVE'}~nsActiveF
          :RETURN
        :CASELIST opts←'del' 'off' 'on'     
          (mirrorData≡⎕NULL) THROW eMirDel 
          mirrorNS← _mirrorOpts ¯1+opts⍳⊂flag
          :RETURN
        :CASE 'new' 
           ⍝ Continue below at NEW
        :ELSE 
          THROW eMirFlag 
      :ENDSELECT
    NEW:
    ⍝ preferNumericKeys:  1=yes, 0=no (default=0). Used only with flag 'NEW', otherwise ignored.
      :IF 900⌶1 ⋄  preferNumericKeys←0
      :ELSE     ⋄  (preferNumericKeys(~∊)0 1) THROW eMirNumKeys
      :ENDIF 
    ⍝ ACTIVATE THE MIRROR, IF REQUIRED.
      nsActiveF←1                      ⍝ Activate mirrorData, creating if necessary...
    ⍝ MIRROR ALREADY EXISTS
      :IF mirrorData≢⎕NULL                     
          mirrorData.preferNumericKeys←preferNumericKeys 
          mirrorNS←mirrorData.mirrorNS 
          :RETURN
      :ENDIF
      mirrorData←⎕NS '' 
      mirrorData.preferNumericKeys←preferNumericKeys            
      mirrorNS←mirrorData.mirrorNS←mirrorData.⎕NS '' 
      mirrorNS.⎕DF '⎕NS@',ID
      mirrorData.ourDict← ⎕THIS                             ⍝ Point to the active dictionary
      :TRAP 0   
          :IF ×≢keysF   
              names← (0⍨7162⌶⍕)¨ keysF                      ⍝ Convert Keys 2 Names via JSON mangling
              names (mirrorNS _AssignVar)¨valuesF           ⍝ In mirrorData.mirrorNS, assign values to names.
          :ENDIF                                            ⍝ ↓↓↓ Activate trigger fn __DictTrigger__
          mirrorNS.⎕FX '⍝ACTIVATE⍝' ⎕R '' ⊣ ⎕NR '__DictTrigger__'
      :ELSE
          THROW eKeyBadName
      :ENDTRAP
    ∇
  
  ⍝ {mirrorNS} ← _mirrorOpts [1 | 0 | ¯1]
  ⍝ setMirror: (0:OFF) Turns mirroring off, or (1:ON) reestablishes it, 
  ⍝        or (¯1:DEL) permanently disconnects the namespace and dictionary entirely, ending mirroring. 
  ⍝ Returns (shyly): the (active) mirror namespace. ⎕NULL, if none established.
  ⍝ HELPER FUNCTION for d.mirror (above)
    ∇{mirrorNS}←_mirrorOpts flag; was  
      :IF (mirrorData≡⎕NULL) ⋄ mirrorNS←⎕NULL ⋄ :RETURN ⋄ :ENDIF
      (flag(~∊)1 0 ¯1) THROW eMirFlag
      :Select ⍬⍴flag
        :CASE ¯1                                      ⍝ Terminate the connection
          ⍝ Suppress trigger...
            ⍝ mirrorData.mirrorNS _SuppressTrigger 1             
          ⍝ Delete trigger fn and dict reference. (Avoid keeping ourDict reference live)
            (0∊mirrorData.⎕EX 'ourDict' 'mirrorNS.__DictTrigger__') THROW eMirLogic
            nsActiveF mirrorData mirrorNS← 0 ⎕NULL ⎕NULL
        :CASELIST 0 1                                    ⍝ Suppress (0) or re-enable (1) mirroring
            was nsActiveF mirrorNS←nsActiveF flag mirrorData.mirrorNS
            :IF was=flag ⋄ :RETURN ⋄ :ENDIF
            mirrorNS _SuppressTrigger ~nsActiveF       
        :ELSE 
            THROW eMirLogic
      :ENDSELECT 
    ∇
   
    ⍝ __DictTrigger__: helper for d.mirror (q.v.).
    ⍝ Do not enable trigger here: it's copied/activated in mirror namespace only.
    ⍝ Note: See importNS. It will not import this object '__DictTrigger__' if found in the source namespace.
    ⍝ WARNING: Be sure all local variables are in fact local. Otherwise, you'll see an infinite loop!!!  
    ∇__DictTrigger__ args  
      ⍝ACTIVATE⍝ :Implements Trigger *             ⍝ Don't touch this line!
      :TRAP 0
         (⎕THIS ##.preferNumericKeys) ##.ourDict.setKeysFromNames  ⊆args.Name 
      :Else 
          ⎕SIGNAL  ⊂⎕DMX.(('EN' EN)('Message'  Message)('EM' ('∆DICT mirror: ',EM))) 
      :ENDTRAP
    ∇

    ∇ {dict}←ns_opts setKeysFromNames nameList
      ;Name2Key;preferNK;saveState;thisNS 
      :Access Public
      dict←⎕THIS 
      :IF 1=≢ns_opts
          thisNS preferNK←ns_opts 0
      :Else 
          thisNS preferNK←ns_opts
      :ENDIF
      Name2Key←preferNK∘{  
          key←1∘(7162⌶) ⍵       ⍝ Uses JSON unmangling
          ~⍺: ⍬⍴⍣(1=≢key)⊣key  ⋄ ok val←⎕VFI key   
          0∊ok: ⍬⍴⍣(1=≢key)⊣key ⋄  1≠≢val: val  ⋄ ⊃val 
      } 
    ⍝ Suppress mapping namespace vars onto dict keys, only if ns is the actively mapped (triggered) namespace
      saveState←nsActiveF 
      :IF thisNS.##≡mirrorData ⋄ nsActiveF←0 ⋄ :ENDIF  
          :TRAP 0  
              importVecs↓⍉↑,thisNS∘{nm←⍵
                    k←Name2Key nm ⋄  valIn←⍺⍎nm  
                    case←⍬⍴⎕NC 'valIn'
                      case∊3 4: k (⍺.⎕OR nm)  
                      case∊2 9: k valIn
              }¨nameList 
          :Else 
              nsActiveF←saveState
              11 ⎕SIGNAL⍨'∆DICT VALUE ERROR: Unable to import item from namespace'
          :EndTrap
    ⍝ Restore mapping of namespace vars onto dict keys, if ns is the actively mapped (triggered) namespace
      nsActiveF←saveState
    ∇

    ⍝ _SuppressTrigger: If ⍵=1, suppresses trigger for namespace ⍺. If ⍵=0, re-enables it.
      _SuppressTrigger←{1: _←2007 ⍺.⌶ ⊢ ⍵}

  ⍝ Dict.help/Help/HELP  - Display help documentation window.
    ∇ {h}←HELP;ln 
      :Access Public Shared
      ⍝ Pick up only internal ⍝H comments!
      DICT_HELP←⍬
      :Trap 0 1000  
          :IF 0=≢DICT_HELP
              h←⎕SRC ⎕THIS 
              h←3↓¨h/⍨(⊂'⍝H')≡¨2↑¨h 
              DICT_HELP←h←⎕PW↑[1]↑h 
          :ENDIF
          ⎕ED&'DICT_HELP'       
      :Else ⋄ ⎕SIGNAL/'Dict.HELP: No help available' 911
      :EndTrap
    ∇
    _←{⍺←'HELP'⋄ ⎕FX ('\b',⍺,'\b')⎕R ⍵⊣⎕NR ⍺}¨ 'help' 'Help'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ INTERNAL UTILITIES
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ Note [ExpandFill0]
    ⍝ ExpandFill0:  ⍺:bool \ ⍵:in, which uses a fill of 0 for the first item. See discussion below.
    ⍝    out ← bool ExpandFill0 in          
    ⍝ Discussion: 
    ⍝  ∘ We want to use expand \ in providing DEFAULT values for as yet unseen keys; it requires that ⍵ have a fill value.
    ⍝    As valuesF is updated, it may include namespaces or other items that lack a fill value. 
    ⍝  ∘ If, during an expand operation ⍺\valuesF, the first item contains such an item, a NONCE ERROR occurs,
    ⍝  ∘ We resolve this using <ExpandFill0>, which ensures a fill value of 0:
    ⍝    vals←found ExpandFill0 valuesF[found/ix]  
    ⍝ Tacit Variant:    ExpandFill0 ← 1↓(1,⊣)⊢⍤\0,⊢      ⍝ a tad slower
      ExpandFill0←{1↓(1,⍺)\ 0,⍵}    

    ∇ {ok}←OPTIMIZE 
    ⍝ Set keysF to be hashed whenever keysF changed-- added or deleted. (If only valuesF changes, no use in calling this).
    ⍝ While it is usually of no benefit to hash small key vectors of simple integers or characters,
    ⍝ it takes about 25% longer to check datatypes and ~15% simply to check first whether keysF is already hashed. 
    ⍝ So we just hash keysF whenever it changes!
      keysF←1500⌶keysF ⋄ ok←1                                                               
    ∇
    
    ⍝ THROW: "Throws an error if ⍺ is omitted or contains a 1; else a NOP."
    ⍝ Syntax:
    ⍝   [cond=1] THROW [en=11] message, 
    ⍝   where en and message are of the form of ⎕DMX fields EN and Message.
     _THROW← { ⍺←1 ⋄ 1(~∊)⍺: ⍬ ⋄ 1=≢⊆⍵: ⍺ ∇ 11 ⍵  
              en msg←⍵ ⋄ em←'∆DICT ',('DOMAIN ' 'INDEX ' ''⊃⍨11 3⍳en),'ERROR'
              ⊂('EN' en)('Message'  msg)('EM' em) 
    }
    THROW←⎕SIGNAL _THROW
    
⍝⍝
⍝⍝ ∆JDICT function --- See HELP INFO BELOW
⍝⍝ =========================================================================================

  ⍝ JSONsample: JSON demo case. To access:  x← Dict.JSONsample or   jd← ∆JDICT Dict.JSONsample
    :Field Public  Shared JSONsample←'[{"id":"001", "name":"John Smith", "phone":"999-1212"},{"id":"002", "name":"Fred Flintstone", "phone":"254-5000"},{"id":"003","name":"Jack Sprat","phone":"NONE"}]'

    ∇ result ← {minorOpt} ∆JDICT strJson
      ;err;oJson5;keys;majorOpt;Key2Name;Name2Key;ns;oNull;vals;keysAsNumbers;⎕IO;⎕TRAP   
      :Access Public Shared
      Key2Name← 0⍨7162⌶⍕            ⍝ JSON mangling
      keysAsNumbers←0               ⍝ 1: Treat imported keys that look like numeric scalars/vectors as APL numbers 
      Name2Key←{      ⍝ JSON unmangling
          key←1∘(7162⌶) ⍵ ⋄ ~⍺: ⍬⍴⍣(1=≢key)⊣key  
          ok val←⎕VFI key  ⋄ 0∊ok: ⍬⍴⍣(1=≢key)⊣key  ⋄ 1≠≢val: val ⋄ ⊃val  ⍝ single # => disclose scalar
      }  
      ⎕IO←0 ⋄ oNull oJson5 oJson3←('Null'⎕NULL)('Dialect' 'JSON5')('Dialect' 'JSON')
      ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(((''∆JDICT: '',EM),Message,⍨'': ''/⍨0≠≢Message) EN)'
      err←⎕SIGNAL {⍺←1 ⋄ ⍺: ⊂('EN' 11)('Message'  ⍵) ⋄ ⍬}
    ⍝ Major opt (majorOpt) automatically set based on type of <json>.
    ⍝ If several namespaces or strings OR converts from string to namespaces, majorOpt=2.
    ⍝ If majorOpt=0, minor option is checked; otherwise ignored.
      minorOpt←{⍵: 0 ⋄ minorOpt} 900⌶1   
      ns majorOpt←strJson{
        badStrE←'At least one invalid ⎕JSON input string found in arg ⍵.'  
        badObjE←'At least one object in arg ⍵ not a JSON string or compatible APL namespace or dictionary.' 
        0::  err badStrE
        ⍵=2.1: strJson{
          ⍵: ns (1+1<≢ns) ⊣ ns←⎕JSON ⍠ oNull oJson5⊣⍺   ⍝ Allow JSON5 on import.
          1<≢⍺: ⍺ 2 
          err badObjE
        }0=80|⎕DR ⍺
        ⍵=9.1: ⍺ 1
        ⍵=9.2: ⎕NULL 0    ⍝ Object is a class instance; expected to be a dict.
        err badObjE
      }⎕NC⊂'strJson'
    
      :Select majorOpt
      :Case 2      ⍝ several objects: JSON strings, namespaces, or dicts
          result←minorOpt (⍎⊃⎕XSI)¨ns       ⍝ Call ∆JDICT on each object...
      :Case 1      ⍝ ns from ⎕JSON obj or directly from user
          dict←DICT_CLASS.##.∆DICT ⍬   
          ns dict∘{
              0:: err 'Valid JSON object ⍵ could not be converted to dictionary.' 
              context dict←⍺ ⋄ varName←⍵ ⋄ val←context⍎varName
              key←keysAsNumbers∘Name2Key varName    
              2=context.⎕NC varName:_←key dict.set1 val
            ⍝ varName points to a namespace, which is converted internally to a dictionary
              dict2←DICT_CLASS.##.∆DICT ⍬ ⋄ subtext←val
              _←key dict.set1 dict2
              1:_←subtext dict2∘∇¨subtext.⎕NL-2.1 9.1
          }¨ns.⎕NL-2.1 9.1
          result←dict  ⍝ Return a single dictionary
      :Else           ⍝ User passed a dictionary to convert
          (~minorOpt∊0 1 2) err 'Option ⍺ was invalid: Must be 0, 1, 2.'  
          Scan←{
              isDict←{9.2≠⎕NC⊂,'⍵':0 ⋄ DICT_CLASS∊⊃⊃⎕CLASS ⍵} 
              ns←⍺⍺ ⋄ k v←⍺ ⍵
              ~isDict v: _←k ns.{⍎⍺,'←⍵'}  v
              _←k ns.{⍎⍺,'←⍵'} ns2←ns.⎕NS ''
              1: ⍬⊣(Key2Name¨ v.keys)(ns2 ∇∇)¨v.vals
          }
          dict←strJson
          :TRAP  0
              ns←⎕NS ''
              (Key2Name¨ dict.keys) (ns Scan)¨dict.vals
          :Else 
              err 'Dictionary ⍵ could not be converted to ⎕JSON.' 
          :EndTrap
        ⍝ Use a compact ⎕JSON format if minorOpt is 0.
        ⍝ minorOpt∊0 1: result is a  JSON string 
        ⍝ minorOpt=2:   result is a namespace.
        ⍝ Always export (default) as JSON3 format.
          result ← minorOpt{⍺=2: ⍵ ⋄ ⎕JSON ⍠ oNull oJson3('Compact' (⍺=0))⊣⍵ }ns
      :EndSelect 
    ∇
  ⍝ _AssignVar:    Assign to name in context <where> the value (std) or create as a function if the value is an ⎕OR.
  ⍝ name ←   name (where _AssignVar) val
  ⍝ Syntax:
  ⍝     ⍺:name (⍺⍺:where ∇) ⍵:val
  ⍝     ⍺:name:   a valid variable name in the current env.
  ⍝     ⍵:val:    a variable (⎕NC 2).
  ⍝               If an ⎕OR, may be a dfn, tradfn, or a derived fn or system fn...
  ⍝     ⍺⍺:where: namespace in which to execute (assign to name).  
  ⍝ Action:
  ⍝     If <val> is a non-⎕OR value,
  ⍝         assigns value <val> to name <name>.
  ⍝     If <val> is an ⎕OR,
  ⍝         assigns the associated function, in place of the value.
  ⍝ Returns <name> shyly.
    _AssignVar←{
        _←⍺⍺.⎕EX ⍺                               ⍝ Replace existing <name> even if incompatible class (⎕NC).  
        (1=≡⍵)∧0=⍴⍴⍵:(⍺⍺{⍺⍺∘⍎ ⍺,'←⍵⍵' ⋄ ⍵⍵}⍵)⍨⍺  ⍝ <val> is an ⎕OR. ⍵⍵: magically convert ⎕OR to function/or (⎕NC∊3 4).  
        1:_←             ⍺⍺∘⍎ ⍺,'←⍵'             ⍝ <val> is a value in ⎕NC=2 that is not an ⎕OR or ⎕NC=9. 
    }                                           

    ∇{list}←EXPORT_FUNCTIONS list;fn;ok
      actual←⍬
      ⍝ Copy list of fns into parent namespace to this one...
      ⍝ In functions to export, 
      ⍝     use DICT_CLASS instead of ⎕THIS (⎕THIS will be treated as an alias for DICT_CLASS)
      ⍝     use DICT_CLASS_## to refer to the namespace for the exported functions
      ⍝ We also optimize DICT_CLASS.## to refer to the exported fns directory (where it's preferred to the class itself)
      :FOR fn :IN list
          ok←##.⎕FX 'DICT_CLASS\.##' 'DICT_CLASS|⎕THIS' ⎕R (⍕DICT_CLASS.##)(⍕DICT_CLASS)⊣⎕NR fn  
          :IF 0=1↑0⍴ok
              ⎕←'EXPORT_GROUP: Unable to export fn "',fn,'". Error in ',fn,' line',ok
          :ENDIF
      :EndFor
    ∇
    EXPORT_FUNCTIONS EXPORT_LIST

⍝H DictClass: A fast, ordered, and simple dictionary for general use.
⍝H            A dictionary is a collection of ITEMS (or pairs), each consisting of 
⍝H            one key and one value, each an arbitrary shape and  
⍝H            in nameclass 2 or 9 (value or namespace-related).
⍝H
⍝H ∆DICT:     Primary function for creating new dictionaries.
⍝H            Documented immediately below.
⍝H ∆JDICT:    Convert between dictionaries and {⎕JSON strings and/or ⎕JSON-compatible namespaces}.
⍝H            Documented further below (see ∆JDICT).
⍝H
⍝H ∆DICT: Creating a dict, initializing items (key-value pairs), setting the default for missing values.
⍝H TYPE       CODE                          ITEMS (key-value pairs)               DEFAULT VALUE
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H empty      a←∆DICT ⍬                     ⍝ None                                none
⍝H items      b←∆DICT (1 10)(2 20)(3 30)    ⍝ (1 10)(2 20)(3 30)                  none
⍝H items+     c←0 ∆DICT (1 10)(2 20)(3 30)  ⍝ (1 10)(2 20)(3 30)                  0
⍝H lists+     d←⍬ ∆DICT ⍪(1 2 3)(10 20 30)  ⍝ (1 10)(2 20)(3 30)                  ⍬ (numeric null)
⍝H dict       e←∆DICT d (4 40)              ⍝ (1 10)(2 20)(3 30)  (4 40)          none
⍝H 
⍝X Dict:      A utility fn that returns the full name of the dictionary class, often #.DictClass.
⍝X            To enable, put [full path].Dict in your ⎕PATH (or specify full path to DictClass).
⍝X            d←⎕NEW Dict            ⍝ Create a new, empty dictionary with no default values.
⍝X            d←⎕NEW DictC (struct)   ⍝ Initialize dictionary with same call as for ∆DICT or d.update.
⍝H Hashes keys for efficiently searching and updating items in large dictionaries.
⍝H For HELP information, call 'Dict.HELP'.
⍝H
⍝H =========================================================================================
⍝H    ∆DICT function 
⍝H =========================================================================================
⍝H
⍝H    Quick Overview of ∆DICT calls and methods (abridged)
⍝H ---------------------------------------------------
⍝H    [def]: An optional default for missing keys of most any value or shape.
⍝H    kN, a key (of most any value); vN, a value of most any value;  iN (an index, ⎕IO dependent).
⍝H    keys, a list of keys; vals, a list of values; indices, a list of indices (integer positions, per ⎕IO)
⍝H    "Active order": the current explicit ordering of keys-- as entered, unless reordered (see sort, reorder).
⍝H CREATE
⍝H    d        ← [def] ∆DICT ⍬                 ⍝ Create empty dictionary
⍝H    d        ← [def] ∆DICT (k1 v1)(k2 v2)..  ⍝ Create dict by initial key-value pairs.
⍝H    d        ← [def] ∆DICT ⍪keys vals        ⍝ Create dict by initial 
⍝H                                             ⍝    keys in keylist and values in valuelist
⍝H GET
⍝H    v1 v2 v3 ←           d[k1 k2 k3]         ⍝ Get value list by key list
⍝H    v1       ← [def] d.get1 k1               ⍝ Get a value disclosed by key (see d.get).
⍝H    v1 v2 v3 ← [def] d.get  keys             ⍝ Get value list by key list, else default
⍝H    keys vals ←          d.export            ⍝ Get key list followed by value list
⍝H    keys     ←           d.keys              ⍝ Get all keys in active order
⍝H    k1 k2 k3 ←           d.keys[indices]     ⍝ Get keys by index (position in active key order)
⍝H    vals     ←           d.vals              ⍝ Get all values in active (key) order
⍝H    v1 v2 v3 ←           d.vals[indices]     ⍝ Get values by index (position in active key order)
⍝H    (k1 v1)...        ←  d.items             ⍝ Get all items (key-val pairs) in active order
⍝H    (k1 v1)(k2 v2)... ←  d.items[indices]    ⍝ Get all items in active (key) order
⍝H SET  
⍝H                   d[keys] ←  vals           ⍝ Set values for arbitrary keys.  For one key:  d[⊂key]←⊂val   
⍝H                   k1 d.set1 v1              ⍝*Set value for one key (see d.set)
⍝H                   keys d.set  vals          ⍝ Set values for keys
⍝H                   d.import keys vals        ⍝ Set values for arbitrary keys
⍝H                   d.update (k1 v1)(k2 v2)(k3 v3)...      ⍝ Set key-value pairs, new or old
⍝H                   d.update dict1 (k1 v1) dict2 (k2 v2)   ⍝ Add dictionaries and key-value pairs to dict <d>
⍝H                   d.sort                    ⍝ Set active order, sorting by ascending keys 
⍝H                   d.sortd                   ⍝ Set active order, sorting by descending keys
⍝H STATUS
⍝H    len      ←     d.len                     ⍝ Return # of items
⍝H    b1 b2 b3 ←     d.defined keys            ⍝ Return 1 for each key in list that exists
⍝H                   d.print                   ⍝ Show (⎕←) keys, values by columns  
⍝H                   d.hprint                  ⍝ Show keys, values by rows (⍪d.print)
⍝H                   d.disp                    ⍝ Print by columns via dfns disp (variant of display) 
⍝H                   d.hdisp                   ⍝ Print by rows via dfns disp
⍝H                   d.⎕CT, d.⎕DCT             ⍝ Set or Get ⎕CT, ⎕DCT: affects key searches!
⍝H DELETE
⍝H    b1 b2 b3 ←  [ign←0] d.del keys           ⍝ Delete items by specific key (ign: ignore missing keys)
⍝H    b1 b2 b3 ←  [ign←0] d.delbyindex indices ⍝ Delete items by specific index (ign: ignore missing keys)
⍝H                   d.clear                   ⍝ Delete all items in the dictionary 
⍝H                                               (maintain defaults, namespace, etc.)
⍝H INC/DEC
⍝H    n1 n2 n3 ←  [incr←1] d.inc keys          ⍝ Increment values for specific keys
⍝H    n1 n2 n3 ←  [decr←1] d.dec keys          ⍝ Decrement values for specific keys
⍝H
⍝H POP
⍝H    (k1 v1)(k2 v2)... ←  d.popitem count     ⍝ Remove/return <count> items from end of dictionary.
⍝H    vals  ←              d.pop keys          ⍝ Remove/return values for specific keys from dictionary.
⍝H
⍝H MISC
⍝H ns  ← preferNumeric  d.mirror 'NEW'         ⍝ Create a namespace whose variables track dictionary entries and vice versa.
⍝H                                             ⍝ preferNumeric: If 1, namespace variables resolving to numeric strings 
⍝H                                             ⍝                are converted to numeric keys and vice versa.
⍝H                      d.mirror 'DEL'         ⍝ * Delete (disconnect) the current namespace from the dictionary forever.
⍝H                      d.mirror 'ON'          ⍝ * Enable active mirroring, after previously disabling. 
⍝H                      d.mirror 'OFF'         ⍝ * Disable active mirroring temporarily.
⍝H                                               * May only be used after d.mirror 'NEW' and d.mirror 'DEL'
⍝H
⍝H =========================================================================================
⍝H    Dictionary CREATION
⍝H =========================================================================================
⍝H d← ∆DICT ⍬
⍝H    Creates a dictionary <d> with no items and no default. Items may be added via d[k1 k2...]←v1 v2...
⍝H    A default value may be added via d.default← <any object>.
⍝H
⍝H d← [def] ∆DICT objs
⍝H    Creates dictionary <d> with optional default <default> and calls 
⍝H       d.update objs   ⍝ See below
⍝H    to set keys and values from key-value pairs, (keys values) vectors, and dictionaries.
⍝H
⍝H d←∆DICT ⊂default      OR    d←default ∆DICT ⍬
⍝H    default must be a simple scalar, like 5, or it must be enclosed.
⍝H        e.g. ∆DICT 10         creates an empty dictionary with default value 10.
⍝H             ∆DICT ⊂⍬         creates an empty dictionary with default value ⍬ (not ⊂⍬).
⍝H             ∆DICT ⊂'Missing' creates an empty dictionary with default value 'Missing'.
⍝H
⍝H newDict ← d.copy             ⍝ Make a copy of dictionary <d> as <newDict>, including defaults.
⍝H
⍝H
⍝H =========================================================================================
⍝H    SETTING/GETTING DICTIONARY ITEMS BY KEY
⍝H =========================================================================================
⍝H d[⊂k1] or d[k1 k2...]
⍝H    Return a value for each key specified. Raises an error any key is not in the dictionary, 
⍝H    unless a default is specified.
⍝H    See also get, get1 
⍝H
⍝H d[⊂k1] ← (⊂v1) OR d[k1 k2...]←v1 v2 ...
⍝H     Assign a value to each key specified, new or existing.
⍝H
⍝H d[] calls the method keys2Vals: d.keys2Vals[k1 k2] ≡ d[k1 k2]  
⍝H
⍝H =========================================================================================
⍝H   GETTING (LISTING) OF ALL KEYS / KEYS BY INDEX OR VALUE (REVERSE LOOK-UP)
⍝H =========================================================================================
⍝H keys ← d.keys                     [alias: key]
⍝H     Return a list of all the keys used in the dictionary d.
⍝H
⍝H keys ← d.keys[indices]            [alias: key]
⍝H     Return a list of keys by numeric indices i1 i2 ...
⍝H
⍝H keys  ←  d.vals2Keys[vals]   
⍝H keys  ←  d.vals2Keys[]  OR  
⍝H "Return lists of keys indexed by values <vals>, as if a 'reverse' lookup." 
⍝H "Treating values as indices, find all keys with given values, if any.
⍝H  Returns a list of 0 or more keys for each value sought; ⍬ is returned for each MISSING value.
⍝H  Unlike dict.keeeeee keys, aka dict[keys], dict.vals2Keys[] may return many keys for each value." 
⍝H  If an index expression is elided,
⍝H       keys←d.vals2Keys[] or keys←d.v2K[],
⍝H  it is treated as requesting ALL values:
⍝H       keys←d.vals2Keys[d.values],
⍝H  returning a keylist for each value in d.values (which need not be unique).
⍝H  (These need not be unique; for only 1 copy of each keylist, do: ukeys←∪d.v2K[]).
⍝H
⍝H ------------------------------------------------
⍝H    SETTING/GETTING ALL VALUES / VALUES BY INDEX
⍝H ------------------------------------------------
⍝H vals ← d.values                     [alias: value, vals, val]
⍝H     Returns the list of values  in entry order for  all items; suitable for iteration
⍝H         :FOR v :in d.values ...
⍝H
⍝H vals ← d.values[indices]            [aliases as above]
⍝H     Returns a list of item values by numeric indices i1 i2 ...
⍝H
⍝H d.values[indices]←newvals           [aliases as above]
⍝H     Sets new values <newvals> for existing items by indices.
⍝H
⍝H =========================================================================================
⍝H    COMMON MISCELLANEOUS METHODS
⍝H =========================================================================================
⍝H d2 ← d.copy
⍝H     Return a shallow copy of the dictionary d, including its defaults
⍝H
⍝H bool ← d.defined (⊂k1) OR d.defined k1 k2 ...
⍝H     Return 1 for each key that is defined (i.e. is in the dictionary)
⍝H
⍝H nitems ← d.len  
⍝H     Return the number of items in the dictionary d.
⍝H
⍝H bool ← [ignore←0] d.del (⊂k1) OR d.del k1 k2 ...
⍝H     Remove keys from d.
⍝H     Ignore=0: Shyly returns 1 for each key; signals an error of any key is not in the dictionary
⍝H     Ignore=1: Shyly returns 1 for each key found, 0 otherwise.
⍝H     Efficient if the items to delete are contiguous at the end of the dictionary
⍝H
⍝H bool ← [ignore←0] d.delbyindex i1 i2 ...               
⍝H bool ← [ignore←0] d.di i1 i2 ...              ⍝ Alias to delbyindex
⍝H     Removes items from d by indices i1 i2 .... 
⍝H     Ignore=0: Returns 1 for each item removed. Signals an error if any item does not exist.
⍝H     Ignore=1: Returns 1 for each item removed; else 0.
⍝H     Efficient if the items to delete are contiguous at the end of the dictionary
⍝H
⍝H d.clear
⍝H     Remove all items from the dictionary.
⍝H
⍝H d.⎕CT, d.⎕DCT 
⍝H     Impacts searches for numeric (⎕CT) or decimal float (⎕DCT) numbers among dictionary keys (see Dyalog ⍳).
⍝H     d.⎕CT←1E¯4, old←d.⎕DCT, etc.
⍝H ------------------------------------------------
⍝H    DEALING WITH VALUE DEFAULTS
⍝H ------------------------------------------------
⍝H d←[def] ∆DICT objs
⍝H   Set DEFAULT values at creation (no default is created if objs is null)
⍝H
⍝H d.default←value
⍝H     Sets a default value for missing keys. Also sets d.hasdefault←1
⍝H
⍝H d.hasdefault←[1 | 0]
⍝H     Activates (1) or deactivates (0) the current default.
⍝H     ∘ Initially, by default:  hasdefault←0  and default←'' 
⍝H     ∘ If set to 0, referencing new entries with missing keys cause a VALUE ERROR to be signalled. 
⍝H     ∘ Setting hasdefault←0 does not delete any existing default; 
⍝H       it is simply inaccessible until hasdefault←1.
⍝H
⍝H d.querydefault
⍝H      Returns a vector containing the current default and 1, if defined; else ('' 0)
⍝H
⍝H vals ← [def] d.get  k1 k2 ...
⍝H val  ← [def] d.get1 k1
⍝H     Return the value for keys in the dictionary, else default. 
⍝H     If <default> is omitted and a key is not found, returns the existing default.
⍝H
⍝H (k1 k2 ... d.set v1 v2) ... OR (d.set (k1 v1)(k2 v2)...)
⍝H (k1 d.set1 v1) OR (d.set1 k1 v1)
⍝H     Set one or more items either with 
⍝H          a keylist and valuelist: k1 k2 ... ∇ v1 v2 ...
⍝H     or as
⍝H          key-value pairs: (k1 v1)(k2 v2)...
⍝H
⍝H =========================================================================================
⍝H    BULK LOADING OF DICTIONARIES
⍝H =========================================================================================
⍝H d.update  [obj1 | obj2 | obj3 | ⊂default] [obj1 | obj2 | obj3 | ⊂default] ...
⍝H    For dictionary d, sets keys and values from objs of various types or set value defaults:
⍝H         ∘ ITEMS:     key-value pairs (each pair specified one at a time), 
⍝H         ∘ DICTS:     dictionaries (nameclass 9.2, with ⎕THIS∊⊃⊃⎕CLASS dict)
⍝H         ∘ LISTS:     key-value lists (keys in one vector, values in another), and 
⍝H         ∘ DEFAULTS:  defaults (must be a scalar or namespace-class, 
⍝H                      as long as not a Dict
⍝H    Any defaults are not loaded.
⍝H    obj1:  (key1 val1)(key2 val2)...
⍝H           objects passed as key-value pairs; keys and vals may be of any type...
⍝H    obj2:  dict
⍝H           A dict is an existing instance (scalar) of a DictClass object.   
⍝H    obj3:  ⍪keys vals [def] 
⍝H           keys and values are each scalars, structured in table form (as a column matrix).
⍝H           The default, if present, may be any shape or nameclass.
⍝H    default: any APL object of any shape (as long as not a dict), but must be enclosed to be recognized. 
⍝H           Note: a default would normally be specified once. Those to the right take precedence.
⍝H           E.g.  5   OR   ⊂'John'   OR  (⊂2 3⍴⍳6)  OR  (⊂'')   OR  (⊂⍬)  
⍝H
⍝H d ← d.import (k1 k2 ...) (v1 v2 ...)
⍝H     Set one or more items from a K-V LIST (⍵1 ⍵2)
⍝H         ⍵1: a vector of keys
⍝H         ⍵2: a vector of values.
⍝H     To set a single key-value pair (k1 v1), use e.g.:
⍝H         k1 d.set1 v1 
⍝H         d.import (,k1)(,v1)
⍝H
⍝H d ← {preferNumericKeys} d.importNS ns
⍝H     Imports items from variables in <ns>, from classes 2, 3, 4, and 9.
⍝H     Items in classes 3 and 4 are converted quietly to ⎕OR representation.
⍝H     Keys are converted to variables via JSON Mangling. 
⍝H     preferNumericKeys: 
⍝H         if 1, prefer numeric keys when mirroring: convert numeric strings to/from numbers; 
⍝H         if 0, do not convert numeric strings. [def]
⍝H     See d.mirror for more information.
⍝H
⍝H keys vals ← d.export
⍝H     Returns a K-V LIST consisting of a vector of keys.
⍝H     Efficient way to export ITEMS from one dictionary to another:
⍝H          d2.import d1.export 
⍝H     Does not export defaults.
⍝H
⍝H =========================================================================================
⍝H    MANAGING ITEMS (K-V PAIRS)
⍝H =========================================================================================
⍝H items ← d.items [k1 k2 ...]
⍝H     Return a list of all OR the specified dictionary’s items ((key, value) pairs).  
⍝H
⍝H items ← d.popitems n
⍝H     Shyly returns and deletes the n (n≥0) most-recently entered key-value pairs.
⍝H     This is done efficiently, so that the dictionary is not rehashed.
⍝H
⍝H keys ← [def] d.pop key1 key2 ...
⍝H     Shyly returns the values for keys key1..., while deleting each found item.
⍝H     If default is NOT specified and there is no dictionary default, then
⍝H     if any key is not found, d.pop signals an error; otherwise,
⍝H     it returns the default for each missing item.
⍝H
⍝H =========================================================================================
⍝H    MAPPING DICTIONARY ENTRIES TO AND FROM VARIABLES IN A PRIVATE NAMESPACE
⍝H    ns ← [⍺] d.mirror NEW 
⍝H    ns ← d.mirror  [DEL | ON | OFF]
⍝H =========================================================================================
⍝H    ns ← preferNumericKeys d.mirror 'NEW'
⍝H          - returns a reference to the active private namespace, activating it if not already so.
⍝H          - Each key in a mirrored dictionary must be a char vector or scalar, or a numeric scalar or vector;
⍝H            it will be rendered as a namespace variable (in ns) via JSON name mangling (see Dyalog I-beam 7162⌶).
⍝H    preferNumericKeys ∊ 1, 0
⍝H      1   - A namespace variable name that (after name demangling) is a numeric string will
⍝H            map onto (be converted to) a dictionary key that is numeric.
⍝H      0   - A namespace variable name that (after name demangling) is a numeric string will
⍝H            map onto  a dictionary key that is a character string.
⍝H      WARNING: A key may be a vector of character vectors, but its namespace variable name
⍝H             will be mirrored back as a single vector with spaces in place of separate vectors. 
⍝H    ∘ Dictionary values that are object representations are a special case...
⍝H      ...Namespace object values that are functions or operators are a special case.
⍝H      - Any dictionary value that is an object representation (⎕OR) will be automatically converted to its
⍝H        function or operator format when assigned to its namespace variable.
⍝H      - Any variable in the namespace assigned a value as a function or operator will map onto 
⍝H        a dictionary item whose value is the ⎕OR of that function or operator.
⍝H    ∘ A special object '__DictTrigger__' (an APL trigger) may appear in the namespace. 
⍝H      It is never imported by d.mirror or d.importNS
⍝H ---------------------------------
⍝H     ns  ← d.mirror 'OFF' | 'ON'  |  'DEL'
⍝H         Valid only for a mirror-enabled dictionary (d.mirror 'NEW'), which has not been disconnected (d.mirror 'DEL').
⍝H         Otherwise, an error is signaled.
⍝H         'OFF'
⍝H            Temporarily disables the mirroring of a dictionary to a namespace and vice versa. 
⍝H            Objects established during that time won't be updated, even when the mirroring
⍝H            is re-enabled, but any subsequent changes (to those or new objects) will be reflected.
⍝H            Returns the mirror namespace.
⍝H         'ON'
⍝H            Restores the mirroring of a dictionary to a namespace and vice versa, if previously disabled.
⍝H            Returns the mirror namespace.
⍝H         'DEL'
⍝H            Permanently severs the connection between the dictionary and the actively mirrored namespace.
⍝H            If the user has maintained a copy of the namespace (e.g. saveNS← d.mirror 0),
⍝H            its contents will reflect the most recent mirroring, but no further updates will occur.
⍝H            Returns ⎕NULL.
⍝H        
⍝H =========================================================================================
⍝H    COUNTING OBJECTS AS KEYS
⍝H =========================================================================================
⍝H nums ← [amount ← 1] d.inc k1 k2 ...
⍝H     Increments the values of keys by <amount←1>. 
⍝H     If a value is undefined and no default is set, 0 is assumed (and incremented).
⍝H     If any referenced key's value is defined and non-numeric, an error is signalled.
⍝H
⍝H nums ← [amount ← 1] d.dec k1 k2 ...
⍝H      Identical to d.inc (above) except decrements the values by <amount←1>.
⍝H
⍝H =========================================================================================
⍝H    SORTING KEYS
⍝H =========================================================================================
⍝H d ← d.sort OR d.sorta
⍝H     Sort a dictionary in place in ascending order by keys, returning the dictionary
⍝H
⍝H d ← d.sortd
⍝H     Sort a dictionary in place in descending order by keys, returning the dictionary 
⍝H
⍝H d ← d.reorder indices
⍝H     Sort a dictionary in place in order by indices.
⍝H     Indices depend on ⎕IO in the caller environment.
⍝H     All indices of <d> must be present w/o duplication:
⍝H           indices[⍋indices] ≡ ⍳d.len
⍝H     Example: Equivalent of d.sortd; sort dictionary by keys
⍝H           d.reorder ⍋d.keys
⍝H     Example: Sort dictionary by values
⍝H           d.reorder ⍋d.values
⍝H     Example: Make a copy of <d>, but sorted in reverse order by values:
⍝H           d_prime ← d.copy.reorder ⍋d.values
⍝H
⍝H ------------------------------------------------
⍝H    Fancy Example
⍝H ------------------------------------------------
⍝H Reorganize a dictionary ordered by vals in descending order, rather than original entry or keys
⍝H      OK       a←a.copy.clear.update a.items[⍒a.vals]
⍝H      BETTER   a.reorder ⍒a.vals
⍝H ------------------------------------------------
⍝H    [NOTES]
⍝H ------------------------------------------------
⍝H Dictionaries are ORDERED: they preserve insertion order unless items are sorted or deleted. 
⍝H ∘ Updating an item's key does not affect its position in order. 
⍝H ∘ New keys are always added at the end, in the last positions in order, so updates are fast.
⍝H ∘ Existing items are updated in place, so updates are fast.
⍝H ∘ Getting items by key or index is quite fast, as is checking if they are defined. 
⍝H ∘ To force an  existing item to the last position in order, 
⍝H   it must be deleted and re-entered, or the entire array must be sorted or reordered.
⍝H
⍝H Dictionaries are hashed according to their keys (using APL hashing: 1500⌶).
⍝H ∘ Hashing is preserved when updating items, adding new items, searching for items, etc.
⍝H ∘ Hashing is preserved when popping items (which is therefore fast)
⍝H ∘ Hashing is NOT usually preserved when deleting objects (del or di).
⍝H   ∘ If all keys to delete are a contiguous set of the last (rightmost) keys, hashing is preserved.
⍝H   ∘ If at least one key is not part of a contiguous set at the right end, the hash is rebuilt.
⍝H   ∘ Deleting a set of keys at once is efficient; the dictionary is rehashed all at once.
⍝H     FAST:     d.del 1 20 17 5 22 29 ... 
⍝H   ∘ Deleting items one at a time reequires rebuilding and rehashing each time. Avoid!
⍝H     SLOW:    :FOR i :in 1 20 17 5 22 29 ... ⋄ d.del i ⋄ :ENDFOR
⍝H     SLOW:    {d.del ⍵}¨ 1 20 17 5 22 29 ...  
⍝H ∘ If the same key is updated in a single call with multiple values 
⍝H       dict[k1 k1 k1]←v1 v2 v3
⍝H   only the last value (v3) is kept.
⍝H
⍝H =========================================================================================
⍝H    ∆JDICT function  for JSON <==> APL Namespaces and Dictionaries  
⍝H =========================================================================================
⍝H  {minorOpt} ∆JDICT fs
⍝H   ∘ Converts between one or more JSON object defs or APL ns equivalents and the equivalent
⍝H     DictClass dictionary (or vice versa).
⍝H   ∘ Assumes that JSON null is mapped onto APL ⎕NULL and vice versa: minorOpt ('Null'⎕NULL).
⍝H   ∘ The user can select either compact or non-compact JSON output; both are valid on input.
⍝H 
⍝H  I. If argument <json> is a string or namespace,  
⍝H    ∘ Convert a Json object string or its equivalent APL namespace
⍝H      to dictionary. 
⍝H    ∘ Keys will be in JSON (non-mangled) format.
⍝H    ∘ If the JSON string refers to an array with multiple items 
⍝H      or if multiple namespaces are presented, returns a vector of dictionaries;
⍝H      Otherwise, returns a single dictionary.
⍝H    ∘ If in namespace form, only objects of classes 2.1 and 9.1 are evaluated,
⍝H      as expected for JSON.
⍝H    ∘ Here, the {minorOpt} parameter is ignored.
⍝H 
⍝H  II. If argument <json> is a dictionary,  
⍝H  A...if minorOpt is 0 (returns compact JSON); if 1 (returns non-compact JSON)
⍝H  B...and if minorOpt is 2 (returns namespace) 
⍝H    ∘ Names are mangled via JSON (APL) protocols, so APL variable names are valid.
⍝H  
⍝H  NOTE: inverses are only partial, since all JSON keys MUST be strings and
⍝H        values must be those that ⎕JSON can deal with. Otherwise an error occurs.
⍝H  EXAMPLE: 
⍝H      d←∆JDICT '{"123": 5, "⍴5":1}'
⍝H      d.table
⍝H  123  5
⍝H  ⍴5   1
⍝H       n←2 ∆JDICT d
⍝H       )cs n
⍝H  #.[Namespace]
⍝H       )vars
⍝H  ⍙123    ⍙⍙9076⍙5      ⍝ From keys: "123"   "⍴5"   
⍝H      ⍙123
⍝H  5
⍝H      ⍙⍙9076⍙5
⍝H  1
⍝H =========================================================================================
⍝H    JSON EXAMPLES
⍝H =========================================================================================
⍝H
⍝H ⍝ Simple JSON test case! Generates 3 top-level dictionaries.
⍝H ⍝ Use DictClass object DictClass.JSONsample
⍝H  
⍝H       ⎕←Dict.JSONsample
⍝H [{"id":"001", "name":"John Smith", "phone":"999-1212"},{"id":"002", "name":"Fred Flintstone", 
⍝H   "phone":"254-5000"},{"id":"003","name":"Jack Sprat","phone":"NONE"}]
⍝H      ⎕←(d e f)← ∆JDICT  ⎕←Dict.JSONsample
⍝H Dict[]  Dict[]  Dict[]         ⍝ 3 dictionaries
⍝H      1 ∆JDICT d e f
⍝H [                             
⍝H   {                           
⍝H     "id": "001",              
⍝H     "name": "John Smith",     
⍝H     "phone": "999-1212"       
⍝H   },                          
⍝H   {                           
⍝H     "id": "002",              
⍝H     "name": "Fred Flintstone",
⍝H     "phone": "254-5000"       
⍝H   },                          
⍝H   {                           
⍝H     "id": "003",              
⍝H     "name": "Jack Sprat",     
⍝H     "phone": "NONE"           
⍝H   }                           
⍝H ]  
⍝H     (d e f).table            ⍝   Show the contents of the 3 dictionaries
⍝H  id     001           id     002                id     003         
⍝H  name   John Smith    name   Fred Flintstone    name   Jack Sprat  
⍝H  phone  999-1212      phone  254-5000           phone  NONE        
⍝H
:EndClass
