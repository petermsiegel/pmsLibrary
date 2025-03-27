:namespace ⍙Gen
  ⎕IO ⎕ML←0 1

⍝ Set "Class" Token range and initialize curTokens 
  tokenInc← 0.0000001
  curTokens← (⎕TALLOC 1 '∆Gen') + tokenInc + 0 (tokenInc÷2)

⍝ msgs with code >0 are Dyalog error numbers (EN)
  debug←     0  
  tgetMinWait←  debug⊃ 15 1  

⍝ Signal-related
  domEn stopEn failEn← 11 901 911    
  ⍙st← ('EN' stopEn) ('EM' 'Generator: Generator has stopped')
  stopSignal←      ⊂⍙st 
  returnedSignal←  ⊂⍙st, ⊂'Message' '(Generator has returned)' 
  interruptSignal← ⊂⍙st, ⊂'Message' '(Interrupted by user)'
  badEnvSignal←    ⊂('EN' domEn)  ('EM' 'Generator: Calling generator routine from wrong environment')
  logicSignal←     ⊂('EN' failEn) ('EM' 'Generator Logic Error')

⍝ ∆TGET: interruptible ⎕TGET (given bug in Dyalog 18: can't interrupt ⎕TGET). 
  ∇ data← ∆TGET from; obj 
    :TRAP 1000
      :Repeat
          obj← tgetMinWait ⎕TGET from 
      :Until 0≠ ≢obj
      data← ⊃obj 
    :Else 
        ⎕SIGNAL interruptSignal
    :EndTrap 
  ∇
  ∆SignalDmx← ⎕SIGNAL { ⊂⎕DMX.( ('EN' EN) ('EM' ('Generator: ',EM)) ('Message' Message) ) }
  ∆FlatDmx← { en← stopEn ⍵.EN⊃⍨ ⍵.EN<1000 ⋄  ('EN' en) ('EM' ('Generator: ', ⍵.EM))  ('Message' ⍵.Message) }

  :Namespace genLib 
    toGen fromGen genTid← ¯1 
    saved return returned← ⍬ ⎕NULL 0      
    eof← 0 
  
    ∇ data← Next ; isSig 
      :If ⎕TID = genTid ⋄ ⎕SIGNAL ##.badEnvSignal ⋄ :EndIf 
      :Trap 0 1000
          isSig data← ⍙Next 
          :If isSig ⋄ ⎕SIGNAL data ⋄ :EndIf 
      :Case 0
          ∆SignalDmx⍬
      :Else 
          ⎕SIGNAL ##.interruptSignal 
      :EndTrap 
    ∇
    ∇ (isSig payload)← ⍙Next  
      :If ×≢saved 
          (isSig payload) saved← saved ⍬
      :Elseif eof
          isSig payload← 1 (returned⊃ ##.(stopSignal returnedSignal))
      :Else  
          0 ⎕NULL ⎕TPUT toGen 
          isSig payload← ##.∆TGET fromGen 
      :EndIf 
    ∇
    ∇ {data}← Yield data
     ⍝ :If ⎕TID ≠ genTid ⋄ ⎕SIGNAL ##.badEnvSignal ⋄ :EndIf 
      {} ##.∆TGET toGen        ⍝ Wait until they are ready for us!
      0 data ⎕TPUT fromGen        ⍝ Now send the payload
    ∇ 
    ∇ {tokens}← Close 
      ⍝ :If ⎕TID = genTid ⋄ ⎕SIGNAL ##.badEnvSignal ⋄ :EndIf 
      :If ×≢ fromGen 
          tokens← ⎕TPOOL/⍨ ⎕TPOOL∊ fromGen toGen 
          eof saved fromGen toGen← 1 ⍬ ⍬ ⍬  
          ⎕TGET tokens 
          ⎕TKILL genTid 
      :Else
          eof tokens saved← 1 ⍬ ⍬ 
      :EndIf 
    ∇
    ∇ b← Eof  
      :Trap 0 1000 
         b← _Eof 
      :Case 0 
          ##.∆SignalDmx⍬
      :Else 
          ⎕SIGNAL ##.interruptSignal 
      :EndTrap 
    ∇
    ∇ b← More   
      :Trap 0 1000 
         b← ~_Eof 
      :Case 0  
          ##.∆SignalDmx⍬
      :Else 
          ⎕SIGNAL ##.interruptSignal 
      :EndTrap 
    ∇
    ∇ b← _Eof  
      :If ×≢ saved
          b← 0 
      :Elseif eof=1  
          b← 1  
      :Else 
          saved← ⍙Next 
          b← 0
      :EndIf  
    ∇
   :EndNamespace 

⍝H ===========================
⍝H FUNCTIONS FOR USER ONLY
⍝H ===========================
  ∆Gen← { ⍺←0  
    0/1000:: ⎕SIGNAL interruptSignal
    0:: ∆SignalDmx⍬ 
      gNs← ⎕NS genLib 
      gNs.(toGen fromGen)← curTokens 
      curTokens+← tokenInc        
      gNs.(debug gNs)← ⍺ ⍬ 
    ⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝⍝
      _← ⍺ ⍺⍺ gNs.{  
          0/0:: ##.∆SignalDmx⍬⊣ {
            eof⊢← 1 
            _← ⎕TGET ⎕TPOOL/⍨ ⎕TPOOL= toGen 
            1 (##.∆FlatDmx ⎕DMX) ⎕TPUT fromGen   
          } ⍬  
      ⍝ Initialise
          ⎕THIS.gNs← ⎕THIS 
          Say← (⎕∘←)⍣debug 
          _← ⎕DF 'Generator ',(⍕genTid⊢← ⎕TID),' ',⍕toGen    
      ⍝ Start the user's generator (⍺⍺) passing this namespace (as ⍺) and caller's ⍵ as ⍵ 
          _← Say 'Starting generator'
          return⊢← ⎕THIS ⍺⍺ ⍵ 
          eof⊢← 1 ⋄ returned⊢← 1   
          _← Say 'Terminating generator'      
      ⍝ Return... 
          _← Say 'Returning now'
          gNs⊢← ⎕THIS                                      
      }& ⍵
      gNs    
  }
  ##.∆Gen←  ⎕THIS.∆Gen
:endNamespace
