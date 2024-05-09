:Namespace ∆DClass
⍝H ∆D, ∆DL:   "Create and Manage an Ordered, Hashed Dictionary"
⍝H 
⍝H ]load ∆D   
⍝H    loads functions ∆D, ∆DL (see below) in the target directory, 
⍝H    as well as supporting services in namespace ∆DClass.
⍝H 
⍝H ∆D, ∆DL:   "Create and Manage an Ordered, Hashed Dictionary"
⍝H ∘ Create a dictionary whose items are in a fixed order based on order of creation
⍝H   (oldest first) [see Sorting below for sorted order).]
⍝H ∘ Keys are by default hashed, which leads to performance improvements especially for
⍝H   non-numeric keys.
⍝H ∘ Adding new values for existing keys does not change their order.
⍝H ∘ Keys and Values may be of any datatype.  
⍝H ∘ Sorted Order: To create a dictionary with keys in sorted order (or sorted by
⍝H   other criteria), use the FromIx or FromKey methods.
⍝H ∘ The FromIx and FromKeys methods are available to (among other things)
⍝H   select and/or sort items (based on criteria you choose) into a new dictionary,
⍝H   without affecting the original dictionary.
⍝H 
⍝H ∆D "Dictionary from Key-Value Pairs"
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯ 
⍝H d← [default] ∆D items             ⍝ items => (k1 v1)(k2 v2)…
⍝H d← [default] ∆D ⍬                 ⍝ empty dictionary
⍝H d← [default] ∆D d0.Items          ⍝ d.Items <= d0.Items (slower than ∆DL equiv.).
⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
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
⍝H ==========
⍝H Note: ∆D 'help' will display this help information.
⍝H   
⍝H ∆DL "Dictionary from a Key list and Value list"
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d← [default] ∆DL keylist vallist      ⍝ => (k1 k2…)(v1 v2…)
⍝H d← [default] ∆DL keylist (sv)         ⍝ => (k1 k2…)(sv sv…), with sv a scalar value.
⍝H d← [default] ∆DL ⍬                    ⍝ empty dictionary
⍝H d← [default] ∆DL d0.(Keys Vals)       ⍝ dict d efficiently initialized with items of d0
⍝H ¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨¨
⍝H ∘ Create a dictionary from a list of keys and corresponding values or, if there
⍝H   is a single scalar (simple or enclosed) value, make it the value for each key.
⍝H   * For keys KK and values VV, (KK=⍥≢VV)∨(1=≢VV) must be true. 
⍝H ∘ Both may be empty, resulting in an empty dictionary.
⍝H ∘ If no default is specified, then querying the values of keys that do not exist
⍝H   will cause an INDEX ERROR to be generated.
⍝H ∘ By default, new dictionaries created with ∆DL will be automatically hashed.
⍝H   That is, Dyalog hashing will be turned on for Key searches and will be re-established
⍝H   within methods that might require the hash table Dyalog maintains to be rebuilt
⍝H   (e.g. deletions of non-trailing entries). 
⍝H   ∘ Dictionaries derived from those with hashing will automatically have hashing turned on.  
⍝H   ∘ For even moderate-sized dictionaries, having the keys hashed improves performance significantly.
⍝H   ∘ This feature is enabled if the class variable AUTOHASH is 1. It is currently $AUTOHASH.
⍝H   ∘ See d.Hash and d.NoHash.
⍝H ==========
⍝H Note: ∆DL'help' will display this help information.
⍝H
⍝  *** See additional HELP info throughout the class below ***

⎕IO ⎕ML←0 1  
_TS← { ⍺←'' ⋄ ⊂⎕DMX.('EN' 'Message' 'EM',⍥⊂¨ EN Message,⊂ '^(∆D\w? )?'⎕R('∆D',⍺,' ')⊢EM)} 
Trap← ⎕SIGNAL _TS 

⍝ ##.∆D: Create from items (key-value pairs: (k1 v1)(k2 v2)…)   
⍝ dict← [default] ∇ items
⍝ 
##.∆D← ⍎'{⍺←⊢⋄ñ←', '⋄0::ñ.Trap⍬⋄⍺ñ.⍙D⍵}',⍨ ⍕⎕THIS 
⍙D←{ 
  dFlag←2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 'help'≡⎕C⍵: _← Help          
  ⎕NEW Dict (⍵ ⍺ dFlag Dict.AUTOHASH)           
}

⍝ ##.∆DL: Create from two lists: keylist and valuelist
⍝          or from a list and a scalar: keylist (scalar_value)
⍝ dict← [default] ∇ keylist valuelist
⍝ Promote to ##
##.∆DL← ⍎'{⍺←⊢⋄ñ←', '⋄0::''L''ñ.Trap⍬⋄⍺ñ.⍙DL⍵}',⍨ ⍕⎕THIS 
⍙DL←{ Err← ⎕SIGNAL {⊂'Message' 'EN',⍥⊂¨'invalid right arg shape' 11} 
    dFlag← 2=⎕NC'⍺' ⋄ ⍺←⎕NULL ⋄ 'help'≡⎕C⍵: _← Help       ⍝ ⋄ 0:: 'L'Trap⍬ 
  2≠≢⍵: Err⍬ ⋄ (⊃=⍥≢/⍵)⍱ 1=≢⊃⌽⍵: Err⍬  
    ⎕NEW Dict (⍵, ⍺ dFlag Dict.AUTOHASH)             
}

