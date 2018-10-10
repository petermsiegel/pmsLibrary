:Class dict
⍝ dict: A fast, ordered, and simple dictionary for general use.
⍝ Hashes vector KEYS for efficiency on large dictionaries.
⍝ For HELP information, call 'dict.HELP'.
    ⍝ ⎕←'For dictionary HELP, call "dict.HELP".'
    ⎕IO ⎕ML←0 1  ⍝

  ⍝ Shared Fields
    :Field Public Shared DEBUG←0                  ⍝ See DEBUGset.
    :Field Public Shared TRAP_SIGNAL←DEBUG×999    ⍝ Ditto: Dependent on DEBUG
    :Field Public Shared ∆TRAP←TRAP_SIGNAL 'C' '⎕SIGNAL/⎕DMX.(EM EN)'  ⍝ Ditto

  ⍝ INSTANCE FIELDS and Related
    KEYS←⍬     ⍝ Variable, not Field, to avoid APL hashing bug
    :Field Private VALUES       ← ⍬
    :Field Private HASDEFAULT   ← 0
    :Field Private DEFAULT      ← ''    ⍝ Initial value

  ⍝ ERROR MESSAGES:
    eBadLoad←'dict initial or loaded data not key-value pairs, dictionary or default value.'
    eBadDefault←'dict/HasDefault: HasDefault must be set to 1 (true) or 0 (false).'
    eDeleteKeyMissing←'dict/Del: Attempt to delete non-existent keys with Ignore=0.'
    eIndexRange←'dict/DelByIndex: An index argument was not in range.'
    eKeyAlterAttempt←'dict/Keys: An entry''s key may not be altered.'
    eHasNoDefaultK←'dict[]: Value Error: Key does not exist.'
    eHasNoDefaultD←'dict[]: Value Error: HasDefault set to 0.'
    eQueryDontSet←'dict/QueryDefault may be queried, but not set directly.'

  ⍝ General Local Names
    ClassNameStr←⍕⊃⊃⎕CLASS ⎕THIS


    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Constructors...

    ⍝ New1: "Constructs a dictionary and loads*** with entries, defined either as individual key-value pairs,
    ⍝        or by name from existing dictionaries. Alternatively, sets the default value."
    ⍝ Uses Load/Import, which will handle duplicate keys (the last value quietly wins), and so on.
    ⍝ *** See Load for conventions for <initial>.
    ∇ New1 initial;⎕TRAP
      :Implements Constructor
      :Access Public
      ⎕TRAP←∆TRAP
      ⎕DF ClassNameStr,'[]'
      _Load initial
    ∇

    ⍝ New0: "Constructs a dictionary w/ no initial entries and no default value for missing keys."
    ∇ New0
      :Implements Constructor
      :Access Public
     ⎕DF ClassNameStr,'[]'
    ∇

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ General external utility function...
    ⍝ ∆DICT:  "Create a new dictionary."
    ⍝ Syntax:
    ⍝    dict←{default} ∇ initial
    ⍝    initial: (k1 v1)(k2 v2)...
    ⍝    default: If present, sets Default value for missing key.
    ∇ d←{default}∆DICT initial;Action;f;i;item;opt;⎕TRAP
      :Access Public Shared
      ⎕TRAP←⎕THIS.∆TRAP
      d←⎕NEW ⎕THIS initial
      :If ~(900⌶)0
          d.Default←default
      :EndIf
    ∇
     _←##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR '∆DICT'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ Instance Methods
    ⍝    (Methods of form Name; helper fns of form _Name)

    ⍝ GetVal: "Using standard vector selection and assignment, set and get key-value pairs. New entries are created automatically"
    ⍝ SETTING key-value pairs
    ⍝ dict[key1 key2...] ← val1 val2...
    ⍝
    ⍝ GETTING key-value pairs
    ⍝ val ← dict[key1 key2...]
    ⍝
    ⍝ As always, if there is only one pair to set or get, use ⊂, as in:
    ⍝        dict[⊂'unicorn'] ← ⊂'non-existent'
    :Property Default Keyed GetVal
    :Access Public
        ∇ vals←get args;err;_ix;found;keys;vals;⎕TRAP
          ⎕TRAP←∆TRAP
          p←KEYS⍳⊃args.Indexers
          found←(≢KEYS)>p
          :If ~0∊found
              vals←VALUES[p]
          :ElseIf HASDEFAULT
              vals←found\VALUES[found/p]
              ((~found)/vals)←⊂DEFAULT     ⍝ Add defaults
              vals←(⍴p)⍴vals               ⍝ If input parm is scalar, vals must be as well...
          :Else
              eHasNoDefaultK ⎕SIGNAL 11
          :EndIf
        ∇
        ∇ set args;keys;vals;⎕TRAP
          keys←⊃args.Indexers ⋄ vals←args.NewValue
          ⎕TRAP←∆TRAP
          _Import keys vals
        ∇
    :EndProperty


    ⍝ Load ⍵: Load data into dictionary and/or set default for values of missing keys.
    ⍝        "Accept either SCALAR or VECTOR right argument.
    ⍝         SCALAR or 1-ITEM VECTOR that is not a Class Instance (⎕NC≠9.2)
    ⍝            dictionary is null with Default←⊃⍵ and HasDefault←1.
    ⍝            E.g. Load 1:   Default←1
    ⍝                 Load ⊂'': Default←''
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
    ⍝ _Load: "Utility to be called from top-level routines."
    ⍝
    ∇ {me}←Load initial;⎕TRAP
      :Access Public
      me←⎕THIS ⋄ ⎕TRAP←∆TRAP
      _Load initial
    ∇
    ∇ _Load items;keys;vals;item         ⍝ Syntax                          Action
      :If 0=≢items                       ⍝ ∇ '' or ∇ ⍬                     SD (Set Default)
          DEFAULT HASDEFAULT←items 1
      :ElseIf 1=≢items                   ⍝ ∇ 1 or ∇ (⊂'') or ∇ ⎕NULL etc.  SD
      :AndIf 9.2≠⎕NC⊂'item'⊣item←⍬⍴items ⍝ ∇ dict1
          DEFAULT HASDEFAULT←item 1
      :ElseIf 2=⍴⍴items                  ⍝ ∇ ⍪keyVec valVec [Default]      (2=⍴) Import
          :If 3=⍴items←,items            ⍝                                 (3=⍴) Import + SD
              DEFAULT HASDEFAULT∘←(2⊃items)1
          :EndIf
          _Import 2↑items
      :ElseIf 2∧.=≢¨items                ⍝ ∇ (k1 v1)(k2 v2) etc.           Import
          _Import↓⍉↑items
      :Else                              ⍝ ((k1 v1)(k2 v2)*                Load
          keys←vals←⍬                    ⍝  | (d1)(d2)* | (⊂default))+
          {
              2<≢⍵:eBadLoad ⎕SIGNAL 11
              2=≢⍵:(keys vals),←⊂¨⍵      ⍝ (k1 v1)                         Load k-v pair
              item←⍵
              9.2=⎕NC⊂'item'⊣item:(keys vals),←⍵.Export   ⍝ dict1          Import Dictionary
              DEFAULT HASDEFAULT∘←(⊃⍵)1  ⍝ Default←⊃⍵                      SD
          }¨⊆items
          _Import keys vals
      :EndIf
    ∇

    ⍝ Import: "Enters keys and values separately into a dictionary.
    ⍝          Import (keys values)."
    ⍝
    ⍝ _Import: "Utility to be called from top-level routines.
    ⍝           _Import  keys values."
    ⍝
    ∇ {me}←Import(keys vals);⎕TRAP
      :Access Public
      me←⎕THIS ⋄ ⎕TRAP←∆TRAP
      _Import keys vals
    ∇

    ⍝ ignore←_Import keyVec valVec
    ⍝ Updates instance vars KEYS VALUES, then calls _hashK to be sure hashing enabled.
      _Import←{
          k v←⍵                  ⍝ 0.  k, v: k may have old and new keys, some duplicated.
          ∆←(≢KEYS)>p←KEYS⍳k     ⍝ I.  Find old keys
          VALUES[∆/p]←∆/v        ⍝     Update old keys in place w/ new vals; duplicates? Keep last new val.
          ~0∊∆:_←⍬               ⍝     All old? Return
          k v←(⊂~∆)/¨k v         ⍝ II. Update NEW k-v pairs
          v[k⍳k]←v               ⍝     Accept last new duplicate, by copying its value onto first
          ∆←(k⍳k)=⍳≢k            ⍝     Note duplicates
          KEYS,←(∆/k)            ⍝     ...remove duplicates (keep first for each key)
          VALUES,←(∆/v)          ⍝     ...and update KEYS and VALUES
          1:_←_hashK 0       ⍝     Return.
      }

    ⍝ Copy:  "Creates a copy of an object including its current settings (by copying fields).
    ∇ new←Copy
      :Access Public
      new←⎕NEW⊃⎕CLASS ⎕THIS
      new._Copy(KEYS VALUES HASDEFAULT DEFAULT)
    ∇
    ⍝ _Copy-- internal fast copying method.
    ∇ {me}←_Copy(keys vals hasdefault default)
      :Access Private
      me←⎕THIS
      (KEYS VALUES HASDEFAULT DEFAULT)←keys vals hasdefault default
    ∇

    ⍝ Export: "Returns a list of Keys and Values for the object in an efficient way."
    ∇ (k v)←Export
      :Access Public
      k v←KEYS VALUES
    ∇

    ⍝ Table: "Returns all the key-value pairs as a matrix, one pair per row.
    ⍝         Equivalent to ↑⍵.Items."
    ∇ r←Table
      :Access Public
      :If 0=≢KEYS ⋄ r←⍬
      :Else ⋄ r←⍉↑KEYS VALUES
      :EndIf
    ∇

    ⍝ Items/Pairs: "Returns ALL key-value pairs as a vector, one vector element per pair"
    :Property Items,Pairs
    :Access Public
        ∇ r←get args
          :If 0=≢KEYS ⋄ r←⍬
          :Else ⋄ r←↓⍉↑KEYS VALUES
          :EndIf
        ∇
    :EndProperty

    ⍝ Iota ⍵: "Returns the indices (⎕IO=0) of each key specified in ⍵ (returns (Len) for missing values).
    ⍝          The order is the same as used in ⍺.Keys and ⍺.Vals
    ⍝          Same as (⍵.Keys⍳keys) but much faster."
    ∇ ix←Iota keys
      :Access Public
      ix←KEYS⍳keys
    ∇


    ⍝ Len:  "Returns the number of key-value pairs"
    ⍝ Length,Size,Shape,Tally: aliases of Len
    :Property Len,Length,Size,Shape,Tally
    :Access Public
        ∇ r←get args
          r←≢KEYS
        ∇
    :EndProperty

    ⍝ Keys|Key:  "Get Keys by Index."
    ⍝     "For efficiency, returns the KEYS vector, rather than one index element
    ⍝      at a time. Keys may be retrieved, but not set.
    ⍝      In contrast, Values/Vals works element by element to allow direct updates (q.v.)."
    ⍝ k ← Keys              returns all Keys in entry order
    ⍝ k ← Keys[ix1 ix2...]  returns zero or more keys by index (user origin).
    ⍝ :Property Numbered Keys,Key  ⍝ Keys by Index
    :Property Keys
    :Access Public
        ⍝ get: retrieves Keys
        ∇ keys←get args;cur;err;ix;keys;vals
          keys←KEYS
