:Class DictClass
⍝ Documentation is provided in detail at ∆DICT.help

⍝ ------------------------------------------------------------------------------------------
⍝ INITIALIZATION  
⍝ ------------------------------------------------------------------------------------------
⍝ System Variables...
    ⎕IO ⎕ML ⎕PP ←0 1 34  
⍝ ⎕CT, ⎕DCT, ⎕RL are set to be the same as in ## at FIX time
    (⎕CT ⎕DCT ⎕RL)←##.(⎕CT ⎕DCT ⎕RL)   
⍝ ------------------------------------------------------------------------------------------
⍝ General class Fields                                  /U_U/
  ⍝ Export/Class Fields: Export key utilities to the parent environment (hard-wiring ⎕THIS namespace)?
  ⍝     [0]    Dict,     [1]    ∆DICT 
    :Field Private Shared EXPORT_LIST←        'Dict' '∆DICT'     ⍝ See EXPORT_FUNCTIONS below
    :Field Private Shared DICTCLASS←          ⎕THIS   ⍝ Utilities are exported to DICTCLASS.## 
    :Field Private Shared BASECLASS←          ⊃⊃⎕CLASS ⎕THIS
  ⍝ ID fields
    :Field Private Shared ID_COUNT←           0
    :Field Private Shared ID_PREFIX←          ,'<⎕DICT=>,6ZI2,<.>'⎕FMT⍉⍪(6↑¯2000)+¯1↓⎕TS
  ⍝ TRAPPING
    :Field Private  Shared ∆TRAP←           0 'C' '⎕SIGNAL/⎕DMX.((EM,Message,⍨'': ''/⍨0≠≢Message) EN)'
  ⍝ ERROR MESSAGES:  [en=11] 'Error Message'          /eCC/
    :Field Private Shared eImportBad←         'At least one object to import was invalid.'
    :Field Private Shared eImportBad2←        'At least one object to import was invalid. Did you mean (⊂key val)?'
    :Field Private Shared eBadClass←          'Invalid class specification.' 
    :Field Private Shared eBadDefault←        'hasDefault must be set to 1 (true) or 0 (false).'
    :Field Private Shared eBadNS←             'Namespace specified is invalid.'
    :Field Private Shared eBadNSVar←          'Unable to import item from namespace. Invalid nameclass or subclass.'
    :Field Private Shared eDelKeyMissing←     'd.del: at least one key was not found and ⍺:ignore≠1.'
    :Field Private Shared eIndexRange←      3 'd.delByIndex: An index argument was invalid or not in range (⍺:ignore≠1).'
    :Field Private Shared eKeyAlterAttempt←   'd.keys: item keys may not be altered.'
    :Field Private Shared eHasNoDefault←    3 'Key does not exist and no default was set.'
    :Field Private Shared eHasNoDefaultD←   6 'd.default: no default was set.'
    :Field Private Shared eQueryDontSet←      'd.queryDefault is read-only. Set d.default or d.hasDefault.'
    :Field Private Shared eBadInt←            'd.inc/d.dec: increment (±⍺) and value for each key in ⍵ must be numeric.'
    :Field Private Shared eKeyBadName←        'd.namespace: Unable to convert key to valid APL variable name'
    :Field Private Shared eMirFlag←           'd.mirror: flag (⍵) must be one of CONNECT | ON | OFF | DISCONNECT.'
    :Field Private Shared eMirDisc←           'd.mirror: No namespace mirror established (via d.mirror ''CONNECT'').'
    :Field Private Shared eMirNumKeys←        'd.mirror: left arg, if present, must be 1 (prefer numeric keys) or 0.'
    :Field Private Shared eMirLogic←          'd.mirror (⍙mirrorOpts) LOGIC ERROR'
    :Field Private Shared ePopItems←        3 'd.popItems: # items to remove from "end" of dictionary must be ≥0'
    :Field Private Shared eReorder←           'd.reorder: at least one index value is out of range, missing, or duplicated.'
  ⍝ ------------------------------------------------------------------------------------------
  ⍝ Instance Fields and Related                         /øcC/       
  ⍝ A. IDs:  Create Display form of form:      
  ⍝          DictMMDDHHMMSS.dd (digits from day, hour, ... sec, plus increment for each dict created).
  ⍝    See d.ID: the R/O instance method
    :Field Private        øid          
  ⍝ B. Core dictionary fields
                   økeys←                   ⍬        ⍝ Non-field variable avoids Dyalog bugs with catenating/hashing.
    :Field Private øvalues←                 ⍬        ⍝ Always (≢økeys)≡(≢øvalues)
    :Field Private øhasDefault←             0
    :Field Private ødefault←                ''       ⍝ Default value (suppressed until øhasDefault is 1)
  ⍝ C. Mirroring dictionary to a namespace
  ⍝    ømirror etc.: see d.preferNumericKeys, d.ns, d.mirror
    :Field Private ømirror←                 ⎕NULL    ⍝ ⎕NULL (no mirror), namespace ref (active mirror)
    :Field Private ømirPrefNK←              0        ⍝ 0 (var names map onto strings), 0 (...onto numbers, if feasible)
    :Field Private ømirActive←              0        ⍝ 1 (active), 0 (inactive: temporarily or because no ømirror)  
    :Field Private ømirId←                  0        ⍝ Increments on each new mirror namespace created
  ⍝-------------------------------------------------------------------------------------------
  ⍝ External (User-visible) Utilities...
  ⍝   In DICTCLASS and copied to ##.DICTCLASS 
  ⍝-------------------------------------------------------------------------------------------
  ⍝ ∆DICT (user utility)
    ∇dict←{default} ∆DICT items_default                   ⍝ Creates ⎕NEW Dict via cover function
    :Access Public Shared
     :TRAP 0
        dict←(⊃⎕RSI,#).⎕NEW DICTCLASS items_default       ⍝ May set the d.default via <items_default>
        :IF ~900⌶1 ⋄ dict.default←default ⋄ :Endif        ⍝ An explicit <default> overrides any set in <items_default>
     :Else
        ⎕SIGNAL ⊂⎕DMX.(('EN' 11)('EM' EM) ('Message' Message))
     :EndTrap
    ∇
  ⍝ Dict (user utility)
  ⍝ Returns the dictionary class namespace. Searchable via ⎕PATH. 
     ∇ ns←Dict                      
        :Access Public Shared                             ⍝ Usage:  a←⎕NEW Dict [...]  with ⎕THIS.## in the path!
        ns←DICTCLASS
    ∇ 
  ⍝-------------------------------------------------------------------------------------------
  ⍝ Constructors...
  ⍝-------------------------------------------------------------------------------------------
    ⍝ New1: "Constructs a dictionary and updates*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Optionally, sets the default value."
    ⍝ Uses ⍙import, which will handle duplicate keys (the last duplicate quietly wins), and so on.
    ⍝ *** See d.import for conventions for <items_default>.
    ∇ new1 struct
      :Implements Constructor
      :Access Public
      :Trap 0
          ⍙import struct      
          SET_ID
      :Else  
          ⎕SIGNAL ⊂⎕DMX.(('EN' EN)('EM' EM) ('Message' Message))
      :EndTrap
    ∇
    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
       SET_ID
    ∇
    ⍝ SET_ID: Set unique ID of this dictionary (for fast comparisons) of the form:
    ⍝        øid:   'DICT:',<date-time prefix>,<counter>
    ⍝ Sets the display form and returns the ID field øid, after incrementing the ID_COUNT.
    ∇ {returning}←SET_ID
      ⎕DF returning ← øid←ID_PREFIX,⍕ID_COUNT ← 2147483647 | ID_COUNT + 1
    ∇
    ∇ destroy
      :Implements Destructor
      :If ømirror≢⎕NULL 
          ⍙mirrorOpts ¯1   ⍝ If there's any mirroring, remove it. 
      :EndIf
    ∇

⍝-------------------------------------------------------------------------------------------
⍝ Instance Methods
⍝    (Methods documented as d.methodName
⍝-------------------------------------------------------------------------------------------  
  ⍝ d.id
    ⍝ "Return the ID field, øid, (same as instance ⎕DF) for the current dictionary instance" 
    ∇id←id
     :Access Public
     id←øid
    ∇

  ⍝ d[key1 key2...] | d[⊂key]     (Implicit [] version)
  ⍝ d.keys2Vals                   (Explicit version)
    ⍝ keys2Vals: "Using standard vector indexing and assignment, set and get the value for each key." 
    ⍝             New entries are created automatically
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
          :If ⎕NULL≡⊃args.Indexers ⋄ vals←øvalues ⋄ :Return ⋄  :EndIf
          shape←⍴ix←økeys⍳⊃args.Indexers  
          :If ~0∊found←ix<≢økeys
              vals←øvalues[ix]                
          :ElseIf øhasDefault
             vals← found ∆EXPAND øvalues[found/ix]    ⍝ Insert slot(s) for values of new keys. See Note [∆EXPAND]
              ((~found)/vals)←⊂ødefault                   ⍝ Add default values for slots just inserted.
              vals⍴⍨←shape                                ⍝ Ensure vals is scalar, if the input parm args.Indexers is.
          :Else
               THROW eHasNoDefault
          :EndIf
        ∇
        ∇ set args;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          keys←⊃args.Indexers ⋄ vals←args.NewValue 
          ⍙importVecs keys vals
        ∇
    :EndProperty

  ⍝ d.vals2Keys val1 [val2...] 
  ⍝    "Get the (zero or more) keys for each dictionary value, parallel to keys2Vals."
  ⍝     Since many keys may have the same value, 
  ⍝     returns a list (vector) of 0 or more keys for each value sought.
  ⍝     ⍬ is returned for each MISSING value."
  ⍝     Setting is prohibited!
  ⍝ keys ← d.vals2Keys[]         ⍝ Return keys for all values
    :Property keyed vals2Keys 
    :Access Public
        ∇ keys←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          ix←{⎕NULL≡⍵: øvalues ⋄ ⍵}⊃args.Indexers
          keys←{k ⍬⊃⍨0=≢k←økeys/⍨øvalues≡¨⊂⍵}¨ix   ⍝ Ensure 0-length ⍬ when vals missing.
          keys⍴⍨←⍴ix     ⍝ Ensure scalar index means scalar is returned.
        ∇
    :EndProperty
    
  ⍝ d.get      
    ⍝ "Retrieve values for keys ⍵ with optional default value ⍺ for each missing key"
    ⍝    default d.get key1 key2...   OR   default d.get ⊂key1 
    ⍝ (See also d.get1)
    ⍝  Use d[⊂⍵] when a default is already set (via d.default) or missing keys are disallowed.
    ⍝  d.get keys   ⍝ -- all keys must exist or have a (class-based) default
    ⍝ default d.get keys   ⍝ -- keys which don't exist are given the (fn-specified) default
    ∇ vals←{def} get keys;d;nd;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1 
          vals←keys2Vals[keys]
      :ELSE 
          nd←~d←defined keys
          vals← d ∆EXPAND keys2Vals[d/keys]  ⍝ See ∆EXPAND definition above
          (nd/vals)←⊂def
      :ENDIF
    ∇
  ⍝ d.get1
    ⍝ "Retrieve value for a single key ⍵ with optional default value ⍺, where ⍵ is missing."
    ⍝     default d.get1 key   ⍝ -- if key doesn't exist, it's given the specified default
    ⍝  Notes:
    ⍝     [⍺] d.get1 ⍵ <==>  [⍺] d.get ⊂⍵ 
    ⍝     Use d[⊂⍵] when a default is already set (via d.default) or missing keys are disallowed.  
    ⍝         d.get1 key   ⍝ -- the key must exist or have a default
    ∇ val←{def} get1 key;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1  ⋄ def←⊢ ⋄ :ENDIF
      val←⊃def get ⊂key
    ∇

  ⍝ d.set  
    ⍝ "Set keys ⍺ to values ⍵ OR set key value pairs: (k1:⍵11 v1:⍵12)(k2:⍵21 v2:⍵22)..."
    ⍝  (See also d.set1)
    ⍝  {vals}← keys d.set values
    ⍝  {vals}←      d.set (key1 val1)(key2 val2)...(keyN valN)
    ∇ {vals}←{keys} set vals;⎕TRAP
        :Access Public
        ⎕TRAP←∆TRAP
        :If 900⌶1 ⋄ keys vals←↓⍉↑,vals ⋄ :EndIf
        ⍙importVecs keys vals
    ∇
  
  ⍝ d.set1  
    ⍝ "set single key ⍺ to value ⍵ OR set key value pair: (k1:⍵1 v1:⍵2)"
    ⍝  (See also d.set)
    ⍝  {val}←k1 d.set1 v1    
    ⍝  {val}←   d.set1 k1 v1    
    ∇ {val}←{key} set1 val;⎕TRAP
        :Access Public
        ⎕TRAP←∆TRAP
        :If 900⌶1 ⋄ key val←val ⋄ :EndIf
        ⍙importVecs ,∘⊂¨key val
    ∇

  ⍝ d.import ⍵ 
  ⍝ internal: ⍙import, ⍙importVecs,  ⍙importTable, ⍙importNS 
    ⍝ "inserts items in the dictionary from (possibly complicated) scalar objects ⍵[N] of several types." 
    ⍝  [preferNK] d.import ⍵:   
    ⍝ ------------------------
    ⍝  1. If ⍵[N] contains a vector, it is treated as an "item" (a key-value pair) and must have two elements.
    ⍝     e.g. (1 10) or ('John' 'Smith')
    ⍝  2. ⍵[N] may be a dictionary to import (sans settings)
    ⍝  3. ⍵[N] may be a namespace whose variables/values are to be imported
    ⍝     ∘ In this case, if preferNK is set to 1, 
    ⍝       variables of the form of a numeric scalar/vector (after JSON name conversion) will generate numeric keys
    ⍝     ∘ By default, such variables are treated as numeric character strings (e.g. "12345" or "123.45")
    ⍝  4. ⍵[N] may be a "table", i.e. a matrix of shape 2 1 or 3 1, of the form (⍪keyList valList [default]) 
    ⍝     ∘ whose first "row" contains an (enclosed) list of keys
    ⍝     ∘ whose second "row" contains an (enclosed) list of corresponding values
    ⍝     ∘ whose third row, if present, contains the (enclosed) default for missing values  
    ⍝       It's called a "table" format because it is typically generated via the table function "⍪", as in
    ⍝          ⍪(⍳10)(○⍳10)('???')   ==>   keyList←⍳10, valList←○⍳10, default←'???'
    ⍝ Note: import (actually ⍙import) accepts either a SCALAR or VECTOR right argument ⍵.           
    ∇ {dict}←{preferNK} import objects;⎕TRAP
      :Access Public
      :IF 900⌶1 ⋄ preferNK←0 ⋄ :ENDIF
      :TRAP 0 
          preferNK ⍙import objects         ⍝ ⍙import:  See below.
      :Else
          THROW ⎕DMX.(EN Message)
      :EndTrap
      dict←⎕THIS
    ∇
  ⍝ ⍙import objects:            [used only internally]
    ⍝ {preferNK}⍙import objects:  relevant only with namespace objects (⍙importNS)
    ⍝     Returns: void
    ⍝ Used in initialization of ∆DICTs or via ⎕NEW Dict...
    ⍝ objects: 
    ⍝        (⍪keys vals [def]) OR (key1 val1)(key2 val2)(...) OR dictionary
    ⍝    OR  (key1 val1) dict2 (key3 val3) dict4...      ⍝ A mix of key-value pairs and dictionaries
    ⍝ Special case:
    ⍝        If a scalar is passed which is not a dictionary, 
    ⍝        it is assumed to be a default value instead.
    ⍝ Returns: none
     ∇ {preferNK} ⍙import objects;o; isDict;isNS
        isDict← {9.2=⎕NC ⊂,'⍵': BASECLASS∊⊃⊃⎕CLASS ⍵ ⋄ 0} 
        isNS←   {9.1=⎕NC ⊂,'⍵'} 
      ⍝ preferNK- used only for ⍙importNS; otherwise, ignored.
      ⍝ Fast path for ⍬ arg and for vectors of items...
        :IF 0=≢objects
            ⍝ Nothing to import (⍙import ⍬)
        :Elseif 2=⍴⍴objects               ⍝ A table: (⍪k v [def])
            ⍙importTable objects
        :Elseif  2∧.=≢¨objects            ⍝ Fast path-- handle all ITEMS (k v pairs) at once. 
        :Andif   ~2∊∊⍴∘⍴¨objects          ⍝ Ensure  all are items, with none a matrix (see ⍙importTable)
            ⍙importVecs ↓⍉↑,objects
        :Else  
            :FOR o :IN ,objects           ⍝ Mixed objects. Import one by one left to right.
                :IF 2=⎕NC 'o'
                    :SELECT ⍴⍴o
                    :CASE ,1     ⍝ ITEM
                        (2≠≢o) THROW eImportBad
                        ⍙importVecs ,∘⊂¨o   ⍝ set1/o
                    :CASE ,2    
                        ⍙importTable o      ⍝ a table: (⍪k v [def])
                    :ELSE        ⍝ error
                        THROW eImportBad eImportBad2⊃⍨2=≢objects
                    :ENDSELECT
                :ELSEIF isDict o 
                      ⍙importVecs o.(keys vals)   ⍝ Same as: o.keys set o.vals
                :ELSEIF isNS o 
                      o ⍙importNS ⍨ {⍵: 0 ⋄ preferNK}900⌶1
                :ELSE 
                      ⎕SIGNAL eImportBad
                :ENDIF 
            :ENDFOR
        :ENDIF 
    ∇
  ⍝ {keys}←⍙importVecs (keyVec valVec) 
    ⍝ keyVec must be present, but may be 0-len list [call is then a nop].
    ⍝ From vectors of keys and values, keyVec valVec, 
    ⍝ imports instance vars økeys øvalues, then calls OPTIMIZE to be sure hashing enabled.
    ⍝ Returns: shy keys
    ∇ {k}←⍙importVecs (k v)
          ;ix;kp;old;oix;nk;nv;uniq    
      →0/⍨0=≢k                    ⍝      No keys/vals? Return now.
      ix←økeys⍳k                  ⍝ I.   Process existing (old) keys
      old←ix<≢økeys               ⍝      Update old keys in place w/ new vals;
      øvalues[oix←old/ix]←old/v   ⍝      Duplicates? Keep only the last val for a given ix.
      :IF ømirActive  
          ⍙mirror2NS (økeys[oix]) (øvalues[oix]) 0 
      :ENDIF
      →0/⍨~0∊old                  ⍝      All old? No more to do; shy return.
      nk nv←k v/¨⍨⊂~old           ⍝ II.  Process new keys (which may include duplicates)
      uniq←⍳⍨nk                   ⍝      For duplicate keys,... 
      nv[uniq]←nv                 ⍝      ... "accept" last (rightmost) value
      kp←⊂uniq=⍳≢nk               ⍝      Keep: Create and enclose mask...
      nk nv←kp/¨nk nv             ⍝      ... of those to keep.
      (økeys øvalues),← nk nv     ⍝ III. Add new keys and values fields  
      :IF ømirActive 
          ⍙mirror2NS nk nv 0 
      :ENDIF
      OPTIMIZE                    ⍝      New entries: Update hash and shyly return.
    ∇
  ⍝ ⍙importTable: Imports ⍪keyvec valuevec [def]
    ⍙importTable←⍙importVecs{ 2=≢⍵: ⍵ ⋄ 3≠≢⍵: THROW eImportBad ⋄ ødefault øhasDefault⊢←(2⊃⍵) 1⋄ 2↑⍵}∘,  
  ⍝ ⍙importNS: See import method.
    ∇{names}←{preferNK} ⍙importNS ns_classes
      ;classes;hideNS;names;ns;IGNORE
    ⍝ IGNORE: Names NOT to import from the namespace...
      IGNORE←⊆'__DictTrigger__'
      preferNK←{⍵: 0 ⋄ preferNK  }900⌶1 
      ns classes←(⍬⍴ns_classes)({0=≢⍵: 2 3 4 9 ⋄  ⍵ }1↓ns_classes)
          (9.1≠⎕NC⊂'ns')      THROW eBadNS
          (0∊classes∊2 3 4 9) THROW eBadClass
    ⍝ Remove (ignore) names in  IGNORE
      names←IGNORE{⍵/⍨⍺∘{(⊂⍵)(~∊)⍺}¨⍵}ns.⎕NL -classes
    ⍝ ⍝⍝⍝ Replace keys, vals with kvPairs
      (ns preferNK) setKeysFromNames names
    ∇ 

  ⍝ d.copy
    ⍝ "Creates a copy of an object including its current settings (by copying fields)."
    ⍝  Uses ⊃⊃⎕CLASS in case the object is from a class derived from Dict (as a base class).
    ∇ {newDict}←copy
      :Access Public
      newDict←⎕NEW (⊃⊃⎕CLASS ⎕THIS) 
      newDict.import økeys øvalues
      :IF øhasDefault ⋄ newDict.default←ødefault ⋄ :ENDIF 
    ∇

  ⍝ d.export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←export
      :Access Public
      k v←økeys øvalues
    ∇

  ⍝ d.exportNS
    ∇ eNS←exportNS; destroyFlag
      :Access Public
      ømirActive←1                         
      destroyFlag← ømirror≡⎕NULL   ⍝ Check ømirror before mirror call...
      eNS←⎕NS mirror 'CONNECT'     ⍝ mirror call: resets ømirror
      eNS.⎕DF 'Exported.',(⍕ømirId),'@',øid
      {}⍙mirrorOpts ⍣destroyFlag⊣¯1  
    ∇

  ⍝ d.items
    ⍝ items: "Returns ALL key-value pairs as a vector, one pair per vector element. ⍬ if none."
    :Property items,item 
    :Access Public
        ∇ r←get args
          :If 0=≢økeys ⋄ r←⍬
          :Else ⋄ r←↓⍉↑økeys øvalues
          :EndIf
        ∇
    :EndProperty

  ⍝ d.print, d.hprint:  "Returns all the key-value pairs as a matrix, one pair per row/column."
  ⍝ d.disp,  d.hdisp:   "Returns results of print/hprint formatted via dfns.disp (⎕SE.Dyalog.Utils.disp)"
    ⍝ If no items,   returns ⍬.
    :Property print,hprint,disp,hdisp
    :Access Public
    ∇ r←get args
      ;show;disp;⎕PP   
      :If 0=≢økeys ⋄ r←⍬ ⋄ :Return ⋄ :EndIf
      disp←⎕SE.Dyalog.Utils.disp    
      r←↑økeys øvalues 
      ⎕PP←34 
      :SELECT args.Name    
         :Case 'print'   ⋄ r←           ⍉r
         :Case 'disp'    ⋄ r← 0 1 disp  ⍉r 
         :Case 'hdisp'   ⋄ r← 0 1 disp   r  
         :Case 'hprint'  ⍝ r returned as is
      :EndSelect
    ∇
    :EndProperty

  ⍝ d.len:  "Returns the number of key-value pairs."
    :Property len 
    :Access Public
        ∇ r←get args
          r←≢økeys
        ∇
    :EndProperty

  ⍝ d.keys, d.key:  "Get Keys by Index."
    ⍝     "For efficiency, returns the økeys vector, rather than one index element
    ⍝      at a time. Keys may be retrieved, but not set.
    ⍝      In contrast, Values/Vals works element by element to allow direct imports (q.v.)."
    ⍝ k ← d.keys              returns all Keys in entry order
    ⍝ k ← d.keys[ix1 ix2...]  returns zero or more keys by index (user origin).
    :Property keys,key
    :Access Public
        ⍝ get: retrieves keys
        ∇ k←get args 
          k←økeys
        ∇
        ∇ set args
          THROW eKeyAlterAttempt 
        ∇
    :EndProperty

  ⍝ d.values, d.value, d.vals, d.val:
    ⍝   "Get or Set values by index, in active order (creation order, or, if sorted, sort order).
    ⍝    Indices are in caller ⎕IO (per APL).
    ⍝    Note: sets/retrieves element-by-element, as a Dyalog numbered property.
    :Property numbered values,value,vals,val  
    :Access Public
        ⍝ get: retrieves values, not økeys
        ∇ vals←get args;ix
          ix←⊃args.Indexers
          vals←øvalues[ix]     ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ⍝ set: sets Values, not økeys
        ∇ set args;newval;ix
          ix←⊃args.Indexers
          newval←args.NewValue
          øvalues[ix]←newval
        ∇
        ∇ r←shape
          r←⍴øvalues
        ∇
    :EndProperty

  ⍝ d.hasDefault, d.queryDefault, d.default
  ⍝ d.hasDefault← [ 1 | 0]
  ⍝ d.default←    <default_value>
    ⍝    "Sets or queries a default value for missing keys.
    ⍝     By default, hasDefault=0, so the initial Default ('') or previously set Default is ignored,
    ⍝     i.e. a VALUE ERROR is signalled. Setting hasDefault←1 will make the current Default available.
    ⍝     Setting Default to a new value always turns on hasDefault as well."
    ⍝                SETTING    GETTING
    ⍝ hasDefault        Y          Y
    ⍝ default           Y          Y
    ⍝ queryDefault      N          Y
    ⍝
    ⍝ hasDefault:    "Sets the dictionary property ON (1) or OFF (0). If ON, activates current Default value.
    ⍝                 Alternatively, retrieves the current status (1 or 0)."
    ⍝ default:       "Sets the default value for use when retrieving missing values, setting hasDefault←1.
    ⍝                 Alternatively, retrieves the current default."
    ⍝ queryDefault:  "Combines hasDefault and default in a single command, returning the current settings from
    ⍝                 hasDefault and Default as a single pair. queryDefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property default,hasDefault,queryDefault
    :Access Public
    ∇ r←get args
      :Select args.Name
      :Case 'default'      ⋄ (~øhasDefault) THROW eHasNoDefaultD  
                              r←ødefault
      :Case 'hasDefault'   ⋄ r←øhasDefault
      :Case 'queryDefault' ⋄ r←øhasDefault ødefault
      :EndSelect
    ∇
    ∇ set args
      :Select args.Name
      :Case 'default'
          ødefault øhasDefault←args.NewValue 1
      :Case 'hasDefault'
          eBadDefault THROW⍨ (~0 1∊⍨⊂args.NewValue) 
          øhasDefault←⍬⍴args.NewValue   ⍝ ødefault unchanged...
      :Case 'queryDefault'
          THROW eQueryDontSet
      :EndSelect
    ∇
    :EndProperty

  ⍝ d.inc
  ⍝ d.dec
    ⍝  ⍺ d.inc/d.dec ⍵:  Adds (subtracts) ⍺ from values for keys ⍵
    ⍝    d.inc/d.dec ⍵:  Adds (subtracts) 1 from values for key ⍵
    ⍝  ∘ ⍺ must be conformable to ⍵ (same shape or scalar)
    ⍝  Increments serially, left to right, so even if a key is repeated, the increments accumlate.
    ⍝  NOTE: Assumes a default value of 0, for undefined keys, even with an instance default specified.
    ∇ {newvals}←{∆} inc keys;_inc_;⎕TRAP 
      :Access Public
      ⎕TRAP←∆TRAP
      _inc_← { nv←⍺+0 ⍺⍺ ⍵ ⋄ nv⊣⍵ ⍵⍵ nv }
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :TRAP 11 
          :IF (≢∪keys)=≢keys    ⍝ Keys are unique: no need for slower incremental alg.
            newvals←∆ (get _inc_ set) keys
          :Else 
            newvals←∆ (get1 _inc_ set1)¨ keys
          :Endif
      :Else
          THROW eBadInt
      :EndTrap 
    ∇
  ⍝ d.dec - see d.inc
    ∇ {newval}←{∆} dec keys;⎕TRAP
      :Access Public
       ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      (0≠1↑0⍴∆) THROW eBadInt  
      newval←(-∆)inc keys
    ∇

  ⍝ d.defined
    ⍝ Returns 1 for each key found in the dictionary
    ∇ exists←defined keys
      :Access Public
      exists←(≢økeys)>økeys⍳keys
    ∇

  ⍝ d.del
    ⍝ del:  "Deletes key-value pairs from the dictionary for all keys found in a dictionary."
    ⍝        If ignore is 1, missing keys quietly return 0.
    ⍝        If ignore is 0 or omitted, missing keys signal a DOMAIN error (11)."
    ⍝ b ← {ignore←1} d.del key1 key2...
    ⍝ Returns a vector of 1s and 0s: a 1 for each key kN deleted; else 0.
    ∇ {b}←{ignore} del keys;ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      b←(≢økeys)>ix←økeys⍳keys
    ⍝ (Unless ignore=1) Signal error if not all k-v pairs exist
      eDelKeyMissing THROW⍨ (0∊b)∧~ignore 
      ⍙diFast b/ix
    ∇

  ⍝ d.delByIndex
  ⍝ d.di
  ⍝ Internal: ⍙diFast
    ⍝ "Deletes key-value pairs from the d. by index. See del."
    ⍝     If ignore is 1, indices out of range quietly return 0.
    ⍝     If ignore is 0 or omitted, indicates out of range signal an INDEX ERROR (7).
    ⍝ b ← {ignore←1} ⍵.delByIndex ix1 ix2...
    ⍝ b ← (ignore←1} ⍵.di           ix1 ix2...
    ⍝
    ∇ {b}←{ignore} delByIndex ix;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf    
      b←ix{⍵:0=0(≢økeys)⍸⍺ ⋄ 0⍴⍨≢⍺}×≢økeys
      eIndexRange THROW⍨ (0∊b)∧~ignore            ⍝ At least 1 index out of range                     
      ⍙diFast b/ix                                ⍝ Consider only those in index range
    ∇
    ∇ {b}←{ignore} di ix;keys 
      :Access Public
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      :TRAP 0 
        b←ignore delByIndex ix
      :Else
        THROW ⎕DMX.Message   
      :EndTrap
    ∇
  ⍝ ⍙diFast: [INTERNAL UTILITY] 
    ⍝ Delete items by ix, where indices <ix> (if non-null) guaranteed to be in range of økeys.
    ⍝ ALL deletion routines MUST call ⍙diFast...
    ∇ ⍙diFast ix;count;endblock;uix;∆
      → 0/⍨ 0=count←≢uix←∪ix                ⍝ Return now if no indices refer to active keys.
      endblock←(¯1+≢økeys)-⍳count           ⍝ All keys contiguous at end?
      :IF ømirActive ⋄ ⍙mirror2NS (økeys[ix]) ⎕NULL 1 ⋄ :ENDIF   ⍝ Mirror key deletion to mirrored ns
      :IF  ∧/uix∊endblock                   ⍝ Fast path: delete contiguous keys as a block
          økeys↓⍨←-count ⋄ øvalues↓⍨←-count ⍝ No need to OPTIMIZE hash.
      :Else  
          ∆←1⍴⍨≢økeys ⋄ ∆[uix]←0            ⍝ ∆: Delete items with indices in <ix>
          økeys←∆/økeys ⋄ øvalues←∆/øvalues 
          OPTIMIZE 
      :EndIf 
    ∇

  ⍝ d.clear  
    ⍝  "Clears the entire dictionary (i.e. deletes every key-value pair) and returns the dictionary."
    ∇ {dict}←clear ;⎕TRAP
        :Access Public
        ⎕TRAP←∆TRAP
      ⍝ If mirror active, delete each var (<key) from mirror ns. 
      ⍝ Don't alter other vars separately established by user.
      ⍝ Leave mirror active!
        ⍙mirror2NS økeys ⎕NULL 1   
        økeys←øvalues←⍬                       
        dict←⎕THIS ⋄ OPTIMIZE
    ∇

  ⍝ d.popItems
    ⍝  "Removes and returns last (|n) items (pairs) from dictionary as if a LIFO stack."
    ⍝   Efficiently updates økeys, preserving hash status. 
    ⍝   If there are insufficient pairs left, returns only what is left (potentially none)"
    ⍝ kv1 kv2... ← d.pop count   where count is a non-negative number.
    ⍝     If count≥≢økeys, all items will be popped (and the dictionary will have no entries).
    ⍝ Note: count must be ≥0.  
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove |n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs. 
    ⍝ If no pairs, returns simple ⍬.
    ∇ {poppedItems}←popItems count ;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      (count<0) THROW ePopItems 
      count←-(≢økeys)⌊count                               
      :If count=0                                          ⍝ Fast exit if nothing to pop
         poppedItems←⍬                           
      :Else
        :IF ømirActive ⋄  ⍙mirror2NS (count↑økeys) ⎕NULL 1 ⋄  :ENDIF 
        poppedItems←↓⍉↑count↑¨økeys øvalues
        økeys↓⍨←count ⋄ øvalues↓⍨←count
      :ENDIF 
    ∇

  ⍝ d.pop
    ⍝ Consume dictionary items by key name, returning the val for that key.
    ⍝ Same as:   d[keys]  ⋄ d.del keys
    ⍝ For each k in <keys>, return its value <v>, removing the key-value pair from the dictionary.
    ⍝ If a key does not exist, return its default, if specified (else an error, as for d.del)
    ∇{vals}←{default}pop keys;⎕TRAP 
      :Access Public 
      ⎕TRAP←∆TRAP
      :If 900⌶1  
         vals←get keys ⋄ 0 del keys 
      :Else 
         vals←default get keys ⋄ 1 del keys
      :Endif 
    ∇

  ⍝ d.sort/sortA (ascending)
  ⍝ d.sortD      (descending)
    ⍝ Descr:
    ⍝    "Sort a dictionary IN PLACE:
    ⍝     ∘ Sort keys in (Sort/A: ascending (D: descending) 
    ⍝     ∘ Keys may be any array in the domain of ⍋, using TAO (total array ordering).
    ⍝ Returns: the dict
    ⍝
    :Property sort,sortA,sortD
    :Access Public
        ∇ dict←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If 'd'=¯1↑args.Name   ⍝ sortD
              ix←⊂⍒økeys
          :Else                  ⍝ sortA, sort
              ix←⊂⍋økeys
          :EndIf
          økeys   ⌷⍨←ix  
          øvalues ⌷⍨←ix 
          OPTIMIZE ⋄ dict←⎕THIS
        ∇
    :EndProperty

  ⍝ d.reorder:  
    ⍝ "Reorder a dictionary in place based on the new indices specified. 
    ⍝  All the indices of the dictionary must be specified exactly once in the caller's ⎕IO."
    ⍝ Allows sorting externally by keys, values, or whatever, without losing any keys...
    ∇{dict}←reorder ix
     :Access Public
      ix-←(⊃⎕RSI).⎕IO      ⍝ Adjust indices to reflect caller's index origin, if need be
      eReorder  THROW⍨ ix[⍋ix]≢⍳≢økeys
      økeys ⌷⍨←⊂ix ⋄ øvalues ⌷⍨←⊂ix 
      OPTIMIZE ⋄ dict←⎕THIS
    ∇

⍝-----------------------------------------------------------------------------------
⍝ MIRRORING
⍝      d.ns                           ⍝ returns a reference to the actively mapped namespace, creating if new.
⍝      d.ns ← ⎕NULL/¯1, 1, 0          ⍝ d.ns←⎕NULL (or ¯1) "Disconnect" namespace at d.ns (next ref to d.ns creates a new namespace)
⍝                                     ⍝ d.ns←1: mirror is actively mapping dict entries <=> namespace vars
⍝                                     ⍝ d.ns←0: mirror is quiescent (connected but not actively mapping entries<=> vars)
⍝      d.preferNumericKeys ←  1       ⍝ sets ømirPrefNK
⍝      d.preferNumericKeys ←  0       ⍝ sets ømirPrefNK
⍝      x← d.preferNumeric             ⍝ gets ømirPrefNK
⍝ DEPRECATED: d.mirror
⍝    1 d.mirror  'CONNect'            ⍝ ⍺=1: preferNumericKeys (when translating a d.ns variable to a dict. key)
⍝    0 d.mirror  'Connect'            ⍝ ⍺=0: preferCharacterKeys (ditto)
⍝      d.mirror  'DISConnect' | 'STATus' | 'ON' | 'OFF'
⍝-----------------------------------------------------------------------------------
  ⍝ d.ns
    ⍝ Getting the value of d.ns  --- SEE BELOW
    ⍝ Setting the value of d.ns  --- SEE BELOW 
    :Property ns
    :Access Public
        ∇ mirrorNS←get args            
          ømirPrefNK mirror 'CONNECT'   ⍝ Takes action based on both args...
          mirrorNS←ømirror.mirrorNS 
        ∇
        ∇ set args;  ⎕TRAP
          ⎕TRAP←∆TRAP  
          :IF 1=≢args.NewValue
          :AndIf args.NewValue∊1 0 ¯1 ⎕NULL    ⍝ Setting d.ns←⍵. ⍵ may be: 1 'ON', 0 'OFF', ¯1 or ⎕NULL 'DISCONNECT'
                 ⍙mirrorOpts args.NewValue     ⍝ To set preferNumericKeys to ⍵, see d.preferNumericKeys←⍵
          :Else  
                THROW 'd.ns: Invalid assignment. Only ⎕NULL (or ¯1), 0, or 1 allowed.' 
          :ENDIf
        ∇
    :EndProperty
     ⍝ d.preferNumericKeys, alias: d.prefNK
    ⍝ Getting the value of d.preferNumericKeys  --- SEE BELOW
    ⍝ Setting the value of d.preferNumericKeys  --- SEE BELOW 
    :Property preferNumericKeys,prefNK
    :Access Public
        ∇ pnk←get args 
          pnk←ømirPrefNK
        ∇
        ∇ set args 
          :IF 1=≢args.NewValue
          :AndIf args.NewValue∊0 1
              ømirPrefNK←⍬⍴args.NewValue
          :Else 
              THROW 'preferNumericKeys: value assigned must be 1 (true) or 0 (false).'
          :EndIf                            
        ∇
    :EndProperty
⍝ d.mirror
    ⍝ mirrorNS ← {preferNK:[0|1]} d.mirror [CONNECT | ON | OFF | DISCONNECT ]
    ⍝ See documentation for details. 
    ⍝ Enables a namespace that 
    ⍝            replicates the dictionaries keys as variable names and
    ⍝            whose values, if changed, are reflected on the fly in the dictionary itself.
    ⍝ A.  On first call with CONNECT option
    ⍝     1. creates namespace <ns>, setting two fields
    ⍝           ømirror - the namespace with mirror-related variables, and 
    ⍝           ømirActive  - 1 when it's active, else 0.
    ⍝        as well as 
    ⍝           ømirror.mirrorNS (the user-accessible mirrored namespace)
    ⍝     2. creates 
    ⍝           ns.ourDict - points to the active dictionary instance
    ⍝           ns.mirrorNS   - contains user variables and the trigger fn (__DictTrigger__)
    ⍝ B1. On subsequent calls with CONNECT option
    ⍝     May change the preferNK(⍺) setting, for future mirroring
    ⍝ B2. On subsequent calls, with
    ⍝     ON            enables real-time mirroring of active namespace (created via CONNECT)
    ⍝     OFF           temporarily disables ...
    ⍝     DISCONNECT           turns off mirroring and severs any connection with the mirroring namespace from CONNECT
    ⍝     STATUS        shows current mirroring status
    ⍝ RETURNS [shyly] in all cases:
    ⍝    the user-accessible mirror namespace (ømirror.mirrorNS), retrievable via d.ns
    ∇{mirrorNS}←{preferNK} mirror flag ;⎕TRAP 
      :Access Public
      ⎕TRAP←∆TRAP
      :SELECT flag← 1 ⎕C flag
        :CASELIST 'CONNECT' 'CONN' 
            mirrorNS← ⍙mirrorConnect { ⍵: 0 ⋄ preferNK∊0 1: preferNK ⋄ THROW eMirNumKeys} 900⌶1
        :CASELIST 'ON' 'OFF' 'DISCONNECT' 'DISC'
            (ømirror≡⎕NULL) THROW eMirDisc 
            flag←1-'ON' 'OFF'⍳⊂flag    ⍝ 1/ON 0/OFF ¯1/DISConnect
            mirrorNS← ⍙mirrorOpts flag
        :CASELIST 'STATUS' 'STAT'
            mirrorNS← ømirror{⍺≡⎕NULL: 'NONE' ⋄ (⍵/'IN'),'ACTIVE'}~ømirActive
        :ELSE 
            THROW eMirFlag 
      :ENDSELECT
    ∇
    ∇  mirrorNS ← ⍙mirrorConnect preferNK 
      ⍝ preferNK:  1=yes, 0=no (default=0). Used only with flag 'CONNECT', otherwise ignored.
      ⍝ Set mirror flag to active, whether mirror is CONNECT or old.
        ømirActive←1                       
      ⍝ MIRROR ALREADY EXISTS? Update preference and return the mirrorNS
        :IF ømirror≢⎕NULL
            ⍝ 'existing mirror'
            ømirror.preferNumericKeys←preferNK 
            mirrorNS←ømirror.mirrorNS                  
        :ELSE  
           ⍝ 'new mirror'
          ⍝ Connecting NEW mirror. Define mirror data, establish the namespace, mirror existing items to it, 
          ⍝ then activate trigger, so namespace objects are mirrored back...
            ømirror←⎕NS '' 
            ømirId+←1
            ømirror.preferNumericKeys←preferNK            
            mirrorNS←ømirror.mirrorNS←ømirror.⎕NS '' 
            mirrorNS.⎕DF 'Mirror.',(⍕ømirId),'@',øid
            ømirror.ourDict← ⎕THIS                             ⍝ Point to the active dictionary
            :TRAP 0   
                :IF ×≢økeys   
                    names← (0⍨7162⌶⍕)¨ økeys                      ⍝ Convert Keys to Var Names via JSON rules
                    names (mirrorNS ⍙AssignVar)¨øvalues           ⍝ Map dict(keys and values) ==> ns(vars and values)
                :ENDIF                                            ⍝ ↓↓↓ Activate trigger fn __DictTrigger__
                mirrorNS.⎕FX '⍝ACTIVATE⍝' ⎕R '' ⊣ ⎕NR '__DictTrigger__'
            :ELSE
                THROW eKeyBadName
            :ENDTRAP
        :ENDIF
    ∇
  ⍝ {mirrorNS} ← ⍙mirrorOpts [1 | 0 | ¯1/⎕NULL]
    ⍝ setMirror: (0:OFF) Turns mirroring off, or (1:ON) reestablishes it, 
    ⍝        or (¯1/⎕NULL:DISCONNECT) permanently disconnects the namespace and dictionary entirely, ending mirroring. 
    ⍝ Returns (shyly): the (active) mirror namespace. ⎕NULL, if none established.
    ⍝ HELPER FUNCTION for d.mirror (above)
    ∇{mirrorNS}←⍙mirrorOpts flag; was  
      :IF (ømirror≡⎕NULL) ⋄ mirrorNS←⎕NULL ⋄ :RETURN ⋄ :ENDIF
      eMirFlag THROW⍨  flag(~∊)1 0 ¯1 ⎕NULL 
      :Select ⍬⍴flag
          :CASELIST ¯1 ⎕NULL                                   
            ⍝ Delete trigger fn (cancelling the trigger) and dict reference (to avoid keeping ourDict reference live)
              eMirLogic THROW⍨ 0∊ømirror.⎕EX 'ourDict' 'mirrorNS.__DictTrigger__' 
              ømirror.mirrorNS.⎕DF 'Exported.',(⍕ømirId),'@',øid
              ømirActive ømirror mirrorNS← 0 ⎕NULL ⎕NULL
          :CASELIST 0 1                                 
              was ømirActive mirrorNS←ømirActive flag ømirror.mirrorNS
              :IF was=flag ⋄ :RETURN ⋄ :ENDIF     ⍝ Same as before. Don't bother de/re-activating
              mirrorNS ⍙SuppressTrigger ~ømirActive       
          :ELSE 
              THROW eMirLogic
      :ENDSELECT 
    ∇
  ⍝ ⍙mirror2NS
    ⍝    {nkeys} ← ∇ (keys vals delB=0|1)
    ⍝    If (delB=0), update values (vals) for keys; If (delB=1), delete keys (vals ignored)
    ⍝ Note: Won't mirror if ømirActive=0, so ignoring minor efficiency issues, it can be called whenever keys are updated.
    ⍝ (Local utility used in ⍙importVecs)
    ⍝ Returns # of keys mirrored (or 0).
    ⍝ See __DictTrigger__, helper fn required in mirror namespace.
    ∇{nkeys}← ⍙mirror2NS (keys vals delB)
     ;Key2Name;mKeys 
     nkeys←ømirActive×≢keys
     :IF (0=≢keys) ⋄ :ORIF ~ømirActive ⋄ :RETURN ⋄ :ENDIF   
     Key2Name← 0⍨7162⌶⍕   ⍝ JSON mangling
     ømirror.mirrorNS ⍙SuppressTrigger 1        ⍝ No triggering in mirror ns, while updating its variables
        mKeys←{0:: ⍬ ⋄ Key2Name¨⍵}keys
        (~×≢mKeys) THROW eKeyBadName
        :IF delB 
            ømirror.mirrorNS.⎕EX mKeys      
        :ELSE 
            mKeys (ømirror.mirrorNS ⍙AssignVar)¨vals
        :ENDIF
      ømirror.mirrorNS ⍙SuppressTrigger 0       ⍝ Re-enable mirror ns trigger
    ∇ 

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
    _←{⍺←'HELP' ⋄  ⎕FX ('\b',⍺,'\b')⎕R ⍵⊣⎕NR ⍺}¨ 'help' 'Help'

  ⍝-------------------------------------------------------------------------------------------
  ⍝-------------------------------------------------------------------------------------------
  ⍝ INTERNAL UTILITIES
  ⍝ ----------------------------------------------------------------------------------------
  ⍝ ----------------------------------------------------------------------------------------
    ⍝ ∆EXPAND...
    ⍝ ∆EXPAND:  ⍺:bool \ ⍵:in, which uses a fill of 0 for the first item. See discussion below.
    ⍝    out ← bool ∆EXPAND in          
    ⍝ Discussion: 
    ⍝  ∘ We want to use expand \ in providing DEFAULT values for as yet unseen keys; it requires that ⍵ (in ⍺\⍵) have a fill value.
    ⍝    As øvalues is updated, it may include namespaces or other items that lack a fill value. 
    ⍝  ∘ If, during an expand operation ⍺\øvalues, the first item contains such an item, a NONCE ERROR occurs,
    ⍝  ∘ We resolve this using ∆EXPAND, which ensures a fill value of 0:
    ⍝    vals←found ∆EXPAND øvalues[found/ix]  
      ∆EXPAND←{1↓(1,⍺)\ 0,⍵}     ⍝ Tacit equivalent: 1↓(1,⊣)⊢⍤\0,⊢      

  ⍝ OPTIMIZE
    ⍝ Set økeys to be hashed whenever økeys changed-- added or deleted. (If only øvalues changes, no use in calling this).
    ⍝ While it is usually of no benefit to hash small key vectors of simple integers or characters,
    ⍝ it takes about 25% longer to check datatypes and ~15% simply to check first whether økeys is already hashed. 
    ⍝ So we just hash økeys whenever it changes!
    ∇ {ok}←OPTIMIZE 
       økeys←1500⌶økeys ⋄ ok←1                                                               
    ∇
    
  ⍝ THROW: "Throws an error if ⍺ is omitted or contains a 1; else a NOP."
    ⍝ Syntax:
    ⍝   [cond=1] THROW [en=11] message, 
    ⍝   where en and message are of the form of ⎕DMX fields EN and Message.
    ⍝ Helper: ⍙THROW
      ⍙THROW←{  ⍺←1 ⋄ 1(~∊)⍺: ⍬ ⋄ 1=≢⊆⍵: ⍺ ∇ 11 ⍵  
                majorS← 'DOMAIN' 'INDEX' 'VALUE'  
                majorN←  11       3       6
                en msg←⍵ ⋄ em←'∆DICT',((majorN⍳en)⊃(' ',¨majorS),⊂''),' ERROR'
                ⊂('EN' en)('Message'  msg)('EM' em) 
      }   
    THROW←⎕SIGNAL ⍙THROW 
 
  ⍝ ⍙AssignVar: "Assign to name in context <where> the value (std) or create as a function if the value is an ⎕OR.
    ⍝ name ←   name (where ⍙AssignVar) val
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
    ⍙AssignVar←{
        _←⍺⍺.⎕EX ⍺                               ⍝ Replace existing <name> even if incompatible class (⎕NC).  
        (1=≡⍵)∧0=⍴⍴⍵:(⍺⍺{⍺⍺∘⍎ ⍺,'←⍵⍵' ⋄ ⍵⍵}⍵)⍨⍺  ⍝ <val> is an ⎕OR. ⍵⍵: magically convert ⎕OR to function/or (⎕NC∊3 4).  
        1:_←             ⍺⍺∘⍎ ⍺,'←⍵'             ⍝ <val> is a value in ⎕NC=2 that is not an ⎕OR or ⎕NC=9. 
    }                                           

  ⍝ __DictTrigger__: helper for d.mirror (q.v.).
    ⍝ Do not enable trigger here: it's copied/activated in mirror namespace only.
    ⍝ Note: See ⍙importNS. It will not import this object '__DictTrigger__' if found in the source namespace.
    ⍝ WARNING: Be sure all local variables are in fact local. Otherwise, you'll see an infinite loop!!!  
    ∇__DictTrigger__ args  
      ⍝ACTIVATE⍝ :Implements Trigger *             ⍝ Don't touch this line!
      :TRAP 0
         (⎕THIS ##.preferNumericKeys) ##.ourDict.setKeysFromNames  ⊆args.Name 
      :Else 
          ⎕SIGNAL  ⊂⎕DMX.(('EN' EN)('Message'  Message)('EM' ('∆DICT mirror: ',EM))) 
      :ENDTRAP
    ∇

  ⍝ setKeysFromNames              
    ⍝  Pseudo-internal: accessed from mirror namespace fn __DictTrigger__ and from d.importNS.
    ∇ {dict}←ns_opts setKeysFromNames nameList
      ;preferNK;saveState;thisNS 
      :Access Public
      dict←⎕THIS 
      :IF 1=≢ns_opts
          thisNS preferNK←ns_opts 0
      :Else 
          thisNS preferNK←ns_opts
      :ENDIF
    ⍝ Suppress mapping namespace vars onto dict keys, only if ns is the actively mapped (triggered) namespace
      saveState←ømirActive 
      :IF thisNS.##≡ømirror ⋄ ømirActive←0 ⋄ :ENDIF  
      :TRAP 0 
          :IF ×≢nameList  ⍝ An empty namelist is ok...
            ⍙importVecs↓⍉↑,thisNS∘{nm←⍵
                  k←preferNK ⍙Name2Key nm 
                  case←⍺.⎕NC nm 
                  case∊3 4: k (⍺.⎕OR nm)  
                  case∊2 9: k (⍺⍎nm)
                  ∘ ∘ ∘   ⍝ THROW eBadNSVar
            }¨nameList 
          :ENDIF 
      :Else 
          ømirActive←saveState
          THROW eBadNSVar
      :EndTrap
    ⍝ Restore mapping of namespace vars onto dict keys, if ns is the actively mapped (triggered) namespace
      ømirActive←saveState
    ∇
  ⍝ See setKeysFromNames etc.
  ⍝ ⍙Name2Key:    [⍺=1|0] ∇ name 
    ⍙Name2Key←{  
          key←1∘(7162⌶) ⍵       ⍝ ⍵ must be char vector. Uses JSON unmangling
          ~⍺: ⍬⍴⍣(1=≢key)⊣key  ⋄ ok val←⎕VFI key   
          0∊ok: ⍬⍴⍣(1=≢key)⊣key ⋄  1≠≢val: val  ⋄ ⊃val 
    } 
  ⍝ ⍙SuppressTrigger: If ⍵=1, suppresses trigger for namespace ⍺. If ⍵=0, re-enables it.
    ⍙SuppressTrigger←{1: _←2007 ⍺.⌶ ⊢ ⍵}

    ∇{list}←EXPORT_FUNCTIONS list;fn;ok
      actual←⍬
      ⍝ Copy list of fns into parent namespace to this one...
      ⍝ In functions to export, 
      ⍝     use DICTCLASS instead of ⎕THIS (⎕THIS will be treated as an alias for DICTCLASS)
      ⍝     use DICTCLASS.## to refer to the namespace for the exported functions
      ⍝ We also optimize DICTCLASS.## to refer to the exported fns directory (where it's preferred to the class itself)
      :FOR fn :IN list
          ok←##.⎕FX '\QDICTCLASS.##\E' 'DICTCLASS|⎕THIS' ⎕R (⍕DICTCLASS.##)(⍕DICTCLASS)⊣⎕NR fn  
          :IF 0=1↑0⍴ok
              ⎕←'EXPORT_GROUP: Unable to export fn "',fn,'". Error in ',fn,' line',ok
          :ENDIF
      :EndFor
    ∇
    EXPORT_FUNCTIONS EXPORT_LIST

:SECTION HELP DOCUMENTATION
⍝H DictClass: A fast, ordered, and simple dictionary for general use.
⍝H            A dictionary is a collection of ITEMS (or pairs), each consisting of 
⍝H            one key and one value, each an arbitrary shape and  
⍝H            in nameclass 2 or 9 (value or namespace-related).
⍝H
⍝H ∆DICT:     Primary function for creating new dictionaries ("hashes").
⍝H            ∘ Accepts a variety of formats for initialization and for import/export.
⍝H            ∘ JSON-generated namespaces can be used to initialize a dictionary or via d.import.
⍝H              A dictionary can export a JSON-ready namespace via d.mirror 'EXPORT'
⍝H            ∘ Documentation follows.
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
⍝H Dict:      A utility fn that returns the full name of the dictionary class, often #.DictClass.
⍝H            To enable, put [full path].Dict in your ⎕PATH (or specify full path to DictClass).
⍝H            d←⎕NEW Dict             ⍝ Create a new, empty dictionary with no default values.
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
⍝H    v1 v2 v3 ← [def] d.get  keys             ⍝ Get value list by key list, else return <def> for each missing key,
⍝H                                               if present, else the instance-level default (q.v.), if present.
⍝H                                               If any key is missing and there's no default, an error is signaled.
⍝H    keys vals ←          d.export            ⍝ Get key list followed by value list 
⍝H    ns       ←           d.exportNS          ⍝ Export the dict items as variables in a namespace (see d.mirror).
⍝H    keys     ←           d.keys              ⍝ Get all keys in active order
⍝H    k1 k2 k3 ←           d.keys[indices]     ⍝ Get keys by index (position in active key order)
⍝H    vals     ←           d.vals              ⍝ Get all values in active (key) order
⍝H    v1 v2 v3 ←           d.vals[indices]     ⍝ Get values by index (position in active key order)
⍝H    (k1 v1)...        ←  d.items             ⍝ Get all items (key-val pairs) in active order
⍝H    (k1 v1)(k2 v2)... ←  d.items[indices]    ⍝ Get all items in active (key) order
⍝H SET  
⍝H                   d[keys] ←  vals           ⍝ Set values for arbitrary keys.  For one key:  d[⊂key]←⊂val   
⍝H                   k1 d.set1 v1              ⍝ Set value for one key (see d.set)
⍝H                OR d.set1 k1 v1              ⍝ --DITTO--
⍝H                   keys d.set  vals          ⍝ Set by vectors 
⍝H                   d.set (k1 v1)(k2 v2)(...) ⍝ Set by pairs   
⍝H                   keys d.set vecs           ⍝ Set by vectors...
⍝H                   d.import obj1 [obj2 ...]  ⍝ Add items from dictionaries, namespaces, or via key and value vectors.
⍝H                   d.sortA or d.sort         ⍝ Set active order, sorting by ascending keys 
⍝H                   d.sortD                   ⍝ Set active order, sorting by descending keys
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
⍝H    b1 b2 b3 ←  [ign←0] d.delByIndex indices ⍝ Delete items by specific index (ign: ignore missing keys)
⍝H                   d.clear                   ⍝ Delete all items in the dictionary 
⍝H                                               (maintain defaults, namespace, etc.)
⍝H INC/DEC
⍝H    n1 n2 n3 ←  [incr←1] d.inc keys          ⍝ Increment values for specific keys
⍝H    n1 n2 n3 ←  [decr←1] d.dec keys          ⍝ Decrement values for specific keys
⍝H
⍝H POP
⍝H    (k1 v1)(k2 v2)... ←  d.popItems count    ⍝ Remove and return <count> items from end of dictionary.
⍝H    vals  ←              d.pop keys          ⍝ Remove and return values for specific keys from dictionary.
⍝H
⍝H MISC
⍝H MIRRORING FROM DICTIONARY ENTRIES TO NAMESPACE VARIABLES
⍝h {ns}  ← {preferNumeric} d.mirror 'CONNECT'  ⍝ Create a ns whose vars dynamically mirror dict entries and vice versa.
⍝h                                             ⍝ preferNumeric: If 1, namespace variables resolving to numeric strings 
⍝h                                             ⍝                are converted to numeric keys and vice versa.
⍝h                       d.mirror 'DISCONNECT' ⍝ * Permanently delete (disconnect) the current namespace from the dictionary.
⍝h                       d.mirror 'ON'         ⍝ * Dynamically nable active mirroring, after previously disabling. 
⍝h                       d.mirror 'OFF'        ⍝ * Dynamically isable active mirroring temporarily.
⍝h                                             ⍝ * May only be used after d.mirror 'CONNECT' (and before d.mirror 'DISCONNECT')
⍝h                       d.mirror 'STATUS'     ⍝ Returns the current mirror status...
⍝H d.ns                                        ⍝ On first call, creates a namespace whose variable names
⍝H                                             ⍝ will be mirrors of the dictionaries keys and vice versa.
⍝H                                             ⍝ The values will be identical, except that dictionary object
⍝H                                             ⍝ representations (⎕OR) will be mapped onto fns / ops in the namespace and vice versa.
⍝H d.ns ← ⎕NULL  (or ¯1)                       ⍝ "Disconnects" the current namespace (from prior d.ns calls).
⍝H                                             ⍝ The next "get" of d.ns will create a new namespace
⍝H d.ns ← 1 | 0                                ⍝ Temporarily turn mirroring off (0) or back on (1: default).
⍝H d.preferNumericKeys ← [1 | 0]               ⍝ Manages "prefer numeric keys" for variable to namespace conversion.
⍝H ALIAS: d.prefNK                             ⍝ The default is d.ns ← 0, numeric key conversions are NOT performed.
⍝H    d.preferNumericKeys ← 1                  ⍝ ∘ Sets the preferred conversion mode to "prefer numeric keys" 
⍝H                                             ⍝   for mirroring from namespace variable names.
⍝H    d.preferNumericKeys ← 0                  ⍝ ∘ Sets the preferred conversion mode to the default
⍝H                                             ⍝   where namespace variable names are kept as character strings
⍝H                                             ⍝   even if they appear to be numeric strings.
⍝H ns ←   exportNS                             ⍝ Exports the items as variables as a namespace (see d.mirror).
⍝H                                             ⍝ If mirroring is active, shares a copy of the current mirror
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
⍝H       d.import objs  
⍝H    to set keys and values from key-value pairs, dictionaries, namespace variables, or "tables".
⍝H    See d.import below.
⍝H
⍝H  d←default ∆DICT ⍬
⍝H     Creates an empty dictionary with default <default>
⍝H
⍝H newDict ← d.copy             ⍝ Make a copy of dictionary <d> as <newDict>, including defaults.
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
⍝H  Unlike d.keys2vals keys, aka d[keys], d.vals2Keys[] may return many keys for each value." 
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
⍝H bool ← [ignore←0] d.delByIndex i1 i2 ...               
⍝H bool ← [ignore←0] d.di i1 i2 ...              ⍝ Alias to delByIndex
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
⍝H     Sets a default value for missing keys. Also sets d.hasDefault←1
⍝H
⍝H d.hasDefault←[1 | 0]
⍝H     Activates (1) or deactivates (0) the current default.
⍝H     ∘ Initially, by default:  hasDefault←0  and default←'' 
⍝H     ∘ If set to 0, referencing new entries with missing keys cause a VALUE ERROR to be signalled. 
⍝H     ∘ Setting hasDefault←0 does not delete any existing default; 
⍝H       it is simply inaccessible until hasDefault←1.
⍝H
⍝H d.queryDefault
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
⍝H d.import
⍝H                   d.import [ITEM | DICT | NAMESPACE | TABLE] ...
⍝H preferNumericKeys d.import [ITEM | DICT | NAMESPACE | TABLE]...
⍝H preferNumerickeys (⍺): Only relevant when importing namespaces (NAMESPACE).
⍝H 
⍝H    For dictionary d, sets keys and values from objs of various types or set value defaults:
⍝H         ∘ ITEM:      ∘  a (key value) pair: If just one, enclose it:  d.import (⊂1 10)
⍝H         ∘ DICT:      ∘  dictionaries (nameclass 9.2, with ⎕THIS∊⊃⊃⎕CLASS dict)
⍝H         ∘ NAMESPACE: ∘  Imports items from variables in <ns>, from classes 2, 3, 4, and 9.
⍝H                         Items in classes 3 and 4 are converted quietly to ⎕OR representation.
⍝H                      ∘  Keys are converted to variables via JSON Mangling. 
⍝H                      ∘  preferNumericKeys(⍺, default: 0)
⍝H                         If 1, prefer numeric keys when mirroring: convert numeric strings to/from numbers; 
⍝H                         If 0, do not convert numeric strings; leave as character vectors.
⍝H                         See d.mirror for more information.
⍝H                      ∘ See mirror for details on JSON mapping. 
⍝H         ∘ TABLE      ∘ A single-column matrix in "table" format to allow loading keys and values as vectors
⍝H                        ⍪key_vec value_vec [default]
⍝H         e.g. d.import ⍪(⍳10)(○⍳10)  <==>  d.import (0 (○0))(1 (○1))...(9 (○9))
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
⍝H items ← d.popItems n
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
⍝H -----------------------------------
⍝H    DICTIONARY MIRRORING 
⍝H    d.ns    Dictionary mirroring
⍝H -----------------------------------
⍝H    ... MANIPULATING THE MIRROR NAMESPACE REFERENCE
⍝H        ... ← d.ns,  d.ns.var←... ,etc.      
⍝H        ∘ Returns the currently active mirror namespace, creating it if not already established.
⍝H          d.ns.⎕NL 2     d.ns.myVar←'myVal'
⍝H        ∘ Disconnect the current namespace from the mirror; the next call to get d.ns will create a new mirroring namespace.
⍝H          This makes sense only if the name has been saved:   saveNS ← d.ns
⍝H          d.ns ← ⎕NULL   
⍝H          d.ns ← ¯1        Alias for d.ns ← ⎕NULL
⍝H        ∘ Advanced: d.ns ← 0  ⍝ Don't map keys to ns vars or vice versa until d.ns is set again to 1. 
⍝H                    d.ns ← 1  ⍝ Restore (or continue) mapping keys to ns vars and vice versa.  
⍝H -----------------------------------
⍝H    ... SETTING THE MIRROR NAMESPACE MAPPING MODE
⍝H        d.preferNumericKeys ← [1 | 0 ]       
⍝H        d.prefNK            ← [1 | 0 ] Alias for d.preferNumericKeys     
⍝H        ∘ d.preferNumericKeys ← 1       Connects the mirror namespace, preferring numeric   keys. Creates the namespace if needed.
⍝H        ∘ d.preferNumericKeys ← 0       Connects the mirror namespace, preferring character keys. Creates the namespace if needed.
⍝H                                        DEFAULT
⍝H -----------------------------------
⍝H     ... EXAMPLES
⍝H        ∘ Example 1:
⍝H            d.default←'Whoops!'             ⍝ Clear feedback for undefined keys...
⍝H            d.prefNK ← 1 ⋄ d.ns.⍙45 ← 90    ⍝ <== Prefer numeric keys when mapping from d.ns vars to d keys
⍝H            d[45]                           ⍝ Numeric preferred, so ⍙45 should map to 45
⍝H          90
⍝H            d[⊂'45']                        ⍝ The default when char is preferred would be ⍙45 mapping to '45'...
⍝H          Whoops!                           ⍝ ... Not in this case!
⍝H        ∘ Example 2
⍝H            d.keys
⍝H         'fred' 'mary' 'jack'
⍝H            d.ns.⎕NL 2                      ⍝ Displays current namespace variables, if mirror is connected.
⍝H         fred  mary  jack
⍝H            d.ns.fred←¯1  ⋄  ⎕←d[⊂'fred']   ⍝ Sets current namespace variable <fred> to 15. Mirrors to the dictionary.
⍝H         ¯1
⍝H            d[⊂'fred']←16 ⋄  ⎕←d.ns.fred    ⍝ Sets <fred> via the dictionary, reading via the namespace
⍝H         16
⍝H
⍝H    -----
⍝H    NOTES
⍝H    -----
⍝H    ∘ "BUGS": A key may be a vector of character vectors, but its namespace variable name
⍝H             will be mirrored back as a single vector with spaces in place of separate vectors. 
⍝H    ∘ Dictionary values that are object representations are a special case...
⍝H      ...Namespace object values that are functions or operators are a special case.
⍝H      - Any dictionary value that is an object representation (⎕OR) will be automatically converted to its
⍝H        function or operator format when assigned to its namespace variable.
⍝H      - Any variable in the namespace assigned a value as a function or operator will map onto 
⍝H        a dictionary item whose value is the ⎕OR of that function or operator.
⍝H    ∘ A special object '__DictTrigger__' (an APL trigger) may appear in the namespace. 
⍝H      It is never imported automatically when mirroring (See d.ns) or importing (d.import)
⍝H
⍝h    MAPPING (MIRRORING) DICTIONARY ENTRIES TO AND FROM VARIABLES IN A PRIVATE NAMESPACE
⍝h    ns ← [⍺] d.mirror 'CONNECT '
⍝h    ns ← d.mirror  ['DISCONNECT' | 'ON' | 'OFF']
⍝h    info←d.mirror 'STATUS'
⍝h =========================================================================================
⍝h    {ns} ← [preferNumericKeys] d.mirror 'CONNECT'
⍝h          - returns (shyly) a reference to the active private namespace, activating it if not already so.
⍝h          - the namespace reference is also stored in d.ns, which may be referenced, but not directly set.
⍝h            e.g.    d.ns.⎕NL 2
⍝h          - Each key in a mirrored dictionary must be a char vector or scalar, or a numeric scalar or vector;
⍝h            it will be rendered as a namespace variable (in ns) via JSON name mangling (see Dyalog I-beam 7162⌶).
⍝h    preferNumericKeys ∊ 1, 0
⍝h      1   - A namespace variable name that (after name demangling) is a numeric string will
⍝h            map onto (be converted to) a dictionary key that is numeric.
⍝h      0   - A namespace variable name that (after name demangling) is a numeric string will
⍝h            map onto  a dictionary key that is a character string.
⍝h      WARNING: A key may be a vector of character vectors, but its namespace variable name
⍝h             will be mirrored back as a single vector with spaces in place of separate vectors. 
⍝h    ∘ Dictionary values that are object representations are a special case...
⍝h      ...Namespace object values that are functions or operators are a special case.
⍝h      - Any dictionary value that is an object representation (⎕OR) will be automatically converted to its
⍝h        function or operator format when assigned to its namespace variable.
⍝h      - Any variable in the namespace assigned a value as a function or operator will map onto 
⍝h        a dictionary item whose value is the ⎕OR of that function or operator.
⍝h    ∘ A special object '__DictTrigger__' (an APL trigger) may appear in the namespace. 
⍝h      It is never imported by d.mirror or d.import
⍝h ---------------------------------
⍝h    {ns} ← d.mirror 'OFF' | 'ON'  |  'DISCONNECT' 
⍝h         Valid only for a mirror-enabled dictionary (d.mirror 'CONNECT'), which has not been disconnected (d.mirror 'DISCONNECT').
⍝h         Otherwise, an error is signaled.
⍝h         'OFF'
⍝h            Temporarily disables the mirroring of a dictionary to a namespace and vice versa. 
⍝h            Objects established during that time won't be updated, even when the mirroring
⍝h            is re-enabled, but any subsequent changes (to those or new objects) will be reflected.
⍝h            Returns the mirror namespace.
⍝h         'ON'
⍝h            Restores the mirroring of a dictionary to a namespace and vice versa, if previously disabled.
⍝h            Returns the mirror namespace.
⍝h         'DISCONNECT'
⍝h            Permanently severs the connection between the dictionary and the actively mirrored namespace.
⍝h            If the user has maintained a copy of the namespace (e.g. saveNS← d.mirror 0),
⍝h            its contents will reflect the most recent mirroring, but no further updates will occur.
⍝h            Returns ⎕NULL.
⍝h     info ← d.mirror 'STATUS'
⍝h            Returns the current status of mirroring. May be called even if inactive.
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
⍝H d ← d.sort OR d.sortA
⍝H     Sort a dictionary in place in ascending order by keys, returning the dictionary
⍝H
⍝H d ← d.sortD
⍝H     Sort a dictionary in place in descending order by keys, returning the dictionary 
⍝H
⍝H d ← d.reorder indices
⍝H     Sort a dictionary in place in order by indices.
⍝H     Indices depend on ⎕IO in the caller environment.
⍝H     All indices of <d> must be present w/o duplication:
⍝H           indices[⍋indices] ≡ ⍳d.len
⍝H     Example: Equivalent of d.sortD; sort dictionary by keys
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
⍝H      OK       a←a.copy.clear.import a.items[⍒a.vals]
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
⍝H Using ∆DICT directly with Dyalog ⎕JSON
⍝H =========================================================================================
⍝H Importing...   
⍝H ======================================
⍝H  ⍝ Allow JSON5 extensions; map JSON 'null' to Dyalog ⎕NULL 
⍝H      jSTR← '{"10": 25, "20": [1, 2, 3], "abc\ndef": true, null: null}'
⍝H      jNS←  ⎕JSON⍠('Null'⎕NULL)('Dialect' 'JSON5')⊢ jSTR
⍝H      b←    ∆DICT jNS                ⍝ Imports the namespace...
⍝H      b.hdisp
⍝H ┌──────┬──┬─────┬──────┐
⍝H │ Null │10│ 20  │ abc  │
⍝H │      │  │     │ def  │
⍝H ├──────┼──┼─────┼──────┤
⍝H │      │  │     │┌────┐│
⍝H │[Null]│25│1 2 3││true││
⍝H │      │  │     │└────┘│
⍝H └──────┴──┴─────┴──────┘
⍝H 
⍝H ======================================
⍝H Exporting...
⍝H ======================================
⍝H ⍝ Consider non-default options: ('HighRank' 'Split') and ('Compact' 0)        
⍝H ⍝ as well as those above:       ('Null' ⎕NULL) ('Dialect' 'JSON5')
⍝H      jOPTS←('Null'⎕NULL)('Compact' 0)('Dialect' 'JSON5')
⍝H      ns←b.mirror 'EXPORT'       ⍝ Return a ns that mirrors the current dictionary
⍝H      ⎕←1 ⎕JSON⍠ jOPTS⊣ns 
⍝H  {        
⍝H    null: null,          
⍝H    "10": 25,        
⍝H    "20": [          
⍝H      1,             
⍝H      2,             
⍝H      3,             
⍝H    ],               
⍝H    "abc\ndef": true,
⍝H  }     
⍝H  ⍝ This is equivalent to the sequence just above:
⍝H     ⎕←1 ⎕JSON⍠('Null'⎕NULL)('Compact' 0)('Dialect' 'JSON5')⊣b.mirror 'EXPORT'              
⍝H  ⍝ This is the compact version...
⍝H     ⎕←1 ⎕JSON⍠('Null'⎕NULL)('Compact' 1)('Dialect' 'JSON5')⊣b.mirror 'EXPORT'      
⍝H  {null:null,"10":25,"20":[1,2,3],"abc\ndef":true}  
⍝H
:EndClass