⍝ Provide help information. See also Dict.Help.
∇ {help}← Help;  R; S 
  R← '\$AUTOHASH'    ⎕R (⍕Dict.AUTOHASH)
  S← '^\h*⍝H\h?(.*)' ⎕S ' \1'
  help← ⎕ED 'help'⊣ help← R S ⊣ ⎕SRC ⎕THIS 
∇
 
:Class Dict
⍝H ┌──────────────────────────────────────────────────────────────────────────────────┐
⍝H │           Methods of class ∆D.Dict in alphabetica order by type…                 │
⍝H ├──────────────────────────────────────────────────────────────────────────────────┤
⍝H ├─ Index Methods returning elements or info ───────────────────────────────────────┤  
⍝H │  vv←d[kk]  d[kk]←vv  vv←d[]          d.ⁱᵃDef[kk]  d.⁲DelIx[ii]  d.DelIx[]        │
⍝H │  d.⁲Items[ii]        d.⁲ItemsIx[ii]  d.⁲Keys[ii]  d.⁲Vals[ii]   d.⁲Vals[ii]←vv   │ 
⍝H ├─ Simple methods returning elements or info ──────────────────────────────────────┤  
⍝H │  any←d.ⁱᵇDefault   d.ⁱᵇDefault←any   d.⁳Del kk           vv←{tdef}d.Get kk       │
⍝H │  v←{tdef}d.Get1 k  n← d.HasDefault   d.HasDefault←[1|0]  d.HashStatus            │
⍝H │  d.Help            {items}← d.Pop n   {vv}← d.Tally kk                           │
⍝H ├─ Returning dictionaries ─────────────────────────────────────────────────────────┤ 
⍝H │  Same dict:  {d}←d.Clear  {d}←d.[No]Hash  {d}←d.Import items  {d}←d.ImportL kkvv │      
⍝H │  New dict:   d2←d.Copy    d2←{tdef}d.FromKeys kk     d2← d.FromIx ii             │
⍝H ├─ Experimental (temporary)────────────────────────────────────────────────────────┤ 
⍝H │  ii← {default} d.Index kk    vv← {default} GetSet kk                             │
⍝H ├─ Abbrev. used above ─┬─────────────────────────────┬─────────────────────────────┤ 
⍝H │    kk: list of keys  │    vv: list of vals         │    ii: list of indices      │  
⍝H │     k: disclosed key │     v: disclosed val        │    ii: list of indices      │  
⍝H │  kkvv: kk vv         │ items: (k1 v1)(k2 v2)…      │   any: any val.             │ 
⍝H │     n: an integer    │  tdef: 1-time def (any val) │                             │     
⍝H ├─ Footnotes ──────────┴─────────────────────────────┴─────────────────────────────┤ 
⍝H │  ⁱᵃDef: Is item defined?                                                         │
⍝H │  ⁱᵇDefault: define/query the default value for new (missing) keys.               │
⍝H │  ⁲ DelIx, Items, ItemsIx, Keys, Vals: Each uses Index Origin (⎕IO) of caller.    │   
⍝H │  ⁳ Del: If a left arg is present and 1, all keys MUST exist.                     │
⍝H └──────────────────────────────────────────────────────────────────────────────────┘
⍝H 
⍝H ┌──────────────────────────────────────────────────────────────────────────────────┐
⍝H │  What Python methods or fns are roughly comparable (even if scalar)?             │
⍝H ├──Comparable──────────────────────────────────────────────────────────────────────┤
⍝H │  clear, copy, fromkeys, del, get, has_key [d.Def], items, keys, len,             │
⍝H │  popitem [d.Pop 1], setdefault [d.GetSet], values [d.Vals], update [d.Import],   │
⍝H │  indexing dictionary by key, etc.                                                │
⍝H ├─ Note ───────────────────────────────────────────────────────────────────────────┤ 
⍝H │  ∆D equivalents that are comparable are in UpperCamelCase like this: FromKeys.   │  
⍝H │  Where major differences obtain, the ∆D equivalents are shown in brackets.       │    
⍝H └──────────────────────────────────────────────────────────────────────────────────┘
⍝H 
 
⍝ Error Msgs: Format: EN Message, where Message may be a null string ('').
  :Namespace error ⍝ em message
      badLeftArg←    11 'Method left arg is invalid'
      badRightArg←   11 'Method right arg is invalid'
      delIxBad←       3 'Nothing deleted'  
      delKeyBad←      3 'Key(s) not found (nothing deleted)'    
      itemsBad←      11 'A list of items (key-value pairs) is required (enclose if just one)'
      keyNotFnd←      3 'Key(s) not found and no default is active'
      mismatch←       5 'Mismatched left and right argument shapes'
      noDef←          6 'Default not set or active'
      noKeys←        11 'No keys were specified'
  :EndNamespace
⍝ Default states for d.Default
  :Namespace def   
      active←       1
      quiesced←    ¯1
      none←         0
  :EndNamespace 
⍝ Traps within methods, utilities
  :Namespace trap
      index←       3 'E' '##.Trap⍬' 
      domain←     11 'E' '##.Trap⍬' 
  :EndNamespace
