:class Conundrum
      :Field Private  vector
      ∇ make2 (tally prototype)  
    ⍝          c← ⎕NEW Conundrum (tally prototype)  
    ⍝ Creates a vector of <tally> objects created by reshaping <prototype>
    ⍝          c← ⎕NEW Conundrum (1000 1.1)   
    ⍝          tally: how many items in the vector created
    ⍝          prototype: what item(s) to shape to create a <tally>-itemed vector via 
    ⍝                     vector← tally⍴ prototype  
    ⍝          Example prototypes: 999 - short int, 1.1 - float, ⎕A - characters
    ⍝                  (⊂'abc') - vector of char. vectors, ⎕NULL - vector of objects
      :Implements constructor 
      :Access Public 
      vector← tally⍴ prototype   
      ∇ 
      ∇ make1 tally 
    ⍝ Usage:   c← ⎕NEW Conundrum tally
    ⍝ Creates a vector of <tally> char. vector objects (each 1 byte of payload)
    ⍝          tally: how many items in the vector created                          
      :Implements constructor 
      :Access Public 
      vector← tally⍴ ⊂¨⎕A 
      ∇ 

      :Property Numbered GetSlow 
    ⍝ GetSlow: a Property Numbered method
        :Access Public
          ∇ val← Get args
            val←  vector[ args.Indexers ]  
          ∇
          ∇ r← Shape
            r← ⍴vector
          ∇
      :EndProperty 
      :Property Keyed GetFast
    ⍝ GetFast: a Property Keyed method
        :Access Public
          ∇ vals← Get args
            vals← vector[ (⊃args.Indexers) - (⊃⎕RSI).⎕IO ]  
          ∇
      :EndProperty
      ⎕←'You are invited to execute this sequence:'
      ⎕←'   ⎕IO←0 ⋄ ⎕←''cmpx'' ⎕CY ''dfns'' '
      ⎕←'   TestC←(⌽∘↓⍉∘↑){ a∘←⎕NEW Conundrum ⍵ ⋄ ⍵,⍥⊂ ÷/⍎∘cmpx¨  ''a.GetSlow[0]'' ''a.GetFast[0]'' }¨'
      ⎕←'   TALLY_VS_SLOWDOWN← TestC 10*2×⍳4 '
      ⎕←'   ⎕←''  ⍝ Plot tally (length of vector) vs slowdown (how much slower a.GetSlow is than a.GetFast)'' '
      ⎕←'   ⎕SE.UCMD ''plot TALLY_VS_SLOWDOWN'' '
:EndClass 