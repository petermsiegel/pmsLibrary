:Class DictClass
⍝ dict: A fast, ordered, and simple dictionary for general use.
⍝ Hashes vector KEYS for efficiency on large dictionaries.
⍝ For HELP information, call 'dict.HELP'.
    ⍝ ⎕←'For dictionary HELP, call "dict.HELP".'
    ⎕IO ⎕ML←0 1

  ⍝ Shared Fields
    :Field Public Shared DEBUG←0                  ⍝ See DEBUGset.
    :Field Public Shared TRAP_SIGNAL←DEBUG×999    ⍝ Ditto: Dependent on DEBUG
    :Field Public Shared ∆TRAP←TRAP_SIGNAL 'C' '⎕SIGNAL/⎕DMX.(EM EN)'  ⍝ Ditto

  ⍝ INSTANCE FIELDS and Related
    keysF←⍬     ⍝ Variable, not Field, to avoid APL hashing bug
    :Field Private valuesF       ← ⍬
    :Field Private has_defaultF   ← 0
    :Field Private defaultF      ← ''    ⍝ Initial value

  ⍝ ERROR MESSAGES:
    eBadLoad←'Dict initial or loaded data not key-value pairs, dictionary or default value.'
    eBadDefault←'Dict/has_default: has_default must be set to 1 (true) or 0 (false).'
    eDeleteKeyMissing←'Dict/del: Attempt to delete non-existent keys with Ignore=0.'
    eIndexRange←'Dict/del_by_index: An index argument was not in range.'
    eKeyAlterAttempt←'dict/keys: An entry''s key may not be altered.'
    eHasNoDefaultK←'dict: Value Error: Key does not exist.'
    eHasNoDefaultD←'dict: Value Error: has_default set to 0.'
    eQueryDontSet←'dict/query_default may be queried, but not set directly.'

  ⍝ General Local Names
    ClassNameStr←⍕⊃⊃⎕CLASS ⎕THIS

    ∇ ns←Dict
      :Access Public Shared
      ns←⎕THIS
    ∇
    ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'Dict'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Constructors...

    ⍝ New1: "Constructs a dictionary and loads*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Alternatively, sets the default value."
    ⍝ Uses Load/Import, which will handle duplicate keys (the last value quietly wins), and so on.
    ⍝ *** See Load for conventions for <initial>.
    ∇ new1 initial
      :Implements Constructor
      :Access Public
      ⎕DF ClassNameStr,'[]'
      :Trap DEBUG×99
          _load initial
      :EndTrap
    ∇

    ⍝ new0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ new0
      :Implements Constructor
      :Access Public
      ⎕DF ClassNameStr,'[]'
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)

    ⍝ get: "Using standard vector selection and assignment, set and get key-value pairs. New entries are created automatically"
    ⍝ SETTING key-value pairs
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING key-value pairs
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property default keyed get_val
    :Access Public
        ∇ vals←get args;err;_ix;found;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          :If ⎕NULL≡⊃args.Indexers
              vals←valuesF
              :Return
          :EndIf

          p←keysF⍳⊃args.Indexers
          found←(≢keysF)>p
          :If ~0∊found
              vals←valuesF[p] ⍝ Error here...
          :ElseIf has_defaultF
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

    ⍝ dict.get
    ⍝ --------
    ⍝ dict.get items
    ∇ vals←get keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      vals←⎕THIS[keys]
    ∇

    ⍝ dict.put
    ⍝ --------
    ⍝ {vals}←keys dict.put vals
    ⍝ {vals}←     dict,put (k v)(k v)...
    ∇ {vals}←{keys}put vals;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      :If 0=⎕NC'keys'
          keys vals←↓⍉↑vals
      :EndIf
      :If 1=≢keys
          keys←⊂keys ⋄ vals←⊂vals
      :EndIf
      _import keys vals
    ∇


    ⍝ load ⍵: Load data into dictionary and/or set default for values of missing keys.
    ⍝        "Accept either SCALAR or VECTOR right argument.
    ⍝         SCALAR or 1-ITEM VECTOR that is not a Class Instance (⎕NC≠9.2)
    ⍝            dictionary is null with Default←⊃⍵ and has_default←1.
    ⍝            E.g. load 1:   Default←1
    ⍝                 load ⊂'': Default←''
    ⍝         0-LENGTH VECTOR (⍬ or '')
    ⍝            If ⍵≡⍬    dictionary is empty with default ⍬
    ⍝            If ⍵≡''   dictionary is empty with default ''
    ⍝         MATRIX (3×1 or 2×1). ⍵ is ⍪KeyVector ValueVector
    ⍝            Equiv. to _Import 2↑,⍵  (Default←⊃2⊃,⍵, if shape 3×1)
    ⍝         VECTOR: three types of right arguments ⍵N in a list ⍵:
    ⍝            2=≢⍵N:    key value pairs
    ⍝            9.2=≢⍵N:  a dictionary with Keys and Values
    ⍝            scalar:   default for missing value is ⊃⍵N.
    ⍝                      To specify null string:  (⊂'').
    ⍝                                 numeric null: (⊂⍬).
    ⍝                                 0:            0
    ⍝              It is used to specify a null (empty) dictionary)
    ⍝ _load: "Utility to be called from top-level routines."
    ⍝
    ∇ {me}←load initial;⎕TRAP
      :Access Public
      me←⎕THIS ⋄ ⎕TRAP←∆TRAP
      _load initial
    ∇
    ⍝ _load: used only by classes, but visible
    ∇ _load items;keys;vals;item         ⍝ Syntax                          Action
      :If 0=≢items                       ⍝ ∇ '' or ∇ ⍬                     SD (Set Default)
          defaultF has_defaultF←items 1
      :ElseIf 1=≢items                   ⍝ ∇ 1 or ∇ (⊂'') or ∇ ⎕NULL etc.  SD
      :AndIf 9.2≠⎕NC⊂'item'⊣item←⍬⍴items ⍝ ∇ dict1
          defaultF has_defaultF←(⊃⊆item)1
      :ElseIf 2=⍴⍴items                  ⍝ ∇ ⍪keyVec valVec [Default]      (2=⍴) Import
          :If 3=⍴items←,items            ⍝                                 (3=⍴) Import + SD
              defaultF has_defaultF←(2⊃items)1
          :EndIf
          _import 2↑items
      :ElseIf 2∧.=≢¨items                ⍝ ∇ (k1 v1)(k2 v2) etc.           Import
          _import↓⍉↑items
      :Else                              ⍝ ((k1 v1)(k2 v2)*                Load
          keys←vals←⍬                    ⍝  | (d1)(d2)* | (⊂default))+
          {
              2<≢⍵:eBadLoad ⎕SIGNAL 11
              2=≢⍵:(keys vals),←⊂¨⍵      ⍝ (k1 v1)                         Load k-v pair
              item←⍵
              9.2=⎕NC⊂'item'⊣item:(keys vals),←⍵.Export   ⍝ dict1          Import Dictionary
              defaultF has_defaultF∘←(⊃⍵)1  ⍝ Default←⊃⍵                      SD
          }¨⊆items
          _import keys vals
      :EndIf
    ∇

    ⍝ import: "Enters keys and values separately into a dictionary.
    ⍝          import (keys values)."
    ⍝
    ⍝ _import: "Utility to be called from top-level routines.
    ⍝           _import  keys values."
    ⍝
    ∇ {me}←import(keys vals);⎕TRAP
      :Access Public
      me←⎕THIS ⋄ ⎕TRAP←∆TRAP
      _import keys vals
    ∇

    ⍝ ignore←_import keyVec valVec
    ⍝ Updates instance vars keysF valuesF, then calls _hashK to be sure hashing enabled.
    ⍝ Shyly returns ⍬ (ignored).
      _import←{                  ⍝ 0.  k, v: k may have old and new keys, some duplicated.
          k v←,¨⍵                ⍝     Make sure k and v are each vectors...
          old←(≢keysF)>p←keysF⍳k ⍝ I.  Note old keys
          valuesF[old/p]←old/v   ⍝     Update old keys in place w/ new vals; duplicates? Keep last new val.
          ~0∊old:_←⍬             ⍝     All old? No more to do; shy return.
          k v←(⊂~old)/¨k v       ⍝ II. Mark new keys and their values as k, v.
          v[k1←⍳⍨k]←v            ⍝     For duplicate keys, "accept" last (rightmost) value
          mask←⊂k1=⍳≢k           ⍝     Create and enclose mask of those to keep.
          keysF valuesF,←mask/¨k v  ⍝ Update keys and values fields based on umask.
          1:_←⍬⊣_hashK 0           ⍝    Update hash and shyly return.
      }

    ⍝ copy:  "Creates a copy of an object including its current settings (by copying fields).
    ∇ new←copy
      :Access Public
      new←⎕NEW⊃⎕CLASS ⎕THIS
      new._copy(keysF valuesF has_defaultF defaultF)
    ∇
    ⍝ _copy-- internal fast copying method.
    ∇ {me}←_copy(keysF valuesF has_defaultF defaultF)
      :Access Private
      me←⎕THIS
      (keysF valuesF has_defaultF defaultF)←keysF valuesF has_defaultF defaultF
    ∇

    ⍝ export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←export
      :Access Public
      k v←keysF valuesF
    ∇

    ⍝ table: "Returns all the key-value pairs as a matrix, one pair per row.
    ⍝         Equivalent to ↑⍵.Items."
    ∇ r←table
      :Access Public
      :If 0=≢keysF ⋄ r←⍬
      :Else ⋄ r←⍉↑keysF valuesF
      :EndIf
    ∇

    ⍝ Items/Pairs: "Returns ALL key-value pairs as a vector, one vector element per pair"
    :Property items,pairs
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
    ⍝ aliases: len,length,size,shape,tally
    :Property len,length,size,shape,tally
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
    ⍝ :Property Numbered Keys,Key  ⍝ Keys by Index
    :Property keys
    :Access Public
        ⍝ get: retrieves keys
        ∇ k←get args;cur;err;ix;keys;vals
          k←keysF