⍝ 
  :Field Public Shared AUTOHASH←     1     ⍝ If 1, ∆D and ∆DL will enable hashing for new dicts
                  KEYS←              ⍬     ⍝ Avoid Field, since it disrupts hashing (in 19.0)!
  :Field Private  VALS←              ⍬
  :Field Private  DEFAULT_V←       ⎕NULL ⍝ Placeholder: ignored if DEFAULT_S=def.none.
  :Field Private  DEFAULT_S← def.none  ⍝ See namespace <def>
  :Field Private  HASH_SET←          0     ⍝ If 1, set hash where required. See d.Hash, internal CheckRehash
 
⍝ ErrIf: Internal helper. Usage:  en msg ErrIf bool 
⍝     ⍺: Message (default: ''), ⍵: Error #. 
⍝     No error if ⍵ is ⍬.
  ErrIf← ⎕SIGNAL {~⍵: ⍬ ⋄ ⊂'EN' 'Message' 'EM',⍥⊂¨ ⍺,⊂'∆D ',⎕EM ⊃⍺}

  ∇ makeFill                             ⍝ Create an empty dict with no DEFAULT_V 
    :Implements constructor 
    :Access Public 
    ⎕DF '∆D0[Dict+null]'
  ∇ 

  ∇ makeItems (ii dVal dFlag hFlag)      ⍝ Create dict from Items and opt'l Default
    ;kk; vv; kkvv                   
    :Implements constructor
    :Access Public
    :If 0= ≢ii 
        ⍝ no values
    :Elseif 2=≢kkvv← ,¨(↓∘⍉↑∘,) ii
        kk vv← kkvv 
        ValsByKey[kk]←vv 
    :Else 
        error.itemsBad ErrIf 1 
    :EndIf  
    DEFAULT_V DEFAULT_S ← dVal dFlag 
    :IF hFlag ⋄ Hash ⋄ :Endif 
    ⎕DF '∆D[Dict+items',(dFlag/'+default'),(hFlag/'+hash'),']' 
  ∇

  ∇ makeLists (kk vv dVal dFlag hFlag)     ⍝ Create dict from Keylist Valuelist and opt'l Default  
    :Implements constructor    ⍝ If h=0, the DEFAULT_V is NOT set.
    :Access Public
    :If 1=≢vv ⋄ vv⍴⍨← ⍴kk ⋄ :EndIf    ⍝ Conform vv to kk, if vv is a singleton.
    ValsByKey[kk]←vv  
    DEFAULT_V DEFAULT_S← dVal dFlag 
    :IF hFlag ⋄ Hash ⋄ :Endif 
    ⎕DF '∆D[Dict+list',(dFlag/'+default'),(hFlag/'+hash'),']' 
  ∇

⍝H d[k1 k2 …], 
⍝H d[k1 k2 …]← v1 v2 …
⍝H d[]
⍝H Retrieve or set specific values of the dictionary by key.
⍝H You can also retrieve (but not set) all values via d[]. 
⍝H See also 
⍝H    d.Vals[]              ⍝ Retrieve values by Index
⍝H    d.Get, and d.Get1.    ⍝ Retrieve values by key with an optional ad hoc default.
⍝H 
  :Property Default Keyed ValsByKey 
  :Access Public
    ∇ vv←get args; ii; kk; old 
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          vv← VALS                            ⍝ Grab all values if d[] is specified.
      :Else 
          old← (≢KEYS)≠ ii← KEYS⍳ kk
          :If ~0∊ old                         ⍝ All keys old? 
              vv← VALS[ ii ]                  ⍝ … Just grab existing values.
          :Else                               ⍝ Some old and some new keys.
              ⋄ error.keyNotFnd ErrIf DEFAULT_S≠ def.active  ⍝ … error unless we have a DEFAULT_V;
              vv← (≢kk)⍴ ⊂DEFAULT_V             ⍝ … where new, return DEFAULT_V;
              vv[ ⍸old ]← VALS[ old/ ii ]     ⍝ … where old, return existing value.
          :Endif 
          vv ⍴⍨← ⍴kk                          ⍝ If kk is a scalar, we must return a scalar!
      :Endif  
    ∇
  ⍝ ValsByKey "set" function
  ⍝ Note: Regarding which values to use when there are duplicate keys being set:
  ⍝   we add new keys keeping the leftmost duplicate (as expected for dict ordering);
  ⍝   we add new values keeping the rightmost duplicate value (consistent with APL indexing).
    ∇ set args; kk; ii; new; vv; nKEYS   
      kk← ,⊃args.Indexers 
      vv← ,args.NewValue 
      ⋄ error.noKeys ErrIf ⎕NULL≡ kk           ⍝ d[]← … NOT ALLOWED.
      kk vv← ↓⍉{ ⍺, vv[⊃⌽⍵] }⌸ kk              ⍝ Handles duplicate and new keys.
      nKEYS← ≢KEYS  
      :IF 1∊ new← nKEYS= ii← KEYS⍳ kk          ⍝ New Keys…
          VALS,← 0⍴⍨ ≢KEYS,← nkk← new/ kk      ⍝ Add placeholder for each new val 
          (new/ ii)← nKEYS+ ⍳⍨nkk              ⍝ Add new key indices
      :EndIf 
      VALS[ ii ]← vv                           ⍝ Update all values, replacing any placeholders 
    ∇ 
  :EndProperty

  ⍝H {d}← d.Clear
  ⍝H Remove all items (keys and values) from the dictionary,
  ⍝H preserving the default value (Default) and hashing status.
  ⍝H Shyly returns the dictionary.
  ⍝H 
    ∇{d}← Clear 
      :Access Public 
      d← ⎕THIS ⋄ KEYS←VALS← ⍬ ⋄ CheckRehash 
    ∇

  ⍝H d2← d.Copy
  ⍝H Make a copy of dictionary d, including the Keys and Vals, as well as the 
  ⍝H default and hash settings.
  ⍝H 
  ∇ d2← Copy; def  
    :Access Public 
    d2← ⎕NEW Dict (KEYS VALS DEFAULT_V DEFAULT_S HASH_SET)  
    d2.⎕DF ⍕⎕THIS 
  ∇

