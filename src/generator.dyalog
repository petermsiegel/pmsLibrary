:namespace Generator
⍝!  For description/help, see function ∘help∘ below.
⍝!  For a demo, see Demo below.
⍝

 Gen← { ⍺←0 ⋄ genNs.genNs∘← genNs∘← ⎕NS genLib ⋄ genNs.debug← ⍺ 
      0::  utilNs.GenErr⍬ ⋄ 1000:: utilNs.Interrupt⍬  
        genNs.(toGen fromGen) tokNs.Cur∘← tokNs.Reserve tokNs.cur 
        genNs.genId← ⍺⍺ genNs.{  
          0:: utilNs.GenErr ⍬ ⋄ 1000:: utilNs.Interrupt ⍬
            genName⊢← 'Gen[tid=',(⍕⎕TID),', toGen=',(⍕toGen),']' 
            _← ⎕DF genName ⋄ ⎕TNAME← genName
            _← ⎕TPUT fromGen                      ⍝ All vars are set. Tell user  
          ⍝ ↓↓↓↓↓↓  RUN THE GENERATOR ↓↓↓↓↓↓ ⍝   
          ⍝ ↓↓↓↓↓↓ Returning ¨result¨ ↓↓↓↓↓↓ ⍝                  
            ⎕THIS.result← ⎕THIS ⍺⍺ ⍵   
          ⍝ ↑↑↑↑↑↑ ↑↑↑ ↑↑↑ ↑↑↑↑↑↑↑↑↑ ↑↑↑↑↑↑ ⍝ 
            genStatus⊢← 0 ⊣ ⎕DF genName,' [terminated]'
            1: _←⎕THIS.result
        }& ⍵
        genNs←genNs  ⍝ Why is this necessary? Dyalog bug?!?!
      0= ≢ genNs.INIT_WAIT ⎕TGET genNs.fromGen: 11 ⎕SIGNAL⍨'Generator did not start up properly!'
        genNs 
  }
  ##.Gen← ⎕THIS.Gen

:Namespace genLib
⍝ Const for Generator Objects (cloned)
  ⎕IO ⎕ML←0 1
  GENSTOP_EM GENSTOP_EN GENFAIL_EN← 'GENERATOR STOP SIGNAL' 901  911
⍝ INIT_WAIT: wait <INIT_WAIT> seconds for generator preamble to startup and handshake
  INIT_WAIT← 2
⍝ End Const

⍝ Vars for Generator Objects (cloned)
  debug← 0
⍝ stopWait: wait after notifying generator that an GENSTOP_EN Signal has been requested
⍝ See SetStopWait above
  stopWait←  0.005   ⍝ See SetStopWait
⍝ genNs: Defined in cloned Generator namespace
  genNs toGen fromGen← ⎕NULL 0 0 
⍝ genStatus: 1 (active), 0 (terminated/completed)
  genStatus genId error genName← 1 ⎕NULL ⎕NULL ''
  result← ⎕NULL 
⍝ End Vars

⍝ User "Methods"
  SetStopWait← stopWait∘{ stopWait⊢← ⍵ ⍺⊃⍨ 0=≢⍵ }
  ∇ r←Done  ⍝ goes in user or generator
    r← 0= genStatus
  ∇
  ∇ r←More  ⍝ goes in user or generator
    r← 0≠ genStatus
  ∇
⍝ code in_msg← [timeout← infinite] Yield out_msg
  Yield← {  ⍝ Generator only
        ⍺← ⊢ ⋄ timeout← ⍺
      ⎕TID≠ genId: 'Yield only valid in generator code' ⎕SIGNAL 11 
      0= genStatus: (utilNs.Terminate 0)  ⎕SIGNAL 911
          code msgIn← ⊃timeout ⎕TGET toGen
      code=0:   _← msgIn⊣ 0 ⍵ ⎕TPUT fromGen
      code>0:   (⍕msgIn) ⎕SIGNAL code 
      code=¯1:  GENSTOP_EM ⎕SIGNAL GENSTOP_EN 
          'Yield: Invalid left arg' ⎕SIGNAL 11
  }
