:namespace ⍙Gen
  ⎕IO ⎕ML←0 1
⍝ msgs with code >0 are Dyalog error numbers (EN)
  debug←     0 
  nullMsg←   'NULL'
  stdMsg←     0
  eofMsg←    'EOF'  
  tokMinWait←  debug⊃ 15 1  

⍝ Bug in Dyalog 18: can't interrupt ⎕TGET. 
  ∆TGET← {
    1003:: ⎕SIGNAL InterruptSignal
    tok← tokMinWait ⎕TGET ⍵
    0≠ ≢ tok: tok 
    ∇ ⍵ 
  }

  ∆Signal← ⎕SIGNAL { ⊂⍵.(('EM' ('Generator: ',EM))('EN' EN)('Message' Message)) }
  ∆FlatDmx← { en← 911 ⍵.EN⊃⍨ ⍵.EN<1000 ⋄ en ⍵.(∊('Generator: ',EM),  (×≢Message)/': ', Message) }

  tokenSpace← ⎕TALLOC 1 'Generator'
  tokenInc← 0.000001
  tokenPair← tokenInc + tokenInc÷1 2 
  curToken← tokenSpace + tokenInc 

  STOP← 901 
  StopSignal← ⊂('EN' STOP)('EM' 'Generator has stopped')
  InterruptSignal← ⊂('EN' STOP)('EM' 'Generator has stopped')('Message' '(Interrupted by user)')

  :Namespace genLib 
    toGen fromGen myTid← ¯1 
    saved← return← ⍬ ⋄ gotReturned← 0      
    eof← 0 
  ⍝ 
    ∇ payload← Next ; rc; ret 
      rc payload← 911 ⍬ 
      :Trap 0 1000
        :If ×≢saved 
            (rc payload) saved← saved ⍬
        :Elseif eof
            :IF ~gotReturned 
                gotReturned⊢← 1 
                ##.STOP ⎕SIGNAL⍨ 'Generator has stopped. Value (¨return¨)',∊(⎕UCS 13),' ',⎕FMT return 
            :Else 
                ⎕SIGNAL ##.StopSignal
            :EndIf 
        :Else  
            ##.nullMsg ⎕TPUT toGen 
            rc payload← ⊃##.∆TGET fromGen 
        :EndIf 
        :Case 0
            ⎕SIGNAL ##.InterruptSignal
        :Case 1000
            ⎕SIGNAL ##.InterruptSignal
      :EndTrap 
      :IF 911= rc 
           'Generator Logic Error' ⎕SIGNAL 911
      :ElseIf 0 < rc
          ##.STOP ⎕SIGNAL⍨ 'Generator has stopped. ',,⎕FMT rc payload
      :EndIf 
    ∇
    ∇ {payload}← Yield data
      {}##.∆TGET toGen            ⍝ Wait until they are ready for us!
      payload← ##.stdMsg data     ⍝ 
      payload ⎕TPUT fromGen       ⍝ Now send the payload
    ∇ 
    ∇ {tokens}← Close 
      :If ×fromGen 
          ⎕TGET tokens← ⎕TPOOL/⍨ ⎕TPOOL∊ fromGen toGen 
          fromGen toGen← 0 
          ⎕TKILL myTid 
      :EndIf 
      eof← 1 
    ∇
    ∇ b← Eof ; ⎕TRAP 
      :Trap 0 1000
        b← _Eof 
      :Case 0
          ##.∆Signal ⎕DMX 
      :Else  
          ⎕SIGNAL ##.InterruptSignal
      :EndTrap 

    ∇
     ∇ b← _Eof  
      :If ×≢ saved
          b← 0 
      :Elseif eof=1  
          b← eof  
      :Else 
          saved,← Next 
          b← 0
      :EndIf  
    ∇
    ∇ b← More  
      :Trap 0 1000 
          b← ~_Eof 
      :Case 0
          ##.∆Signal ⎕DMX 
      :Else
          ⎕SIGNAL ##.InterruptSignal
      :EndTrap 
    ∇
  :EndNamespace 

⍝H ===========================
⍝H FUNCTIONS FOR USER ONLY
⍝H ===========================
  ∆Gen← { ⍺←0  
    1000:: ⎕SIGNAL InterruptSignal
    0:: ∆Signal ⎕DMX 
      _← 'gNs' ⎕NS genLib 
    ⍝ gNs: generator namespace instance, copied in from genLib                 
      gNs.(toGen fromGen)← curToken+ tokenPair
      curToken+← tokenInc       ⍝ Update genLib 
      gNs.(debug gNs)← ⍺ ⍬ 
    ⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝
      _← ⍺ ⍺⍺ gNs.{  
          0:: ##.∆Signal ⎕DMX⊣ {
            eof⊢← 1 
            _← ⎕TGET ⎕TPOOL/⍨ ⎕TPOOL= toGen 
            fromGen ⎕TPUT⍨ ##.∆FlatDmx ⎕DMX  
          } ⍬  
      ⍝ Initialise
          myTid⊢← ⎕TID 
          ⎕THIS.gNs← ⎕THIS 
          Say← (⎕∘←)⍣debug 
          _← ⎕DF ,⎕FMT toGen myTid 
      ⍝ Start the user's generator (⍺⍺) passing this namespace (as ⍺) and caller's ⍵ as ⍵ 
          _← Say 'Starting generator'
          return⊢← ⎕THIS ⍺⍺ ⍵ 
          eof⊢← 1   
          _← Say 'Terminating generator'      
      ⍝ Prepare to return normally 
      ⍝ Clear our tokens   
        _← ⎕TGET ⎕TPOOL/⍨ ⎕TPOOL= toGen 
      ⍝ Return... 
        _← Say 'Returning now'
        gNs⊢← ⎕THIS                                      
      }& ⍵
      gNs    
  }
  ##.∆Gen←  ⎕THIS.∆Gen
:endNamespace
