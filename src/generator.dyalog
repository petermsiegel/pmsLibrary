:namespace Generator
⍝!  For description/help, see function ∘help∘ below.
⍝
  
⍝ CLASS SHARED CONSTANTS  (*) All class constants are replicated to clones
  ⎕IO ⎕ML←0 1
  DEBUG← 0
  TIMEOUT← 2     ⍝ Wait <TIMEOUT> seconds for generator preamble to startup and handshake

⍝ CLASS-ONLY SHARED VARIABLES  
  tokMin tokMax tokCur tokEach← 0
  threadDefaults← 0 2 1003741824 10

⍝ ⍙TReserve: Retrieve a pair from a range of "reserved" thread ids.
  ⍙TReserve← {  ⍝ Internal use only 
      defaults← ⍺
      tCur tEach tMin nTok← 4↑ ⍵, defaults↑⍨0⌊¯4+≢⍵
      0{  
        tries← ⍺
        tCur← tMin+ nTok| |⍵-tMin
        tries≥ nTok:11 ⎕SIGNAL⍨'GetNext: Can''t find ',(⍕tEach),' tokens in range [',(⍕tMin),',',(⍕tMin+nTok-1),']'
        1∊⎕TPOOL∊⍨ tNew← tCur+ ⍳tEach: ⊃∇/ tries tCur+ 1 
        tNew
      }tCur 
  }

 Gen← { ⍺←0 
        genNs∘← ⎕NS genLib
        genNs.(genNs DEBUG)← genNs ⍺  
        1000:: ⍙Interrupt ⍬
        0/⍨ ~DEBUG::  genNs.⍙Error ⍬
        genNs.(toGen fromGen)← threadDefaults ⍙TReserve 0
        genNs.genId← ⍺⍺ genNs.{  
          0:: ⍙Error ⍬ ⋄ 1000:: ⍙Interrupt ⍬
            genName∘← 'Gen[thread=',']',⍨ ⍕⎕TID
            _← ⎕DF genName ⋄ ⎕TNAME← genName
            _← ⎕TPUT fromGen                      ⍝ All vars are set. Tell user                        
            result∘← ⎕THIS ⍺⍺ ⍵
            genStatus=¯1: ⍙Cleanup& ⍬
            genStatus∘← 1 ⊣ ⎕DF genName,' [terminated]'
            1: _←result
        }& ⍵
        0= ≢TIMEOUT ⎕TGET genNs.fromGen: 11 ⎕SIGNAL⍨'Generator did not start up properly!'
        genNs 
  }
  ##.Gen← ⎕THIS.Gen

:Namespace genLib
  DEBUG← ##.DEBUG
  Blab← { DEBUG: ⍺⊣ ⎕← ⍵ ⋄ ⍺ }
  genStatus←0
  STOP_MSG STOP_SIGNAL← 'GENERATOR STOP SIGNAL' 901
  ∇ r←Done  ⍝ goes in user or generator
    r← 0≠ genStatus
  ∇
  ∇ r←More  ⍝ goes in user or generator
    r← 0= genStatus
  ∇
  Yield← {  ⍝ Generator only
      ⎕TID≠ genId: 'Yield only valid in generator code' ⎕SIGNAL 11 
      0≠ genStatus: ('Generator ',(genName),' no longer active')  ⎕SIGNAL 911
      code msg← ⊃⎕TGET toGen
      code∊ 0 1: _← msg⊣ 0 ⍵ ⎕TPUT fromGen
      STOP_MSG ⎕SIGNAL STOP_SIGNAL
  }
⍝  r←Next  Returns next message (no rc) from generator
 ∇ r←Next  ⍝ user only
    :TRAP 0 ⋄ r←⊃⌽Send ⎕NULL
    :ELSE   ⋄ ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ EM EN Message)
    :Endtrap
∇
⍝  [0: std send | 1: send now | ¯1: send quit (signal 901) request msg] Send value
⍝  Returns rc and msg
 Send←  { ⍝ user only
        ⍺← 0
    0::  ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ EM EN Message)
    ⎕TID= genId: 'Next/Send not valid in generator code' ⎕SIGNAL 11 
    1≠≢⍺: 'Domain Error: ⍺ must be 0 (default), 1 (send now), or ¯1 (abort)' ⎕SIGNAL 11
    0≠ genStatus: ('Generator ',(genName),' no longer active') ⎕SIGNAL 901 911⊃⍨ genStatus=¯1
    ⍺= 0: _← ⊃⎕TGET fromGen ⊣ 0 ⍵ ⎕TPUT toGen  
          Now← {saveV ⎕TPUT saveT ⊣ ⍺ ⍵ ⎕TPUT toGen ⊣ saveV← ⎕TGET saveT← ⎕TPOOL∩toGen}
    ⍺= 1: _← ⊃⎕TGET fromGen ⊣ ⍺ Now ⍵
    ⍺=¯1: _← ⊃0.001 ⎕TGET fromGen ⊣ 0 ⍵ ⎕TPUT toGen ⊣ ⍺ Now ⍵
 }