⍝          ix←⊃args.Indexers
⍝          keys←KEYS[ix]    ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ∇ set args
          eKeyAlterAttempt ⎕SIGNAL 11
        ∇
⍝        ∇ r←shape
⍝          r←≢KEYS
⍝        ∇
    :EndProperty

    ⍝ Values|Vals|Value|Val:
    ⍝   "Get or Set Values by Key Index, in creation order or, if sorted, sort order.
    ⍝    Indicates are in ⎕IO=0 ONLY"
    ⍝
    :Property Numbered Values,Vals,Value,Val  ⍝ Vi = keys by index
    :Access Public
        ⍝ get: retrieves Values, not KEYS
        ∇ vals←get args;ix;vals
          ix←⊃args.Indexers
          vals←VALUES[ix]     ⍝ Always scalar-- APL handles ok even if 1-elem vector
        ∇
        ⍝ set: sets Values, not KEYS
        ∇ set args;newvals;ix
          ix←⊃args.Indexers
          newvals←args.NewValue
          VALUES[ix]←newvals
        ∇
        ∇ r←shape
          r←Len
        ∇
    :EndProperty

    ⍝ HasDefault, Default, QueryDefault
    ⍝    "Sets or queries a default value for missing keys. Th
    ⍝     By default, HasDefault=0, so the initial Default ('') or previously set Default is ignored,
    ⍝     i.e. a VALUE ERROR is signalled. Setting HasDefault←1 will make the current Default available.
    ⍝     Setting Default to a new value always turns on HasDefault as well."
    ⍝                SETTING    GETTING
    ⍝ HasDefault        Y          Y
    ⍝ Default           Y          Y
    ⍝ QueryDefault      N          Y
    ⍝
    ⍝ HasDefault:    "Sets the dictionary property ON (1) or OFF (0). If ON, activates current Default value.
    ⍝                 Alternatively, retrieves the current status (1 or 0)."
    ⍝ Default:       "Sets the default value for use when retrieving missing values, setting HasDefault←1.
    ⍝                 Alternatively, retrieves the current default."
    ⍝ QueryDefault:  "Combines HasDefault and Default in a single command, returning the current settings from
    ⍝                     HasDefault and Default
    ⍝                 as a single pair. QueryDefault may ONLY be queried, not set."
    ⍝ The default may have any datatype and shape.
    :Property HasDefault,QueryDefault,Default
    :Access Public
        ∇ r←get args
          :Select args.Name
          :Case 'Default'
              :If ~HasDefault ⋄ eHasNoDefaultD ⎕SIGNAL 11 ⋄ :EndIf
              r←DEFAULT
          :Case 'HasDefault'
              r←HASDEFAULT
          :Case 'QueryDefault'
              r←HASDEFAULT(DEFAULT)
          :EndSelect
        ∇
        ∇ set args
          :Select args.Name
          :Case 'Default'
              DEFAULT HASDEFAULT←args.NewValue 1
          :Case 'HasDefault'
              :If ~0 1∊⍨⊂args.NewValue
                  eBadDefault ⎕SIGNAL 11
              :EndIf
              HASDEFAULT←⍬⍴args.NewValue   ⍝ DEFAULT unchanged...
          :Case 'QueryDefault'
              eQueryDontSet ⎕SIGNAL 11
          :EndSelect
        ∇
    :EndProperty

    ⍝ HasKeys: Returns 1 for each key found in the dictionary
    ∇ old←HasKeys keys
      :Access Public
      old←(≢KEYS)>KEYS⍳keys
    ∇

    ⍝ Del:  "Deletes key-value pairs from the dictionary by key, but only if all the keys exist"
    ⍝        If left arg is specified and 0, missing keys cause an error. Otherwise, they are ignored."
    ⍝ b ← {ignore←1} ⍵.Del key1 key2...
    ⍝ Retursn bN=1 for each key kN deleted; else 0.
    ∇ {b}←{ignore}Del keys;nf;old;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      keys←∪keys
      b←(≢KEYS)>p←KEYS⍳keys
      nf←0∊b
      :If nf
      :AndIf 0={⍵:0 ⋄ ignore}(900⌶)1
          eDeleteKeyMissing ⎕SIGNAL 11   ⍝ SIGNAL error if not all k-v pairs exist
      :EndIf
      :If 0≠≢b←b/p
          ∆←1⍴⍨≢KEYS ⋄ ∆[b]←0
          _hashK KEYS←∆/KEYS ⋄ VALUES←∆/VALUES
      :EndIf
    ∇

    ⍝ DelByIndex | DI:    "Deletes key-value pairs from the dict. by index. Like Del"
    ⍝
    ⍝ b ← {ignore←1} ⍵.DelByIndex ix1 ix2...
    ⍝ b ← (ignore←1} ⍵.DI ix1 ix2...
    ⍝
    ∇ {b}←{ignore}DI ix;keys;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      ignore←{⍵:0 ⋄ ignore}(900⌶)1
      keys←ignore DelByIndex ix
    ∇
    ∇ {b}←{ignore}DelByIndex ix;∆;⎕TRAP
      :Access Public
      ⎕TRAP←∆TRAP
      ix←∪ix
   ⍝ (0(≢KEYS)⍸ix) → 0 [in range 0..≢KEYS-1], ¯1 or 1 [out of range]
      b←{⍵:0=0(≢KEYS)⍸ix ⋄ 0}×≢KEYS
      :If 0∊b             ⍝ At least 1 missing key?
      :AndIf 0={⍵:0 ⋄ ignore}(900⌶)1  ⍝ And ignore=0
          eIndexRange ⎕SIGNAL 7
      :EndIf
      ix←b/ix             ⍝ Keep those in range
      keys←KEYS[ix]             ⍝ Remember keys being deleted
      :If 0<≢ix                 ⍝ At least one...
          ∆←(≢KEYS)⍴1 ⋄ ∆[ix]←0 ⍝ Note their position in KEYS
          _hashK KEYS←∆/KEYS ⋄ VALUES←∆/VALUES
      :EndIf
    ∇

    ⍝ Clear:  "Clears the entire dictionary (i.e. deletes every key-value pair)
    ⍝          and returns the dictionary."
    ∇ {dict}←Clear
      :Access Public
      KEYS←VALUES←⍬                            ⍝ Rehash: See AutoKeyHashUpdateTrigger
      dict←⎕THIS
    ∇

    ⍝ Pop:  "Removes and returns last <n> items (pairs) from dictionary as if a LIFO stack.
    ⍝        Efficiently updates KEYS to preserve hash status."
    ⍝ kv1 kv2... ← ⍵.Pop n   where n is a number between 0 and Len
    ⍝
    ⍝ Use dict[k1 k2]←val1 val2 to Push N*E*W items onto the dictionary "LIFO" stack.
    ⍝ Remove n items from the END of the table (most recent items)
    ⍝ Return pairs popped as a (shy) vector of key-value pairs
    ∇ {popped}←Pop n;last;k;v
      :Access Public
      :If 0=n ⋄ popped←⍬ ⋄ :Return ⋄ :EndIf        ⍝ Pop 0 does nothing, returns ⍬
      last←-|n⌊≢KEYS                               ⍝ Don't pop what isn't there...
      popped←↓⍉↑last↑¨KEYS VALUES
      KEYS↓⍨←last ⋄ VALUES↓⍨←last
    ∇

    ⍝ Sort/SortA (ascending), SortD (descending)
    ⍝ Descr:
    ⍝    "Sort a dictionary IN PLACE:
    ⍝     ∘ Sort keys in (Sort/A: ascending (D: descending) order;
    ⍝       - revised to use TAO (sorting anything).
    ⍝ Returns: the dict
    ⍝
    :Property Sort,SortA,SortD
    :Access Public
        ∇ me←get args;ix;⎕TRAP
          ⎕TRAP←∆TRAP
          :If args.Name≢'SortD' ⍝ Sort, SortA
              ix←⍋KEYS
          :Else                 ⍝ SortD
              ix←⍒KEYS
          :EndIf
          KEYS←KEYS[ix] ⋄ VALUES←VALUES[ix]
          _hashK me←⎕THIS
        ∇
    :EndProperty

    ⍝ GradeUp, GradeDown/GradeDn: Returns the indices of the keys in sorted order, either graded up or down.
    ⍝ Note: Doesn't reorder the dictionary, returns indices reordered..
    :Property GradeUp,GradeDown,GradeDn
    :Access Public
        ∇ ix←get args;⎕TRAP
          ⎕TRAP←∆TRAP
          :If args.Name≡'GradeUp'
              ix←⍋KEYS
          :Else  ⍝ GradeDown, GradeDn
              ix←⍒KEYS
          :EndIf
        ∇
    :EndProperty

  ⍝ Dict.HELP  - Display Help documentation window.
    ∇ {h}←HELP
      :Access Public Shared
      h←{3↓¨⍵/⍨(⊂'⍝H')≡¨2↑¨⍵}⎕SRC ⎕THIS
      :Trap 1000
          ⎕ED'h'
      :EndTrap
    ∇
    _←⎕FX 'HELP'⎕R'Help'⊣⎕NR 'HELP'
    _←⎕FX 'HELP'⎕R'help'⊣⎕NR 'HELP'

    ⍝-------------------------------------------------------------------------------------------
    ⍝-------------------------------------------------------------------------------------------
    ⍝ ----------------------------------------------------------------------------------------
    ⍝ INTERNAL UTILITIES
    ⍝ ----------------------------------------------------------------------------------------

    ∇ {ignore}←_hashK ignore
    ⍝ Ignore right argument, while setting KEYS to be hashed!
      :If (0=1(1500⌶)KEYS)∧2≤≢KEYS
          KEYS←(1500⌶)KEYS
      :EndIf
    ∇

    ∇ DEBUGset
      :Implements Trigger DEBUG
     ⍝ Dependents: TRAP_SIGNAL, ∆TRAP
      TRAP_SIGNAL←999×DEBUG≠0
      ∆TRAP←TRAP_SIGNAL'C' '⎕SIGNAL/⎕DMX.(EM EN)'  ⍝ Ditto
     
    ∇



⍝H +--------------------+
⍝H |  Dict HELP         |
⍝H +---------------------
⍝H  A fast, streamlined Ordered Dictionary (Hash Table)
⍝H     Items are stored in the order created; the dictionary order is maintained, even when a value is changed.
⍝H     (Items may be moved by sorting or by deleting and re-entering.)
⍝H  KEYS and VALUES
⍝H     Keys may be of any type and shape. Case is always respected.
⍝H  ⍵.Default, ⍵.HasDefault
⍝H     If ⍵.HasDefault←1 (default is 0), then
⍝H     ⍵.Default will be returned as the value when missing keys are requested.
⍝H     Initially, ⍵.Default←'' but ⍵.HasDefault←0, so missing keys trigger a VALUE ERROR.
⍝H     If ⍵.HasDefault←1, then the current ⍵.Default is used.
⍝H
⍝H Syntax:    ⍺ ← ⎕NEW dict specs
⍝H            specs: [[ Format I | Format II | Format III | Format IV ]]
⍝H                I:   [k v | dict | ⊂default)]+
⍝H                II:  (⊂default)                    ⍝ For simple scalar, same as ⊂default
⍝H                III: n×1 Matrix:   ⍪keyVec valVec [default]
⍝H                IV:  0-length Vec: '' or ⍬
⍝H
⍝H     Format I: list of  [k v  |  dict  |  ⊂default]
⍝H           k v:      key-value pair of the form (k1 v1)
⍝H           dict:     an existing dictionary returned from ⎕NEW dict.
⍝H           default:  If a scalar value ⍵1 is detected and it's not a dictionary.
⍝H                     ⊃⍵ will be the default value returned for keys which are not in the dict.
⍝H                     E.g. to enter items or dictionaries AND a default:
⍝H                     for Default←'':     ⎕New dict ((⊂'')(key1 val1)(key2 val2)...)
⍝H                     for Default←⎕NULL:  ⎕NEW dict (⎕NULL(key1 val1)(key2 val2)...)
⍝H     Format II: Enclosed or simple scalar
⍝H         general ⍵:  Initialize empty dictionary with Default←⊃⍵
⍝H           1:            "        "       "        "  Default←1  (numeric 1)
⍝H           0:            "        "       "        "  Default←0  (numeric 0)
⍝H           ⎕NULL:        "        "       "        "  Default←⎕NULL
⍝H     Format III: Matrix of shape 2 1 or 3 1
⍝H           ⍪keys vals [default]:
⍝H                     First row is ⊂keys, 2nd row is ⊂values, third is the default (if present).
⍝H                     ⎕NEW dict (⍪keys vals)  ←-→   ⎕NEW dict (↓⍉↑keys vals)
⍝H     Format IV: 0-length Vector arg
⍝H           '' or ⍬   Initialize empty dictionary with Default←'' or Default←⍬
⍝H
⍝H  ┌────────────────────────────────────────────┐─────────────────────────────────────────────┐
⍝H  |a ← ⎕NEW dict                               │ Create empty dict, no default               │
⍝H  │a ← ⎕NEW dict (1  | 0)                      │ Create empty dict, default: 1               │
⍝H  |a ← ⎕NEW dict ('' | ⍬)                      │ Create empty dict, default '' or ⍬          │
⍝H  │a ← ⎕NEW dict (⊂default)                    │ Create empty dict, default (default)        │
⍝H  │a ← ⎕NEW dict ((k,v)(k,v))                  │ Create dict with k v pairs, no def          │
⍝H  │a ← ⎕NEW dict ⍪(k1 k2..)(v1 v2..) [default] │ Create dict with keys vals and def          │
⍝H  │a ← ⎕NEW dict (d1,d2)                       │ Create dict from dicts d1 d2                │
⍝H  │a ← ⎕NEW dict ((k,v)d1(k,v)d2)              │ Create dict from mix of k v pairs and dicts │
⍝H  └────────────────────────────────────────────┘─────────────────────────────────────────────│
⍝H
⍝H  ∆DICT -- Ordered Dictionary Helper Function
⍝H     Provides simple function (visible in ⎕PATH) for creating new dictionaries
⍝H     with optional defaults for null values.
⍝H  Syntax:   a ← {default} ∆DICT specs (same format for specs as for ⎕NEW)
⍝H  ┌─────────────────────────────────────────────┐─────────────────────────────────────────────┐
⍝H  │    a ← ∆DICT  1                             │ Create empty dict, default: 1               │
⍝H  │or  a← 1 ∆DICT ⍬                             │ Create empty dict, default: 1               │
⍝H  |    a ← ∆DICT  ('' | ⍬)                      │ Create empty dict, default '' or ⍬          │
⍝H  │    a ← ∆DICT     (⊂default)                 │ Create empty dict, default (default)        │
⍝H  │    a ← ∆DICT     ((k,v)(k,v))               │ Create dict with k v pairs, no def          │
⍝H  │    a ← default ∆DICT  ⍪(k1 k2..)(v1 v2..)   │ Create dict with keys vals and def          │
⍝H  |or  a ← ∆DICT ⍪(k1 k2..)(v1 v2..)(⊂default)  │ Create empty dict, default '' or ⍬          │
⍝H  │    a ← ∆DICT     (d1,d2)                    │ Create dict from dicts d1 d2                │
⍝H  │    a ← ∆DICT     ((k,v)d1(k,v)d2)           │ Create dict from mix of k v pairs and dicts │
⍝H  └─────────────────────────────────────────────┘─────────────────────────────────────────────│

