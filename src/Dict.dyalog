:Class DictClass
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
⍝⍝ TYPE       CODE                          ITEMS                                 DEFAULT
⍝⍝ ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝⍝ empty      a←∆DICT ⍬                     ⍝ None                                none
⍝⍝ items      b←∆DICT (1 10)(2 20)(3 30)    ⍝ 3: (1 10)...                        none
⍝⍝ items+     c←0 ∆DICT (1 10)(2 20)(3 30)  ⍝ 3: (1 10)...                        0
⍝⍝ lists+     d←⍬ ∆DICT ⍪(1 2 3)(10 20 30)  ⍝ 3: (1 10)...                        ⍬ (numeric null)
⍝⍝ copy       e←∆DICT d (4 40)              ⍝ 4: (1 10)...(4 40)                  none
⍝⍝ 
⍝X Dict:      A utility fn that returns the full name of the dictionary class, often #.DictClass.
⍝X            To enable, put #.DictClass in your ⎕PATH.
⍝X            d←⎕NEW Dict            ⍝ Create a new, empty dictionary with no default values.
⍝X            d←⎕NEW Dict (struct)   ⍝ Initialize dictionary with same call as for ∆DICT or d.load.
⍝⍝ Hashes keys for efficiently searching and updating items in large dictionaries.
⍝⍝ For HELP information, call 'dict.HELP'.
⍝⍝
⍝⍝ --------------------------
⍝⍝    CREATION
⍝⍝ --------------------------
⍝⍝ d← ∆DICT ⍬
⍝⍝    Creates a dictionary <d> with no items and no default. Items may be added via d[k1 k2...]←v1 v2...
⍝⍝    A default value may be added via d.default← <any object>.
⍝⍝
⍝⍝ d← [default] ∆DICT objs
⍝⍝    Creates dictionary <d> with optional default <default> and calls 
⍝⍝       d.load objs   ⍝ Se below
⍝⍝    to set keys and values from key-value pairs, (keys values) vectors, and dictionaries.
⍝⍝
⍝⍝ d←∆DICT ⊂default      OR    d←default ∆DICT ⍬
⍝⍝    default must be a simple scalar, like 5, or it must be enclosed.
⍝⍝        e.g. ∆DICT 10         creates an empty dictionary with default value 10.
⍝⍝             ∆DICT ⊂⍬         creates an empty dictionary with default value ⍬ (not ⊂⍬).
⍝⍝             ∆DICT ⊂'Missing' creates an empty dictionary with default value 'Missing'.
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
⍝⍝ ---------------------------------------------------
⍝⍝     GETTING (LISTING) OF ALL KEYS / KEYS BY INDEX
⍝⍝ ---------------------------------------------------
⍝⍝ keys ← d.keys                     [alias: key]
⍝⍝     Return a list of all the keys used in the dictionary d.
⍝⍝
⍝⍝ keys ← d.keys[indices]            [alias: key]
⍝⍝     Return a list of keys by numeric indices i1 i2 ...
⍝⍝
⍝⍝ ------------------------------------------------
⍝⍝    SETTING/GETTING ALL VALUES / VALUES BY INDEX
⍝⍝ ------------------------------------------------
⍝⍝ vals ← d.vals                     [alias: val]
⍝⍝     Returns the list of values  in entry order for  all items; suitable for iteration
⍝⍝         :FOR v :in d.vals ...
⍝⍝
⍝⍝ vals ← d.vals[indices]            [alias: val]
⍝⍝     Returns a list of item values by numeric indices i1 i2 ...
⍝⍝
⍝⍝ d.vals[indices]←newvals           [alias: val]
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
⍝⍝ d.DEBUG ← [1 | 0]   
⍝⍝ :IF d.DEBUG ⋄ ... ⋄ :ENDIF 
⍝⍝     If DEBUG is 1, an error will be signalled where it occurs.
⍝⍝     Otherwise, it will be signalled at the dictionary call (cutback).
⍝⍝     When DEBUG←1, the # of items in a dictionary is part of its display form.
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
⍝⍝ d.load  [obj1 | obj2 | obj3 | ⊂default] [obj1 | obj2 | obj3 | ⊂default] ...
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
⍝⍝ d.import (k1 k2 ...) (v1 v2 ...)
⍝⍝     Set one or more items from a K-V LIST (⍵1 ⍵2)
⍝⍝         ⍵1: a vector of keys
⍝⍝         ⍵2: a vector of values.
⍝⍝     To set a single key-value pair (k1 v1), use e.g.:
⍝⍝         k1 d.set1 v1 
⍝⍝         d.import (,k1)(,v1)
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
⍝⍝     Remove and return the n (n≥0) most-recently entered key-value pairs.
⍝⍝     This is done efficiently, so that the dictionary is not rehashed.
⍝⍝
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
⍝⍝ ix ← d.gradeup
⍝⍝     Returns the indices of the dictionary sorted in ascending order by keys 
⍝⍝     (doesn't reorder the dictionary)
⍝⍝
⍝⍝ ix ← d.gradedown    
⍝⍝ ix ← d.gradedn           ⍝ Alias for d.gradedown
⍝⍝     Returns the indices of the dictionary sorted in descending order by keys 
⍝⍝     (doesn't reorder the dictionary)
⍝⍝
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

⍝ Export key utilities to the parent environment (hard-wiring this namespace)
  ⍝ ##.Dict:   [ ] created, [x] suppressed. 
  ⍝ ##.∆DICT:  [x] created, [ ] suppressed. 
  ⍝ ##.∆JDICT:[x] created, [ ] suppressed
    ⎕IO ⎕ML←0 1
  
  ⍝ DEBUG_TRIGGER: When DEBUG instance variable changes, keep ∆TRAP synchronized...
  ⍝ For use in Instances only.
  ∇ DEBUG_TRIGGER    
      :Implements Trigger DEBUG
      :SELECT ⍬⍴DEBUG
        :CASE DEBUG_WAS 
        :CASE 1 ⋄ ∆TRAP← 0⍴⎕TRAP ⋄  ⎕←'DEBUG ACTIVE' ⋄ UPDATE
        :CASE 0 ⋄ ∆TRAP←  ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.((EM,Message,⍨'': ''/⍨0≠≢Message) EN)'
                  ⎕DF 'Dict[]'   
      :ENDSELECT
      DEBUG_WAS←DEBUG 
   ∇
   ∇t←⍙TRAP
    t←⊂⎕DMX.(('EM' EM)('EN' EN)('Message' Message))
   ∇


  ⍝ Shared Fields
  ⍝ DEBUG and ⎕TRAP-related: If DEBUG is set or reset to a new value, the ⎕TRAP is updated...
    :Field Public  DEBUG←      0 
    :Field Private ∆TRAP←      0 'C' '⎕SIGNAL/⎕DMX.(((''∆DICT: '',EM),Message,⍨'': ''/⍨0≠≢Message) EN)'
    :Field Private DEBUG_WAS←  ⎕NULL  
                   
  ⍝ INSTANCE FIELDS and Related
                   keysF←         ⍬         ⍝ Variable, not Field, to avoid Dyalog bugs (catenating/hashing)
    :Field Private valuesF←       ⍬
    :Field Private hasdefaultF←   0
    :Field Private defaultF←      ''        ⍝ Initial value
    :Field Private baseclassF←     ⊃⊃⎕CLASS ⎕THIS

  ⍝ ERROR MESSAGES:  ⎕SIGNAL⊂('EN' 200)('EM' 'Main error')('Message' 'My error')
    eBadLoad←         11 '∆DICT: invalid right argument (⍵) on initialization or load.'
    eBadDefault←      11 '∆DICT: hasdefault must be set to 1 (true) or 0 (false).'
    eDelKeyMissing←   11 '∆DICT.del: at least one key was not found and ⍺:ignore≠1.'
    eIndexRange←       3 '∆DICT.delbyindex: An index argument was not in range and ⍺:ignore≠1.'
    eKeyAlterAttempt← 11 '∆DICT.keys: item keys may not be altered.'
    eHasNoDefault←     3 '∆DICT.index: key does not exist and no default was set.'
    eHasNoDefaultD←   11 '∆DICT: no default has been set.'
    eQueryDontSet←    11 '∆DICT: querydefault may not be set; Use Dict.(default or hasdefault).'
    eBadInt←          11 '∆DICT.(inc dec): increment (⍺) and value for each key in ⍵ must be numeric.'

  ⍝ General Local Names
    ∇ ns←Dict                      ⍝ Returns this namespace. Searchable via ⎕PATH. 
      :Access Public Shared
      ns←⎕THIS
    ∇
    ⍝ ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'Dict'

    ∇dict←{def} ∆DICT initial      ⍝ Creates ⎕NEW Dict via cover function
     :TRAP 0
        dict←(⊃⎕RSI).⎕NEW ⎕THIS initial 
        :IF ~900⌶1 ⋄ dict.default←def ⋄ :Endif 
     :Else
        ⎕SIGNAL ⊂('EN' 11)('EM' ('∆DICT ',⎕DMX.EM)) ('Message' ⎕DMX.Message)
     :EndTrap
    ∇
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
       ⎕DF 'Dict[]'  
      :Trap 0
          _load struct
      :Else  
          ⎕SIGNAL ⎕DMX.((⊂'EN' EN)('EM' EM) ('Message' Message))
      :EndTrap
    ∇
    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
      ⎕DF 'Dict[]'
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)
    ⍝-------------------------------------------------------------------------------------------
    ⍝ index: "Using standard vector indexing and assignment, set and get values given keys. 
    ⍝ New entries are created automatically"
    ⍝ SETTING values for each key
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING values for each key
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property default keyed index
    :Access Public
        ∇ vals←get args;found;ix;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          :If ⎕NULL≡⊃args.Indexers ⋄ vals←valuesF ⋄ :Return ⋄  :EndIf
          ix←keysF⍳⊃args.Indexers
          :If ~0∊found←ix<≢keysF
              vals←valuesF[ix]                
          :ElseIf hasdefaultF
            ⍝ {0=...}: If valuesF starts with a namespace, found\valuesF[...] can lead to a NONCE ERROR.
              vals←found\{0=≢⍵:⍬ ⋄ ⍵}valuesF[found/ix]
              ((~found)/vals)←⊂defaultF      ⍝ Add defaults
              vals←(⍴ix)⍴vals                ⍝ If input parm is scalar, vals must be as well...
          :Else
               THROW eHasNoDefault
          :EndIf
        ∇
        ∇ set args;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          keys←⊃args.Indexers ⋄ vals←args.NewValue
          _import keys vals
        ∇
    :EndProperty

    ⍝ dict.get      Retrieve values for keys ⍵ with optional default value ⍺ for each missing key
    ⍝ --------      (See also dict.get1)
    ⍝         dict.get keys   ⍝ -- all keys must exist or have a (class-basd) default
    ⍝ default dict.get keys   ⍝ -- keys which don't exist are given the (fn-specified) default
    ∇ vals←{def} get keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :IF 900⌶1 
          vals←⎕THIS[keys]
      :ELSE 
          nh←~has←defined keys
          vals←has\⎕THIS[has/keys]
          (nh/vals)←⊂def
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
    ⍝ {vals}←     dict.import keys values    
    ∇ {vals}←{keys} set vals;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ keys vals←↓⍉↑vals ⋄ :EndIf
      _import keys vals
    ∇
    ∇{vals}←import (keys vals);⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      _import keys vals
    ∇

    ⍝ dict.set1  -- set single key ⍺ to value ⍵ OR set key value pair: (k1:⍵1 v1:⍵2)
    ⍝ ---------     (See also dict.set)
    ⍝ {val}←k1 dict.set1 v1    
    ⍝ {val}←   dict.set1 k1 v1    
    ∇ {val}←{key} set1 val;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ key val←val ⋄ :EndIf
      _import (⊂key) (⊂val)
    ∇

    ⍝ dict.load ⍵:  
    ⍝ Load data into dictionary and/or set default for values of missing keys.
    ⍝ Workhorse for loading dictionaries, importing vectors of (keys values), and key-value pairs.
    ⍝ Determines the argument types and calls _import as needed. 
    ⍝   NOTE: Use dict.import to efficiently add a (key_vector value_vector) vector pair 
    ⍝         (e.g. exported via dict1.export)
    ⍝ 
    ⍝ _load ⍵: Internal utility to be called from top-level routines."
    ⍝ load accepts either a SCALAR or VECTOR right argument ⍵.
    ⍝ ∘  SET DEFAULT: SCALAR or 1-ITEM VECTOR that is not a Dict
    ⍝     dictionary is empty with default←⊃⍵ and hasdefault←1.
    ⍝     E.g. load 1:   default←1
    ⍝         load ⊂'': default←''
    ⍝ ∘  DICTIONARY IMPORT: SCALAR or 1-ITEM VECTOR that is a Dict
    ⍝     dictionary's keys and values will be copied from the dictionary ⍵ (fast)
    ⍝     ⍵ need not be in the class 'dict', but ⍵.export must return a list of (keys values)
    ⍝ ∘  SET DEFAULT: 0-LENGTH VECTOR (⍬ or '')
    ⍝     If ⍵≡⍬    dictionary is empty with default ⍬
    ⍝     If ⍵≡''   dictionary is empty with default ''
    ⍝ ∘  IMPORT KEYS, VALUES [AND OPT'L DEFAULT]: MATRIX (3×1 or 2×1) using ⍪ (table / comma-bar) 
    ⍝       2×1 MATRIX:  ⍵ is ⍪Keys_vector Values_vector
    ⍝       3×1 MATRIX:  ⍵ is ⍪Keys_vector Value_vector Default_scalar
    ⍝         Equiv. to dict.import 2↑⍵  ⋄ dict.default←⊃2⊃⍵ 
    ⍝ ∘  MISCELLANY: VECTOR: ⍵ interpreted as 1 or more items: ⍵1 ⍵2 ⍵3 ... 
    ⍝     For each element ⍵N:
    ⍝       2=≢⍵N:    ⍵N is a (key value) pair
    ⍝       9.2=⎕NC'⍵N' and #.DictClass∊⊃⊃⎕CLASS: ⍵N is a Dict instance
    ⍝       scalar:  ⍵N specifies the default (for missing keys). Normally, this item is first or last.
    ⍝               If more than one is specified, the last is used.
    ⍝               Equivalent to dict←⎕NEW dict ⋄ dict.default←⊃⍵N
    ⍝               To set the default to a null value:
    ⍝                   null string:  (⊂'')     numeric null:  (⊂⍬)
    ⍝                   ⎕NULL:        ⎕NULL     0 (zero):      0            
    ∇ {me}←load initial;⎕TRAP
      :Access Public
       :TRAP 0 
          _load initial  
       :Else
          THROW (⎕UCS 10),⎕DMX.Message
       :EndTrap
      me←⎕THIS
    ∇
    ⍝ <new_keys> ← _load args: used only internally
    ⍝ Loads command-line args from ⎕NEW Dict or ∆DICT:
    ⍝ May update keysF and valuesF and/or defaultF and hasdefaultF
    ⍝ Returns new keys (if any)
    ∇ {k}←_load args
        ;k;v;d;hd;ismx;isD 
        isD←{9.2≠⎕NC⊂,'⍵':0 ⋄ baseclassF∊⊃⊃⎕CLASS ⍵}  ⍝ Note more stringent definition... 
        k←⍬                                        ⍝ Local buffer for keysF
        :IF 0=≢args ⋄ :RETURN                      ⍝ null?   Fast path
        :ElseIf 0=⍴⍴args                           ⍝ SCALAR? Fast path
            :IF isD args ⋄ _import args.export
            :Else        ⋄ defaultF hasdefaultF←(⊃args) 1   
            :Endif 
        :Else                                      ⍝ Scan each item, one at a time!
          :IF 2=⍴⍴args ⋄ args←⊂args ⋄ :ENDIF
          v←d←⍬ ⋄ hd←0           ⍝ Local buffers for valuesF; defaultF, hasdefaultF
          { ⍝ Extern: k, v, d, hd
            2=⍴⍴⍵:_←{                        ⍝ ⍪keys vals [defaults]
              (k v),←0 1⊃¨⊂⍵                 ⍝ Keys, values are subitems 0, 1
              2=⍬⍴⍴⍵: ⍬                      ⍝ No optional default? Done.
              def←2⊃⍵                        ⍝ Opt'l default. Disclose from scalar packaging...
              ⊣d hd∘←def 1                   ⍝ Opt'l default disclosed!       Set Defaults
            },⍵
          ⍝ Each non-matrix item must have 2 or 1 members...
            2<≢⍵:THROW eBadLoad   
            2=≢⍵:(k v),←⊂¨⍵                  ⍝ key-val pair                    Load single k-v pair
            isD ⍵:(k v),←⍵.export            ⍝ dict                            Import Dictionary
            1:_←d hd∘←(⊃⍵) 1                 ⍝ default←⊃⍵                      Set Defaults
          }¨args
          _import k v  
          :IF hd ⋄ defaultF hasdefaultF←d 1 ⋄ :Endif 
        :Endif 
    ∇

    ⍝ ignore←_import keyVec valVec
    ⍝ From vectors of keys and values, keyVec valVec, 
    ⍝ updates instance vars keysF valuesF, then calls UPDATE to be sure hashing enabled.
    ⍝ Returns: shy keys
    ∇ {k}←_import (k v)
          ;ix;old;nk;nv;uniq;kp   ⍝ 0.   k, v: k may have old and new keys, some duplicated.                 
          →0/⍨0=≢k                ⍝      No keys/vals? Return now.
          k v←,¨k v               ⍝      Make sure k and v are each vectors...
          ix←keysF⍳k              ⍝ I.   Process existing (old) keys
          old←ix<≢keysF           ⍝      Update old keys in place w/ new vals;
          valuesF[old/ix]←old/v   ⍝      Duplicates? Keep only the last val for a given ix.
          →0/⍨~0∊old              ⍝      All old? No more to do; shy return.
          nk nv←k v/¨⍨⊂~old       ⍝ II.  Process new keys (which may include duplicates)
          uniq←⍳⍨nk               ⍝      For duplicate keys,... 
          nv[uniq]←nv             ⍝      ... "accept" last (rightmost) value
          kp←⊂uniq=⍳≢nk           ⍝      Keep: Create and enclose mask...
          nk nv←kp/¨nk nv         ⍝      ... of those to keep.
          (keysF valuesF),← nk nv ⍝ III. Update keys and values fields based on umask.
          UPDATE                  ⍝      Update hash and shyly return.
      ∇

    ⍝ copy:  "Creates a copy of an object including its current settings (by copying fields).
    ⍝         Uses ⊃⊃⎕CLASS in case the object is from a class derived from Dict (as a base class).
    ∇ {new}←copy
      :Access Public
      new←⎕NEW (⊃⊃⎕CLASS ⎕THIS) 
      new.import keysF valuesF
      :IF hasdefaultF ⋄ new.default←defaultF ⋄ :ENDIF 
    ∇

    ⍝ export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←export
      :Access Public
      k v←keysF valuesF
    ∇

    ⍝ items: "Returns ALL key-value pairs as a vector, one pair per vector element"
    :Property items,item 
    :Access Public
        ∇ r←get args
          :If 0=≢keysF ⋄ r←⍬
          :Else ⋄ r←↓⍉↑keysF valuesF
          :EndIf
        ∇
    :EndProperty

    ⍝ table/print: "Returns all the key-value pairs as a matrix, one pair per row.
    ⍝         Equivalent to ↑d.items."
    ⍝ disp/display: "filter output of d.table through (std dfns) disp or display."
    ⍝ If no items, returns ⍬ (unfiltered).
    :Property table,print,display,disp 
    :Access Public
    ∇ r←get args;show;lib
      :If 0=≢keysF ⋄ r←⍬ ⋄ :RETURN ⋄ :ENDIF 
      lib←⎕SE.Dyalog.Utils   ⍝ Includes: disp, display (not table or print)
      r←⍉↑keysF valuesF  
      :SELECT args.Name   ⍝ default: do nothing more
         :Case 'display' ⋄ r←lib.display r
         :Case 'disp'    ⋄ r←lib.disp    r 
      :EndSelect
    ∇
    :EndProperty

    ⍝ len:  "Returns the number of key-value pairs."
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
    ⍝ k ← keys              returns all Keys in entry order
    ⍝ k ← keys[ix1 ix2...]  returns zero or more keys by index (user origin).
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
    ⍝   "Get or Set values by index, in creation order (or, if sorted, sort order).
    ⍝    Indices are in caller ⎕IO (per APL).
    ⍝    Note: sets/retrieves element-by-element, as a Dyalog numbered property.
    ⍝ dict.vals← v1 v2 ...
    ⍝ dict.vals[ix1 ix2...] ← v1 v2...
    ⍝ :For v :in dict.vals ⋄ ... ⋄ :EndFor
    ⍝ :For v :in dict.vals[2×⍳ ⌊0.5×dict.vals] ⋄ ... ⋄ :EndFor
    :Property numbered values,value,vals,val  
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
    ⍝                  Alternatively, retrieves the current status (1 or 0)."
    ⍝ default:       "Sets the default value for use when retrieving missing values, setting hasdefault←1.
    ⍝                  Alternatively, retrieves the current default."
    ⍝ querydefault:  "Combines hasdefault and default in a single command, returning the current settings from
    ⍝                  hasdefault and Default as a single pair. querydefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property default,hasdefault,querydefault
    :Access Public
        ∇ r←get args
          :Select args.Name
          :Case 'default'
              :If ~hasdefaultF ⋄ THROW eHasNoDefaultD ⋄ :EndIf
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
                  THROW eBadDefault
              :EndIf
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
    ⍝  NOTE: Forces a default of 0, for undefined keys.
    ∇ {newvals}←{∆} inc keys;_inc;⎕TRAP 
      :Access Public
      ⎕TRAP←∆TRAP
      _inc←{
          nv←⍺+0 get ⍵
          nv⊣_import ⍵ nv
      }
      :If 900⌶1 ⋄ ∆←1 ⋄ :EndIf
      :TRAP 11 
          :IF (≢∪keys)=≢keys
            newvals←∆ _inc keys
          :Else 
            newvals←∆ _inc¨⊂¨keys
          :Endif
      :Else
          THROW eBadInt
      :EndTrap 
    ∇

    ∇ {newval}←{∆}dec keys;⎕TRAP
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

    ⍝ del:  "Deletes key-value pairs from the dictionary by key, but only if all the keys exist"
    ⍝        If ignore is 1, missing keys quietly return 0.
    ⍝        If ignore is 0 or omitted, missing keys signal a DOMAIN error (11).
    ⍝ b ← {ignore←1} ⍵.del key1 key2...
    ⍝ Returns a vector of 1s and 0s: a 1 for each key kN deleted; else 0.
    ∇ {b}←{ignore} del keys;ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf
      b←(≢keysF)>ix←keysF⍳keys
    ⍝ (Unless ignore=1) Signal error if not all k-v pairs exist
      eDelKeyMissing THROW⍨ (0∊b)∧~ignore 
      ignore _delbyindex b/ix
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
         ⎕SIGNAL ERROR ⎕DMX.Message
      :EndTrap
    ∇

    ∇ {b}←{ignore} delbyindex ix;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 900⌶1 ⋄ ignore←0 ⋄ :EndIf    
      b←ix{⍵:0=0(≢keysF)⍸⍺ ⋄ 0⍴⍨≢⍺}×≢keysF
      eIndexRange ERROR⍨ (0∊b)∧~ignore       ⍝ At least 1 index out of range                     
      ignore _delbyindex b/ix                    ⍝ Consider only those in index range
    ∇

    ⍝ _delbyindex: [INTERNAL UTILITY] 
    ⍝ Delete items by ix, where ix (if non-null) in range of keysF.
    ∇ ignore _delbyindex ix;count
      :If 0≠count←≢ix←∪ix                    ⍝ Delete keys marked for del'n
          :IF  ∧/ix∊(¯1+≢keysF)-⍳count       ⍝ Fast path: all keys to delete at end!
              keysF↓⍨←-count ⋄ valuesF↓⍨←-count
          :Else  
              ∆←(≢keysF)⍴1 ⋄ ∆[ix]←0      ⍝ ∆: Delete items with indices in <ix>
              keysF←∆/keysF ⋄ valuesF←∆/valuesF 
              UPDATE 
          :EndIf 
      :EndIf
    ∇

    ⍝ clear:  "Clears the entire dictionary (i.e. deletes every key-value pair)
    ⍝          and returns the dictionary."
    ∇ {me}←clear
      :Access Public
      keysF←valuesF←⍬                            
      me←⎕THIS ⋄ UPDATE
    ∇

    ⍝ popitems:  "Removes and returns last (|n) items (pairs) from dictionary as if a LIFO stack.
    ⍝             Efficiently updates keysF to preserve hash status."
    ⍝ kv1 kv2... ← d.pop count   where count is a non-negative number.
    ⍝     If count≥≢keysF, all items will be popped (and the dictionary will have no entries).
    ⍝     If count<0, it will be treated as |count.
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove |n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs. 
    ⍝ If no pairs, returns simple ⍬.
    ∇ {poppedItems}←popitems count 
      :Access Public
      count←-(≢keysF)⌊|count                               ⍝ Treat ∇¯5 as if ∇5 
      :If count=0                                          ⍝ Fast exit if nothing to pop
         poppedItems←⍬                           
      :Else
        poppedItems←↓⍉↑count↑¨keysF valuesF
        keysF↓⍨←count ⋄ valuesF↓⍨←count
      :ENDIF 
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
        ∇ me←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If 'd'=¯1↑args.Name   ⍝ sortd
              ix←⊂⍒keysF
          :Else                  ⍝ sorta, sort
              ix←⊂⍋keysF
          :EndIf
          keysF   ⌷⍨←ix  
          valuesF ⌷⍨←ix 
          UPDATE ⋄ me←⎕THIS
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
    ∇ h←help;ln 
      :Access Public Shared
      ⍝ Pick up only ⍝⍝ comments!
      :Trap 0 ⋄ h←⎕SRC ⎕THIS ⋄ h←3↓¨h/⍨(⊂'⍝⍝')≡¨2↑¨h 
                h←⎕PW↑[1]↑h
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

    ∇ {hashStatus}←UPDATE
    ⍝ Set keysF to be hashed (if not already and if there are at least 2 keys [Dyalog "bug"]!
    ⍝ If DEBUG≡1:  Sets display form to show # of entries.
      hashStatus←1(1500⌶)keysF
      :If (0=hashStatus)∧2≤≢keysF
          keysF←1500⌶keysF
      :EndIf
      :IF DEBUG≡1 ⋄ ⎕DF 'Dict[',(⍕≢keysF),']' ⋄ :ENDIF 
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
⍝⍝  A...and if minorOpt is 0 or 1
⍝⍝    ∘ Reverse the process: from dictionary to JSON object.
⍝⍝      minorOpt=0 or omitted: ⎕JSON compact (single line) format;
⍝⍝      minorOpt=1:            ⎕JSON non-compact (multiline) format.
⍝⍝  B...and if minorOpt is 2 
⍝⍝    ∘ Reverse the process, but from dictionary to APL namespace 
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
      ;TRAP;THROW11;keys;majorOpt;mangle;ns;optNull;unmangle;vals;⎕IO;⎕TRAP   
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
          unmangle←1∘(7162⌶)   ⍝ Convert APL key strings to JSON format
          dict←∆DICT ⍬
          ns dict∘{
              TRAP:: THROW11 'Valid JSON object ⍵ could not be converted to dictionary.' 
              ⋄ ns dict←⍺ ⋄ itemA itemJ←⍵ (unmangle ⍵) ⋄ val←ns⍎itemA
              2=ns.⎕NC itemA:_←itemJ dict.set1 val
              ⋄ dict2←∆DICT ⍬ ⋄ ns2←val
              ⋄ _←itemJ dict.set1 dict2
              1:_←ns2 dict2∘∇¨ns2.⎕NL-2.1 9.1
          }¨ns.⎕NL-2.1 9.1
          result←dict  ⍝ Return a single dictionary
      :Else           ⍝ User passed a dictionary to convert
          (~minorOpt∊0 1 2) THROW11 'Option ⍺ was invalid: Must be 0, 1, 2.'  
          mangle←(0∘(7162⌶))∘⍕¨ 
          scan←{
              isDict←{9.2≠⎕NC⊂,'⍵':0 ⋄ ⎕THIS∊⊃⊃⎕CLASS ⍵} 
              ns←⍺⍺ ⋄ k v←⍺ ⍵
              ~isDict v: _←k ns.{⍎⍺,'←⍵'}  v
              _←k ns.{⍎⍺,'←⍵'} ns2←ns.⎕NS ''
              1: ⍬⊣(mangle v.keys)(ns2 ∇∇)¨v.vals
          }
          dict←json
          :TRAP TRAP 
              ns←⎕NS ''
              (mangle dict.keys) (ns scan)¨dict.vals
          :Else 
              THROW11 'Dictionary ⍵ could not be converted to ⎕JSON.' 
          :EndTrap
        ⍝ Use a compact ⎕JSON format if minorOpt is 0.
        ⍝ minorOpt∊0 1: result is a  JSON string 
        ⍝ minorOpt=2:   result is a namespace.
          result ← minorOpt{⍺=2: ⍵ ⋄ ⎕JSON ⍠ optNull('Compact' (⍺=0))⊣⍵ }ns
      :EndSelect 
    ∇
     ##.⎕FX '⎕THIS\b' ⎕R (⍕⎕THIS)⊣⎕NR '∆JDICT'
:EndClass