⍝ r←Peek   1 if there is a message waiting for me (user or generator)
∇ r←Peek  ⍝ goes in user OR generator 
  r←0 
  :IF 0= genStatus 
      r← ⎕TPOOL∊⍨ fromGen toGen⊃⍨ ⎕TID= genId
  :Endif 
∇
⍝ Abort: Forces an abort
∇ {r}← Abort ⍝ user or generator
  :IF ⎕TID= genId  ⍝ generator
      901 ⎕SIGNAL⍨ 'Generator is terminating.'  
  :ELSE
    :TRAP 0    ⋄ r← 'Generator ',(⍕⎕TID),' terminated' ⊣ ⊃⌽¯1 Send ⎕NULL ⋄ ⍙Cleanup ⍬
    :CASE 901  ⋄ r← ⎕DMX.EM 
    :ELSE      ⋄ ⎕SIGNAL ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ EM EN Message)
    :ENDTRAP
  :ENDIF 
∇ 
⍙Cleanup← { 
    genStatus⊢← ¯1  
    _← 1 ⎕TGET ⎕TPOOL∩toGen,fromGen
    _← ⎕DF genName,' [terminated]'
    1: _←⍬⊣ ⎕TKILL genId Blab 'Cleanup: Generator process',genId,' terminated' 
}
⍙⍙Error← { 
    _← ⍙Cleanup& genId Blab ↑(⊂'Gen: '),¨⎕DMX.DM 
    ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ ('Generator: ',EM) EN Message)
}
⍙Error← ⎕SIGNAL ⍙⍙Error
⍙Interrupt← ⎕SIGNAL {⊂'EM' 'EN' ,⍥⊂¨ 'Generator was interrupted' 911⊣ ⍙Cleanup& ⍬ }
  
:EndNamespace

  ∇ Help ;h
    ⎕ED'h'⊣h← '^\h*⍝H\h?(.*)'⎕S '\1'⊣⎕SRC ⎕THIS 
  ∇
