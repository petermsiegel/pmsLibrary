:Namespace tinyGen

    genId←0               ⍝ The generator's thread # (0=unassigned or terminated)
    firstToken←33333      ⍝ First token number for tinyGen
    curToken←firstToken   ⍝ Restarted at firstToken when class is ⎕FIX'd.

 ⍝ This is a minimalist set of elements for showing the interpreter failure
 ⍝ The real generator creates a Python-like generator (a kind of iterator) using the <yield>, <next> and related methods.
 ⍝ We first tried to implement entirely in a class which causes fatal problems in the interpreter  of several years ago and today.
 ⍝ We moved to a minimalist model based on classes, which works fine without the destructor components.
 ⍝ The destructor is needed to "cleanup" on the caller side when a generator has terminated (to avoid zombie threads and tokens).

  ⍝ tinyGen.erator
  ⍝    myGen ← tinyGen.erator
  ⍝    ⎕EX 'myGen'

    ∇ myGenClass←erator;theGen;waitSec
      waitSec←600
      genId←waitSec{_←10 ⎕TGET ⍵-1 ⋄ ⎕←'Generator ',⎕THIS,' is active, waiting on token',⍵,'for',⍺,'seconds' ⋄ 600 ⎕TGET ⍵}&curToken
      theGen←⎕NS ⎕THIS
      myGenClass←⎕NEW register theGen
      theGen.⎕DF'Generator ',(⍕genId),' token=',(⍕curToken)
      ⎕TPUT curToken-1
     
    ⍝ Prepare curToken for next round...
      curToken←firstToken+(1000|curToken+1-firstToken)
     
    ∇


    :Class register
        :Field Public           genId        ← 0
        :Field Public           theGenerator
        ∇ New theGen;whence
          :Access Public
          :Implements Constructor
          theGenerator←theGen
          genId←theGenerator.genId
          '>>> register: constructor complete for generator'
          ⎕FMT'>>>       id:'theGenerator
          ⎕FMT'>>> threadid:'genId
        ∇

        ∇ nomoreGenerator
          :Implements destructor
          :If theGenerator≢0
              '>>> register: destructor called on generator'
              ⎕FMT'>>>       id:'theGenerator
              ⎕FMT'>>> threadid:'genId
            ⍝ Here's the actual work-- the destructor by itself causes APL to abort.
              ⎕TKILL genId
              genId theGenerator←0
          :EndIf
        ∇
    :endClass


:EndNamespace
