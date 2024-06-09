  :Namespace TestConundrum 
      ⎕IO←0 
      ⍞←'Run:',(⎕UCS 13),'   ',(⍕⎕THIS),'.Script'
  :class Conundrum
      :Field Private       vector
      :Field Public Shared types←     0      1       2      3 
      :Field Public Shared typeNames← 'Int' 'Float'  'Char' 'String'

      ∇ makeN (tally type)                             
      :Implements constructor 
      :Access Public 
      :Select ⊃type
        :CASE 0 ⋄ vector← 32767+⍳tally  ⍝ int vector 
        :CASE 1 ⋄ vector← 0.1+⍳tally    ⍝ float vector
        :CASE 2 ⋄ vector← ⎕A⍴⍨ tally    ⍝ char vector
        :CASE 3 ⋄ vector← ⍕¨⍳tally      ⍝ vector of char vectors
        :Else   ⋄ 911 ⎕SIGNAL⍨'LOGIC ERROR'
      :EndSelect 
      ∇ 
      :Property Numbered GetSlow 
        :Access Public
          ∇ val← Get args
            val←  vector[ args.Indexers ]  
          ∇
          ∇ r← Shape
            r← ⍴vector
          ∇
      :EndProperty 
      :Property Keyed GetFast
        :Access Public
          ∇ vals← Get args
            vals← vector[ (⊃args.Indexers) - (⊃⎕RSI).⎕IO ]  
          ∇
      :EndProperty
:EndClass 

⍝ Here's our timings script!!!
∇ Script ;d ; len; lengths; timings; type; cmpx; EF; RelTime; Select; ⎕IO

    ⎕TRAP← 1000 'C' '⎕←''Interrupted!''⋄:RETURN'
    ⎕IO←0                          ⍝ We like 0 
    {}'cmpx' ⎕CY 'dfns'            ⍝ Copy in cmpx 
    EF← ,∘' '((~∘'.')¯1∘⍕) 
    RelTime← ÷/(⍎cmpx)¨ 
    Select← { ⍺=⍥⎕C 1↑' '~⍨⍞↓⍨≢⍞← ⍵ }
    
    :IF 0                   ⍝ Verify GetSlow and GetFast produce same results
      sanityCheck←1 
      :For len :in lengths← 1 5 10 50 100 500 1000 5000 10000 50000 100000 1E6
          :For type :in Conundrum.types 
              d← ⎕NEW Conundrum (len type)  
              :for l :in (len-1)⌊0 500 1000
                :IF d.GetSlow[l]≢d.GetFast[l]
                    ⎕←'d.GetSlow[',(⍕l),']≢d.GetFast[',(⍕l),']'
                    sanityCheck←0 
                :EndIf 
              :EndFor 
          :EndFor 
      :endFor 
      ⎕←'The sanity check (d.GetSlow[0]≡d.GetFast[0]) for all N: ',sanityCheck⊃'FAILED' 'PASSED'
    :EndIf 

⍝   Select which types to evaluate...
    typesActive← 0 1 0 1                      ⍝  typesActive∊ Conundrum.typeNames 
    :IF 1∊ typesActive
        :IF ~'l' Select 'Should the list of lengths be short or long? [s|l] '
            lengths← 1 50000 1E6
        :Else 
            lengths←  1 5 10 50 100 500 1000 5000 10000 50000 100000 1E6
        :EndIf 
   
        ⎕←'>>> Beginning Timings across lengths and types'
        timings← (≢Conundrum.types)⍴ ⊂⍬
        :FOR type :in typesActive/Conundrum.types 
            ⍞←'*** Type: ',(type⊃ Conundrum.typeNames),⎕UCS 13 
            ⍞←'*** Lengths: '
          :for len :in lengths 
              ⍞← EF len 
              d← ⎕NEW Conundrum (len type)  
              t← RelTime'd.GetSlow[0]' 'd.GetFast[0]'
              (type⊃timings),← t 
          :endFor 
          ⍞←⎕UCS 13
        :EndFor 
        tNames← ∊'t',¨' ',⍨¨ typesActive/Conundrum.typeNames 
        tNames ##.{⍎'(',⍺,')←⍵'} typesActive/timings
        ##.lengths←lengths 
        ##.timings←timings 
        # UCMD 'plot (',tNames,') lengths'
    :EndIf 
    ⎕←'Done'
∇

:EndNamespace 