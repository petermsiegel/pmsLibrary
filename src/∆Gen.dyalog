:namespace ⍙Gen
  ⎕IO ⎕ML←0 1

⍝ Set "Class" Token range and initialize curTokens 
∇ (tBase tInc curT)← AllocTokens maxGens
  ⍝ extern: tokenBase tokenInc curTokens
    tInc← 0.5÷maxGens
    tBase← ⎕TALLOC 1 '∆Gen'
    curT← tBase + tInc + 0 (tInc÷2)
∇
⍝ AllocTokens: We'll allow up to maxGens generators per session
  tokenBase tokenInc curTokens← AllocTokens maxGens← 1E9   
  
⍝ msgs with code >0 are Dyalog error numbers (EN)
  debug←     0  
  tgetMinWait←  debug⊃ 30 1  

⍝ Signal-related
  domEn stopEn failEn← 11 901 911    
  ⍙st← ('EN' stopEn) ('EM' '∆Gen STOPITERATION') 
  stopSignal←      ⊂⍙st 
  returnedSignal←  ⊂⍙st, ⊂'Message' 'Generator has returned' 
  interruptSignal← ⊂⍙st, ⊂'Message' 'Interrupted by user'
  badEnvSignal←    ⊂('EN' domEn)  ('EM' '∆Gen ENVIRONMENT ERROR') ('Message' 'Routine called from wrong environment')
  logicSignal←     ⊂('EN' failEn) ('EM' '∆Gen LOGIC ERROR')

⍝ User routine ⍙Gen.Reset-- Resets the tokenBase parameters
⍝ Clears all token relating to this ∆Gen "class" and deallocates the base
⍝ Generates a possibly new base...
  ∇ {response} ← Reset ; oldTB
  ⍝ extern: tokenBase tokenInc curTokens
    :If {11:: 1 ⋄ 0⊣ ⍵ ⎕TALLOC ¯1⊣ ⎕TGET ⍵ ⎕TALLOC 2} oldTB← tokenBase
        oldTB← ⎕NULL
    :EndIf 
    tokenBase tokenInc curTokens← AllocTokens maxGens
    response← oldTB tokenBase 
  ∇

⍝ ∆TGET: interruptible ⎕TGET (given bug in Dyalog 18: can't interrupt ⎕TGET). 
  ∇ {data}← ∆TGET fromTId; obj 
    :TRAP 1000
      :Repeat
          obj← tgetMinWait ⎕TGET fromTId 
      :Until 0≠ ≢obj
      data← ⊃obj 
    :Else 
        ⎕SIGNAL interruptSignal
    :EndTrap 
  ∇
  ∆SignalDmx← ⎕SIGNAL { ⊂⎕DMX.( ('EN' EN) ('EM' ('∆Gen ',EM)) ('Message' Message) ) }
  ∆FlatDmx← { en← stopEn ⍵.EN⊃⍨ ⍵.EN<1000 ⋄  ('EN' en) ('EM' ('∆Gen ', ⍵.EM))  ('Message' ⍵.Message) }
⍝ See ∆Gen below.
  ⍙ResetGen← { ⍵.eof⊢← 1 ⋄ _← ⎕TGET ⎕TPOOL/⍨ ⎕TPOOL= ⍵.toGen ⋄ 1 (∆FlatDmx ⎕DMX) ⎕TPUT ⍵.fromGen }

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
      :If ⎕TID ≠ genTid ⋄ ⎕SIGNAL ##.badEnvSignal ⋄ :EndIf 
      ##.∆TGET toGen        ⍝ Wait until they are ready for us!
      0 data ⎕TPUT fromGen        ⍝ Now send the payload
    ∇ 
    ∇ {tokens}← Close 
      :If ⎕TID = genTid ⋄ ⎕SIGNAL ##.badEnvSignal ⋄ :EndIf 
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
         b← _Eof⍬
      :Case 0 
          ##.∆SignalDmx⍬
      :Else 
          ⎕SIGNAL ##.interruptSignal 
      :EndTrap 
    ∇
    ∇ b← More   
      :Trap 0 1000 
         b← ~_Eof⍬ 
      :Case 0  
          ##.∆SignalDmx⍬
      :Else 
          ⎕SIGNAL ##.interruptSignal 
      :EndTrap 
    ∇
    _Eof← { ×≢ saved: 0 ⋄ eof=1: 1 ⋄ 0⊣ saved⊢← ⍙Next }
   :EndNamespace 
 
⍝H ========================
⍝H ∆Gen - Generator utility 
⍝H ========================
  ∆Gen← { ⍺←0  
    1000:: ⎕SIGNAL interruptSignal
    0:: ∆SignalDmx⍬ 
      gNs← ⎕NS genLib 
      gNs.(toGen fromGen)← curTokens 
      curTokens+← tokenInc        
      gNs.(debug gNs)← ⍺ ⍬ 
      _← ⍺ ⍺⍺ gNs.{  
          0:: ##.{ ∆SignalDmx⍬⊣ ⍙ResetGen ⍵ } ⎕THIS   
      ⍝ Initialise
          ⎕THIS.gNs← ⎕THIS ⋄ genTid⊢← ⎕TID 
          Say← (⎕∘←)⍣debug 
          _← ⎕DF ⎕TNAME← '∆GEN tid=',(⍕genTid),' tok=',⍕toGen 
          _← Say ⎕TNAME,': Starting generator'
        ⍝ === USER GENERATOR (⍺) ===
          return⊢← ⎕THIS ⍺⍺ ⍵ 
        ⍝ ==========================
          eof⊢← 1 ⋄ returned⊢← 1      
      ⍝ Return... 
          _← Say ⎕TNAME,': Returning now'
          gNs⊢← ⎕THIS                                      
      }& ⍵
      gNs    
  }
  ##.∆Gen←  ⎕THIS.∆Gen
:endNamespace