⍝H bb← d.Def[k1 k2…]        "Are keys k1 k2…  defined in Keys?"
⍝H Returns a 1 for each key (k1, etc.) defined in Keys and a 0 otherwise.
⍝H 
  :Property Keyed Defined, Def 
  :Access Public
    ∇ bb←get args; kk 
      ⋄ error.noKeys ErrIf ⎕NULL≡ kk← ⊃args.Indexers 
      bb← ⊂⍣ (0= ⊃⍴⍴kk)⊢ (≢KEYS)≠ KEYS⍳ kk 
    ∇
  :EndProperty

⍝H d.Default
⍝H d.Default← any_value 
⍝H Retrieve or set/redefine the default value for missing dictionary items
⍝H (those requested by key that do not exist).
⍝H If you set a default, HasDefault is automatically set to 1.
⍝H 
  :Property Simple Default
  :Access Public
    ∇ d←get 
      ⋄ error.noDef ErrIf DEFAULT_S≠ def.active
      d← DEFAULT_V 
    ∇
    ∇ set new  
      DEFAULT_S DEFAULT_V← def.active new.NewValue 
    ∇
  :EndProperty 

⍝H bb← d.Del: Delete items by keyword (k1 k2…)
⍝H bb← [required←0*] d.Del k1 k2…     ⍝ If missing keys are seen, they are ignored.
⍝H bb← [required←1]  d.Del k1 k2…     ⍝ If missing key are seen, an error is signaled.
⍝H Delete items from the dictionary by key.
⍝H ∘ Duplicate keys allowed.
⍝H ∘ Returns 1 for each entry found and deleted, else 0.
⍝H ∘ If the left arg is present and 1, all items MUST exist.
⍝H
    ∇ {bb}← {required} Del kk; ii; err; msg  
       :Access Public
      :If 0=≢kk ⋄ bb←⍬ ⋄ :Return ⋄ :EndIf       ⍝ Nothing to do... 
      bb← (≢KEYS)≠ ii← KEYS⍳ kk                 ⍝ Get indices of keys 
      :If 0∊ bb ⋄ :AndIf ~900⌶⍬                 ⍝ Some missing, but required?
          ⋄ error.badLeftArg ErrIf required(~∊) 0 1
          ⋄ error.delKeyBad  ErrIf required             
      :EndIf 
      :IF 1∊ bb                         
          ⋄ ErrIf/ 0 ⍙DelIx ∪bb/ ii              ⍝ Delete by index…
      :EndIf 
      bb⍴⍨← ⍴kk                                  ⍝ Scalar in, scalar out
    ∇
    
