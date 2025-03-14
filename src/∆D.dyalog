:Namespace ⍙D
⍝ ∆D, ∆DL - Create and Manage an Ordered, Hashed Dictionary from 
⍝           (∆D) key-value pairs or (∆DL) a key list-value list.
⍝ *** Help info is contained throughout Class Dict (below)
⍝ *** on lines prefixed with ⍝H (⍝H=, ⍝Hf, etc. are special help codes).
⍝ *** NOTE: Changing ANY OF THESE LINES will affect ∆D'help',∆DL'help' and 
⍝ ***       the d.Help method (see below).
⍝ *** See :Section Help Information 
⍝ *** For help info, execute:  ∆D⍨'help'
  ⎕IO ⎕ML←0 1  
⍝ Traps 
  ⍙T2← { ⍺←'' ⋄ ⊂⎕DMX.('EN' 'Message' 'EM',⍥⊂¨ EN Message,⊂ '^(∆D\w? )?'⎕R('∆D',⍺,' ')⊢EM)} 
  Trap← ⎕SIGNAL ⍙T2

⍝ Create fns pointing to ⎕THIS ns.
  ⍙CR← ⍎'mê' '"' ⎕R (⍕⎕THIS)''''           ⍝ Internal Utility...

⍝ ##.∆D: Creat dictionary <dict> from items (key-value pairs: (k1 v1)(k2 v2)…)   
⍝ dict← [default] ∇ items   |   dict← [default] ∇ (↑keyList) valueList
⍝ Create path-accessible version in ##
  ##.∆D← ⍙CR '{⍺←⊢⋄0::mê.Trap⍬⋄1:_←⍺mê.∆D⍵}'
  ∆D←{ 
    dFlag← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 'help'≡⎕C⍵: _← Help     
    ⎕NEW Dict (⍵ ⍺ dFlag Dict.AUTOHASH)           
  }
  
⍝ ##.∆DL: Create dict from two lists: <keylist> and <valuelist>
⍝          or from a list and a scalar: <keylist> <scalar_value>
⍝ dict← [default] ∇ keylist [valuelist | scalar_value]
⍝ Create path-accessible version in ##
  ##.∆DL← ⍙CR '{⍺←⊢⋄0::"L"mê.Trap⍬⋄1:_←⍺mê.∆DL⍵}' 
  ∆DL←{  
      dFlag← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 'help'≡⎕C⍵: _← Help     
      kkvv← ⍵ (⍬ ⍬)⊃⍨ 0=≢⍵
    2=≢kkvv:  ⎕NEW Dict (kkvv, ⍺ dFlag Dict.AUTOHASH)  
      ⎕SIGNAL ⊂'EN' 'Message',⍥⊂¨ Dict.error.badKVLists            
  }

⍝ ##.∆DV: Create a dictionary from keys and values, where each key is a simple char vector.
⍝         Both (a) keylist-valuelist arrays and (b) key-value pairs are allowed, with the syntax shown here.
⍝ (a) dict← [default] ∇ (↑keylist) valuelist
⍝ (b) dict← [default] ∇ (item1 item2 ...), where itemN is a text-vector key followed by any value.
  ##.∆DV← ⍙CR '{⍺←⊢⋄0::"V"mê.Trap⍬⋄1:_←⍺mê.∆DV⍵}' 
  ∆DV←{ em11← 'DOMAIN ERROR: Invalid keylist matrix'
      dFlag← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 'help'≡⎕C⍵: _← Help     
    0=≢⍵:    ⎕NEW Dict (⍬ ⍬ ⍺ dFlag Dict.AUTOHASH)
    2=⍴⍴⊃⍵:  ⎕NEW Dict ((↓⊃⍵) (⊃⌽⍵) ⍺ dFlag Dict.AUTOHASH) ⊣ em11 ⎕SIGNAL 11/⍨ 0≠ 80| ⎕DR ⊃⍵
             ⎕NEW Dict (⍵ ⍺ dFlag Dict.AUTOHASH)  
  }

:Section Preamble
⍝HR
⍝H ∆D, ∆DL:   "Create and Manage an Ordered, Hashed Dictionary"
⍝HR
  ⍝Ht Example...
  ⍝H
  ⍝H⍝ Create dictionary of capital cities (capc)
  ⍝H⍎ capc←∆D('Italy' 'Naples')('United States' 'Washington, DC')('United Kingdom' 'London')
  ⍝H
  ⍝H⍝ Correct one incorrect item
  ⍝H⍎ capc[⊂'Italy']←⊂'Rome'
  ⍝H
  ⍝H⍝ Add two items (one is silly-- we'll clean up in a moment)
  ⍝H⍎ capc['France' 'Antarctica']←'Paris' 'Penguin City'
  ⍝H
  ⍝H⍝ How many items or keys or values (capc.Tally is the idiom)?
  ⍝H⍎ 'We have',capc.Tally,'items'
  ⍝H
  ⍝H⍝ Display all items. (Note syntax; capc.Items per se will trigger a NONCE ERROR.)
  ⍝H⍎ ↑capc.Items[]
  ⍝H
  ⍝H⍝ Delete (remove) invalid item 'Antarctica'
  ⍝H⍎ capc.Del⊂'Antarctica'
  ⍝H
  ⍝H⍝ Sort items by keys in ascending order 'back' into dictionary capc
  ⍝H⍎ capc←capc.(FromIx ⍋Keys)          ⍝ i.e. capc← capc.FromIx ⍋capc.Keys
  ⍝H
  ⍝H⍝ Display sorted items
  ⍝H⍎ ↑capc.Items[]
  ⍝H
  ⍝H⍝ Sort all items by Value (works for values in the domain of ⍋)
  ⍝H⍎ ↑capc.(FromIx ⍋Vals).Items[]      ⍝ temporary sorting: capc itself not reordered
⍝HR
⍝H ]load [-target ns] ∆D   
⍝H    loads functions ∆D, ∆DL (see below) in the target namespace ns (default ⎕THIS), 
⍝H    as well as supporting services in ns.⍙D.
⍝HR
⍝H ∆D, ∆DL:   "Create and Manage an Ordered, Hashed Dictionary"
⍝H ∘ Create a dictionary from 
⍝H    (∆D)  0 or more key-value pairs (items) or 
⍝H    (∆DL) a key list and value list,
⍝H   whose items are in a fixed order based on order of creation (oldest first) 
⍝H   [see d.FromIx, d.FromKeys for sorted order).]
⍝H ∘ Keys are by default hashed, which leads to performance improvements especially for
⍝H   non-numeric keys.
⍝H ∘ Adding new values for existing keys does not change their order.
⍝H ∘ Keys and Values may be of nameclasses:
⍝H      2 (variables incl. ⎕OR objects), 9.1 (namespaces), 9.2 (class instances),
⍝H   * I.e. Keys may be any shape.
⍝H   * Keys in class 9 or those that are ⎕OR objects are not in the domain of 
⍝H     methods like Equal (uses ⍋) or Count.
⍝H ∘ Sorted Order: To create a dictionary with keys in sorted order (or sorted by
⍝H   other criteria), use the FromIx or FromKey methods.
⍝H ∘ The FromIx and FromKeys methods are available to (among other things)
⍝H   select and/or sort items (based on criteria you choose) into a new dictionary,
⍝H   without affecting the original dictionary (unless you choose to replace it).
⍝HR
⍝H
⍝H ∆D "Dictionary from Items (Key-Value Pairs)"
⍝Hr 
⍝H d← [default] ∆D items           ⍝ items => (k1 v1)(k2 v2)…  
⍝H d← [default] ∆D ⊂item           ⍝ single item ==> ⊂(k1 v1)
⍝H d← [default] ∆D ⍬               ⍝ empty dictionary
⍝H d← [default] ∆D d0.Items[]      ⍝ d.Items <= d0.Items (slower than ∆DL equiv.).
⍝Hr
⍝H ∘ Create a dictionary with items (k1 v1)(k2 v2)….
⍝H ∘ If no items are specified, an empty dictionary is created.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H ∘ By default, new dictionaries created with ∆D will be automatically hashed.
⍝H   That is, Dyalog hashing will be turned on for Key searches and will be re-established
⍝H   within methods that might require the hash table Dyalog maintains to be rebuilt
⍝H   (e.g. deletions of non-trailing entries). 
⍝H   ∘ Dictionaries derived from those with hashing will automatically have hashing turned on.
⍝H   ∘ For even moderate-sized dictionaries, having the keys hashed improves performance significantly.
⍝H   ∘ This feature is enabled if the class variable AUTOHASH is 1. It is currently $AUTOHASH.
⍝H   ∘ See d.Hash and d.NoHash. 
⍝Hf
⍝H Note: ∆D 'help' will display this help information.
⍝HR
⍝H
⍝H ∆DL "Dictionary from a Key list and Value list"
⍝Hr
⍝H d← [default] ∆DL keylist vallist    ⍝ => (k1 k2…)(v1 v2…)
⍝H d← [default] ∆DL keylist (sv)       ⍝ => (k1 k2…)(sv), where sv is a scalar value
⍝H                                     ⍝                  replicated for each key kN. 
⍝H d← [default] ∆DL ⍬                  ⍝ empty dictionary. Shorthand for ∆DL ⍬ ⍬
⍝H d← [default] ∆DL d0.(Keys Vals)     ⍝ dict d efficiently initialized with items of d0
⍝Hr
⍝H ∘ Create a dictionary from a list of keys and corresponding values or, if there
⍝H   is a single scalar (simple or enclosed) value, make it the value for each key.
⍝H   For key vector KK and value vector VV, 
⍝H      (KK=⍥≢VV)∨(1=≢VV) must be true. 
⍝H ∘ Both keys and values may be empty (⍬), resulting in an empty dictionary.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H ∘ By default, new dictionaries created with ∆DL will be automatically hashed.
⍝H   That is, Dyalog hashing will be turned on for Key searches and will be re-established
⍝H   within methods that might require the hash table Dyalog maintains to be rebuilt
⍝H   (e.g. deletions of non-trailing entries). 
⍝H   ∘ See Copy for hashing attributes.
⍝H   ∘ For even moderate-sized dictionaries, having the keys hashed improves performance significantly.
⍝H   ∘ This feature is enabled if the class variable AUTOHASH is 1. It is currently $AUTOHASH.
⍝H   ∘ See d.Hash and d.NoHash.
⍝Hf 
⍝H Note: ∆DL'help' will display this help information.
⍝HR
⍝H 
⍝H ┌──────────────────────────────────────────────────────────────────────────────────┐
⍝H │                Methods of class ∆D.Dict in alphabetical order by type…           │
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │              Keyed (Index) Methods returning elements or info                    │ 
⍝H │              ────────────────────────────────────────────────                    │
⍝H ‖  ←[]  []←  Defined  DelIx  Has  Items                                            │ 
⍝H ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┤
⍝H │  vv←d[kk]       d[kk]←vv            bb←d.ⁱDefined[kk]  items←d.⁲DelIx[ii]        │
⍝H │  bb←d.ⁱHas[kk]  items←d.⁲Items[ii]                                               │ 
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │                Standard methods returning elements or info                       │  
⍝H │                ───────────────────────────────────────────                       │
⍝H ‖  Count        ←Default     Default←    Del   Equal  Get   Get1  GetSet           │ 
⍝H ‖  ←HasDefault  HasDefault←  HashStatus  Help  Index  Keys  Pop   Tally  Vals      │ 
⍝H ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┤
⍝H │  {vv}←{nn}d.Count kk  any←d.⁳Default     d.⁳Default←any      bb←{b}d.⁴Del kk     │
⍝H │  b←d.Equal d2         vv←{tdef}d.Get kk  v←{tdef}d.Get1 k    vv← {tdef}GetSet kk │
⍝H │  b←d.HasDefault    d.HasDefault←[1|0]    d.HashStatus                            │
⍝H │  d.Help            ii←{tdef}d.Index kk   kk← d.⁲Keys         {items}←d.Pop n     │ 
⍝H │  n←d.Tally            vals←d.⁲Vals                                               │ 
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │                Standard Methods returning dictionaries                           │ 
⍝H │                ───────────────────────────────────────                           │
⍝H ‖  Clear  [No]Hash  Import  ImportL  ImportN                                       │
⍝H ‖  Copy   FromKeys  FromIx  New                                                    │
⍝H ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┤
⍝H │  Same dict (updated):                                                            │  
⍝H │   {d}←d.Clear  {d}←d.[No]Hash  {d}←d.Import items {d}←d.ImportL kkvv             │  
⍝H │   {d}←{json}d.ImportN ns                                                         │      
⍝H │  New dict:                                                                       │
⍝H │   d2←d.Copy   d2←{tdef}d.FromKeys kk   d2←d.FromIx ii   d2←d.New                 │
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │                            Miscellaneous Methods                                 │ 
⍝H │                            ─────────────────────                                 │
⍝H ‖  ExportN                                                                         │
⍝H ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  ┤
⍝H │  Exporting a dictionary to a namespace(*):                                       │
⍝H │    {ns}←d.ExportN ns 
⍝H │         ns must be a namespace reference 
⍝H │          (*)  Keys must be strings convertible to valid APL variable names.      │
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │                         Abbreviations used above                                 │
⍝H ├──────────────────────┬─────────────────────────────┬─────────────────────────────┤
⍝H │    kk: list of keys  │    vv: list of vals         │    ii: list of indices      │  
⍝H │     k: disclosed key │     v: disclosed val        │    ii: list of indices      │  
⍝H │  kkvv: kk vv         │ items: (k1 v1)(k2 v2)…      │   any: any value            │ 
⍝H │     b: a boolean     │    bb: list of booleans     │  json: 1|0 (deflt: 1)       │  
⍝H │     n: an integer    │    nn: list of integers     │  tdef: any value            │
⍝H ├──────────────────────┴─────────────────────────────┴─────────────────────────────┤
⍝H │                                    Notes                                         │ 
⍝H ├──────────────────────────────────────────────────────────────────────────────────┤
⍝H │  ⁱᵃDefined, Has: (synonyms) Are the keys defined in the dictionary?              │
⍝H │    Does the dictionary have the associated items?                                │
⍝H │  ⁲ DelIx[], FromIx[], Index[]:   Each uses the Index Origin (⎕IO) of caller.     │ 
⍝H │    Items[], Keys, Vals:    Each uses the Index Origin (⎕IO) of caller.           │ 
⍝H │    * Keys, Vals are fast, returning the read-only source array unchanged.        │ 
⍝H │    * Items[ii] is calculated on the fly, index by index.                         │  
⍝H │  ⁳ Default: define/query the default value for new (missing) keys.               │
⍝H │  ⁴ Del: If a left arg is present and 1, all keys MUST exist.                     │
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H ╞══════════════════════════════════════════════════════════════════════════════════╡ 
⍝H │      What Python methods or fns are roughly comparable (even if scalar)?*        │
⍝H ├────────────────────────┬─────────────────┬──────────┬────────┬───────────────────┤
⍝H │  clear                 │ copy            │ fromkeys │ del    │ get               │
⍝H │  has_key [d.Has]       │ items           │ keys     │ len    │ popitem [d.Pop 1] │
⍝H │  setdefault [d.GetSet] │ values [d.Vals] │ update [d.Import] │                   │
⍝H │  𝑑[key], i.e. indexing by key, etc.      │                   │                   │
⍝H ├──────────────────────────────────────────┴───────────────────┴───────────────────┤
⍝H │                                     Notes                                        │ 
⍝H ├──────────────────────────────────────────────────────────────────────────────────┤
⍝H │  * Where not obvious, comparable ∆D equivalents are in brackets in               │  
⍝H │    UpperCamelCase like this:  [d.GetSet].                                        │    
⍝H └──────────────────────────────────────────────────────────────────────────────────┘
⍝HR
⍝H
⍝  *** Rest of Help info (with ⍝H prefix) is presented with each method below. ***   ⍝
:EndSection
   
:Class Dict
   
⍝ Error Msgs: Format: EN Message, where Message may be a null string ('').
  :Namespace error ⍝ em message
        badItems←      11 'Right arg must contain a list of items (enclosed key-value pairs)'
        badKVLists←     5 'Non-empty right arg must contain two lists: keys values'
        delBadIx←       3 'Nothing deleted'  
        delBadKey←      3 'Key(s) not found (nothing deleted)' 
        delBadLeft←    11 'Del left arg is invalid' 
        equalBadDict←  11 'Equal expects one or more dictionaries'
        badNm←         11 'At least one key cannot be converted to a variable name'
        badNs←         11 'Invalid namespace reference'  
        keyNotFnd←      3 'Key(s) not found and no default is active'
        mismatch←       5 'Number of keys and values must match or conform'
        noDefault←      6 'Default not set or active'
        noKeys←        11 'No keys were specified'
  :EndNamespace
⍝ Default states for d.Default
  :Namespace def   
        active←       1     ⍝ Default has a value and is active
        quiesced←    ¯1     ⍝ Default had a value, but is inactive
        none←         0     ⍝ Default didn't have a value AND is inactive
  :EndNamespace 
⍝ Traps within methods, utilities
  :Namespace trap 
        Ê← (,⍥⊆)∘'E' '##.Trap⍬' 
        domain←       Ê 11    
        index←        Ê  3     
        index_domain← Ê  3 11
  :EndNamespace
⍝ KEYS: Do not use :Field for KEYS, since it disrupts hashing (still in 19.0)!
                  KEYS←              ⍬   ⍝ List of keys (hashed by default); Keys is the method.
                  VALS←              ⍬   ⍝ List of values; Vals is the method.
  :Field Private  DEFAULT_V←       ⎕NULL ⍝ Placeholder: ignored if DEFAULT_S=def.none.
  :Field Private  DEFAULT_S←    def.none ⍝ See namespace <def> for default states.
  :Field Private  HASH_SET←          0   ⍝ If 1, set hash where required. See d.Hash, internal CheckRehash
  :Field Public Shared AUTOHASH←     1   ⍝ If 1, ∆D and ∆DL will enable hashing for new dicts
    
⍝ ErrIf: Internal helper. Usage:  en msg ErrIf bool 
⍝       If bool=0, NOP.
⍝       If bool=1, signals error with standard EM from (⎕EM en) and Message passed.
  ErrIf← ⎕SIGNAL {~⍵: ⍬ ⋄ ⊂'EN' 'Message' 'EM',⍥⊂¨ ⍺,⊂'∆D ',⎕EM ⊃⍺}
    
  ∇ makeFill                              ⍝ Create an empty dict with no DEFAULT_V 
    :Implements constructor               ⍝ ⎕NEW ⎕SE.⍙D.Dict ()
    :Access Public 
    ⎕DF '∆D[Dict+null]'
  ∇ 

  ∇ makeItems1 (items)                    ⍝ Create a dictionary of items with defaults
    :Implements constructor               ⍝ ⎕NEW ⎕SE.⍙D.Dict (('k1' 'v1')('k2' 'v2'))
    :Access Public 
    makeItems4 (items ⍬ 1 1)
  ∇

  ∇ makeLists2 (kk vv)                    ⍝ Create a dictionary from key- and value-lists with defaults
    :Implements constructor               ⍝ ⎕NEW ⎕SE.⍙D.Dict,⊂('k1' 'k2' 'k3')('v1' 'v2' 'v3')
    :Access Public 
    makeLists5 (kk vv ⍬ 1 1)
  ∇

  ∇ makeItems4 (items dVal dFlag hFlag)    ⍝ Create dict from Items and opt'l Default
    ;kk; vv; kkvv                   
    :Implements constructor
    :Access Public
    :If 0= ≢items 
      ⍝ no values: KEYS, VALS are predefined.
    :Elseif 2=≢kkvv← ,¨(↓∘⍉↑∘,) items
        kk vv← kkvv 
        ValsByKey[kk]←vv 
    :Else 
        error.badItems ErrIf 1 
    :EndIf  
    DEFAULT_V DEFAULT_S ← dVal dFlag 
    :IF hFlag ⋄ Hash ⋄ :Endif 
    ⎕DF '∆D[Dict+items',(dFlag/'+default'),(hFlag/'+hash'),']' 
  ∇

  ∇ makeLists5 (kk vv dVal dFlag hFlag)   ⍝ Create dict from Keylist Valuelist and opt'l Default  
    :Implements constructor  ⍝ If h=0, the DEFAULT_V is NOT set.
    :Access Public
    :If kk ≠⍥≢ vv 
        :If 1≠ ≢vv ⋄ error.mismatch ErrIf 1 ⋄ :EndIf 
        vv ⍴⍨← ⍴kk                        ⍝ Conform vv to kk, if vv is a singleton.
    :EndIf 
    :If 0≠≢kk   
        ValsByKey[kk]← vv    
    :EndIf  
    DEFAULT_V DEFAULT_S← dVal dFlag 
    :IF hFlag ⋄ Hash ⋄ :Endif 
    ⎕DF '∆D[Dict+list',(dFlag/'+default'),(hFlag/'+hash'),']' 
  ∇
  
  ∇{kkvv}← RESTORE kkvv
⍝ RESTORE: "Secret" Utility Method for timing/debugging only. 
⍝ Used to restore (replace) keys and values w/ minimal overhead
⍝ for use in timing/debugging only: e.g.
⍝     SAVED_KKVV← d.(Keys Vals) ⋄ ... ⋄ cmp 'd.Del ...⊣ d.RESTORE SAVED_KKVV'
⍝ DO NOT USE IN PRODUCTION-- use d.ImportL!
   :Access Public 
   KEYS VALS← kkvv 
  :If HASH_SET ⋄ :AndIf 0=1(1500⌶)KEYS ⋄ 'LOGIC ERROR: KEYS aren''t hashed' ⎕SIGNAL 911 ⋄ :EndIf  
  ∇ 
  
⍝H d[…]:  Retrieve or set specific values of the dictionary by key.
⍝H   d[k1 k2 …]           ⍝ Retrieve specific values by key 
⍝H                        ⍝ (values for keys not found are the default, if previously set).
⍝H   d[k1 k2 …]← v1 v2 …  ⍝ Set specific values by key
⍝H   d[]                  ⍝ Retrieve all values.
⍝H See also 
⍝H    d.Vals              ⍝ Retrieve all/specific values by Index
⍝H    d.Get, and d.Get1.  ⍝ Retrieve specific values by key with an optional ad hoc default.
⍝HR
⍝H
  :Property Default Keyed ValsByKey 
  :Access Public
⍝ ValsByKey "get" method
    ∇ vv←get args; ii; kk; old 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          vv← VALS                          ⍝ Grab all values if d[] is specified.
      :Else 
          old← (≢KEYS)≠ ii← KEYS⍳ kk
          :If ~0∊ old                       ⍝ All keys old? 
              vv← VALS[ ii ]                ⍝ … Just grab existing values.
          :Else                             ⍝ Some old and some new keys.
              error.keyNotFnd ErrIf DEFAULT_S≠ def.active ⍝ … error unless we have a DEFAULT_V;
              vv← (≢kk)⍴ ⊂DEFAULT_V         ⍝ … where new, return DEFAULT_V;
              vv[ ⍸old ]← VALS[ old/ ii ]   ⍝ … where old, return existing value.
          :Endif 
          vv ⍴⍨← ⍴kk                        ⍝ If kk is a scalar, we must return a scalar!
      :Endif  
    ∇
  ⍝ ValsByKey "set" method
  ⍝ Note: What if a key appears more than once with different values, when being set?
  ⍝       If a key is duplicated, then to be consistent with APL indexing: 
  ⍝       ∘ its position is set according to the leftmost appearance;
  ⍝       ∘ its value is set to the rightmost value seen for that key.
  ⍝       See use of ⌸ (Key operator) below. 
      ∇ set args; kk; ii; new; vv; nKEYS   
        kk← ,⊃args.Indexers 
        vv← ,args.NewValue 
        ⋄ error.noKeys ErrIf ⎕NULL≡ kk         ⍝ d[]← … NOT ALLOWED.
        kk vv← ↓⍉{ ⍺, vv[⊃⌽⍵] }⌸ kk            ⍝ ⌸ (Key operator): see Note above.
        nKEYS← ≢KEYS  
        :IF 1∊ new← nKEYS= ii← KEYS⍳ kk        ⍝ New Keys…
            VALS,← 0⍴⍨≢ KEYS,← nkk← new/ kk    ⍝ Add placeholder (0) for each new val 
            (new/ ii)← nKEYS+ ⍳⍨nkk            ⍝ Add new key indices
        :EndIf 
        VALS[ ii ]← vv                         ⍝ Update ALL values, replacing any placeholders 
      ∇ 
    :EndProperty
  
  ⍝H d.Clear:  Remove all items (keys and values) from the dictionary,
  ⍝H           preserving the default value (Default) and hashing status.
  ⍝H   {d}← d.Clear
  ⍝H Shyly returns the dictionary.
  ⍝HR
  ⍝H
      ∇{d}← Clear 
        :Access Public 
        d← ⎕THIS ⋄ KEYS←VALS← ⍬ ⋄ CheckRehash 
      ∇
  
  ⍝H d.Copy:  Make a copy of dictionary d, including the Keys and Vals, as well as the 
  ⍝H          existing default and hash settings. 
  ⍝H   d2← d.Copy
  ⍝Hr 
  ⍝H d2← d.Copy.Clear.ImportL kk vv ⍝ Create new dict. d2 with same Hash and Defaults as <d>
  ⍝HR
  ⍝H
    ∇ d2← Copy; def  
      :Access Public 
      d2← ⎕NEW Dict (KEYS VALS DEFAULT_V DEFAULT_S HASH_SET)  
      d2.⎕DF ⍕⎕THIS 
    ∇
  
⍝H d.Has, d.Defined:  "Are keys k1 k2…  defined in Keys?"
⍝H   bb← d.Has[k1 k2…]        
⍝H Returns a 1 for each key (k1, etc.) defined in Keys and a 0 otherwise.
⍝HR
⍝H
  :Property Keyed Has, Defined 
  :Access Public
    ∇ bb←get args; kk 
      ⋄ error.noKeys ErrIf ⎕NULL≡ kk← ⊃args.Indexers 
      bb← ⊂⍣ (0= ⊃⍴⍴kk)⊢ (≢KEYS)≠ KEYS⍳ kk 
    ∇
  :EndProperty
  
⍝H d.Default:  Retrieve or set/redefine the default value for missing dictionary items
⍝H             (those requested by key that do not exist) 
⍝H   val← d.Default            ⍝ Retrieve the default value (or signal an error, if none)
⍝H   d.Default← any_value      ⍝ Set the default value, also setting HasDefault←1.
⍝H If you set a default, HasDefault is automatically set to 1.
⍝H If HasDefault=0, a query of d.Default will signal a VALUE ERROR (⎕EN=6).
⍝HR
⍝H
  :Property Simple Default
  :Access Public
    ∇ d←get 
      ⋄ error.noDefault ErrIf DEFAULT_S≠ def.active
      d← DEFAULT_V 
    ∇
    ∇ set new  
      DEFAULT_S DEFAULT_V← def.active new.NewValue 
    ∇
  :EndProperty 
  
⍝H d.Del:   Delete items by keyword (k1 k2…)
⍝H    {bb}← [required←0*] d.Del k1 k2…   ⍝ If missing keys are seen, they are ignored (default).
⍝H    {bb}← [required←1 ] d.Del k1 k2…   ⍝ If missing key are seen, an error is signaled.
⍝H ∘ Duplicate keys allowed.
⍝H ∘ Returns 1 for each entry found and deleted, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
⍝HR
⍝H
      ∇ {bb}← {required} Del kk; ii; err; msg  
         :Access Public
        :If 0=≢kk ⋄ bb←⍬ ⋄ :Return ⋄ :EndIf      ⍝ Nothing to do… 
        bb← (≢KEYS)≠ ii← KEYS⍳ kk               ⍝ Get indices of keys 
        :If 0∊ bb ⋄ :AndIf ~900⌶⍬               ⍝ Some missing, but required?
            ⋄ error.delBadLeft ErrIf required(~∊) 0 1
            ⋄ error.delBadKey  ErrIf required             
        :EndIf 
        :IF 1∊ bb                         
            ⋄ ErrIf/ 0 ⍙DelIx ∪bb/ ii            ⍝ Delete by index…
        :EndIf 
        bb⍴⍨← ⍴kk                                ⍝ Scalar in, scalar out
      ∇
      
⍝H d.DelIx: Delete items by index (per caller's ⎕IO), returning prior value.
⍝H   items← d.DelIx[i1 i2…]    ⍝ Entries at [i1 i2…] returned and deleted 
⍝H   items← d.DelIx[]          ⍝ All entries returned and deleted
⍝H Returns all items indexed after deleting them from the dictionary.
⍝H ∘ All indexed items must exist, else INDEX ERROR. 
⍝H ∘ Duplicate indices ok: items at the indices specified are returned.
⍝H See also: d.Pop N
⍝HR
⍝H
  :Property Keyed DelIx 
  :Access Public
    ∇ items←Get args; ii; ei; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          items← Items ⋄ Clear               ⍝ Deleting and returning everything!
      :Else 
          items err← 1 ⍙DelIx ii-(⊃⎕RSI).⎕IO ⍝ Adjust for caller's ⎕IO   
          ⋄ items ErrIf err  
      :Endif 
    ∇
  :EndProperty
  
  ⍝ ret← ⍙DelIx ii     (Internal helper function)
  ⍝   Delete items for indices specified (which must exist per ⎕IO=0); duplicate items ok.
  ⍝ On success:
  ⍝   ∘ If ⍺=1: returns:   (the items deleted) 0 
  ⍝   ∘ If ⍺=0: returns:   ii 0   
  ⍝ If an INDEX ERROR occurs: 
  ⍝   ∘         returns:   (error.object) 1
  ⍝ Note: if all items to delete are in a contiguous trailing block of keys (possibly repeated),
  ⍝       they are deleted via drop (↓); hashing will be maintained automatically (if set).     
  ⍝                    
  ⍙DelIx←{  
    3:: error.delBadIx 1 
        ret← ⍺ { ⍺: ↓⍉↑ KEYS VALS⌷⍨¨ ⊂⊂⍵ ⋄ ⍵ } ii←⍵ 
        blk← -+/∧\⌽bb← 1@ ii⊣ 0⍴⍨ ≢KEYS    ⍝ catches INDEX ERRORs  
  ⍝ If all items are in a contig. trailing block, remove via ↓⍨←, which preserves any hashing.   
    1(~∊) bb↓⍨ blk: ret 0⊣ KEYS↓⍨← VALS↓⍨← blk ⍝ Assign separately to maintain any hashing of KEYS 
    ⍝ Remove items to delete by indexing (depends on ix errors being caught above)
        KEYS/⍨← VALS/⍨← ~bb                      
        ret 0 ⊣ CheckRehash   
  }
  
⍝H d.Equal: Do dictionaries presented have the same items as <d>, ignoring order.
⍝H   same← d.Equal d2 [d3 [...]]
⍝H Returns 1 if two dictionaries have the same key-value pairs, regardless of order.
⍝H    ∘ A DOMAIN ERROR will result if any KEY is outside the domain of ⍋ (sorting);
⍝H      values may include namespaces, class instances, and ⎕OR objects. 
⍝H      The domain for ⍋ (sorting) includes character and numeric arrays, 
⍝H      but excludes ⎕OR objects or object in class 9 (including namespaces or class instances).
⍝H    ∘ Values in class 9 (9.1 or 9.2) are treated as different if they do not
⍝H      reference the very same object, even if their contents are identical.
⍝H Note: d.Equal is slow, sorting all keys and comparing each corresponding key and value.
⍝HR
⍝H 
  ∇ bb← Equal dd; ⎕TRAP   
    :Access Public 
    ⎕TRAP← trap.domain
    bb← {  
      9.2≠⎕NC ⊂,'⍵': error.equalBadDict ErrIf 1 
      KEYS≠⍥≢ kk← ⍵.Keys: 0
      KEYS[ p← ⍋KEYS ]≢ kk[ q← ⍋kk ]: 0
      VALS[ p ]≡ ⍵.Vals[ q ]
    }¨dd  
  ∇
  
⍝H d.FromKeys:  Create a new dictionary from the keys specified, with their values.
⍝H   d2← {tempDef} d.FromKeys kk
⍝H ∘ Returns a new dictionary including the items from d which contain the keys kk,
⍝H   but in the order selected.
⍝H ∘ Useful for things like sorting entries according to keys (or values),
⍝H   without modifying the entries themselves in any way.
⍝H ∘ Missing keys trigger an INDEX ERROR (Keys not found) unless a default has been set,
⍝H   either as a dict-wide default or via tempDef, the left argument to d.FromKeys.
⍝Hf
⍝H d.FromKeys can be easily used to sort items into a new dictionary…
⍝H   b←a.(FromKeys Keys[⍋   Keys])       ⍝ Sort by key in ascending order.
⍝H   b←a.(FromKeys Keys[⍒   Keys])       ⍝ Sort by key in descending order.
⍝H   b←a.(FromKeys Keys[⍋   Vals])       ⍝ Sort by value(!!) in ascending order.
⍝H   b←a.(FromKeys Keys[⍋⎕C Keys])       ⍝ Sort by folded keys in ascending order; dict. keys preserve case.
⍝H   b←a.(FromKeys Keys[⍋|  Keys])       ⍝ Sort numeric keys in ascending order by absolute value
⍝H See also: d.FromIx
⍝HR
⍝H
  ∇ d2← {tempDef} FromKeys kk; ⎕TRAP  
    :Access Public 
    ⎕TRAP← trap.index ⋄ :If 900⌶⍬ ⋄ tempDef← ⊢ ⋄ :EndIf 
    d2← Copy.Clear.ImportL kk (tempDef Get kk)
  ∇
  
⍝H d.FromIx:  Create a new dictionary from the indices specified (which must be in range).
⍝H   d2← d.FromIx ii
⍝H ∘ Returns a new dictionary including only the items from d at indices ii,
⍝H   but in the index order presented. 
⍝H ∘ Useful for things like sorting entries according to keys (or values),
⍝H   without modifying the entries themselves in any way.
⍝H ∘ Repeated indices are ignored.
⍝H ∘ Indices out of range trigger an INDEX ERROR.
⍝H ∘ Respects the ⎕IO of the caller.
⍝Hf
⍝H d.FromIx can be easily used to sort items into a new dictionary…
⍝H   b←a.(FromIx ⍋   Keys)         ⍝ Sort by key in ascending order.
⍝H   b←a.(FromIx ⍒   Keys)         ⍝ Sort by key in descending order
⍝H   b←a.(FromIx ⍋   Vals)         ⍝ Sort by value(!!) in ascending order.
⍝H   b←a.(FromIx (5⌊Count)↑⍒ Keys) ⍝ Sort by key in descending order and keep the top 5 (if poss.).
⍝H   b←a.(FromIx ⍋⎕C Keys)         ⍝ Sort by folded keys in ascending order
⍝H   b←a.(FromIx ⍋|  Keys)         ⍝ Sort numeric keys in ascending order by absolute value
⍝H See also: d.FromKeys. 
⍝H   d.FromIx is typically up to 10% faster than d.FromKeys across a range of dictionary sizes.
⍝HR
⍝H
  ∇ d2← FromIx ii; ⎕TRAP 
    :Access Public 
    ⎕TRAP← trap.index_domain 
    d2← Copy.Clear.ImportL KEYS VALS⌷⍨¨⊂⊂∪ii- (⊃⎕RSI).⎕IO  
  ∇
  
⍝H d.Get:   Retrieve values for one or more keys.
⍝H   v1 v2…← d.Get k1 k2…           ⍝ One or more keys (present a list, returns a list)
⍝H   v1 v2…← default d.Get k1 k2…    
⍝H ∘ If a default is not specified, all keys must be currently defined (else INDEX ERROR)
⍝H   unless a global default has been set (e.g. when the dictionary was created). 
⍝H ∘ If a default is specified, it will be used for all keys not in the dictionary,
⍝H   independent of any global default value set.
⍝Hf
⍝H Note: (d.Get kk) is equivalent to d[kk] key-based indexing, except d.Get allows a   
⍝H       temporary default value either when the dictionary otherwise lacks a default or  
⍝H       when the general default is not appropriate in a particular case.
⍝HR
⍝H
  ∇ vv← {tempDef} Get kk; noDefault; ii; bb 
    :Access Public
    ii← KEYS⍳ kk
    :If 0∊ bb← ii≠ ≢KEYS                       ⍝ If 'tempDef' isn't set, use DEFAULT_V (if set).
        :If noDefault← 900⌶⍬ ⋄ :AndIf DEFAULT_S= def.active   
            tempDef noDefault← DEFAULT_V def.none    ⍝ Else, there's no tempDef to use.
        :EndIf    
        ⋄ error.keyNotFnd ErrIf noDefault 
        vv← (≢kk)⍴ ⊂tempDef                    ⍝ vv: assume default for each;
        vv[ ⍸bb ]← VALS[ bb/ii ]               ⍝     use "old" values where defined. 
    :Else 
        vv← VALS[ ii ]
    :Endif 
  ∇
  
⍝H d.Get1:   Retrieve a (disclosed) value for exactly one (disclosed) Key.
⍝H   v1← [tempDef] d.Get1 k1        ⍝ One key (present a value, returns a value)
⍝H Like d.Get, but retrieves the value* for exactly one key*. 
⍝H    d.Get1 'myKey' <==>  ⊃d.Get ⊂'myKey'                    
⍝H Note: [*] Neither the key passed nor the return value is enclosed.
⍝H *** See also the note at d.Get (above).
⍝HR
⍝H
  ∇ v1← {tempDef} Get1 k1; ⎕TRAP   
    :Access Public       
    ⎕TRAP← trap.index ⋄ :IF 900⌶⍬ ⋄ tempDef← ⊢ ⋄ :EndIf 
    v1← ⊃tempDef Get ⊂k1  
  ∇ 
  
⍝H d.GetSet: Returns the value of each key or the temporary default, if specified. 
⍝H   v1 v2 ...← {tempdef} GetSet k1 k2 ...
⍝H Returns the value for each existing key specified; 
⍝H If a key does NOT exist in the dictionary:
⍝H    a) if tempdef is specified, 
⍝H       returns tempdef and, at the same time, enters that key into the dictionary.
⍝H    b) otherwise,
⍝H       signals an INDEX ERROR.
⍝H * Similar to Python "setdefault" method, which returns the value of a single existing item 
⍝H   with the specified key or a single new item, with the default value specified, after 
⍝H   inserting the item into the dictionary. 
⍝H See also d.Index.
⍝HR
⍝H
    ∇ vv← {tempdef} GetSet kk; ⎕TRAP  
      :Access Public
      ⎕TRAP← trap.index ⋄ :IF 900⌶⍬ ⋄ tempdef← ⊢ ⋄ :EndIf 
      vv← VALS⌷⍨  ⊂tempdef _Index kk      ⍝ Local ⎕IO only.
    ∇
  
⍝H d.HasDefault:  Retrieve or set the current Default status. 
⍝H   b← d.HasDefault            
⍝H   d.HasDefault← [1|0]
⍝H - If you set HasDefault to 1, 
⍝H   the prior default (if any) is restored;
⍝H   ∘ If no default exists, HasDefault remains 0 and a VALUE ERROR is generated. 
⍝H - If you set HasDefault to 0, 
⍝H   any attempt to access an item that doesn't exist will cause a VALUE ERROR to 
⍝H   be signalled, until you reset HasDefault to 1 (see also d.Default).
⍝HR
⍝H
    :Property Simple HasDefault 
    :Access Public
      ∇ b←get 
        b← def.active= DEFAULT_S 
      ∇
      ∇ set new; d   
         :If 1≠≢d← new.NewValue :OrIf d (~∊) 0 1 ⋄ 11 ''ErrIf 1 ⋄ :EndIf 
         :If d 
            ⋄ error.noDefault ErrIf def.none= DEFAULT_S 
            DEFAULT_S← def.active 
         :Else 
            DEFAULT_S×← def.quiesced
         :EndIf 
      ∇
    :EndProperty 
  
⍝H d.Hash:    Turns on hashing, if not already. (Default for both ∆D and ∆DL dictionaries)
⍝H d.NoHash   Turns off hashing,if not already.
⍝Hr
⍝H   {d}← d.Hash 
⍝H Turns on hashing and shyly returns the hash itself:
⍝H ∘ Hashing is the default for dictionaries created via ∆D, ∆DL or d.Copy.
⍝H ∘ Set the flag HASH_SET to 1 and mark the vector KEYS as a Dyalog hashtable, 
⍝H   so it can be searched faster. This creates some overhead, but searches of (large) 
⍝H   key vectors can be done in O(1) time, rather than O(N).
⍝H ∘ When set, hashing is established immediately and re-established when a delete or 
⍝H   clear takes place (i.e. when the hash table is disrupted).
⍝H ∘ Hashing generally affects performance positively, and will use up space proportional
⍝H   to the dictionary size, but is otherwise transparent.
⍝Hr
⍝H {d}← d.NoHash
⍝H Turns off hashing for the dictionary keys, shyly returning the dict itself.
⍝H ∘ This ensures there is no hashing, for things like performance tests.
⍝H ∘ In general, there should be no need to turn off hashing; there is noticeable 
⍝H   overhead in turning hashing off the first time, but not subsequently (i.e. when already off). 
⍝H See d.Hash.
⍝HR
⍝H 
    ∇ {d}← Hash
      :Access Public
      d← ⎕THIS ⋄ :If ~HASH_SET ⋄ KEYS← 1500⌶KEYS ⋄ HASH_SET← 1 ⋄ :EndIf   
    ∇
    ∇ {d}← NoHash
      :Access Public             ⍝  ⊃⊂KEYS: Undo hashing of KEYS
      d← ⎕THIS ⋄ :If HASH_SET ⋄ KEYS← ⊃⊂KEYS ⋄  HASH_SET← 0 ⋄ :EndIf   
    ∇
  
⍝H d.HashStatus: Returns the current hash status of the dictionary.
⍝H The return format is:  int msg 
⍝H    int  msg
⍝H    0    NOT HASHED           (this dictionary has NoHash set explicitly or implicitly)
⍝H    1    HASH ENABLED         (no searches yet, so hash table not yet built)
⍝H    2    HASH ACTIVE          (hash table built and in use)
⍝H HashStatus verifies that the hash setting is consistent with the Dyalog hash status returned.
⍝H This is checked since hashing is disabled by certain operations.
⍝HR
⍝H
    ∇ status← HashStatus; s; m 
      :Access Public
  ⍝ Consistency check for HASH_SET and actual hash setting for KEYS
      :If HASH_SET≠ ×s← 1(1500⌶)KEYS  
          m← 'HASH_SET=',(⍕HASH_SET),', (1500⌶) status=',⍕s 
          911 ⎕SIGNAL⍨ 'Logic Error: Hash setting and (1500⌶) status are inconsistent for KEYS: ',m 
      :EndIf 
      status← s (s⊃ 'NOT HASHED' 'HASH ENABLED' 'HASH ACTIVE') 
    ∇
    
    ∇ {h}← CheckRehash
  ⍝ Forces KEYS to be rehashed no matter what, if HASH_SET.
  ⍝ Returns 1 if it rehashed; else 0 (either HASH_SET=0 or keys already hashed).
  ⍝ Used only when hashing is known to be off or disrupted (deleting non-trailing keys, etc)
      :Access Private
      :If HASH_SET ⋄ :AndIf 0=1(1500⌶)KEYS  
          h←1 ⋄ KEYS← 1500⌶KEYS 
      :Else 
          h←0 
      :EndIf
    ∇ 
   
⍝H d.Help:  Display help information.
⍝H d.Help ⍝ No args or return value. 
⍝H See also: ∆D'help', ∆DL'help' for identical information.
⍝HR
⍝H
    ∇ {ok}← Help
    :Access Public Shared
      ok← ##.Help 
    ∇
  
⍝H d.Import, d.ImportL: import dictionary items/key-value lists into the dictionary.
⍝H   {d}←  d.Import  items             ⍝ i.e. key-value pairs: (k1 v1)(k2 v2)…
⍝H   {d}←  d.ImportL keylist vallist 
⍝Hr 
⍝H d.Import adds items (k1 v1)(k2 v2)… to the dictionary in order left to right.
⍝H    This is equivalent to {d[ kk ]← vv ⊣ kk vv← ↓⍉↑⍵} items
⍝H d.ImportL adds a key list and a matched value list to the dictionary in order left to right.
⍝H    This is equivalent to d[ keylist ]← vallist.
⍝Hr
⍝H To clear the existing keylist vallist and quickly import new ones, do 
⍝H    d.Clear.ImportL keylist vallist  
⍝H This can be useful for a specialized sort "in place" (really: in the same dict.)
⍝H ∘ Re-sort numeric keys by absolute value (keeping the keys themselves intact)
⍝H   d.Clear.ImportL d.(Keys Vals)⌷⍨¨⊂⊂⍋|d.Keys
⍝H ∘ If the dictionary is empty, import efficiently sets the KEYS and VALS to the input args. 
⍝H ∘ In all cases, keys are inserted based on the first (leftmost) instance and 
⍝H   values are updated based on the rightmost of the key as expected for APL indexing. 
⍝H ∘ What if I want to import all the items from a dictionary myD?
⍝H   d.ImportL myD.(Keys Vals) ⍝ Faster
⍝H   d.Import  myD.Items[]     ⍝ Slower
⍝H See also d.FromKeys, d.FromIx 
⍝HR
⍝H
    ∇ {d}←  Import items ; kkvv; kk; vv 
      :Access Public
      d← ⎕THIS 
      kkvv← ,¨↓⍉↑ items ⋄ error.badItems ErrIf 2≠ ≢kkvv 
      kk vv← kkvv 
      ValsByKey[kk] ← vv      ⍝ Handle old, new, and duplicate keys
    ∇
    ∇ {d}←  ImportL (kk vv)
      :Access Public
      d← ⎕THIS 
      :If 1=≢vv ⋄ vv⍴⍨← ≢kk 
      :Else ⋄ error.mismatch ErrIf kk≠⍥≢vv 
      :EndIf   
      ValsByKey[kk] ← vv      ⍝ Handle old, new, and duplicate keys
    ∇
  
⍝H  d.ImportN and d.ExportN
⍝H  d.ImportN: Imports key-value pairs from/to namespace variables.
⍝H  d.ExportN: Exports key-value pairs from/to namespace variables.
⍝Hr 
⍝H   {d}← {json←1} d.ImportN ns 
⍝H     ns: an APL namespace reference 
⍝H   json: If json=1 (default, if omitted), converts "mangled" JSON names to 
⍝H         strings (see Dyalog ⎕JSON). E.g. name ⍙123 will become string '123'.
⍝H         Otherwise, if json=0, mangled JSON names become equiv. strings (e.g. '⍙123').
⍝H    * Only nameclasses 2 (arrays) and 9 (namespaces etc.) names are imported; 
⍝H      others are ignored.
⍝H  Returns: updates d in place, returning d itself, with objects of class 2, 9 imported. 
⍝Hr
⍝H   {ns}← ExportN ns
⍝H       ns: an APL namespace reference (which may contain one or more relevant items)
⍝H  ∘ Exports all keys that are strings convertible to APL names; this includes
⍝H    strings that match APL names already and names convertible via JSON name-mangling.
⍝H    * E.g. string '123' will become name ⍙123 via 0∘(7162⌶)).
⍝H  ∘ Values will remain as is without name or format conversion.
⍝H  If any keys are not simple strings (char vectors), ExportN signals a DOMAIN ERROR.
⍝H  Returns: the namespace reference presented, if successful. 
⍝HR
⍝H
    ∇{d}← {json} ImportN ns; JMapK; ⎕TRAP  
      :Access Public 
      ⎕←'this' ⎕THIS 
      ⎕←'rsi ' ⎕RSI 
      JMapK← 1∘(7162⌶)                             ⍝ Mangled JSON name to string
      ⎕TRAP← trap.domain ⋄ d← ⎕THIS ⋄ :If 900⌶⍬ ⋄ json←1 ⋄ :EndIf 
      ⋄ error.badNs ErrIf 9≠⎕NC 'ns' 
      :If ×≢nms← ns.⎕NL ¯2 ¯9   
          ValsByKey[ JMapK¨⍣json⊣ nms ]← ns.⎕OR¨ nms
      :EndIf 
    ∇
    ∇ {ns}← ExportN ns; nms; KMapJ; ⎕TRAP; here 
       :Access Public
        KMapJ← 0∘(7162⌶)
        here← ⊃⎕RSI 
        ⎕TRAP← trap.domain  
        ns← {9=⎕NC 'ns': ns ⋄ 9=here.⎕NC ns: here⍎ns ⋄ ns }⍬
        error.badNs ErrIf 9≠⎕NC 'ns'
        :Trap 11 
          nms← KMapJ¨KEYS
        :Else
          error.badNm ErrIf 1
        :EndTrap 
        {} nms {ns⍎⍺,'←⍵' }¨VALS 
    ∇
  
⍝H d.Index: Select items by key and return their indices (respecting caller's ⎕IO).  
⍝H   ii← {default} d.Index kk
⍝H ∘ If there's a default:
⍝H   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H   Return the indices of items for all the keys specified, including those are 
⍝H   newly added (if any). The caller's ⎕IO is respected.
⍝H   (New items are added permanently to the dictionary with value ¨default¨).
⍝H ∘ If there is no default:
⍝H   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H   Returns the indices of keys specified, if all exist.
⍝H   Signals an INDEX ERROR, if any keys specified do not already exist.
⍝H ∘ Useful for multiple, efficient manipulations of the same items.
⍝H * Similar to Python "setdefault" method, which returns the value of a single existing item 
⍝H   with the specified key or a single new item, with the default value specified, after 
⍝H   inserting the item. 
⍝H See also d.GetSet.
⍝HR
⍝H
    ∇ ii← {default} Index kk; ⎕TRAP   
      :Access Public
      ⎕TRAP← trap.index ⋄ :IF 900⌶⍬ ⋄ default← ⊢ ⋄ :EndIf 
      ii←  (⊃⎕RSI).⎕IO+ default _Index kk 
    ∇
⍝ _Index:  Returns indices where keys <kk> are located. If <default> is specified,
⍝          adds new keys with <default> as value; otherwise signals an index error.
⍝          Uses the internal ⎕IO (0) only. 
⍝   ii← {default} _Index k1 [k2…]   
⍝ See methods d.Index, d.GetSet.
    _Index←{   
        noDef← 0=⎕NC '⍺' ⋄ nKEYS← ≢KEYS
      1(~∊) new← nKEYS= ii← KEYS⍳ ⍵: ii 
      noDef: error.keyNotFnd ErrIf 1 
        ukk← ∪nkk← new/kk  
        (new/ ii)← nKEYS+ ukk⍳ nkk 
        KEYS,← ukk         
        VALS,← (≢ukk)⍴ ⊂⍺
        ii 
    }
  
⍝ ItemsNaive - just here for testing alternative to Items below
⍝ FOR TESTING ONLY!!!
⍝ It is unexpectedly slow, even when called just once (e.g. a single index).
⍝ One call per index element, i.e. O(N).
⍝ See Items-- the "production" way to select dictionary Items.
   :Property Numbered ItemsNaive
    :Access Public
      ∇ item← Get args; i    
        i← args.Indexers 
        item←  ⊂KEYS[i], VALS[i] 
      ∇
      ∇ r← Shape
        r← ≢KEYS
      ∇
  :EndProperty
  
⍝H d.Items: retrieve selected items of the dictionary by index as key-value pairs. 
⍝H   items← d.Items[ ii ]   Retrieve items with indices ii.           Caller ⎕IO is honored.
⍝H   items← d.Items[]       Retrieve all items (in order by index).           -ditto-
⍝H                          Note: d.Items[]; d.Items per se will trigger a NONCE ERROR.
⍝Hr 
⍝H Note: All items are generated on the fly, all at once (as a keyed method) for efficiency.
⍝H (Items are read-only)
⍝HR
⍝H
  :Property Keyed Items    
    :Access Public
      ∇ items← Get args; ii 
        :If ⎕NULL≡ ii← ⊃args.Indexers 
            items← ↓⍉↑ KEYS VALS 
        :Else  
            ii-← (⊃⎕RSI).⎕IO 
            items← ↓⍉↑ (KEYS[ii]) (VALS[ii])
        :EndIf 
      ∇
  :EndProperty
  
⍝H d.Keys: Retrieve all the keys of the dictionary. (Keys are read-only)
⍝H   kk← d.Keys
⍝HR
⍝H
  ∇ kk←Keys 
    :Access Public
    kk← KEYS  
  ∇
  
  
⍝H d.Tally: Return the # of Keys or Vals or Items.
⍝H   n← d.Tally
⍝HR
⍝H
  ∇ n← Tally 
    :Access Public 
    n← ≢KEYS 
  ∇
  
⍝H d.New: Make a new dictionary that is completely pristine: no entries, default, or hashing.
⍝H   d2← d.New
⍝H You may add characteristics via dictionary methods like Hash, Clear, and ImportL:
⍝H   d2← d.New.Hash
⍝H   d2← d.New.Hash.ImportL keylist vallist
⍝H   d2← d.New ⋄ d2.Default← ¯1
⍝H See d.Copy, d.Clear, d.Import, d.ImportL.
⍝HR
⍝H
    ∇ d2← New 
      :Access Public 
      d2← ⎕NEW Dict   
    ∇
  
⍝H d.Pop    Remove and return a contiguous selection of ¨n¨ of the most 
⍝H          recent items in the dictionary (n, a positive integer).
⍝H   {items}← d.Pop n
⍝H Remove and shyly return the last <n> items from the dictionary;
⍝H if no items to return, returns ⍬.
⍝H   n: a single non-negative integer. 
⍝H If n exceeds the # of items, the actual items are returned (no padding is done).
⍝HR
⍝H
    ∇{items}← Pop n; p; ⎕TRAP 
      :Access Public     
      ⎕TRAP← trap.domain ⋄ ⎕SIGNAL 11/⍨ n<0    ⍝ Catch Pop ¯1 etc here.
      items← ↓⍉↑ KEYS VALS↑⍨¨ p← - n⌊ ≢KEYS    ⍝ Other DOMAIN ERRORs caught here
      KEYS↓⍨← VALS↓⍨← p                        ⍝ Keep any hashing for KEYS intact   
      :If 0= ≢items ⋄ items← ⍬ ⋄ :EndIf 
    ∇
  
⍝H d.Count  Count the # of instances of each key passed, incrementing the key's value 
⍝H          by that count (optionally applying a weight besides +1).
⍝H   {res}← {weight} d.Count kk
⍝H   kk:  1 or more keys, which 
⍝H        (a) may include duplicates in any order and 
⍝H        (b) may be new to d 
⍝H   weight: (defaults to 1) How much to weight each increment.
⍝H        If weight=1 (default), increment the value by 1 for each key found.
⍝H        If weight=¯1, decrement the value by 1 for each key found.
⍝H ∘ Counts how many times each key ¨k¨ is present in kk and adds that (possibly weighted) 
⍝H   count to the existing value of d[k], or, if new, the value 0.  
⍝H ∘ Returns: Shyly returns the final updated (aggregate) tally for each key.
⍝H   * (If keys are duplicated, the final tally will be the same for each duplicate,
⍝H     i.e. the tallies returned are NOT incremental).
⍝H ∘ If d[k] exists, but is not numeric, a DOMAIN ERROR occurs.
⍝H   d[k] may be any numeric array; the tally is added to each element by APL rules.
⍝HR
⍝H 
    ∇ {res}← {weight} Count kk; ii; new; nkk; freq; nKEYS; ⎕TRAP    
      :Access Public
      ⎕TRAP← trap.domain ⋄ :If 900⌶⍬ ⋄ weight← 1 ⋄ :EndIf  
      kk freq← ↓⍉{ ⍺, ≢⍵ }⌸ ,kk              ⍝ Determine (unique) keys and freq.
      nKEYS← ≢KEYS 
      :If 1∊ new← nKEYS= ii← KEYS⍳ kk   
          VALS,← 0⍴⍨ ≢KEYS,← nkk← new/ kk     ⍝ Initialize  new values to 0  
          (new/ ii)← nKEYS+ ⍳⍨nkk                
      :EndIf 
      VALS[ ii ]+← freq× weight               ⍝ Update values left to right
      res← VALS[ ii ]    
    ∇
   
⍝H d.Vals:     Retrieve/Set values of items by index (respecting caller's ⎕IO)
⍝H d.Vals[ ix1 ix2 …].
⍝H (Read-only: It is not possible to set a value by index)
⍝HR
⍝H
    ∇ v← Vals 
     :Access Public
      v← VALS
    ∇
  :EndClass
  
  :Section Help Information Processing and Display
  ⍝ Help: Process and Display Help information (⍝H, ⍝Ht, etc.) above. 
  ⍝ See also Dict.Help.
    ∇ {help}← Help; cm; dict; line; lm; saved; type; E; H; V
      H← '^\h*⍝H *$' '^\h*⍝H(.*)'  ⎕S ' ' '\1'                         ⍝ Help lines
      V← '\$AUTOHASH'  ⎕R   (⍕Dict.AUTOHASH)                           ⍝ Variables
      E← {
        (⊂lm,lm,⍵),{
        0::  ⊂⎕←'****** ERROR EXECUTING EXAMPLE CODE: ',⍵ 
        85:: ⍬ ⋄ x←1(85⌶)⍵ 
          (⊂lm),¨↓⎕SE.UCMD 'disp x'
        }⍵ 
      } ⍝ Execute 
      lm← 3↑' ' ⋄ cm← 3↑'⍝'  
      saved← 3↓⎕SE.UCMD 'box on -fns=on'  
      help← ⍬
      :For type line :IN (⍬∘⍴,⍥⊂1∘↓)¨H ⎕SRC ⎕THIS 
        :Select type ⍝ '⍝H([12Ft⍝⍎ ])'
        :Case 'R' ⋄ help,← ⊂100⍴'═'  ⋄ :Case 'r' ⋄ help,← ⊂100⍴'─'     
        :Case 'f' ⋄ help,← ⊂35⍴'─'   ⋄ :Case 't' ⋄ help,← ⊂(1↓lm),line  
        :Case ' ' ⋄ help,← ⊂line     ⋄ :Case '⍝' ⋄ help,← ⊂lm,cm, line 
        :Case '⍎' ⋄ help,← E line
        :Else     ⋄ ⎕←'Help logic error: Unknown help type="',type,'" line="',line,'"'  
        :EndSelect  
      :EndFor 
      {}⎕SE.UCMD 'box',saved 
      help← ' '∘,¨ V help 
        _←⎕ED 'help' 
    ∇ 
  :EndSection 
  :EndNamespace
  