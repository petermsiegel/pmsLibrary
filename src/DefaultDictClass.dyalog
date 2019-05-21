:Class DefaultDictClass  : DictClass
    ⍝ require 'DictClass'
 ⍝ General Local Names
    ClassNameStr←⍕⊃⊃⎕CLASS ⎕THIS

  ⍝ new0: "Constructs a default dictionary with default value 0
    ∇ new0
      :Implements Constructor
      :Access Public
      ⎕DF ClassNameStr,'[]'
      _load 0
    ∇
  ⍝ new1 arg: "Constructs a default dictionary with default value arg
    ∇ new1 arg
      :Implements Constructor
      :Access Public
      ⎕TRAP←∆TRAP
      ⎕DF ClassNameStr,'[]'
      _load⊂arg
    ∇
:EndClass