⍝H d.DelIx: Delete items by index (per caller's ⎕IO), returning prior value.
⍝H   items← d.DelIx[i1 i2…]      ⍝ Entries at [i1 i2…] returned and deleted 
⍝H   items← d.DelIx[]            ⍝ All entries returned and deleted
⍝H Delete items in the dictionary by index.
⍝H Returns all items indexed after deleting them from the dictionary.
⍝H ∘ All indexed items must exist, else INDEX ERROR. 
⍝H ∘ Duplicate indices ok: items at the indices specified are returned.
⍝H See also: d.Pop N
⍝H 
  :Property Keyed DelIx 
  :Access Public
    ∇ items←Get args; ii; ei; nK  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          items← Items[] ⋄ Clear   
      :Else 
          items err← 1 ⍙DelIx ii-(⊃⎕RSI).⎕IO   ⍝ Adjust for caller's ⎕IO   
          ⋄ items ErrIf err  
      :Endif 
    ∇
  :EndProperty

  ⍝ ret← ⍙DelIx ii     (Internal helper function)
  ⍝   Delete items for indices specified (which must exist per ⎕IO=0); duplicate items ok.
  ⍝ On success:
  ⍝   ∘ If ⍺=1: returns:   (the items deleted) 0. 
  ⍝   ∘ If ⍺=0: returns:   ii 0.   
  ⍝ If an index error occurs: 
  ⍝   ∘         returns:   (error.object) 1
  ⍝ Note: if all items to delete are in a contiguous trailing block of keys (possibly repeated),
  ⍝       they are deleted via drop (↓); hashing will be maintained automatically (if set).     
  ⍝                    
    ⍙DelIx←{  
      3:: error.delIxBad 1 
          ret← ⍺ { ⍺: ↓⍉↑ KEYS VALS⌷⍨¨ ⊂⊂⍵ ⋄ ⍵ } ii←⍵ 
          blok← -+/∧\⌽bb← 1@ ii⊣ 0⍴⍨ ≢KEYS      ⍝ catches index errors   
    ⍝ If all items are in a contig. trailing block, remove via ↓⍨←, which preserves any hashing.   
      1(~∊) bb↓⍨ blok: ret 0⊣ KEYS↓⍨← VALS↓⍨← blok  
        ⍝ Remove items to delete by indexing (depends on ix errors being caught above)
          KEYS/⍨← VALS/⍨← ~bb                  ⍝ Assign separately to maintain any hashing of KEYS      
          ret 0 ⊣ CheckRehash   
    }

⍝H d.FromKeys:  Create a new dictionary from the keys specified, with their values.
⍝H   Useful for things like sorting entries according to keys (or values),
⍝H   without modifying the entries themselves in any way.
⍝H d2← {tempDef} d.FromKeys kk
⍝H ∘ Returns a new dictionary including the items from d which contain the keys kk,
⍝H   but in the order selected.
⍝H ∘ Missing keys trigger an Index Error (Keys not found) unless a default has been set,
⍝H   either as a dict-wide default or via tempDef, the left argument to d.FromKeys.
⍝H ---------------
⍝H d.FromKeys can be easily used to sort items into a new dictionary…
⍝H   b←a.(FromKeys Keys[⍋   Keys])  ⍝ Sort by key in ascending order.
⍝H   b←a.(FromKeys Keys[⍒   Keys])  ⍝ Sort by key in descending order
⍝H   b←a.(FromKeys Keys[⍋   Vals])  ⍝ Sort by value(!!) in ascending order.
⍝H   b←a.(FromKeys Keys[⍋⎕C Keys])  ⍝ Sort by folded keys in ascending order
⍝H   b←a.(FromKeys Keys[⍋|  Keys])  ⍝ Sort numeric keys in ascending order by absolute value
⍝H See also: d.FromIx
⍝H 
∇ d2← {tempDef} FromKeys kk; ⎕TRAP  
  :Access Public 
  ⎕TRAP← trap.index          ⍝ Error number expected: 3 (⊃error.keyNotFnd)
  :If 900⌶⍬ ⋄ tempDef← ⊢ ⋄ :EndIf 
  d2← Copy.Clear.ImportL kk (tempDef Get kk)
∇

⍝H d.FromIx:    Create a new dictionary from the indices specified (which must be in range).
⍝H   Useful for things like sorting entries according to keys (or values),
⍝H   without modifying the entries themselves in any way.
⍝H d2← d.FromIx ii
⍝H ∘ Returns a new dictionary including only the items from d at indices ii,
⍝H   but in the index order presented. 
⍝H   * Repeated indices are ignored.
⍝H   * Indices out of range trigger an Index Error.
⍝H ---------------
⍝H d.FromIx can be easily used to sort items into a new dictionary…
⍝H   b←a.(FromIx ⍋   Keys)  ⍝ Sort by key in ascending order.
⍝H   b←a.(FromIx ⍒   Keys)  ⍝ Sort by key in descending order
⍝H   b←a.(FromIx ⍋   Vals)  ⍝ Sort by value(!!) in ascending order.
⍝H   b←a.(FromIx 5↑⍒ Keys)  ⍝ Sort by key in descending order and keep the top 5 (5≤≢a.Keys).
⍝H   b←a.(FromIx ⍋⎕C Keys)  ⍝ Sort by folded keys in ascending order
⍝H   b←a.(FromIx ⍋|  Keys)  ⍝ Sort numeric keys in ascending order by absolute value
⍝H See also: d.FromKeys. 
⍝H   d.FromIx is typically up to 10% faster than d.FromKeys across a range of dictionary sizes.
⍝H 
∇ d2← FromIx ii; ⎕TRAP 
  :Access Public 
  ⎕TRAP← trap.index 
  d2← Copy.Clear.ImportL KEYS VALS⌷⍨¨⊂⊂∪ii 
∇

⍝H d.Get:   Retrieve values for one or more keys.
⍝H v1 v2…← d.Get k1 k2…             ⍝ One or more keys (present a list, returns a list)
⍝H v1 v2…← default d.Get k1 k2…    
⍝H ∘ If a default is not specified, all keys must be currently defined (else Index Error)
⍝H   unless a global default has been set (e.g. when the dictionary was created). 
⍝H ∘ If a default is specified, it will be used for all keys not in the dictionary,
⍝H   independent of any global default value set.
⍝H ---------------
⍝H Note: d.Get is equivalent to d[xxx] key-based indexing, except d.Get allows a temporary  
⍝H       default value either when the dictionary otherwise lacks a default or when the   
⍝H       general default is not appropriate in this case.
⍝H 
∇ vv← {tempDef} Get kk; noDef; ii; bb 
  :Access Public
  ii← KEYS⍳ kk
  :If 0∊ bb← ii≠ ≢KEYS                         ⍝ If 'tempDef' isn't set, use DEFAULT_V (if set).
      :If noDef← 900⌶⍬ ⋄ :AndIf DEFAULT_S= def.active   
          tempDef noDef← DEFAULT_V def.none      ⍝ Else, there's no tempDef to use.
      :EndIf    
      ⋄ error.keyNotFnd ErrIf noDef 
      vv← (≢kk)⍴ ⊂tempDef                      ⍝ vv: assume default for each;
      vv[ ⍸bb ]← VALS[ bb/ii ]                 ⍝     use "old" values where defined. 
  :Else 
      vv← VALS[ ii ]
  :Endif 
∇

⍝H d.Get1:   Retrieve a (disclosed) value for exactly one (disclosed) Key.
⍝H v1← [tempDef] d.Get1 k1          ⍝ One key (present a value, returns a value)
⍝H Like d.Get, but retrieves the value* for exactly one key*. 
⍝H    d.Get1 'myKey' <==>  ⊃d.Get ⊂'myKey'                    
⍝H Note: [*] Neither the key passed nor the return value is enclosed.
⍝H *** See also the note at d.Get (above).
⍝H
∇ v1← {tempDef} Get1 k1; ⎕TRAP   
  :Access Public       
  ⎕TRAP← trap.index 
  :IF 900⌶⍬ ⋄ tempDef← ⊢ ⋄ :EndIf 
  v1← tempDef Get ⊂k1  
∇ 

⍝H d.HasDefault 
⍝H d.HasDefault← [1|0]
⍝H Retrieve or set the current Default status. 
⍝H - If you set HasDefault to 1, 
⍝H   the prior default (if any) is restored;
⍝H   ∘ If no default exists, HasDefault remains 0 and a VALUE ERROR is generated. 
⍝H - If you set HasDefault to 0, 
⍝H   any attempt to access an item that doesn't exist will cause a VALUE ERROR to 
⍝H   be signalled, until you reset HasDefault to 1.
⍝H 
  :Property Simple HasDefault 
  :Access Public
    ∇ b←get 
      b← def.active= DEFAULT_S 
    ∇
    ∇ set new; d   
       :If 1≠≢d← new.NewValue :OrIf d (~∊) 0 1 ⋄ 11 ''ErrIf 1 ⋄ :EndIf 
       :If d 
          ⋄ error.noDef ErrIf def.none= DEFAULT_S 
          DEFAULT_S← def.active 
       :Else 
          DEFAULT_S×← def.quiesced
       :EndIf 
    ∇
  :EndProperty 

⍝H d.Hash:    Turns on hashing,  if not already. (Default for ∆D and ∆DL dictionaries)
⍝H d.NoHash   Turns off hashing, if not already.
⍝H {d}← d.Hash 
⍝H Turns on hashing and shyly returns the hash itself:
⍝H ∘ Set the flag HASH_SET to 1 and mark the vector KEYS as a Dyalog hashtable, 
⍝H   so it can be searched faster. This creates some overhead, but searches of (large) 
⍝H   key vectors can be done in O(1) time, rather than O(N).
⍝H ∘ When set, hashing is established immediately and re-established when a delete or 
⍝H   clear takes place.
⍝H ∘ Hashing generally affects performance positively, and will use up space proportional
⍝H   to the dictionary size, but is otherwise transparent.
⍝H 
⍝H {d}← d.NoHash
⍝H Turns off hashing for the dictionary keys, shyly returning the dict itself.
⍝H ∘ This ensures there is no hashing, for things like performance tests.
⍝H ∘ In general, there should be no need to turn off hashing, and there is overhead in
⍝H   ensuring hashing is off. 
⍝H See d.Hash.
⍝H 
  ∇ {d}← Hash
    :Access Public
    d← ⎕THIS ⋄ :If ~HASH_SET ⋄ KEYS← 1500⌶KEYS ⋄ HASH_SET← 1 ⋄ :EndIf   
  ∇
  ∇ {d}← NoHash
    :Access Public               ⍝  ⊃⊂KEYS: Undo hashing of KEYS
    d← ⎕THIS ⋄ :If HASH_SET ⋄ KEYS← ⊃⊂KEYS ⋄  HASH_SET← 0 ⋄ :EndIf   
  ∇

⍝H d.HashStatus: Returns the current hash status of the dictionary.
⍝H The return format is:  int msg 
⍝H    int     msg
⍝H    0    NOT HASHED           (this dictionary has NoHash set explicitly or implicitly)
⍝H    1    HASH ENABLED         (no searches yet, so hash table not yet built)
⍝H    2    HASH ACTIVE          (hash table built and in use)
⍝H HashStatus verifies that the hash setting is consistent with the Dyalog hash status returned.
⍝H This is checked since hashing is disabled by certain operations.
⍝H 
  ∇ status← HashStatus; s; m 
    :Access Public
  ⍝ Consistency check for HASH_SET and actual hash setting for KEYS
    :If HASH_SET≠ ×s← 1(1500⌶)KEYS  
        m← 'HASH_SET=',(⍕HASH_SET),', 1(1500⌶)KEYS)=',⍕s 
        911 ⎕SIGNAL⍨ 'Logic Error: Hash setting and (1500⌶) status are inconsistent: ',m 
    :EndIf 
    status← s (s⊃ 'NOT HASHED' 'HASH ENABLED' 'HASH ACTIVE') 
  ∇
  
  ∇ {h}← CheckRehash
  ⍝ Forces KEYS to be rehashed no matter what, if HASH_SET.
  ⍝H Returns 1 if it rehashed; else 0 (either HASH_SET=0 or keys already hashed).
  ⍝ Used only when hashing is known to be off or disrupted (deleting non-trailing keys, etc)
    :Access Private
    :If HASH_SET ⋄ :AndIf 0=1(1500⌶)KEYS  
        h←1 ⋄ KEYS← 1500⌶KEYS 
    :Else 
        h←0 
    :EndIf
  ∇ 
 
⍝H d.Help
⍝H Provide help information.
⍝H See also: ∆D'help', ∆DL'help' for identical information.
⍝H 
  ∇ {ok}← Help
  :Access Public Shared
    ok← ##.Help 
  ∇

⍝H d.Import (items), d.ImportL (keylist vallist)
⍝H {d}←  d.Import  items            ⍝(k1 v1)(k2 v2)…
⍝H {d}←  d.ImportL keylist vallist 
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H d.Import adds items (k1 v1)(k2 v2)… to the dictionary in order left to right.
⍝H    This is equivalent to {d[ kk ]← vv ⊣ kk vv← ↓⍉↑⍵} items
⍝H d.ImportL adds a key list and a matched value list to the dictionary in order left to right.
⍝H    This is equivalent to d[ keylist ]← vallist.
⍝H To clear the existing keylist vallist and quickly import new ones, do 
⍝H    d.Clear.ImportL keylist vallist  
⍝H This can be useful for a specialized sort "in place" (really: in the same dict.)
⍝H ∘ Re-sort numeric keys by absolute value (keeping the keys themselves intact)
⍝H   d.Clear.ImportL d.(Keys Vals)⌷⍨¨⊂⊂⍋|d.Keys
⍝H ∘ If the dictionary is empty, import efficiently sets the KEYS and VALS to the input args. 
⍝H ∘ In all cases, keys are inserted based on the first (leftmost) instance and 
⍝H   values are updated based on the rightmost of the key as expected for APL indexing. 
⍝H ∘ What if I want to import all the items from a dictionary myD?
⍝H   d.ImportL myD.(Keys Vals)   ⍝ Faster
⍝H   d.Import  myD.Items         ⍝ Slower
⍝H See also d.FromKeys, d.FromIx 
⍝H 
  ∇ {d}←  Import (items) ; kkvv; kk; vv 
    :Access Public
    d← ⎕THIS 
    kkvv← ,¨↓⍉↑ items ⋄ error.itemsBad ErrIf 2≠ ≢kkvv 
    kk vv← kkvv 
    ValsByKey[kk] ← vv        ⍝ Handle old, new, and duplicate keys
  ∇
  ∇ {d}←  ImportL (kk vv)
    :Access Public
    d← ⎕THIS 
    :If 1=≢vv ⋄ vv⍴⍨← ≢kk ⋄ Else ⋄ error.mismatch ErrIf kk≠⍥≢vv ⋄ :EndIf   
    ValsByKey[kk] ← vv        ⍝ Handle old, new, and duplicate keys
  ∇

⍝H d.Index    [experimental]
⍝H ii← {default} d.Index kk
⍝H ∘ If there's a default:
⍝H   Return the indices of items for all the keys specified, including those that are new.
⍝H   (New items are added with value ¨default¨).
⍝H ∘ If there is no default:
⍝H   Returns the indices of keys specified, if all exist.
⍝H   Signals an INDEX error, if any keys do not already exist.
⍝H ∘ Useful for multiple, efficient manipulations of the same items.
⍝H * Similar to Python "setdefault" method, which returns the value of a single existing item 
⍝H   with the specified key or a single new item, with the default value specified, after 
⍝H   inserting the item. 
⍝H   * To match this simple Python example,
⍝H        x = empl.setdefault("start_date", "today")
⍝H     do:
⍝H        x←  empl.Vals[ 'today' empl.Index 'start_date' ]
⍝H 
⍝H vv← {default} GetSet kk
⍝H     Returns the values for all keys kk. If any keys are new, either
⍝H     a) If default is defined:  set values for the new keys to default before returning;
⍝H     b) If default is NOT defined: signal an INDEX ERROR.
⍝H 
  ∇ vv← {default} GetSet kk; ⎕TRAP  
    :Access Public
    ⎕TRAP← trap.index 
    :IF 900⌶⍬ ⋄ default← ⊢ ⋄ :EndIf 
    vv← VALS⌷⍨  ⊂default _Index kk 
  ∇
  ∇ ii← {default} Index kk; ⎕TRAP   
    :Access Public
    ⎕TRAP← trap.index 
    :IF 900⌶⍬ ⋄ default← ⊢ ⋄ :EndIf 
    ii← default  _Index kk  
  ∇
  _Index←{ 
      noalph← 0=⎕NC '⍺'
      nKEYS← ≢KEYS
    1(~∊) new← nKEYS= ii← KEYS⍳ ⍵: ii 
    noalph: error.keyNotFnd ErrIf 1 
      ukk← ∪nkk← new/kk  
      (new/ ii)← nKEYS+ ukk⍳ nkk 
      KEYS,← ukk         
      VALS,← (≢ukk)⍴ ⊂⍺
      ii 
  }

