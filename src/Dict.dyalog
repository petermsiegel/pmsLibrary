:Class DictClass
⍝⍝ DictClass: A fast, ordered, and simple dictionary for general use.
⍝⍝ ∆DICT:     Primary function for creating new dictionaries.
⍝⍝            d←∆DICT ⍬       ⍝ Create a new, empty dictionary with default value ⍬.
⍝⍝ Dict:      A utility that returns the full name of the dictionary class, often #.DictClass
⍝⍝            d←⎕NEW Dict     ⍝ Create a new, empty dictionary with no default values.
⍝⍝ Hashes vector KEYS for efficiency on large dictionaries.
⍝⍝ For HELP information, call 'dict.HELP'.
⍝⍝
⍝⍝ d←∆DICT item
⍝⍝ d← default ∆DICT item
⍝⍝    item: (key1 val1)(key2 val2)...
⍝⍝          items passed as key-value pairs; keys and vals may be of any type...
⍝⍝    item: dict
⍝⍝          A dict is an existing instance (scalar) of a DictClass object.   
⍝⍝    item: ⍪keys vals [⊂default]  
⍝⍝          items are passed as 2 vectors (keys, vals); 
⍝⍝          the default may optionally be appended as a scalar.
⍝⍝ d←∆DICT [default]
⍝⍝    default must either a scalar:  0 [default: 0],  ⊂'' [default: ''], ⊂⍬ [default: ⍬], 
⍝⍝                                   ⊂'text' [default: 'text'], ⎕NULL, (⊂2 3⍴⍳6)
⍝⍝                 or null:          '' (same as ⊂'') or ⍬ (same as ⊂⍬)
⍝⍝
⍝⍝ d[⊂k1] or d[k1 k2...]
⍝⍝ Return the item of d with key key. Raises an error any key is not in the dictionary, 
⍝⍝ unless a default is specified.
⍝⍝ See also get, get1 
⍝⍝
⍝⍝ d[⊂k1] ← (⊂v1) OR d[k1 k2...]←v1 v2 ...
⍝⍝ Assign a value to each key specified, new or existing.
⍝⍝
⍝⍝ keys ← d.keys                     [alias: key]
⍝⍝ Return a list of all the keys used in the dictionary d.
⍝⍝
⍝⍝ keys ← d.keys[indices]            [alias: key]
⍝⍝ Return a list of keys by numeric indices i1 i2 ...
⍝⍝
⍝⍝ vals ← d.vals                     [alias: val]
⍝⍝ Returns the list of values  in entry order for  all items; suitable for iteration
⍝⍝      :FOR v :in d.vals ...
⍝⍝
⍝⍝ vals ← d.vals[indices]            [alias: val]
⍝⍝ Returns a list of item values by numeric indices i1 i2 ...
⍝⍝
⍝⍝ d.vals[indices]←newvals           [alias: val]
⍝⍝ Sets new values <newvals> for existing items by indices.
⍝⍝
⍝⍝ d.len  
⍝⍝ Return the number of items in the dictionary d.
⍝⍝
⍝⍝ d.del (⊂k1) OR d.del k1 k2 ...
⍝⍝ Remove keys from d.  
⍝⍝ Shyly returns 1 for each key. Signals an error of any key is not in the dictionary.
⍝⍝
⍝⍝ 1 d.del (⊂k1) OR 1 d.del k1 k2
⍝⍝ Removes items from d by keys; takes no action if any key is missing.
⍝⍝ Shyly returns 1 for each key found, 0 otherwise.
⍝⍝
⍝⍝ d.delbyindex indices              [alias: di]
⍝⍝ Removes items from d by indices i1 i2 .... Returns 1 for each item removed.
⍝⍝ Signals an error if any item does not exist.
⍝⍝
⍝⍝ 1 d.delbyindex indices            [alias: di]
⍝⍝ Removes items from d by indices i1 i2 .... Returns 1 for each item removed; else 0.
⍝⍝
⍝⍝ d.defined (⊂k1) OR d.defined k1 k2
⍝⍝ Return 1 for each key that is defined (i.e. is in the dictionary)
⍝⍝
⍝⍝ d.clear
⍝⍝ Remove all items from the dictionary.
⍝⍝
⍝⍝ d.copy
⍝⍝ Return a shallow copy of the dictionary, including its defaults
⍝⍝
⍝⍝ [default] d.get  k1 k2 ...
⍝⍝ [default] d.get1 k1
⍝⍝ Return the value for keys in the dictionary, else default. 
⍝⍝ If <default> is omitted and a key is not found, returns the existing default.
⍝⍝
⍝⍝ (k1 k2 ... d.set v1 v2) ... OR (d.set1 (k1 v1)(k2 v2)...)
⍝⍝ (k1 d.set1 v1) OR (d.set1 k1 v1)
⍝⍝ Set one or more key-value pairs
⍝⍝
⍝⍝ d.items
⍝⍝ Return a list of the dictionary’s items ((key, value) pairs).  
⍝⍝
⍝⍝ d.popitem n
⍝⍝ Remove and return the n most-recently entered key-value pairs.
⍝⍝ This is done efficiently, so that the dictionary is not rehashed.
⍝⍝
⍝⍝ d ← d.sort OR d.sorta
⍝⍝ Sort a dictionary's keys in place in ascending order
⍝⍝
⍝⍝ d ← d.sortd
⍝⍝ Sort a dictionary's keys in place in descending order
⍝⍝
⍝⍝ d.default←value
⍝⍝ Sets a default value for missing keys. Also sets d.hasdefault←1
⍝⍝
⍝⍝ d.hasdefault←[1 | 0]
⍝⍝ Activates (1) or deactivates (0) the current default; if a default exists, it is ignored
⍝⍝ if hasdefault←0, but it is not deleted; when hasdefault is reset to 1, the default (if any) is restored.
⍝⍝
⍝⍝ d.querydefault
⍝⍝ Returns a vector containing the current default and 1, if defined; else ('' 0)
⍝⍝
⍝⍝ Dictionaries preserve insertion order. Note that updating a key does not affect the order. 
⍝⍝ Keys added after deletion are inserted at the end.
⍝⍝ Dictionaries are hashed according to their keys (using APL hashing: 1500⌶)

    ⎕IO ⎕ML←0 1

  ⍝ Shared Fields
  ⍝ If DEBUG is set to one before ⎕FIXing, the ⎕TRAP is ignored.
    :Field Public  Shared DEBUG←  0                       
    :Field Public  Shared ∆TRAP←  (0⍴⍨~DEBUG) 'C' '⎕SIGNAL/⎕DMX.(EM EN)'  

  ⍝ INSTANCE FIELDS and Related
    keysF←⍬                                 ⍝ Variable, not Field, to avoid APL hashing bug
    :Field Private valuesF←       ⍬
    :Field Private hasdefaultF←   0
    :Field Private defaultF←      ''        ⍝ Initial value

  ⍝ ERROR MESSAGES:
    eBadLoad←         'Dict: args consist of key-value pairs, dictionaries, and a scalar default value.'
    eBadDefault←      'Dict: hasdefault must be set to 1 (true) or 0 (false).'
    eDeleteKeyMissing←'Dict/del: non-existent keys may not be deleted, unless ignore (⍺)=1.'
    eIndexRange←      'Dict/delbyindex: An index argument was not in range.'
    eKeyAlterAttempt← 'Dict/keys: keys may not be altered.'
    eHasNoDefaultK←   'Dict: Value Error: key does not exist and no default was set.'
    eHasNoDefaultD←   'Dict: Value Error: no default is set (hasdefault←0).'
    eQueryDontSet←    'Dict/querydefault may not be set; set default or hasdefault.'

  ⍝ General Local Names
    ∇ ns←Dict                     ⍝ Returns this namespace 
      :Access Public Shared
      ns←⎕THIS
    ∇
    ∇ns←{def} ∆DICT initial       ⍝ Creates ⎕NEW Dict via cover function
     :TRAP 0⍴⍨~⎕THIS.DEBUG 
        ns←⎕NEW ⎕THIS initial 
        :IF ~900⌶1 ⋄ ns.default←def ⋄ :Endif 
     :Else
        ⎕SIGNAL/⎕DMX.(EM EN)
     :EndTrap
     ∇
     
    ⍝ Export Dict and ∆DICT to the parent environment (hard-wiring this namespace)
    ⍝ ⎕NEW version:  [x] visible, [ ] suppressed: 
    ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'Dict'
    ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR '∆DICT'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Constructors...

    ⍝ New1: "Constructs a dictionary and loads*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Alternatively, sets the default value."
    ⍝ Uses Load/Import, which will handle duplicate keys (the last value quietly wins), and so on.
    ⍝ *** See Load for conventions for <initial>.
    ∇ new1 struct
      :Implements Constructor
      :Access Public
      ⎕DF (⍕⊃⊃⎕CLASS ⎕THIS),'<1>'
      :Trap 0⍴⍨~DEBUG
          _load struct
      :Else  
          ⎕SIGNAL/⎕DMX.(EM EN)
      :EndTrap
    ∇
    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
      ⎕DF (⍕⊃⊃⎕CLASS ⎕THIS),'<0>'
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)

    ⍝ map: "Using standard vector selection and assignment, set and get values given keys. 
    ⍝ New entries are created automatically"
    ⍝ SETTING key-value pairs
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING key-value pairs
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property default keyed map
    :Access Public
        ∇ vals←get args;err;_ix;found;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          :If ⎕NULL≡⊃args.Indexers ⋄ vals←valuesF ⋄ :Return ⋄  :EndIf
          p←keysF⍳⊃args.Indexers
          found←(≢keysF)>p
          :If ~0∊found
              vals←valuesF[p] ⍝ Error here...
          :ElseIf hasdefaultF
              vals←found\valuesF[found/p]
              ((~found)/vals)←⊂defaultF     ⍝ Add defaults
              vals←(⍴p)⍴vals               ⍝ If input parm is scalar, vals must be as well...
          :Else
              eHasNoDefaultK ⎕SIGNAL 11
          :EndIf
        ∇
        ∇ set args;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          keys←⊃args.Indexers ⋄ vals←args.NewValue
          _import keys vals
        ∇
    :EndProperty

    ⍝ dict.get      Retrieve keys ⍵ with optional default ⍺
    ⍝ --------      (See also dict.get1)
    ⍝         dict.get keys   ⍝ -- all keys must exist or have a default
    ⍝ default dict.get keys   ⍝ -- keys which don't exist are given the specified default
    ∇ vals←{def} get keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1 
          vals←⎕THIS[keys]
      :ELSE 
          nh←~has←defined keys
          vals←⎕THIS[has/keys]
          vals←has\vals
          (nh/vals)←⊂def
      :ENDIF
    ∇
    ⍝ dict.get1      Retrieve key ⍵ with optional default ⍺
    ⍝ ---------      (See also dict.get)
    ⍝         dict.get1 key   ⍝ -- the key must exist or have a default
    ⍝ default dict.get1 key   ⍝ -- if key doesn't exist, it's given the specified default
    ∇ val←{def} get1 key;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1  ⋄ def←⊢ ⋄ :ENDIF
      val←⊃def get ⊂key
    ∇

    ⍝ dict.set  --  Set keys ⍺ to values ⍵ OR set key value pairs: (k1:⍵11 v1:⍵12)(k2:⍵21 v2:⍵22)...
    ⍝ --------      (See also dict.set1)
    ⍝ {vals}←keys dict.set vals
    ⍝ {vals}←     dict.set (k v)(k v)...
    ∇ {vals}←{keys} set vals;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ keys vals←↓⍉↑vals ⋄ :EndIf
      _import keys vals
    ∇
    ⍝ dict.set1  -- set single key ⍺ to value ⍵ OR set key value pair: (k1:⍵1 v1:⍵2)
    ⍝ ---------     (See also dict.set)
    ⍝ {val}←key dict.set1 val
    ⍝ {val}←    dict.set1 k v
    ∇ {val}←{key} set1 val;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ key val←val ⋄ :EndIf
      val←⊃(,⊂key) set (,⊂val)
    ∇

    ⍝ load ⍵:  Load data into dictionary and/or set default for values of missing keys.
    ⍝ _load ⍵: Internal utility to be called from top-level routines."
    ⍝ load accepts either a SCALAR or VECTOR right argument ⍵.
    ⍝ ∘  SCALAR or 1-ITEM VECTOR that is not a Class Instance (⎕NC≠9.2)
    ⍝     dictionary is empty with default←⊃⍵ and hasdefault←1.
    ⍝     E.g. load 1:   default←1
    ⍝         load ⊂'': default←''
    ⍝ ∘  SCALAR or 1-ITEM VECTOR that is a Class instance (⎕NC=9.2)
    ⍝     dictionary's keys and values will be copied from the dictionary ⍵ (fast)
    ⍝     ⍵ need not be in the class 'dict', but ⍵.export must return a list of (keys values)
    ⍝ ∘  0-LENGTH VECTOR (⍬ or '')
    ⍝     If ⍵≡⍬    dictionary is empty with default ⍬
    ⍝     If ⍵≡''   dictionary is empty with default ''
    ⍝ ∘  MATRIX (3×1 or 2×1). 
    ⍝       2×1 MATRIX:  ⍵ is ⍪Keys_vector Values_vector
    ⍝       3×1 MATRIX:  ⍵ is ⍪Keys_vector Value_vector Default_scalar
    ⍝         Equiv. to dict.import 2↑⍵  ⋄ dict.default←⊃2⊃⍵ 
    ⍝ ∘  VECTOR: ⍵ interpreted as 1 or more items: ⍵1 ⍵2 ⍵3 ... 
    ⍝     For each element ⍵N:
    ⍝       2=≢⍵N:    ⍵N is a (key value) pair
    ⍝       9.2=⎕NC'⍵N': ⍵N is a class instance with keys and values accessed via ⍵N.export
    ⍝       scalar:  ⍵N specifies the default (for missing keys). Normally, this item is first or last.
    ⍝               If more than one is specified, the last is used.
    ⍝               Equivalent to ⍵←⎕NEW dict ⋄ ⍵.default←⍬⍴⍵
    ⍝               To set the default to a null value:
    ⍝                   null string:  (⊂'')     numeric null:  (⊂⍬)
    ⍝                   ⎕NULL:        ⎕NULL     0 (zero):      0            
   
    ∇ {me}←load initial;⎕TRAP
      :Access Public
       ⎕TRAP←∆TRAP
      _load initial
      me←⎕THIS
    ∇
    ⍝ _load: used only internally, but visible
    ∇ _load items;k;v;scanArgs 
      k←v←⍬                              ⍝ Syntax                          Action
      scanArg←{
        2<≢⍵:eBadLoad ⎕SIGNAL 11   
        2=≢⍵:(k v),←⊂¨⍵                  ⍝ key-val pair                    Load k-v pair
        ⋄ isDict←9.2=⎕NC⊂'item'⊣item←⍬⍴⍵
        isDict:(k v),←⍵.export           ⍝ dict                            Import Dictionary
        defaultF hasdefaultF∘←(⊃⍵) 1        ⍝ default←⊃⍵                      SD
      }
      :If 0=≢items                       ⍝ ∇ '' or ∇ ⍬                     SD (Set Default)
          defaultF hasdefaultF←items 1
      :ElseIf 1=≢items                   ⍝ ∇ dict OR ∇ scalar              Import Dict or SD
          scanArg ⊂items ⋄ _import k v   ⍝ To default to a 1-item vector (,2), pass as: (⊂,2)
      :ElseIf 2=⍴⍴items                  ⍝ ∇ ⍪keyVec valVec [default]      Matrix? Import
          :Select ⍬⍴⍴items←,items        ⍝ Must be 2 or 3 rows, 1 col.
            :Case 2                      ⍝                                 2 rows? Import
            :Case 3                      ⍝                                 3 rows? Import + SD
              defaultF hasdefaultF←(2⊃items)1
            :Else 
              eBadLoad ⎕SIGNAL 11
          :EndSelect
          _import 2↑items
      :ElseIf 2∧.=≢¨items                ⍝ ∇ (k1 v1)(k2 v2) etc.           Import
          _import↓⍉↑items
      :Else                              ⍝ mix of items                    Load item by item
          k←v←⍬                       
          scanArg¨items ⋄ _import k v  ⍝ scan items one by one
      :EndIf
    ∇

    ⍝ import: "Enters keys and values separately into a dictionary.
    ⍝          import (keys values)."
    ⍝
    ⍝ _import: "Utility to be called from top-level routines.
    ⍝           _import  keys values.
    ⍝           keys, values are ravelled if not already vectors."
    ∇ {me}←import(keys vals);⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      _import keys vals
      me←⎕THIS 
    ∇

    ⍝ ignore←_import keyVec valVec
    ⍝ Updates instance vars keysF valuesF, then calls _hashK to be sure hashing enabled.
    ⍝ Shyly returns ⍬ (ignored).
      _import←{                   ⍝ 0.  k, v: k may have old and new keys, some duplicated.
          k v←,¨⍵                 ⍝     Make sure k and v are each vectors...
          0=≢k:_←⍬                ⍝     No keys/vals? Return now.
          old←(≢keysF)>p←keysF⍳k  ⍝ I.  Note old keys
          valuesF[old/p]←old/v    ⍝     Update old keys in place w/ new vals; duplicates? Keep last new val.
          ~0∊old:_←⍬              ⍝     All old? No more to do; shy return.
          k v←(⊂~old)/¨k v        ⍝ II. Mark new keys and their values as k, v.
          v[k1←⍳⍨k]←v             ⍝     For duplicate keys, "accept" last (rightmost) value
          msk←⊂k1=⍳≢k             ⍝     Create and enclose mask of those to keep.
          keysF valuesF,←msk/¨k v ⍝ III.Update keys and values fields based on umask.
          1:_←⍬⊣_hashK            ⍝     Update hash and shyly return.
      }

    ⍝ copy:  "Creates a copy of an object including its current settings (by copying fields).
    ⍝         Uses ⊃⊃⎕CLASS in case the object is from a class derived from Dict (as a base class).
    ∇ {new}←copy
      :Access Public
      new←⎕NEW (⊃⊃⎕CLASS ⎕THIS) (⍪keysF valuesF)
      :IF hasdefaultF ⋄ new.default←defaultF ⋄ :ENDIF 
    ∇

    ⍝ export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←export
      :Access Public
      k v←keysF valuesF
    ∇

    ⍝ table/print: "Returns all the key-value pairs as a matrix, one pair per row.
    ⍝         Equivalent to ↑⍵.items."
    :Property table,print,disp,display
    :Access Public
    ∇ r←get args
      :If 0=≢keysF ⋄ r←⍬
      :Else ⋄ r←⍉↑keysF valuesF
      :EndIf
      :IF 'd'=1↑args.Name   ⍝ Display using short-form disp(lay) 
          r←⎕SE.Dyalog.Utils.disp r
      :EndIf 
    ∇
    :EndProperty

    ⍝ items: "Returns ALL key-value pairs as a vector, one vector element per pair"
    :Property items,item 
    :Access Public
        ∇ r←get args
          :If 0=≢keysF ⋄ r←⍬
          :Else ⋄ r←↓⍉↑keysF valuesF
          :EndIf
        ∇
    :EndProperty

    ⍝ iota ⍵: "Returns the indices (⎕IO=0) of each key specified in ⍵ (returns (len) for missing values).
    ⍝          The order is the same as used in ⍺.Keys and ⍺.Vals
    ⍝          Same as (⍵.Keys⍳keys) but much faster."
    ∇ ix←iota keys
      :Access Public
      ix←keysF⍳keys
    ∇

    ⍝ len:  "Returns the number of key-value pairs"
    ⍝ aliases: len 
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
    ⍝ k ← Keys              returns all Keys in entry order
    ⍝ k ← Keys[ix1 ix2...]  returns zero or more keys by index (user origin).
    :Property keys,key
    :Access Public
        ⍝ get: retrieves keys
        ∇ k←get args 
          k←keysF
        ∇
        ∇ set args
          eKeyAlterAttempt ⎕SIGNAL 11
        ∇
    :EndProperty

    ⍝ values,vals,val:
    ⍝   "Get or Set values by key index, in creation order or, if sorted, sort order.
    ⍝    Indicates are in current user ⎕IO ONLY"
    :Property numbered values,value,vals,val  ⍝ Vi = keys by index
    :Access Public
        ⍝ get: retrieves values, not keysF
        ∇ vals←get args;ix
          ix←⊃args.Indexers
          vals←valuesF[ix]     ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ⍝ set: sets Values, not keysF
        ∇ set args;newvals;ix
          ix←⊃args.Indexers
          newvals←args.NewValue
          valuesF[ix]←newvals
        ∇
        ∇ r←shape
          r←len
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
    ⍝                  Alternatively, retrieves the current status (1 or 0)."
    ⍝ default:       "Sets the default value for use when retrieving missing values, setting hasdefault←1.
    ⍝                  Alternatively, retrieves the current default."
    ⍝ querydefault:  "Combines hasdefault and Default in a single command, returning the current settings from
    ⍝                  hasdefault and Default as a single pair. querydefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property default,hasdefault,querydefault
    :Access Public
        ∇ r←get args
          :Select args.Name
          :Case 'default'
              :If ~hasdefaultF ⋄ eHasNoDefaultD ⎕SIGNAL 11 ⋄ :EndIf
              r←defaultF
          :Case 'hasdefault'
              r←hasdefaultF
          :Case 'querydefault'
              r←hasdefaultF defaultF
          :EndSelect
        ∇
        ∇ set args
          :Select args.Name
          :Case 'default'
              defaultF hasdefaultF←args.NewValue 1
          :Case 'hasdefault'
              :If ~0 1∊⍨⊂args.NewValue
                  eBadDefault ⎕SIGNAL 11
              :EndIf
              hasdefaultF←⍬⍴args.NewValue   ⍝ defaultF unchanged...
          :Case 'querydefault'
              eQueryDontSet ⎕SIGNAL 11
          :EndSelect
        ∇
    :EndProperty

    ⍝ inc, dec:
    ⍝    ⍺ inc/dec ⍵:  Adds (subtracts) ⍺ from values for keys ⍵
    ⍝      inc/dec ⍵:  Adds (subtracts) 1 from values for key ⍵
    ⍝    ⍺ must be conformable to ⍵ (same shape or scalar)
    ⍝  Returns: Newest value
    ⍝  Esp. useful with DefaultDict...
    ∇ {newval}←{∆}inc keys;this
      :Access Public
      this←⎕THIS
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :If (≢∪keys)=≢keys
          newval←∆+0 get keys
          import keys newval
      :Else     ⍝ keys appear more than once; process all (L to R) so increments accumulate
          newval←∆{
              key1←⊂⍵
              nv1←⍺+0 get key1
              nv1⊣import key1 nv1
          }¨keys
      :EndIf
    ∇
    ∇ {newval}←{∆}dec keys
      :Access Public
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      newval←(-∆)inc keys
    ∇

    ⍝ defined: Returns 1 for each key found in the dictionary
    ∇ old←defined keys
      :Access Public
      old←(≢keysF)>keysF⍳keys
    ∇

    ⍝ del:  "Deletes key-value pairs from the dictionary by key, but only if all the keys exist"
    ⍝        If ignore is 1, missing keys quietly return 0.
    ⍝        If ignore is 0 or omitted, missing keys signal a DOMAIN error (11).
    ⍝ b ← {ignore←1} ⍵.del key1 key2...
    ⍝ Returns a vector of 1s and 0s: a 1 for each key kN deleted; else 0.
    ∇ {b}←{ignore}del keys;nf;old;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      keys←∪keys
      b←(≢keysF)>p←keysF⍳keys
      nf←0∊b
      :If nf∧~ignore     ⍝ (Unless ignore=1) Signal error if not all k-v pairs exist
          eDeleteKeyMissing ⎕SIGNAL 11
      :EndIf
      :If 0≠≢b←b/p
          ∆←1⍴⍨≢keysF ⋄ ∆[b]←0
          keysF←∆/keysF ⋄ valuesF←∆/valuesF ⋄ _hashK 
      :EndIf
    ∇

    ⍝ delbyindex | di:    "Deletes key-value pairs from the dict. by index. See del."
    ⍝     If ignore is 1, indices out of range quietly return 0.
    ⍝     If ignore is 0 or omitted, indicates out of range signal an INDEX ERROR (7).
    ⍝ b ← {ignore←1} ⍵.delbyindex ix1 ix2...
    ⍝ b ← (ignore←1} ⍵.di           ix1 ix2...
    ⍝
    ∇ {b}←{ignore}di ix;keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      ignore delbyindex ix
    ∇
    ∇ {b}←{ignore}delbyindex ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf    
      ix←∪ix
      b←{⍵:0=0(≢keysF)⍸ix ⋄ 0}×≢keysF
      :If (0∊b)∧~ignore               ⍝ At least 1 missing key?
          eIndexRange ⎕SIGNAL 7
      :EndIf
      ix←b/ix                        ⍝ Keep those in range
      :If 0<≢ix                      ⍝ Delete keys marked for del'n
          ∆←(≢keysF)⍴1 ⋄ ∆[ix]←0     ⍝ Note their position in keysF
          keysF←∆/keysF ⋄ valuesF←∆/valuesF ⋄ _hashK 
      :EndIf
    ∇

    ⍝ clear:  "Clears the entire dictionary (i.e. deletes every key-value pair)
    ⍝          and returns the dictionary."
    ∇ {me}←clear
      :Access Public
      keysF←valuesF←⍬                            ⍝ Rehash: See AutoKeyHashUpdateTrigger
      me←⎕THIS
    ∇

    ⍝ popitem:  "Removes and returns last <n> items (pairs) from dictionary as if a LIFO stack.
    ⍝            Efficiently updates keysF to preserve hash status."
    ⍝ kv1 kv2... ← ⍵.pop n   where n is a number between 0 and Len
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs
    ∇ {poppedItems}←popitem n;last;k;v
      :Access Public
      :If 0=n ⋄ poppedItems←⍬ ⋄ :Return ⋄ :EndIf        ⍝ Pop 0 does nothing, returns ⍬
      last←-|n⌊≢keysF                                   ⍝ Don't pop what isn't there...
      poppedItems←↓⍉↑last↑¨keysF valuesF
      keysF↓⍨←last ⋄ valuesF↓⍨←last
    ∇

    ⍝ sort/sorta (ascending),
    ⍝ sortd (descending)
    ⍝ Descr:
    ⍝    "Sort a dictionary IN PLACE:
    ⍝     ∘ Sort keys in (Sort/A: ascending (D: descending) order;
    ⍝       - revised to use TAO (sorting anything).
    ⍝ Returns: the dict
    ⍝
    :Property sort,sorta,sortd
    :Access Public
        ∇ me←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If 'd'=¯1↑args.Name ⍝ sortd
              ix←⍒keysF
          :Else                  ⍝ sorta, sort
              ix←⍋keysF
          :EndIf
          keysF←keysF[ix] ⋄ valuesF←valuesF[ix] ⋄  _hashK 
          me←⎕THIS
        ∇
    :EndProperty

    ⍝ gradeup, gradedown/gradedn: Returns the indices of the keys in sorted order, either graded up or down.
    ⍝ Note: Doesn't reorder the dictionary, returns indices reordered..
    :Property gradeup,gradedown,gradedn
    :Access Public
        ∇ ix←get args;⎕TRAP
          ⎕TRAP←∆TRAP
          :If args.Name≡'gradeup'
              ix←⍋keysF
          :Else  ⍝ gradedown,gradedn
              ix←⍒keysF
          :EndIf
        ∇
    :EndProperty

  ⍝ Dict.help/Help/HELP  - Display help documentation window.
    ∇ {h}←help;ln 
      :Access Public Shared
      ⍝ Pick up only ⍝H1 comments!
      :Trap 0 ⋄ h←⎕SRC ⎕THIS ⋄ h←3↓¨h/⍨(⊂'⍝⍝')≡¨2↑¨h 
              :FOR ln :in h ⋄ ⎕←ln ⋄ :ENDFOR
      :Else ⋄ ⎕SIGNAL/'Dict.HELP: No help available' 911
      :EndTrap
    ∇
    _←⎕FX 'help'⎕R'Help'⊣⎕NR 'help'
    _←⎕FX 'help'⎕R'HELP'⊣⎕NR 'help'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ INTERNAL UTILITIES
    ⍝ ----------------------------------------------------------------------------------------

    ∇ {hashStatus}←_hashK  
    ⍝ Set keysF to be hashed (if not already and if there are at least 2 keys [Dyalog "bug"]!
      hashStatus←1(1500⌶)keysF
      :If (0=hashStatus)∧2≤≢keysF
          keysF←1500⌶keysF
      :EndIf
    ∇
:EndClass


⍝ d ← [default←''] SimpleDict k_v_pairs   OR  [default←''] SimpleDict ⍬
⍝      d.default is ⍺, if specified, else ''
⍝      d.keys    is the list of current keys
⍝      d.vals     is the list of current values
⍝ Methods:
⍝       set:             keys    d.set   vals
⍝       set1:            key     d.set1  val
⍝       get:   vals    ← [def]   d.get   vals   (default for def is d.default)
⍝       get1:  val     ← [def]   d.get1  val
⍝       inc:   newvals ← [num←1] d.inc   keys   (if key is new, increment default (if numeric), else 0)
⍝       inc1:  newval  ← [num←1] d.inc1  key    (ditto)
⍝       dec:   newvals ← [num←1] d.dec   keys   (ditto)
⍝       dec1:  newval  ← [num←1] d.dec1  key    (ditto)
⍝       del:   bools   ←         d.del   keys
⍝       del1:  bool    ←         d.del1  key
⍝       table: mx      ←         d.table
⍝       print: (alias for d.table)
  SimpleDict←{
      ⎕IO ⎕ML←0 1
     ⍝ d ← [default] SimpleDict [key-value pairs | ⍬]
      ⍺←''   ⍝ Default is character null-string.
             ⍝ Use ⍺:⎕NULL etc to distinguish from typical values...
      dict.dict←dict←⎕NS''
    ⍝ vals ← keys set  vals
    ⍝ val  ← key  set1 val
      dict.set←{1:_←⍺ set1¨⍵ }
      dict.set1←{
          p←keys⍳⊂⍺
          p<≢keys:(p⊃vals)←⊂⍵
          keys,←⊂⍺
          1:_←vals,←⊂⍵   ⍝ returns val:⍵
      }
    ⍝ {newval} ← [increments←1]  inc  keys
    ⍝ {newval} ← [increment←1]   inc1 key
      dict.inc←{⍺←1 ⋄ 1:_←⍺ inc1¨⍵}
      dict.inc1←{⍺←1
          p←keys⍳⊂⍵
          p<≢keys:(p⊃vals)+←⍺
          keys,←⊂⍵
        ⍝ If key not found, if default is (apparently) numeric, increment/decrement default
          0=1↑0⍴default: _←vals⊣vals,←⊂⍺+default
        ⍝ Else, ignore default and increment from 0
          1:_←vals⊣vals,←⊂⍺+0  
      }
      ⍝ {key} ← [decrements←1] dec keys
      ⍝ {key} ← [decrement←1]  dec1 key
      dict.dec←{⍺←1 ⋄ 1:_←(-⍺) inc1¨⍵}
      dict.dec1←{⍺←1
          1:_←(-⍺)inc1 ⍵
      }
    ⍝ vals ← [def] get  keys
    ⍝ val ←  [def] get1 key
      dict.get←{⍺←⊢ ⋄ ⍺ get1¨⍵}
      dict.get1←{⍺←default
          p←keys⍳⊂⍵
          p<≢keys:p⊃vals
          ⍺
      }
    ⍝ bools ←  del keys
    ⍝ bool  ←  del1 key
      dict.del←{del1¨⍵}
      dict.del1←{
          p←keys⍳⊂⍵
          p≥≢keys:_←0
          k←p≠⍳≢keys
          keys∘←k/keys
          vals∘←k/vals
          1:_←1
      }
      ⍝ mx ← dict.table
      ⍝ mx ← dict.print
      tblFn←':IF 0=≢keys ⋄ r←⍬ ⋄ :Else ⋄ r←⍉↑keys vals ⋄ :Endif'
      _←dict.⎕FX¨ ('r←table' tblFn)('r←print' tblFn)

      dict.(keys vals)←{0=≢⍵:⍬ ⍬ ⋄ ↓⍉↑⍵}⍵
      dict.default←⍺
      dict⊣dict.⎕DF '[SimpleDict]'
  }