⍝  r←Next  Returns next message from generator.
 ∇ r←Next  ⍝ user only
    :TRAP 0 ⋄ r←Send ⎕NULL
    :ELSE   ⋄ utilNs.ErrDmx⍬
    :Endtrap
∇
⍝  ⍺ Send ⍵
⍝  ⍺ is...?
⍝    0: std send 
⍝   >0: send signal ⍺ to generator 
⍝   ¯1: send "end generator" (signal 901), returning "result" if present.
⍝  If code=0,
⍝    returns output from generator, if code=0.
⍝  If generator has already terminated, 
⍝    signals an error message in the user (caller of Send).
⍝  Otherwise, prioritizes its message to the generator, and
⍝    returns result, if available, else ⎕NULL.
  Send← { ⍝ user only
        ⍺← 0 ⋄ code msg← ⍺ ⍵
    0::  utilNs.ErrDmx⍬
    ⎕TID= genId: 'Next/Send not valid in generator code' ⎕SIGNAL 11 
    1≠≢⍺:        'Domain Error: Send option (⍺) is invalid' ⎕SIGNAL 11
      fail← (0= genStatus)∨ genId(~∊) ⎕TNUMS
    fail: (utilNs.Terminate 0) ⎕SIGNAL GENFAIL_EN⊣ utilNs.Cleanup⍬
    code= 0: _← ⊃⌽⊃⎕TGET fromGen ⊣ 0 ⍵ ⎕TPUT toGen  
      _← ⎕TGET ⎕TPOOL∩fromGen⊣ code utilNs.TPutFirst msg  
      _← utilNs.Cleanup ⍬ 
    1: _← utilNs.GetResult⍬ 
 }

⍝ r← MsgAvail   
⍝    1 if there is a message waiting for me (user or generator)
⍝    Typically useful only in generator, 
⍝    e.g. waiting for user "Next" cmd before doing a Yield
∇ r← MsgAvail  ⍝ goes in user OR generator 
  :IF 0= genStatus ⋄ r←0
  :Else ⋄ r← ⎕TPOOL∊⍨ fromGen toGen⊃⍨ ⎕TID= genId
  :Endif 
∇
⍝ Return: Signals the generator to stop (via ⎕SIGNAL GENSTOP_EN), 
⍝             returning the generator's result as ¨result¨.
⍝         If it doesn't return normally (trapping the signal) within stopWait seconds,
⍝            ¨result¯ will be undefined.
∇ {r}← Return ⍝ user or generator
   ;_
  :IF ⎕TID= genId  ⍝ generator
       GENSTOP_EN ⎕SIGNAL⍨ utilNs.Terminate 1
      :RETURN
  :ENDIF  
  :TRAP 0   
      _← ¯1 Send ⎕NULL  
  :ELSE     
      utilNs.ErrDmx ⍬
  :ENDTRAP
  r← utilNs.GetResult⍬
∇ 