⍝H items← d.Items                 Caller ⎕IO is honored.
⍝H Retrieve all items of the dictionary as key-value pairs. 
⍝H Note: All items are generated on the fly, so d.Items[ii] can be inefficient for
⍝H       large dictionaries. See d.ItemsIx[ii].
⍝H (Items are read-only)
⍝H 
  :Property Simple Items,Item 
  :Access Public 
    ∇ items← Get
      items← ↓⍉↑KEYS VALS
    ∇
  :EndProperty

⍝H items← d.ItemsIx[ ii ]          Caller ⎕IO is honored.
⍝H Retrieve selected items of the dictionary by index as key-value pairs. 
⍝H Note: All items are generated on the fly, so d.ItemsIx[ ii ] is a more efficient 
⍝H       way to gather select items from a large dictionary than d.Items[ ii ].
⍝H (Items are read-only)
⍝H 
 :Property Keyed ItemsByIndex,ItemsIx 
  :Access Public
    ∇ items← Get args; ii;⎕TRAP 
      ⎕TRAP← trap.index  
      :If ⎕NULL≡ ii← ⊃args.Indexers 
         items← { 0= ⍵: ⍬ ⋄ ↓⍉↑KEYS VALS } ≢KEYS 
      :Else 
        items← ↓⍉↑KEYS VALS⌷⍨¨ ⊂⊂ii-(⊃⎕RSI).⎕IO  
      :Endif 
    ∇
  :EndProperty

