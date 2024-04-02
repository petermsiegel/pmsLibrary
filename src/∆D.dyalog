:Namespace ∆DClass

⎕IO ⎕ML←0 1 
∆D←{⍺←⊢ ⋄ ⎕NEW Dict (⍺,⍥⊂↓⍉↑⍵) }
##.∆D← ⎕THIS.∆D 

:Class Dict
  :Field Private  KEYS←       ⍬
  :Field Private  VALS←       ⍬
  :Field Private  DEFAULT
  :Field Private  HAS_DEFAULT← 0  

  ∇ make0
  :Implements constructor 
  :Access Public 
  ∇ 
  ∇ make1 (kkvv)
  :Implements constructor
    :Access Public
    KEYS VALS←  kkvv
  ∇
  ∇ make2 (d kkvv)
  :Implements constructor
  :Access Public
    KEYS VALS← kkvv 
    DEFAULT HAS_DEFAULT← d 1
  ∇

  ∇ {vv}← Import (kk vv)
  ⍝H d.Import keylist vallist 
  ⍝H add new (or existing) entries via lists of KEYS and values
    :Access public
    KEYS[ kk ]← vv 
  ∇

  :Property Simple Keys 
  :Access Public
  ⍝ kk← d.Keys
  ⍝ Retrieve all the keys of the dictionary. (Keys are read-only)
    ∇ kk←Get
      kk← KEYS  
    ∇
  :EndProperty

  ⍝ For Vals, see "ValsByIx, Vals" below

  :Property Simple Items
  ⍝H i← d.Items
  ⍝H Retrieve all items (key-value pairs) of dictionary. (Items are read-only)
  :Access Public
    ∇ i←Get
      i← ↓⍉↑ KEYS VALS 
    ∇
  :EndProperty

  :Property Default Keyed ValuesByKey
  ⍝H d[k1 k2 ...], 
  ⍝H d[k1 k2 ...]← v1 v2 ...
  ⍝H d[]
  ⍝H Retrieve or set specific values of the dictionary by key.
  ⍝H You can also retrieve all values via d[]. See also d.Values[]
  :Access Public
    ∇ r←get args; k
      :If ⎕NULL≡ kk← ⊃args.Indexers 
          r← VALS   
      :Else 
        ii← KEYS⍳ kk
        :If 1∊ new← ii≥ ≢KEYS   
            ⎕SIGNAL 3/⍨ ~HAS_DEFAULT
            r← 0⍴⍨ ≢kk 
            :IF 1∊new 
                r← (⊂DEFAULT)@ (⍸new)⊣ r 
            :Endif
            :If 0∊ old 
                r← VALS[ old/ii ]@ (⍸old← ~new)⊣ r 
            :Endif 
        :Else 
            r← VALS[ ii ]
        :Endif 
        r← ⊂⍣ (0=⊃⍴⍴kk)⊢ r
      :Endif  
    ∇
    ∇ set args;i;m
      ii← KEYS⍳ kk← ⊃args.Indexers 
      old← ~new← ii≥ ≢KEYS 
      VALS[ old/ii ]← old/ args.NewValue
      :If 1∊ new 
          KEYS VALS,← (⊂new)/¨ kk args.NewValue 
      :EndIf 
    ∇
  :EndProperty

  :Property Numbered ValsByIx, Vals  
  ⍝H d.Vals[ ix1 ix2 ...], 
  ⍝H d.Vals[ ix1 ix2...]← val1 val2...
  ⍝H d.Vals[].
  ⍝H Retrieve or set specific values in the dictionary by index (0-origin).
  ⍝H You may also retrieve all the values via d.Vals[]. See also d[].
  :Access Public
    ∇ r←get args; ii 
      :If ⎕NULL≡ ii← ⊃args.Indexers 
          r← VALS
      :Else   
        ⎕SIGNAL 3/⍨ 0∊ ii< ≢KEYS 
        r← VALS[ii]
        ⍝r← ⊂⍣ (0=⊃⍴⍴ii)⊢ r 
      :EndIf 
    ∇
    ∇ set args;i;m
      ii← ⊃args.Indexers 
      ⎕SIGNAL 3/⍨ 0∊ ii< ≢KEYS 
      VALS[ ii ]← args.NewValue 
    ∇
    ∇ r←Shape
      r← ⍴KEYS 
    ∇
  :EndProperty

  :Property Keyed DelByKey, Del 
  ⍝H d.Del[k1 k2...]
  ⍝H Delete items in the dictionary by key.
  ⍝H Returns 1 for each item in range, else 0.
  ⍝H If all items must exist, use d.Validate first.
  :Access Public
    ∇ r←Get args; ii; kk; old 
      ⎕SIGNAL 11/⍨ ⎕NULL≡ kk←⊃args.Indexers
      old← (≢KEYS)> ii← KEYS⍳ kk 
      KEYS VALS/⍨← ⊂~(⍳≢KEYS)∊ old/ii 
      r← old⍴⍨ ⍴kk
    ∇
  :EndProperty

  :Property Keyed Validate, Valid  
  ⍝H r← d.Validate[k1 k2...]
  ⍝H Validate that all keys specified are in the dictionary, returning 1 for each.
  ⍝H (If no keys are specified, returns a scalar 1 as well).
  ⍝H Signals a VALUE ERROR otherwise.
  :Access Public
    ∇ r←Get args; kk 
      :If  ⎕NULL≡ kk←⊃args.Indexers
           r← ⍬
      :Else 
           ⎕SIGNAL 6/⍨ 1∊ (≢KEYS)≤ KEYS⍳ kk 
          r← 1⍴⍨ ⍴kk  
      :EndIf 
    ∇
  :EndProperty

  :Property Keyed DelByIndex, DelIx 
  ⍝H d.DelIx[i1 i2...]
  ⍝H Delete items in the dictionary by index.  
  ⍝H Returns 1 for each item in range, else 0.
  :Access Public
    ∇ r←Get args; ii; old 
      ii← ⊃args.Indexers 
      ⎕SIGNAL 11/⍨ ⎕NULL≡⊃args.Indexers
      old← (≢KEYS)> ii
      KEYS VALS/⍨← ⊂~(⍳≢KEYS)∊ old/ii 
      r← old⍴⍨ ⍴ii
    ∇
  :EndProperty

  ⍝H r← d.Clear
  ⍝H Remove all entries (keys and values) from the dictionary.
  ⍝H Shyly returns the # of entries deleted.
   ∇{r}← Clear 
     :Access Public 
     r← ≢KEYS 
     KEYS←VALS← ⍬
   ∇

  :Property Simple Default
  ⍝H d.Default← any_value 
  ⍝H Set (or redefine) the default value for missing dictionary entries
  ⍝H (those requested by key that do not exist).
  ⍝H If you set a default, HasDefault is also set. 
  :Access Public
    ∇ r←get 
      ⎕SIGNAL 6/⍨ ~HAS_DEFAULT 
      r← DEFAULT 
    ∇
    ∇ set def  
      HAS_DEFAULT DEFAULT← 1 def.NewValue 
    ∇
  :EndProperty 

  :Property Simple HasDefault 
  ⍝H d.HasDefault, 
  ⍝H d.HasDefault← [1|0]
  ⍝H If you set HasDefault to 1, the prior default (if any) is restored.
  ⍝H If you set HasDefault to 0, any attempt to read an item that doesn't exist
  ⍝H will cause a VALUE ERROR to be signalled.
  ⍝H if you reset HasDefault to 1.
  :Access Public
    ∇ r←get 
      r← HAS_DEFAULT 
    ∇
    ∇ set def  
      ⎕SIGNAL 11/⍨ def.NewValue (~∊)0 1
      HAS_DEFAULT← def.NewValue 
    ∇
  :EndProperty 

:EndClass

:EndNamespace