⍝ Internal Utilities
  :Namespace utilNs
  ⍝ TPutFirst: Send msg ahead of all others. Internal only
    TPutFirst← ##.{ V← ⎕TGET T← ⎕TPOOL∩ toGen ⋄ ((⍺ ⍵),V) ⎕TPUT (toGen, T)}
  ⍝ GetResult:  ⍺⍺ ∇ ⍵⍵⊢ ⍬
  ⍝     ⍺⍺: 'result' ⋄ ⍵⍵: # tries (e.g. 3), each with a delay of stopWait÷⍵⍵.
    GetResult← 'result'##.{⍺←⍵⍵⋄⍺≤0:⎕NULL⋄2=⎕NC⍺⍺:⎕OR⍺⍺⋄1:⍵∇⍨⍺-1⊣⎕DL stopWait÷⍵⍵}3
    Cleanup← { 
          _← 1 ⎕TGET ⎕TPOOL∩##.(toGen,fromGen) ⋄ _← ##.(⎕DF genName,' [terminated]')
          TK← { ⎕TKILL ##.genId ⊣ ⎕DL ##.stopWait }
        ##.genId∊⎕TNUMS: TK& ##.genStatus⊢←  0 Blab Terminate 1
        1:                   ##.genStatus⊢←  0 Blab Terminate 0
    }
    Dmx← { ⊂⎕DMX.('EM' 'EN' 'Message',⍥⊂¨ ('Generator: ',EM) EN Message) }
    GenErr← ⎕SIGNAL { Dmx ⊣ Cleanup Blab ⊢##.error∘←  ↑(⊂'Gen: '),¨⎕DMX.DM }
    ErrDmx← ⎕SIGNAL Dmx  
    Interrupt← ⎕SIGNAL {⊂'EM' 'EN' ,⍥⊂¨ (Terminate 2) 911⊣ Cleanup ⍬ }
    Blab← ##.{ ⍺←⍬ ⋄ debug: ⍺⊣ ⎕← ⍵ ⋄ ⍺ }
      termMsgs← 'has been terminated' 'terminating' 'was interrupted' 'LOGIC ERROR!'
    Terminate← termMsgs∘ ##.{'Generator thread ',(⍕genId),' ', ⍺⊃⍨ 0⌊3⌊⍵}
  :EndNamespace ⍝ utilNs

:EndNamespace ⍝ GenNs

⍝ Token management
:namespace tokNs 
  EACH MIN COUNT←2 1003741824 10000  
  DEFAULTS← MIN EACH MIN COUNT
  cur← MIN 
⍝ Reserve: Reserve a pair of contiguous threadids from a range of "reserved" thread ids.
⍝ Returns (the new set of tokens)(the updated tokNs.cur)
  Reserve← {  ⍝ Internal use only 
      defaults← DEFAULTS
      cur each min cnt← 4↑ ⍵, defaults↑⍨0⌊¯4+≢⍵
      0{  
        tries← ⍺
        cur← min+ cnt| |min- ⍵⌈min
        tries≥ cnt:11 ⎕SIGNAL⍨'GetNext: Can''t find ',(⍕each),' tokens in range [',(⍕min),',',(⍕min+cnt-1),']'
        1∊⎕TPOOL∊⍨ new← cur+ ⍳each: ⊃∇/ tries cur+ 1 
        new (cur+each)
      }cur 
  }
:EndNamespace ⍝ tokNs

:Section Examples
⍝ Demo (Example):  Return ndig of random digits (imagining this is very timeconsuming!)
  ∇ Demo
    ; ndig; x

    RandG←{ ⍝ Sample generator'
        big ⎕PP ndig nrequests←(2*31)34 34 0
      901:: nrequests    ⍝ Return value 
        Exec← ⍺.Yield{ ndig>≢⍵:∇ ⍵,⍕?big ⋄ ⍵↑⍨-ndig}
        Rcv←{ nrequests+←1 ⋄ ⎕NULL=⍵: ⍵ ⋄ ⊢ndig⊢←⍵ 34⊃⍨⍵=0} 
        {∇ Rcv Exec ⍬}⍬  ⍝ This will go forever until an x.Return or ¯1 x.Send 'Msg'
  }
    ⎕←⎕VR 'Demo'
    'Demo' ⎕TRACE⍨  (⊃⎕LC)+1+⍳100
    x← RandG Gen⍬
    '>>> Getting value based on default ndig'
    x.Next 
    :For ndig :in 50 25 10
        ⊢x.Send ndig   ⍝ 34 digits for the requested random #s
        '>>> Requested new ndigits:', ndig
        x.Next
    :EndFor
    x.Next 
  ⍝ ... many days later
    '>>> Asking RandG to return ¨nrequests¨ (the # of requests)'
    'x.Return: We processed',x.Return,'requests'
    '>>> DEMO COMPLETE!'
  ∇ 
  ##.⎕FX ⎕CR 'Demo'
  ⎕← (⍕##.⎕THIS),'.Demo installed.'
:EndSection ⍝ Examples

:Section Help
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

:EndSection Help
:endNamespace