⍝H kk← d.Keys
⍝H Retrieve all the keys of the dictionary. (Keys are read-only)
⍝H 
  :Property Simple Keys 
  :Access Public
    ∇ kk←Get
      kk← KEYS  
    ∇
  :EndProperty

⍝H d2← d.New
⍝H Make a new dictionary that is completely pristine: no entries, default, or hashing.
⍝H You may add characteristics via dictionary methods like Hash, Clear, and ImportL:
⍝H   d2← d.New.Hash
⍝H   d2← d.New.Hash.ImportL keylist vallist
⍝H   d2← d.New ⋄ d2.Default← ¯1
⍝H See d.Copy, d.Clear, d.Import, d.ImportL.
⍝H 
  ∇ d2← New 
    :Access Public 
    d2← ⎕NEW Dict   
  ∇

⍝H d.Pop    Remove and return a contiguous selection of ¨n¨ of the most 
⍝H          recent items in the dictionary (n, a positive integer).
⍝H {items}← d.Pop n
⍝H Remove and shyly return the last <n> items from the dictionary;
⍝H if no items to return, returns ⍬.
⍝H   n: a single non-negative integer. 
⍝H If n exceeds the # of items, the actual items are returned (no padding is done).
⍝H 
  ∇{items}← Pop n; p; ⎕TRAP 
    :Access Public     
    ⎕TRAP← trap.domain ⋄ ⎕SIGNAL 11/⍨ n<0      ⍝ Catch Pop ¯1 etc here.
    items← ↓⍉↑ KEYS VALS↑⍨¨ p← - n⌊ ≢KEYS      ⍝ Other domain errors caught here
    KEYS↓⍨← VALS↓⍨← p                          ⍝ Keep any hashing for KEYS intact   
    :If 0= ≢items ⋄ items← ⍬ ⋄ :EndIf 
  ∇