⍝H =======================================  Gen  ==========================================
⍝H Gen        [myOpts]  {mygen} Gen myArgs
⍝H Emulates a python-like generator (iterator function) using Dyalog tokens and threads.
⍝H ∘ Efforts to attach a class to the caller so that its destructor can clean up the generator (e.g. if
⍝H   stuck waiting or looping) lead to interpreter problems.
⍝H ∘ The original approach was to use classes entirely, with comparable problems. Instead we use a namespace
⍝H   structure to emulate class instances without any destructor. It works.
⍝H
⍝H
⍝H Overview:
⍝H
⍝H A.  Call generator <myGen> with right argument <myArg>:
⍝H     mg←myGen gen.erator myArg
⍝H     ∘ Note: the right arg is passed to myGen as ⍵.
⍝H       ⍺ will always contain the generator namespace.
⍝H       Any left arg is stored as ⍺.alpha (and ⍺.hasAlpha=1 if a left argument was passed).
⍝H       If no left arg, ⍺.alpha is undefined (and ⍺.hasAlpha is 0).
⍝H     ∘ Returns: the value returned from the generator is in
⍝H       gen.value (undefined until the function terminates).
⍝H       The return value is otherwise UNUSED.
⍝H
⍝H B. Key Elements
⍝H   0. Setup            gen.TRAP 'gen1 gen2 ...'     ⍝H Setup the trap gen1 etc to cleanup generator (threadids and tokens) on failure.
⍝H   1. Initialization:  mg ← [⍺] <generator> gen.erator ⍵
⍝H   2. Return value:    mg.value
⍝H   3. In caller:
⍝H        Receiving/sending values to/from generator
⍝H                       <val>←mg.next               ⍝H Waits for value from generator's yield. Sends a dummy ⎕NULL.
⍝H                       val←mg.send <newArg>        ⍝H Waits as above, sending arbitrary data (even a ⎕NULL).
⍝H                       [errno] mg.signal <message> ⍝H Waits as above, sending a msg which the generator interprets as
⍝H                                                     default: exit now: yield immediately returns <message> as "last" value, closing stream.
⍝H                                                     errno>0: yield generates  <message> ⎕SIGNAL errno
⍝H                                                     other errno (≤0) not allowed.
⍝H        Is a msg from generator waiting?
⍝H                       mg.more
⍝H                       mg.done
⍝H        Special Handling via Signals in caller
⍝H                       mg.STOPITERATION
⍝H                       set:    ⎕TRAP (mg.STOPITERATION)'C' '→done'
⍝H                       tradfn: TRAP mg.STOPITERATION ⋄ ...
⍝H                       dfn:    mg.STOPITERATION::⍺ ∇ transform* ⍵
⍝H                       mg.close
⍝H
⍝H                                                     * transform is whatever code you want
⍝H   4. In generator:
⍝H       Did the caller provide a left arg ⍺ to the generator on the gen.erator call?
⍝H                       ⍺.hasAlpha, ⍺.alpha
⍝H       Sending values to caller (⍺ is always the generator namespace, ⍺.alpha is the caller's left arg):
⍝H                       _←⍺.yield valueOut                     ⍝H Always returns shy ⎕NULL. If there is a new valueIn, signals YIELDVALUE
⍝H       Special handling via Signals in generator
⍝H                       dfn: ⍺.YIELDVALUE:: ⍺ ∇ transform* ⍺.yieldValue  ⍝H When there's a real value from caller.
⍝H       Sending values to and receiving values from caller:
⍝H                       valueIn←⍺.yieldValue valueOut          ⍝H Won't distinguish caller-sent ⎕NULL and ⎕NULL qua no value...
⍝H       Sending values to and receiving values from caller, distinguishing caller-sent ⎕NULL and ⎕NULL qua no value...
⍝H       yieldS (yield with status)
⍝H                       isData valueIn←⍺.yieldS valueOut       ⍝H isData is 1 if real data; else valueIn=⎕NULL, isData=0.
⍝H
⍝H                                                     * transform is whatever code you want
⍝H IN CALLER
⍝H ¯¯ ¯¯¯¯¯¯
⍝H ∘ Request next yield-ed (quasi-returned) datum:
⍝H     data←mg.next
⍝H ∘ Request next yielded datum, possibly ignored, while sending new value <new> to generator;
⍝H   this signals a mg.YIELDVALUE signal to the generator, retrieved as ⍺.yieldValue
⍝H     data←mg.send <new>
⍝H ∘ See if there's more data from the generator:
⍝H     :IF mg.more
⍝H         ...
⍝H     :Until mg.done
⍝H ∘ Tell the generator we're done, even if there's more data:
⍝H     mg.close
⍝H ∘ Send a signal to the generator with signal <en> and text message <message>:
⍝H     en mg.signal message
⍝H ∘ Send a signal to the generator to exit NOW, but quietly, with arbitrary datum <myStuff>
⍝H   the value returned by the yield will be <myStuff>.
⍝H     mg.signal message
⍝H ∘ Terminate a loop if the generator has no more data:
⍝H     :Trap mg.STOPITERATION ⋄ :While 1
⍝H         ... stuff in the loop
⍝H     :EndWhile ⋄ :EndTrap
⍝H     ... stuff after the loop ...
⍝H
⍝H IN GENERATOR
⍝H ¯¯ ¯¯¯¯¯¯¯¯¯
⍝H  ∘ Send next datum <myStuff> to "yield" (quasi-return) back to the caller.
⍝H     ⍺.yield myStuff
⍝H  ∘ Normally, yield is sent ⎕NULL data from <next>. When the caller sends data (via <send data>),
⍝H    a ⍺.YIELDVALUE is signalled in the generator and ⍺.yieldValue contains the data sent. That is
⍝H    ⍺.yield normally returns the value ⎕NULL and ⎕SIGNALs on any value sent via <send>.
⍝H      nextIntGen←{
⍝H         ⍺.YIELDVALUE:: ⍺ ∇ ⍺.yieldValue
⍝H         ⍺ ∇ ⍵+1
⍝H      }
⍝H      ...OR...
⍝H      ∇b←mg nextIntGen first;next
⍝H       next←first
⍝H       :Repeat ⋄ :Trap mg.YIELDVALUE
⍝H           :WHILE 1
⍝H               mg.yield next ⋄ next +← 1
⍝H           :EndWhile
⍝H         :ELSE
⍝H             next←mg.yieldValue
⍝H         :EndTrap ⋄ :EndRepeat
⍝H      ∇
⍝H  ∘ yieldValue is like yield, except it simply returns data sent from the caller via <send data>.
⍝H    Since a <next> is really a special kind of send, the yield receives a ⎕NULL marked as no data.
⍝H    if ⎕NULL is a possible value. (In this case, use the ⍺.YIELDVALUE signal.)
⍝H  ∘ yieldValue: hen the generator is called initially with right arg ⍵, ⍺.yieldValue is initially set to ⍵.
⍝H    Whenever the caller issues a <send data>, ⍺.yieldValue←data (see ⍺.YIELDVALUE signal above).
⍝H  ∘ Returning: Complete the work of the generator and let the caller know we're done;
⍝H    simply exit:
⍝H      myGen←{...
⍝H        _←⍺.yield myYIELDVALUE
⍝H       if_true: myreturnvalue
⍝H      }
⍝H  ∘ Returning a value in the yield with complete control: yieldS, which returns 1|0 depending on whether a value was received.
⍝H         ⊃ok newVal←⍺.yieldS val: process newVal
⍝H    If a <next> was used in the caller, yieldS will receive (0 ⎕NULL) which can be processed in the usual way.
⍝H  ∘ Abnormally terminate the generator itself, signalling the caller with the identical signal;
⍝H    here, we terminate the generator with signal 911 and message 'The generator is exhausted'
⍝H    and send the same signal to the caller.
⍝H     ⎕SIGNAL/'The generator is exhausted' 911

:endNamespace
