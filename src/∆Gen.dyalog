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
  maxGens← 1E9   
  tokenBase tokenInc curTokens← AllocTokens maxGens 
  
⍝ msgs with code >0 are Dyalog error numbers (EN)
  debug←     0  
  tgetMinWait←  debug⊃ 30 1  

⍝ Signal-related
  STOP← 901   
  ⍙st← ('EN' STOP) ('EM' '∆Gen STOP GENERATOR') 
  sigStop←      ⊂⍙st 
  sigReturn←    ⊂⍙st, ⊂'Message' 'Generator has returned' 
  sigInterrupt← ⊂⍙st, ⊂'Message' 'Interrupted by user'
  sigBadEnv←    ⊂('EN' 11)  ('EM' '∆Gen ENVIRONMENT ERROR') ('Message' 'Routine called from wrong environment')

⍝ User routine ⍙Gen.Reset-- Resets the tokenBase parameters
⍝ Clears all token relating to this ∆Gen "class" and deallocates the base
⍝ Generates a possibly new base...
  ∇ {response} ← Reset ; oldTB
  ⍝ extern: tokenBase tokenInc curTokens
    :If {11:: 1 ⋄ 0⊣ ⍵ ⎕TALLOC ¯1⊣ ⎕TGET ⍵ ⎕TALLOC 2} oldTB← tokenBase
        oldTB← ⎕NULL
    :EndIf 
    tokenBase tokenInc curTokens← AllocTokens maxGens
    response← 'token base:' tokenBase ' maximum generators:' maxGens
  ∇

⍝ ∆TGET: interruptible ⎕TGET (work around bug in Dyalog 18). 
  ∇ {data}← ∆TGET fromTId; obj 
    :TRAP 1000
      :Repeat
          obj← tgetMinWait ⎕TGET fromTId 
      :Until 0≠ ≢obj
      data← ⊃obj 
    :Else 
        ⎕SIGNAL sigInterrupt
    :EndTrap 
  ∇

⍝ Error handling
  ⍙Dmx2Sig← { ⍺←1 ⋄ en← STOP ⍵.EN⊃⍨ ⍵.EN<1000 ⋄  ⊂('EN' en) ('EM' ((⍺/'∆Gen '), ⍵.EM))  ('Message' ⍵.Message) }
  SigDmx←    ⎕SIGNAL   ⍙Dmx2Sig 
  SigRepeat← ⎕SIGNAL 0∘⍙Dmx2Sig 
⍝ ErrExit:  ns ∇ dmx
  ErrExit←  ⎕SIGNAL { ⍺.eof⊢← 1 ⋄ _← ⎕TGET ⎕TPOOL/⍨ ⎕TPOOL= ⍺.toGen ⋄ ⊂⍵⊣ ⍺.fromGen ⎕TPUT⍨ 1, ⊂⍵}∘⍙Dmx2Sig

  :Namespace genLib 
    toGen fromGen genNs genTid retVal← ⎕NULL 
    eof hasRetVal← 0 ⋄ saveStk← ⍬       
    STOP← ##.STOP
  
    ∇ data← Next ; isSig 
      :If ⎕TID = genTid ⋄ ⎕SIGNAL ##.sigBadEnv ⋄ :EndIf 
      :Trap 0 1000
          isSig data← ⍙Next 
          :If isSig ⋄ {⎕SIGNAL⍵} data ⋄ :EndIf 
      :Else 
          ##.SigRepeat ⎕DMX
      :EndTrap 
    ∇
    ∇ (isSig payload)← ⍙Next  
      :If ×≢saveStk 
          (isSig payload)← ⊃saveStk ⋄ saveStk↓⍨← 1    ⍝ Perform all at once in thread
      :Elseif eof
          isSig payload← 1 (hasRetVal⊃ ##.(sigStop sigReturn))
      :Else  
          0 ⎕NULL ⎕TPUT toGen 
          isSig payload← ##.∆TGET fromGen 
      :EndIf 
    ∇
    ∇ {data}← Yield data
      :If ⎕TID ≠ genTid ⋄ ⎕SIGNAL ##.sigBadEnv ⋄ :EndIf 
      ##.∆TGET toGen              ⍝ Wait until they are ready for us!
      0 data ⎕TPUT fromGen        ⍝ Now send the payload
    ∇ 
    ∇ {tokens}← Close 
      :If ⎕TID = genTid ⋄ ⎕SIGNAL ##.sigBadEnv ⋄ :EndIf 
      :If ×≢ fromGen 
          tokens← ⎕TPOOL/⍨ ⎕TPOOL∊ fromGen toGen 
          eof saveStk fromGen toGen← 1 ⍬ ⍬ ⍬  
          ⎕TGET tokens ⋄ ⎕TKILL genTid 
      :Else
          tokens← ⍬ 
          eof saveStk← 1 ⍬ 
      :EndIf 
    ∇
    ∇ b← Eof  
      :Trap 0 1000 
         b← ⍙Eof⍬
      :Else  
          ##.SigDmx ⎕DMX
      :EndTrap 
    ∇
    ∇ b← More   
      :Trap 0 1000 
         b← ~⍙Eof⍬ 
      :Else 
          ##.SigDmx ⎕DMX
      :EndTrap 
    ∇
    ⍙Eof← { 
      ×≢ saveStk: 0 
      eof: 1 
      0⊣ saveStk,← ⊂##.∆TGET fromGen⊣ 0 ⎕NULL ⎕TPUT toGen  
    }
   :EndNamespace 
 
⍝H ========================
⍝H ∆Gen - Generator utility 
⍝H ========================
  ∆Gen← { ⍺←0  
      genNs← ⎕NS genLib 
      genNs.(toGen fromGen)← curTokens 
      curTokens+← tokenInc        
      genNs.(debug genNs genNs)← ⍺ ⍬ genNs 
      _← ⍺ ⍺⍺ genNs.{  
          0 1000:: ⎕THIS ##.ErrExit ⎕DMX 
      ⍝ Initialise
          Say← (⎕∘←)⍣debug 
        ⍝ ⎕THIS.(genNs genTid)← ⎕THIS ⎕TID 
          genTid⊢← ⎕TID 
          _← ⎕DF ⎕TNAME← '∆GEN tid=',(⍕⎕TID ),' tok=',⍕toGen 
          _← Say ⎕TNAME,': Starting generator'
        ⍝ === USER GENERATOR (⍺) ===
          retVal← ⎕THIS ⍺⍺ ⍵
          eof hasRetVal⊢← 1  
        ⍝ ==========================  
          _← Say ⎕TNAME,': Returning now'                                     
      }& ⍵
      genNs    
  }
  ##.∆Gen←  ⎕THIS.∆Gen
:endNamespace