⍝          ix←⊃args.Indexers
⍝          k←keysF[ix]    ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ∇ set args
          eKeyAlterAttempt ⎕SIGNAL 11
        ∇
⍝        ∇ r←shape
⍝          r←≢keysF
⍝        ∇
    :EndProperty

    ⍝ values,vals,val:
    ⍝   "Get or Set values by key index, in creation order or, if sorted, sort order.
    ⍝    Indicates are in ⎕IO=0 ONLY"
    ⍝
    :Property numbered values,value,vals,val  ⍝ Vi = keys by index
    :Access Public
        ⍝ get: retrieves values, not keysF
        ∇ vals←get args;ix;vals
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

    ⍝ has_default,query_default,default
    ⍝    "Sets or queries a default value for missing keys. Th
    ⍝     By default, has_default=0, so the initial Default ('') or previously set Default is ignored,
    ⍝     i.e. a VALUE ERROR is signalled. Setting has_default←1 will make the current Default available.
    ⍝     Setting Default to a new value always turns on has_default as well."
    ⍝                SETTING    GETTING
    ⍝ has_default        Y          Y
    ⍝ default            Y          Y
    ⍝ query_default      N          Y
    ⍝
    ⍝ has_default:    "Sets the dictionary property ON (1) or OFF (0). If ON, activates current Default value.
    ⍝                  Alternatively, retrieves the current status (1 or 0)."
    ⍝ Ddfault:        "Sets the default value for use when retrieving missing values, setting has_default←1.
    ⍝                  Alternatively, retrieves the current default."
    ⍝ query_default:  "Combines has_default and Default in a single command, returning the current settings from
    ⍝                     has_default and Default
    ⍝                  as a single pair. QueryDefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property has_default,query_default,default
    :Access Public
        ∇ r←get args
          :Select args.Name
          :Case 'default'
              :If ~has_defaultF ⋄ eHasNoDefaultD ⎕SIGNAL 11 ⋄ :EndIf
              r←defaultF
          :Case 'has_default'
              r←has_defaultF
          :Case 'query_default'
              r←has_defaultF defaultF
          :EndSelect
        ∇
        ∇ set args
          :Select args.Name
          :Case 'Default'
              defaultF has_defaultF←args.NewValue 1
          :Case 'has_default'
              :If ~0 1∊⍨⊂args.NewValue
                  eBadDefault ⎕SIGNAL 11
              :EndIf
              has_defaultF←⍬⍴args.NewValue   ⍝ defaultF unchanged...
          :Case 'QueryDefault'
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
       ∆←1{0=⎕NC ⍵:⍺  ⋄  ⎕OR ⍵}'∆'
       :IF  (≢∪keys) =  ≢keys
         newval←this[keys] + ∆
         import keys newval
      :Else     ⍝ keys are duplicated; process left to right so we get correct result!
         newval←∆{
            key1←⊂⍵
            nv1←this[key1] +  ⍺
            nv1⊣import key1 nv1
         }¨keys
      :Endif
      ∇
      ∇ {newval}←{∆}dec keys
      :Access Public
       ∆←1{0=⎕NC ⍵:⍺  ⋄  ⎕OR ⍵}'∆'
       newval←(-∆) inc keys
      ∇

    ⍝ has_keys: Returns 1 for each key found in the dictionary
    ∇ old←has_keys keys
      :Access Public
      old←(≢keysF)>keysF⍳keys
    ∇

    ⍝ Del:  "Deletes key-value pairs from the dictionary by key, but only if all the keys exist"
    ⍝        If left arg is specified and 0, missing keys cause an error. Otherwise, they are ignored."
    ⍝ b ← {ignore←1} ⍵.del key1 key2...
    ⍝ Retursn bN=1 for each key kN deleted; else 0.
    ∇ {b}←{ignore}del keys;nf;old;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      keys←∪keys
      b←(≢keysF)>p←keysF⍳keys
      nf←0∊b
      :If nf
      :AndIf 0={⍵:0 ⋄ ignore}(900⌶)1
          eDeleteKeyMissing ⎕SIGNAL 11   ⍝ SIGNAL error if not all k-v pairs exist
      :EndIf
      :If 0≠≢b←b/p
          ∆←1⍴⍨≢keysF ⋄ ∆[b]←0
          _hashK keysF←∆/keysF ⋄ valuesF←∆/valuesF
      :EndIf
    ∇

    ⍝ DelByIndex | DI:    "Deletes key-value pairs from the dict. by index. Like Del"
    ⍝
    ⍝ b ← {ignore←1} ⍵.del_by_index ix1 ix2...
    ⍝ b ← (ignore←1} ⍵.di ix1 ix2...
    ⍝
    ∇ {b}←{ignore}di ix;keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      ignore←{⍵:0 ⋄ ignore}(900⌶)1
      ignore del_by_index ix
    ∇
    ∇ {b}←{ignore}del_by_index ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      ix←∪ix
   ⍝ (0(≢keysF)⍸ix) → 0 [in range 0..≢keysF-1], ¯1 or 1 [out of range]
      b←{⍵:0=0(≢keysF)⍸ix ⋄ 0}×≢keysF
      :If 0∊b                        ⍝ At least 1 missing key?
      :AndIf 0={⍵:0 ⋄ ignore}(900⌶)1 ⍝ And ignore=0
          eIndexRange ⎕SIGNAL 7
      :EndIf
      ix←b/ix                        ⍝ Keep those in range
      :If 0<≢ix                      ⍝ Delete keys marked for del'n
          ∆←(≢keysF)⍴1 ⋄ ∆[ix]←0     ⍝ Note their position in keysF
          _hashK keysF←∆/keysF ⋄ valuesF←∆/valuesF
      :EndIf
    ∇

    ⍝ clear:  "Clears the entire dictionary (i.e. deletes every key-value pair)
    ⍝          and returns the dictionary."
    ∇ {dict}←clear
      :Access Public
      keysF←valuesF←⍬                            ⍝ Rehash: See AutoKeyHashUpdateTrigger
      dict←⎕THIS
    ∇

    ⍝ oop:  "Removes and returns last <n> items (pairs) from dictionary as if a LIFO stack.
    ⍝        Efficiently updates keysF to preserve hash status."
    ⍝ kv1 kv2... ← ⍵.pop n   where n is a number between 0 and Len
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs
    ∇ {popped}←pop n;last;k;v
      :Access Public
      :If 0=n ⋄ popped←⍬ ⋄ :Return ⋄ :EndIf        ⍝ Pop 0 does nothing, returns ⍬
      last←-|n⌊≢keysF                               ⍝ Don't pop what isn't there...
      popped←↓⍉↑last↑¨keysF valuesF
      keysF↓⍨←last ⋄ valuesF↓⍨←last
    ∇

    ⍝ sort/sortA (ascending),
    ⍝ sortD (descending)
    ⍝ Descr:
    ⍝    "Sort a dictionary IN PLACE:
    ⍝     ∘ Sort keys in (Sort/A: ascending (D: descending) order;
    ⍝       - revised to use TAO (sorting anything).
    ⍝ Returns: the dict
    ⍝
    :Property sort,sortA,sortD
    :Access Public
        ∇ me←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If 1∊'dD'=¯1↑args.Name ⍝ SortD
              ix←⍒keysF
          :Else                ⍝ SortA, sort
              ix←⍋keysF
          :EndIf
          keysF←keysF[ix] ⋄ valuesF←valuesF[ix]
          _hashK me←⎕THIS
        ∇
    :EndProperty

    ⍝ GradeUp, GradeDown/GradeDn: Returns the indices of the keys in sorted order, either graded up or down.
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
    ∇ {h}←help
      :Access Public Shared
      ⍝ Pick up only ⍝H1 comments!
      h←'^\h*⍝H1(.*)$' ⎕S '\1'⊣⊃⎕NGET'pmsLibrary/docs/Dict.help'
      :Trap 1000
          ⎕ED'h'
      :EndTrap
    ∇
    _←⎕FX 'help'⎕R'Help'⊣⎕NR 'help'
    _←⎕FX 'help'⎕R'HELP'⊣⎕NR 'help'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ INTERNAL UTILITIES
    ⍝ ----------------------------------------------------------------------------------------

    ∇ {ignore}←_hashK ignore
    ⍝ Ignore right argument, while setting keysF to be hashed!
      :If (0=1(1500⌶)keysF)∧2≤≢keysF
          keysF←(1500⌶)keysF
      :EndIf
    ∇

    ∇ DEBUGset
      :Implements Trigger DEBUG
     ⍝ Dependents: TRAP_SIGNAL, ∆TRAP
      TRAP_SIGNAL←999×DEBUG≠0
      ∆TRAP←TRAP_SIGNAL'C' '⎕SIGNAL/⎕DMX.(EM EN)'  ⍝ Ditto

    ∇
:EndClass
:Class DefaultDictClass  : DictClass
    ⍝ require 'DictClass'

  ⍝ DefaultDict: Function to make class ref visible as <DefaultDict> if DefaultDict is in ⎕PATH
    ∇ ns←DefaultDict
      ns←⎕THIS
    ∇
    ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'DefaultDict'

 ⍝ General Local Names
    ClassNameStr←⍕⊃⊃⎕CLASS ⎕THIS

  ⍝ new0: "Constructs a default dictionary with default value 0
    ∇ new0
      :Implements Constructor
      :Access Public
      ⎕DF ClassNameStr,'[]'
      load 0
    ∇
  ⍝ new1 arg: "Constructs a default dictionary with default value arg
    ∇ new1 arg
      :Implements Constructor
      :Access Public
      ⎕TRAP←∆TRAP
      ⎕DF ClassNameStr,'[]'
      load⊂arg
    ∇
:EndClass
:Namespace TinyDictNs
⍝⍝⍝⍝⍝ See TinyDict below
  ⍝ A simple, namespace-based, dictionary. Fast, low overhead.
  ⍝ Uses Triggers to map local vars onto dictionary namespace and vice versa
  ⍝ See docs/TinyDict.help

  ⍝ TinyDict: Function to make namespace TinyDictNs ref visible as <TinyDict> if TinyDict is in ⎕PATH
    ∇ ns←TinyDict
      ns←⎕THIS
    ∇
    ##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'TinyDict'

    ∇ ns←new0
      ns←⎕NS ⎕THIS
      ns.⎕DF'TinyDict[]'
      ns.default←0   ⍝ zero
    ∇

    ∇ ns←{def}new entries
      ns←⎕THIS.new0
      :If 0≠⎕NC'def'
          ns.default←def
      :EndIf
      :If 0<≢entries   ⍝ If entries is ⍬ or '', same as new0
          ns.(Keys Vals)←{⍺←⍴⍴entries
              2≠⍺:↓⍉↑⍵    ⍝  ('one' 1)('two' 2) ('three' 3)
              1=⊃⍺:,⍵     ⍝  ⍪ ('one' 'two' 'three') (1 2 3)
              ↓⍵          ⍝  ↑('one' 'two')(1 2)
          }entries
      :EndIf
    ∇

    ⎕IO ⎕ML←0 1
    keysF valsF←⍬ ⍬
  ⍝ default: defined in new0 or new

  ⍝ Set "methods"  keys, vals, values for vars keysF valsF
    ∇ k←keys
      k←keysF
    ∇
    ∇ v←vals
      v←valsF
    ∇
    ∇ v←values
      v←valsF
    ∇

    ∇ r←get keys;e;ie;ine;p
      keys←,keys
      p←keysF⍳keys
      r←keys        ⍝ r will have the shape, but not content, of keys.
      :If 0≠≢ie←⍸e←p<≢keysF
          r[ie]←valsF[e/p]
      :EndIf
      :If 0≠≢ine←⍸~e
          :If 0≠⎕NC'default'
              r[ine]←⊂default
          :Else
              ⎕SIGNAL/('TinyDict: One or more keys is undefined')11
          :EndIf
      :EndIf
    ∇

    ∇ r←get1 key;p
      p←keysF⍳⊂key
      :If p≥≢keysF
          :If 0≠⎕NC'default'
              r←default
          :Else
              ⎕SIGNAL/('TinyDict: Key is undefined')11
          :EndIf
      :Else
          r←p⊃valsF
      :EndIf
    ∇

    ∇ {vals}←{keys}put vals;e;ePut1;ePut2;ie;kv;n;p
      ePUT1←'TinyDict/put (1adic): one or more key-value pairs required'
      ePUT2←'TinyDict/put (2adic): number of keys and values must match' 11
      :If 0=⎕NC'keys'    ⍝ monadic put:   put (k1 v1)(k2 v2)...
          kv←↓⍉↑vals
          :If 2≠≢kv ⋄ ⎕SIGNAL/ePUT1 ⋄ :EndIf
          keys vals←kv
      :ElseIf (≢keys)≠(≢vals)
          ⎕SIGNAL/ePUT2
      :EndIf
      keys vals←(,keys)(,vals)
      e←(≢keysF)>p←keysF⍳keys
      :If 0≠≢ie←⍸e    ⍝ Any existing keys?
          valsF[e/p]←e/vals
      :EndIf
      :If 1∊n←~e      ⍝ Any new keys?
        ⍝ If a key appears >1ce, use the LAST value for that key.
          p←(≢keys)-1+(⌽keys)⍳∪n/keys
          (keysF valsF),←(keys[p])(vals[p])
      :EndIf
    ∇

    ∇ {val}←{key}put1 val;p
    ⍝  put1 key val   OR    key put1 val
      :If 0=⎕NC'key'
          key val←val
      :EndIf
      p←keysF⍳⊂key
      :If p≥≢keysF
          keysF,←⊂key ⋄ valsF,←⊂val
      :Else
          (p⊃valsF)←val
      :EndIf
    ∇

    ∇ {b}←del1 key;p;q
      p←keysF⍳⊂key
      :If p≥≢keysF
          b←0   ⍝ Not deleted
      :Else
          b←1   ⍝ Deleted...
          q←1⍴⍨≢keysF ⋄ q[p]←0
          keysF valsF←(q/keysF)(q/valsF)
      :EndIf
    ∇

  ⍝ del: Inefficient (just haven't gotten around to it)
    ∇ {b}←del keys
      b←del1¨keys
    ∇

  ⍝ inc keys by 1 or <∆>, the increment amount
    ∇ {newval}←{∆} inc keys
       :IF 0=⎕NC '∆'  ⋄  ∆←1 ⋄  :EndIf
       :IF (∪≢keys)=≢keys
           newval←keys put ∆ + get keys
       :Else ⍝ duplicates- do 1 at a time
           newval←∆{⍵ put1 ⍺ + get1 ⍵}¨keys
       :Endif
    ∇

    ⍝ dec keys by 1 or <∆>, the decrement amount
    ∇ {newval}←{∆} dec keys
       :IF 0=⎕NC '∆' ⋄ ∆←1 ⋄ :EndIf
       newval←(-∆) inc keys
    ∇

    ∇ b←has_default
      b←0≠⎕NC'default'
    ∇

    ∇ r←table
      r←keysF,[0.5]valsF
    ∇

   ⍝ TinyDict.help/Help/HELP  - Display help documentation window.
    ∇ {h}←help;f;sel
      :Access Public Shared
    ⍝ Pick up ⍝H3 comments only as HELP...
      h←'^\s*⍝H3(.*)$'  ⎕S '\1'⊣⊃⎕NGET'pmsLibrary/docs/Dict.help'
      :Trap 1000
          ⎕ED'h'
      :EndTrap
    ∇
    _←⎕FX 'help'⎕R'Help'⊣⎕NR 'help'
    _←⎕FX 'help'⎕R'HELP'⊣⎕NR 'help'

:EndNamespace
