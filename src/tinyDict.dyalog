:Namespace tinyDict
  ⍝ A simple, namespace-based, dictionary. Fast, low overhead.
  ⍝ See docs/tinyDict.help

    ∇ ns←New
      ns←⎕NS ⎕THIS
      ns.⎕DF 'tinyDict[]'
      ns.Default←⍬
    ∇
    ∇ ns←{def}∆TINYDICT pairs
      ns←⎕THIS.New
      :If 0≠⎕NC'def'
          ns.Default←def
      :EndIf
      :If 0≠≢pairs
          ns.(Keys Vals)←↓⍉↑pairs
      :EndIf
    ∇
    _←##.⎕FX '⎕THIS'  ⎕R (⍕⎕THIS) ⊣⎕NR '∆TINYDICT'

    ⎕IO ⎕ML←0 1
    Keys Vals←⍬ ⍬
  ⍝ Default is defined in New or, optionally, in ∆DICT.

    ∇ r←Get keys;e;ie;ine;p
      keys←,keys
      p←Keys⍳keys
      r←keys        ⍝ r will have the shape, but not content, of keys.
      :If 0≠≢ie←⍸e←p<≢Keys
          r[ie]←Vals[e/p]
      :EndIf
      :If 0≠≢ine←⍸~e
          :If 0≠⎕NC'Default'
              r[ine]←⊂Default
          :Else
              ⎕SIGNAL/('tinyDict: One or more keys undefined: ',keys[ine])11
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

    ∇ {vals}←keys Put vals;e;ePut;ie;n;p
      ePut←'tinyDict/Put: number of keys and values must match' 11
      :If (≢keys)≠(≢vals) ⋄ ⎕SIGNAL/ePut ⋄ :EndIf
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

    ∇ {val}←key Put1 val;p
      p←Keys⍳⊂key
      :If p≥≢Keys
          Keys,←⊂key ⋄ Vals,←⊂val
      :Else
          (p⊃Vals)←val
      :EndIf
    ∇

    ∇ {vals}←PutPairs kv;ePutPairs
      ePutPairs←'tinyDict/PutPairs: key-value pairs must each have 2 items' 11
      :If (0∊2=≢¨kv) ⋄ ⎕SIGNAL/ePutPairs ⋄ :EndIf
      vals←(⊃¨kv)Put(⊃∘⌽¨kv)
    ∇


    ∇ {b}←Del1 key;p;q
      p←Keys⍳⊂key
      :If p≥≢Keys
          b←0   ⍝ Not deleted
      :Else
          b←1   ⍝ Deleted...
          q←1⍴⍨≢Keys ⋄ q[p]←0
          Keys Vals←(q/Keys)(q/Vals)
      :EndIf
    ∇

  ⍝ Del: Inefficient (just haven't gotten around to it)
    ∇ {b}←Del keys
      b←Del1¨keys
    ∇

    ∇ b←HasDefault
      b←0≠⎕NC'Default'
    ∇

    ∇ r←Table
      r←Keys,[0.5]Vals
    ∇

:EndNamespace
