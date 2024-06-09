:namespace TestConundrum 
  ⍝ Here's our minimalist class "Conundrum"
  ⍝ See below for the details...

  ∇ The_Conundrum 
    ⎕←'⍝ Version II'
    ⎕←'⍝ The conundrum:' 
    ⎕←'⍝ Why (in this example) is a "Property Numbered" method for accessing a single item'
    ⎕←'⍝ of a vector so slow, compared to its "Property Keyed" equivalent"?'
    ⎕←'⍝ - More specifically, why does its performance appear to be O(N) (rather than O(1))'
    ⎕←'    where N is the size of the vector being accessed?'
    ⎕←'⍝ - As always, this is a gobsmackingly simplified debugging example. '
    ⎕←'    Of course I would never use this method just to access an element of a simple vector.'
    ⎕←''
    :IF 'STRINGS'∊⍥⊆ ACTIONS ⋄ ⎕← '*** Objects are strings'
    :Else                    ⋄ ⎕← '*** Objects are floats'
    :EndIF
    ⎕←''
   ∇

⍝ STRINGS|FLOATS, COMPARISONS, TIMINGS, SOURCE  
  ACTIONS← 'TIMINGS' 'STRINGS' 


  :class Conundrum
      ⎕IO←0 
      :Field Private VECTOR

      ∇ makeN tally                             
      :Implements constructor 
      :Access Public 
        :IF 'STRINGS'∊⍥⊆ ##.ACTIONS  
          VECTOR← ,⍕¨⍳tally ⍝ char VECTOR
        :Else 
          VECTOR← ,0.1+⍳tally ⍝ float VECTOR
        :EndIF 
       ∇ 
      :Property Numbered GetSlow 
        :Access Public
          ∇ val← Get args
            val←  VECTOR[ args.Indexers ]  
          ∇
          ∇ r← Shape
            r← ⍴VECTOR
          ∇
      :EndProperty 
      :Property Keyed GetFast
        :Access Public
          ∇ vals← Get args
            vals← VECTOR[ (⊃args.Indexers) - (⊃⎕RSI).⎕IO ]  
          ∇
      :EndProperty

  :EndClass 

⍝ Here's our test script!!!
∇ Script
;a ; lenStr; ns; nm; test
;⎕IO 
;cmpx

⎕IO←0   ⍝ We like 0 

{}'cmpx' ⎕CY 'dfns'

The_Conundrum 

 test←⍬ 
 lenStr←  '1' '1E1' '1E2' '1E3' '1E4' '1E5' '1E6'
 ⎕←'Accessing the first item of objects of length ',lenStr
:FOR ns :IN lenStr
    nm←'obj_',ns  ⋄ ⎕SHADOW nm 
    _←⎕NEW Conundrum (,⍎ns)
    ⍎nm,'←_'
    test,←  ⊂'_←',nm 
:EndFor
test_Fast test_Slow← (test,¨ ⊂'.GetFast[0]') (test,¨ ⊂'.GetSlow[0]')

:IF 'COMPARISON'∊⍥⊆ ACTIONS  
   cmpx test_Fast, test_Slow 
:Else 
    ⎕←'Skipping cmpx COMPARISON'
:EndIf 

:IF 'TIMINGS'∊⍥⊆ ACTIONS  
    ⎕←'Timings...'
    ⍞←'t← cmpx¨¨test_Fast test_Slow  '
    t← ⍎∘{⍞←'.' ⋄ cmpx ⍵}¨¨test_Fast test_Slow  
    ⎕←'' 
    ⎕←'#.timings← GetSlow[0] vs GetFast[0]'
    timings← ∊÷⍨⌿t 
    ⎕←'#.lengths← ',lenStr 
    lengths←⍎¨lenStr 
    #.(timings lengths)← (timings lengths) 
    ⍝ ⎕←'   ]plot timings lengths'
    ⎕SE.UCMD 'plot timings lengths⊣''TIMINGS(y←slow÷fast) VS LENGTHS(x-axis)'''
:Else  
    ⎕←'Skipping individual TIMINGS' 
:EndIf 
'' 
:IF 'SOURCE'∊⍥⊆ ACTIONS 
    100⍴'*'
    '⍝ The Source...'
    '↑⎕SRC ##.TestConundrum'
     ↑⎕SRC ##.TestConundrum 
:Else  
     ⎕←'Skipping SOURCE display'
:EndIF 
∇
:endnamespace
