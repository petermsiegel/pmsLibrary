:Namespace tinyDict
  ⍝ A simple, namespace-based, dictionary. Fast, low overhead.
  ⍝
  ⍝ dict ← tinyDict.New
  ⍝     Creates a dictionary with no values and no default
  ⍝
  ⍝ dict ← {def} tinyDict.∆DICT pairs
  ⍝     Creates a dictionary with key-value pairs specified and (optional) default.
  ⍝
  ⍝ r←dict.Get  key1 keys
  ⍝     Like dict.Get1, but for multiple keys.
  ⍝
  ⍝ r←dict.Get1 key
  ⍝     Returns the value for key <key>, if defined.
  ⍝     If not, but a default exists, returns that default.
  ⍝     Otherwise, signals a Key undefined error.
  ⍝     If there is one key, dict.Get1 key ≡≡ ⊃dict.Get key
  ⍝
  ⍝ r←key1 key2 ... dict.Put val1 val2 ...
  ⍝     Like dict.Put1, but for multiple keys and values.
  ⍝
  ⍝ r←key dict.Put1 value
  ⍝     Sets the key specified to the corresponding value.
  ⍝     To set multiple keys, do    k1 k2 ... dict.Put¨ v1 v2 ...
  ⍝
  ⍝ r←dict.Del key
  ⍝     Deletes the specified key. If it exists, returns 1; else 0.
  ⍝
  ⍝ r←dict.Show
  ⍝     Returns Key, Value pairs.
  ⍝
  ⍝ dict.Default←def
  ⍝     Sets the default for the tinyDict.
  ⍝
  ⍝ dict.Keys
  ⍝     A list of Keys in order
  ⍝
  ⍝ dict.Vals
  ⍝     A corresponding list of values in order

    ∇ ns←New
      ns←⎕NS ⎕THIS
    ∇
    ∇ ns←{def}∆DICT pairs
      ns←New
      :If 0≠⎕NC'def'
          ns.Default←def
      :EndIf
      :If 0≠≢pairs
          Keys Vals←↓⍉↑pairs
      :EndIf
    ∇

    ⎕IO ⎕ML←0 1
    Default  Keys Vals←⎕NULL ⍬ ⍬

    ∇ r←Get keys;e;ie;ine;p
      keys←,keys    ⍝ (Or ravel ⍸,e)
      p←Keys⍳keys
      r←keys      ⍝ r will have the shape, but not content, of keys.
      :If 0≠≢ie←⍸e←p<≢Keys
          r[ie]←Vals[e/p]
      :EndIf
      :If 0≠≢ine←⍸~e
          :If 0≠⎕NC'Default'
              r[ine]←⊂Default
          :Else
              ⎕SIGNAL/('tinyDict: Some keys undefined: ',keys[ine])11
          :EndIf
      :EndIf
    ∇
    ∇ r←Get1 key;p
      p←Keys⍳⊂key
      :If p≥≢Keys
          :If 0≠⎕NC'Default'
              r←Default
          :Else
              ⎕SIGNAL/('tinyDict: Key undefined: ',key)11
          :EndIf
      :Else
          r←p⊃Vals
      :EndIf
    ∇
    ∇ {val}←key Put1 val;p
      p←Keys⍳⊂key
      :If p≥≢Keys
          Keys,←⊂key ⋄ Vals,←⊂val
      :Else
          (p⊃Vals)←val
      :EndIf
    ∇
  ⍝ Put: Not implemented efficiently...
    ∇ {vals}←keys Put vals;e;ie;n;p
      e←(≢Keys)>p←Keys⍳keys
      :If 0≠≢ie←⍸e    ⍝ Any existing keys?
          Vals[e/p]←e/vals
      :EndIf
      :If 1∊n←~e      ⍝ Any new keys?
        ⍝ If a key appears >1ce, use the LAST value for that key.
          p←(≢keys)-1+(⌽keys)⍳∪n/keys  
          (Keys Vals),←(keys[p])(vals[p])
      :EndIf
    ∇

    ∇ b←Del key;p;q
      p←Keys⍳⊂key
      :If p≥≢Keys
          b←0   ⍝ Not deleted
      :Else
          b←1   ⍝ Deleted...
          q←1⍴⍨≢Keys ⋄ q[p]←0
          Keys Vals←(q/Keys)(q/Vals)
      :EndIf
    ∇
    ∇ b←HasValue
      b←0≠⎕NC'Value'
    ∇
    ∇ r←Show
      Keys,[0.5]Vals
    ∇

:EndNamespace