⍝H d.Tally    Count the # of instances of each key passed, incrementing the key's value by that count.
⍝H {res}← d.Tally kk
⍝H   kk:  1 or more keys, which (a) may be duplicates in any order and (b) may be new to d.
⍝H ∘ Counts how many times each key ¨k¨ is present in kk and adds that count to the existing
⍝H   value of d[k], or 0, if new. 
⍝H ∘ Returns: Shyly returns the final updated (aggregate) tally for each key.
⍝H   * (If keys are duplicated, the final tally will be the same for each duplicate)
⍝H ∘ If d[k] does not yet exist, the count becomes the new value of d[k]
⍝H   (as if the prior value had been 0), ignoring any default for the dict.
⍝H ∘ If d[k] exists and is not numeric, a DOMAIN ERROR occurs.
⍝H 
  ∇ {res}← Tally kk; ii; new; nkk; freq; nKEYS; ⎕TRAP    
    :Access Public
    ⎕TRAP← trap.domain
    kk freq← ↓⍉{ ⍺, ≢⍵ }⌸ ,kk                ⍝ Determine (unique) keys and freq.
    nKEYS← ≢KEYS 
    :If 1∊ new← nKEYS= ii← KEYS⍳ kk   
        VALS,← 0⍴⍨ ≢KEYS,← nkk← new/ kk       ⍝ Initialize  new values to 0  
        (new/ ii)← nKEYS+ ⍳⍨nkk                
    :EndIf 
    VALS[ ii ]+← freq                         ⍝ Update values left to right
    res← VALS[ ii ]    
  ∇
 
⍝H d.Vals     Retrieve values by index (via caller's ⎕IO)
⍝H d.Vals[ ix1 ix2 …], 
⍝H d.Vals[ ix1 ix2…]← val1 val2…
⍝H d.Vals                     ⍝ Retrieve all vals 
⍝H d.Vals← val1 val2…         ⍝ Obscure, but valid, if (≢val1 val2…)≡≢d.Vals
⍝H Synonym: d.ValsIx, d.ValsByIx
⍝H Retrieve or set specific values in the dictionary by index (caller's ⎕IO).
⍝H You may also retrieve ALL the values using d.Vals[] or simply d[].
⍝H 
  :Property Numbered ValsByIx, ValsIx, Vals  
  :Access Public
    ∇ v←get args; ii
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          v← VALS
      :Else   
          ⋄ 3 ''ErrIf 0∊ ii< ≢KEYS 
          v← VALS[ii]
      :EndIf 
    ∇
    ∇ set args; ii
      ii← ⊃args.Indexers 
      ⋄ 3 '' ErrIf 0∊ ii< ≢KEYS 
      VALS[ii]← args.NewValue 
    ∇
    ∇ s←Shape
      s← ⍴KEYS 
    ∇
  :EndProperty

:EndClass
:EndNamespace