⍝H  Ordered Dictionary Creation
⍝H   ∘ Create empty
⍝H     a ← ⎕NEW dict                              ⍝ Empty dictionary
⍝H   ∘ Create and Insert key-value pairs
⍝H     a ← ⎕NEW dict ((key1 val1)(key2 val2)...)  ⍝ With items, i.e. key-value pairs
⍝H   ∘ Create empty with default value
⍝H     a ← ⎕NEW dict (⊂default)                   ⍝ Argument passed must be scalar, which will be disclosed.
⍝H   ∘ If b is an existing dict, then:
⍝H       a ← ⎕NEW dict (b)
⍝H     copies b's values into a.
⍝H     - Attributes are NOT copied via ⎕NEW.
⍝H     - To copy all keys, values, and default: Use a←b.Copy
⍝H   ∘ Pairs and dictionaries may be assigned to a new dictionary on creation:
⍝H       c←  ⎕NEW dict (a (key1 val1) (key2 val2) b)
⍝H     Elements are assigned IN ORDER, left to right, with the last value "sticking."
⍝H     Here, c is made up of the contents of dictionary a, two key-value pairs, and b.
⍝H   ∘ To make a copy, called a, of a dictionary b, including its Defaults, use Copy:
⍝H       a ← b.Copy
⍝H
⍝H  Utility Function
⍝H   ∆DICT:  "Create a new dictionary."
⍝H           ⍺ [optional]    Default Value (none, if omitted).
⍝H           ⍵:              Dictionary entries. Follows ⎕NEW dict syntax.
⍝H   E.g. Create a new dictionary, setting the default to '', and specifying values for a list of items:
⍝H       b ← '' ∆DICT ('John' 'Jones')('Mary' 'Smith')('Fred' 'Flintstone')
⍝H   E.g. Create a new dictionary from list of Keys and Values
⍝H       c ←    ∆DICT ⍪Keys Values         ⍝ Note ⍪ to signal Import (KeyVec ValVec) approach.
⍝H   E.g. Create a new dictionary and Import Key and Value from vectors K V (not by pairs):
⍝H       a ← (∆DICT ⎕NULL).Import K V
⍝H
⍝H  ┌─────────────────────────────┐
⍝H  | a.Default←val   [*]         │
⍝H  │ w←a.Default                 │
⍝H  │ w←a.HasDefault              │
⍝H  │ a.HasDefault←b              │
⍝H  │ hasdef def←a.QueryDefault   │
⍝H  │ ————————————————            │
⍝H  │ * See ⎕NEW dict             │
⍝H  └─────────────────────────────┘
⍝H  Manage Default Values
⍝H   ∘ At initialization, unless a (dictionary-wide) default has been set,
⍝H     a VALUE ERROR results from trying to retrieve a value for a missing key.
⍝H       a←⎕NEW dict
⍝H       a[10]
⍝H     VALUE ERROR
⍝H     This even occurs when retrieving values from a mix of present and missing keys.
⍝H   ∘ The default may be set to any scalar or vector value. When you set it, HasDefault←1 for you.
⍝H     (If you then set HasDefault←0, the Default value is "hidden" until HasDefault←1 again).
⍝H     ⍺.Default←⍵
⍝H     Example:
⍝H       a←⎕NEW dict ⋄ a.Default←1 3
⍝H       a[10]
⍝H     1 3
⍝H   ∘ Check defaults
⍝H     def←⍺.Default
⍝H   ∘ Check whether a default exists
⍝H     bool←⍺.HasDefault
⍝H   ∘ Turn on the default (If turned on and Default hasn't been set, it's set to Default←'').
⍝H      ⍺.HasDefault←bool
⍝H   ∘ Query current HasDefault flag and default (⎕NULL if not set):
⍝H     hasdef def←⍺.QueryDefault
⍝H  The default may also be set in the ⎕NEW call if there is an argument of this form:
⍝H   ∘ scalar
⍝H   ∘ non-dictionary (not of nameclass 9.2, or if 9.2 doesn't have method isDict or if it does, isDict returns 0).
⍝H
⍝H  ┌────────────────────────────────────────┐
⍝H  | a[k1 k2]←v1 v2                         │
⍝H  │ v1 v2←a[k1 k2]                         │
⍝H  │ a.Vals[i1 i2]←v1 v2                    │
⍝H  │ a.Values[i1 i2]←v1 v2                  │
⍝H  │ k1 k2←a.Keys[i1 i2]                    │
⍝H  │ a.Import keys vals                     │
⍝H  │ keys vals←a.Export                     │
⍝H  │ i1 i2←a.Iota k1 k2   ⍝ a.Keys ⍳ k1 k2  │
⍝H  └────────────────────────────────────────┘
⍝H  Setting keys and values
⍝H     ⍺[k1 k2...]←v1 v2...
⍝H  Retrieving values by key
⍝H     v1 v2...←a[k1 k2...]
⍝H  Setting values by index (indices must exist)
⍝H     ⍺.Values[i1 i2...]←v1 v2...
⍝H     ⍺.Vals[i1 i2...]  ←v1 v2
⍝H  Retrieving values by index (indices must exist)
⍝H     ⍺.Values[i1 i2...]
⍝H     ⍺.Vals[i1 i2...]
⍝H  Retrieve all values
⍝H     ⍺.Values
⍝H     ⍺.Vals
⍝H  Setting Keys by Index
⍝H     **NOT ALLOWED**
⍝H  Retrieving Keys by Index
⍝H      k1 k2...←⍺.Keys[i1 i2...]
⍝H  Retrieving all Keys (in index order, by default the order entered)
⍝H      k1 k2...←⍺.Keys
⍝H  Importing keys and values en masse from vectors keys vals
⍝H      ⍺.Import keys vals
⍝H      Equivalent to: ⍺[keys]←vals   ⍝ But faster!
⍝H      Note: if a key exists, its value is updated in its original order.
⍝H  Exporting keys and values en masse as vectors keys vals
⍝H      keys vals ← ⍺.Export
⍝H      Equivalent to:  keys vals← ⍺.(Keys Vals) ⍝ But faster!
⍝H  Finding index of each key (like ⍳) (or Len if not found)
⍝H      i1 i2... ← a.Iota k1 k2
⍝H      Equiv. to a.Keys ⍳ key1 key2   ⍝ But much faster!
⍝H
⍝H  ┌────────────────────────────────────────┐
⍝H  | uk1 uk2←a.Del k1 k2                    │
⍝H  │ uk1 uk2←(ignore←1) a.Del k1 k2         │
⍝H  │ uk1 uk2←a.DelByIndex i1 i2             │
⍝H  │ uk1 uk2←(ignore←1) a.DelByIndex i1 i2  │
⍝H  │ uk1 uk2←a.DI i1 i2                     │
⍝H  │ a←a.Clear          ⍝ Returns a         │
⍝H  └────────────────────────────────────────┘
⍝H  Delete key-value pairs by key (returns the unique keys deleted)
⍝H  By default, all keys must exist. If left arg is 1, non-existent keys are quietly ignored.
⍝H  Returns unique keys deleted.
⍝H      uk1 uk2...← [[1|0]] ⍺.Del k1 k2...
⍝H  Delete key-value pairs by index (returns the unique keys deleted)
⍝H  ∘ All indices must be valid.
⍝H      uk1 uk2...← ⍺.DelByIndex i1 i2...
⍝H      uk1 uk2...← ⍺.DI i1 i2
⍝H  ∘ Invalid indices to be ignored.
⍝H      uk1 uk2...← 1 ⍺.DelByIndex i1 i2...
⍝H      uk1 uk2...← 1 ⍺.DI i1 i2
⍝H
⍝H  ┌───────────────────────────────────────────┐
⍝H  | b1 b2←a.HasKeys k1 k2                     │
⍝H  │ k1v1 k2v2←a.Items                         │
⍝H  │ k1v1 k2v2←a.Pairs                         │
⍝H  │ kv_Mx←a.Table                             │
⍝H  │ nitems←a.Len(gth)                         │
⍝H  └───────────────────────────────────────────┘
⍝H  Query if a key-value pair exists, by key. Returns 1 for each pair that exists...
⍝H      b1 b2...← ⍺.HasKeys k1 k2...
⍝H  Get all key value pairs
⍝H       k1v1 k2v2...←⍺.Items
⍝H       k1v1 k2v2...←⍺.Pairs
⍝H  Get all key value pairs as a matrix
⍝H      key_value_matrix←⍺.Table
⍝H  Get # of items in a dictionary
⍝H      ⍺.Len
⍝H      ⍺.Length
⍝H
⍝H  ┌────────────────────────────────────────┐
⍝H  | k1v1 k2v2←a.Pop 2                      │
⍝H  │ a['penult' 'ult']←v1 v2   ⍝ Push       │
⍝H  │ {}a.Sort/A      ⍝ Sort up in place     │
⍝H  │ {}a.SortD       ⍝ Sort dn in place     │
⍝H  │ ix←a.GradeUp    ⍝ Return indices       │
⍝H  │ ix←a.GradeDown/GradeDn                 │
⍝H  └────────────────────────────────────────┘
⍝H  Popping the first <n> items from the Ordered Dictionary
⍝H       k1v1...knvn ← ⍺.Pop count
⍝H  Removes and returns the LAST <count> entries from the dictionary (in order of creation, not update).
⍝H  Note 0: The value is returned shyly.
⍝H  Note 1: This uses the efficient idiom for removing items from hashed vectors: item↓⍨←-count
⍝H  Note 2: to "Push" items onto the end of the dictionary, simply add them, ONLY if the key is new.
⍝H      a['2nd to last' 'last'] ← 'val1' 'val2'
⍝H      a.Pop 2
⍝H  ┌───────────┬────┐
⍝H  |2nd to last│val1│
⍝H  ├───────────┼────┤
⍝H  │last       │val2│
⍝H  └───────────┴────┘
⍝H  If keys aren't new, you can delete them first and readd, so they are added at the end.
⍝H  This guarantees that a possibly new <key> is the most recent (first Pop'd) item in dictionary.
⍝H     1 a.Del ⊂'test' ⋄ a[⊂'test']←⊂'THIS IS A TEST!'
⍝H     ⎕←a.Pop 1
⍝H  test   THIS IS A TEST!
⍝H
⍝H  Sorts items in ascending (Sort/SortA) or descending (SortD) order IN PLACE.
⍝H  Uses Dyalog total array ordering.
⍝H  Returns the dictionary itself (not a copy!). Use {} to suppress returned dictionary.
⍝H     {}⍺.Sort  or  {}⍺.SortA
⍝H     {}⍺.SortD
⍝H  Return the indices for the dictionary's keys in sorted order
⍝H     ix←a.GradeUp   (ascending)
⍝H     ix←a.GradeDown (descending)
⍝H     ix←a.GradeDn   (descending)
:EndClass
