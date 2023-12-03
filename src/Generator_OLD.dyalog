:namespace Generator
⍝!  For description/help, see function ∘help∘ below.
⍝
⍝   Namespace is <Generator>, but we export <gen> as a niladic function 
⍝   in parent that points to this namespace...
⍝   gen: makes gen.erator and gen.generator visible as equiv. to ⎕NEW
   ∇ns←gen
    ns←⎕THIS     
   ∇
    _←##.⎕FX '⎕THIS' ⎕R (⍕⎕THIS)⊣⎕NR 'gen'      

⍝ CLASS SHARED CONSTANTS  (*) All class constants are replicated to clones
    ⎕IO ⎕ML←0 1
    DEBUG←0
⍝
⍝ INTERNAL-ONLY SHARED CONSTANTS  (*) See above.
    HASVALUE←0
    NOVALUE←¯1
    EXITNOW←¯911                 ⍝ Quietly exit now.

  ⍝ SHUTDOWNDELAY: delay in seconds when shutting down a generator before doing a ⎕TKILL. See function shutdown
    SHUTDOWNDELAY ← 0.001
  ⍝ ∆TRAP, ∆TRAPI - only valid/userful in caller top-level routines.
    ∆TRAP         ← (0)'C' '⎕SIGNAL/⎕DMX.(EM EN)⊣close'
    ∆TRAPI        ← (0 1000)'C' '⎕SIGNAL/⎕DMX.(EM EN)⊣close'

⍝ USER CLASS SHARED CONSTANTS
    YIELDVALUE←900               ⍝ Signal generator we have a new value in ⍺.yieldValue
    STOPITERATION←901
    eSTOPITERATIONg←'gen: Generator has signalled a STOPITERATION. [return value in ⍺.value]'
    eSTOPITERATIONc←'gen.yield: StopIteration received: Caller not accepting yield messages.'

⍝ CLASS-ONLY SHARED VARIABLES [not used in clones]
⍝   token~: Token numbers in range: tokenBase + ⍳tokenModulo (each call uses 2 tokens)
⍝     Bug: There should be a token manager so we don't give out tokens some other op is using.
⍝     Bug: We cycle through the 10000 tokens without checking. If an earlier one is in use, watch out.
    tokenBase tokenIncr tokenModulo← 1003741824 2 100000
⍝                                    ↑      ↑ ↑___ total num of tokens set aside for <gen> use.
⍝                                    ↑      ↑___ num tokens per generator
⍝                                    ↑___ starting token num
⍝
    curToken←0              ⍝ offset for NEXT generator's two tokens

⍝ CLASS SHARED FUNCTIONS
    ∇ active;ids
       ids←  ( ⊢(/⍨) (tokenBase∘≤)∧ <∘(tokenBase+tokenModulo) ) ⎕TPOOL
      'Active ids:     ',(⎕IO+0<≢ids)⊃'None'ids
    ∇

⍝ USER SHARED FUNCTION
⍝
⍝ [verbose←0] gen.TRAP names
⍝ ∘ where verbose defaults to 0 (not verbose), but may be set to 1 (verbose).
⍝ ∘ where names is a char vector with one or more generator variable names, separated by blanks.
⍝ Action:
⍝   "Sets ⎕TRAP in its caller to signal the local interrupt to the calling fns caller (⎕TRAP should be localized in the caller).
⍝    If verbose=1, then verbosely reports that the generator was interrupted.
⍝    Returns shyly the trap codestring (element 2+⎕IO), suitable for use in a dfn. (In this case, ⎕TRAP is of no consequence)."
⍝ Example: To cleanup on error for 3 generators named 'NAME1 NAME2 NAME3', do:
⍝     tradfn:    gen.TRAP 'NAME1 NAME2 NAME3'      →  ⎕TRAP←(0 1000)'C' '⎕SIGNAL/⎕DMX.(EM EN)⊣(NAME1 NAME2 NAME3).close'
⍝        dfn:    0:: ⍎gen.TRAP 'NAME1 NAME2 NAME3' →  0:: ⍎'⎕SIGNAL/⎕DMX.(EM EN)⊣(NAME1 NAME2 NAME3).close'
⍝ Example2: To cleanup after generator 'gen1' with verbosity:
⍝     tradfn:    1 gen.TRAP 'gen1'                 →  ⎕TRAP←(0 1000)'C' '⎕SIGNAL/⎕DMX.(EM EN)⊣(gen1).close⊣⎕←''Generator interrupted...'''
⍝
    ∇ {trapCode}←{verbose}TRAP names;augment;monadic;n2
      monadic←(900⌶)0 ⋄ n2←' '∊names
      augment←monadic{⍺:'' ⋄ verbose/⍵}'⎕←''Generator interrupted (',(n2/'one of: '),names,')'''
      names←(n2/'('),names,n2/')'
      trapCode←'→0⊣{0::⍬ ⋄ ',names,'.close}',augment,'⊣⎕←↑⎕DMX.DM'
      ⎕TRAP←(0)'C'trapCode               ⍝ Sets caller's ⎕TRAP!
    ∇

    GetTokenPair←{
      ⍺←0 ⋄ tries←⍺ ⋄ defaults←67108864 1000 0
      firstTok nTok curTok←3↑⍵,defaults↑⍨0⌊¯3+≢⍵
      curTok←firstTok+nTok||curTok-firstTok
      tries≥nTok:11 ⎕SIGNAL⍨'GetNext: No free token pair in range [',(⍕firstTok),',',(⍕firstTok+nTok),']'
      1∊⎕TPOOL∊⍨curTok+0 1:(tries+1)∇ firstTok nTok(curTok+2)
      curTok+0 1
    }

⍝ CLONE METHODS (INSTANCE FUNCTIONS)
⍝ "Private" to each generator "clone"
⍝ We set them here to establish their scope.
  ⍝ generator tokens (from class shared variables above)
    genOut genIn←⎕NULL             ⍝ must be set in generator clone
  ⍝ In each clone, 1 or 0. When 0, instructs generator and caller to exit on next yield/next/send...
    genValid← ⎕NULL              ⍝ must be set in genClone ns
  ⍝ genStack: Only used in caller methods. Supports peeking needed in <more> and <done>.
  ⍝           NEVER used by generator.
    genStack←⎕NULL                  ⍝ must be set to ⍬ in genClone ns
  ⍝ yieldValue: Will contain the yieldValue (updated ⍵) sent from the caller to the generator
    yieldValue←⎕NULL               ⍝ must be set in genClone ns
  ⍝ genId: In each clone, the thread id of the clone. Set to 0 to deactivate.
    genId←0                       ⍝ must be set to an actual threadId in genClone ns
  ⍝ hasAlpha: 0 by default. 1 if the generator was called with a left argument.
    hasAlpha←0
  ⍝ alpha: undefined in clones by default. The value of ⍺, if generator was called with a left arg.
    alpha←⎕NULL
  ⍝ value: the value returned from the generator. Undefined until the generator returns.

⍝ Token structure
⍝ On each token we send/receive
⍝     status  value
⍝     0    sending a value
⍝    ¯1    not sending a value
⍝    >0    value is a signal text. type is signal number
⍝    901   value is ignored. Will signal eSTOPITERATION in caller
⍝   ¯911   value is omitted. Exit immediately
⍝
⍝
⍝ Generator routines...
⍝ Proc: srv.yield
⍝ Proc: srv.yieldNew
⍝ Var:  srv.yieldValue   ⍝ local variable (q.v.)
⍝
⍝ resp← [⍺] srv.yield val
⍝ ∘ If ⍺=0 (default): 
⍝     ⎕SIGNAL YIELDVALUE when given a new value via getStatus=HASVALUE.
⍝ ∘ If ⍺=1: 
⍝     simply wait for an return the YIELDVALUE (via getStatus=HASVALUE) (see yieldNew).
⍝     In this case, we can't distinguish ⎕NULL sent to generator from ⎕NULL indicating no value.
⍝ ∘ If ⍺=¯1:
⍝     resp← (1 newValue) if a value was sent;
⍝     resp← (0 ⎕NULL)    if no value was sent.
      yield←{
        ⍝ ⍺=0: handle newValue received via signal; 1: simply return; 2: return (1 newValue) or (0 ⎕NULL)
          ⍺←0    
          STOPITERATION:: ⎕SIGNAL/ { genValid∘←0 ⋄ ⍵⊣(⌽⍵)⎕TPUT genOut } ⎕DMX.(EM EN)
          _←⎕DL 0
          0≥genValid: ⎕TKILL ⎕TID⊣ genId←0      
          _←0 ⍵ ⎕TPUT genOut
          getStatus getValue←⊃∆TGET genIn
          getStatus>0:(⍕getValue)⎕SIGNAL getStatus⊣genValid genStack∘←0 ⍬
          getStatus=EXITNOW:_←⍺{⍺=¯1:0 ⍵ ⋄ ⍵}getValue⊣genValid genStack∘←0 ⍬         ⍝ Return this value. Error on next
          getStatus=NOVALUE:_←⍺{⍺=¯1:0 ⍵ ⋄ ⍵}getValue                                ⍝ getValue should be ⎕NULL,
          getStatus≠HASVALUE:⎕SIGNAL/('yield: did not understand received status flag',(⍕getStatus),'with data',⍕getValue)11
        ⍝ getStatus=HASVALUE:...
          yieldValue∘←getValue                                       ⍝ HASVALUE: Simply return new value...
          ⍺=¯1:1 yieldValue
          ⍺=1:yieldValue
          ⎕SIGNAL YIELDVALUE                                           ⍝ HASVALUE and ⍺=0: Signal there's a new value..
      }
    yieldNew←1∘yield
    yieldS←¯1∘yield   ⍝ verify with status

⍝ Caller routines:
⍝   g← [⍺] ⍺⍺ generator ⍵
⍝   g.next
⍝   g.ok
⍝   g.done
⍝   g.close
⍝   g.send
⍝   g.signal

  ⍝ genHandle←<generator:⍺⍺> genLib.generator <value>
  ⍝
      generator←{⍺←⊢
          genClone←⎕NS ⎕THIS
          0::⎕SIGNAL/⎕DMX.(EM EN)⊣ Cleanup 1
          Cleanup← genClone∘{
                genValid genStack⊢← 0 ⍬
                _← STOPITERATION eSTOPITERATIONg ⎕TPUT genOut
                _← ⎕NULL ⎕TPUT ⎕TPOOL∩genIn,genOut
                _← ⎕DL 5
                _← ⎕TGET ⎕TPOOL∩genIn,genOut
                _ ⊣ ⎕TKILL⍣ (⍵≡1)⊣ genId⊣ ⎕DL 5
          } 
          _←⍺{⍺←⊢ ⋄ ~⍵.hasAlpha←1≢⍺ 1:⍵.⎕EX'alpha' ⋄ ⍵.alpha←⍺}genClone    ⍝ Set genClone.(alpha hasAlpha)
          genClone.genOut genClone.genIn curToken ←GetTokenPair tokenBase tokenModulo curToken 
          callGenerator←{
            ⍝ Prepare to start generator... Set ⍺.genId, ⍺.⎕TNAME, and ⍺.⎕DF
              ⍺.(⎕TNAME←name∘←'generator [⎕TID ',(⍕genId∘←⎕TID),', tokens OUT/IN ',(⍕genOut),'/',(⍕genIn),']')
              ⍺.(_←⎕DF name)
              0::⎕SIGNAL/⎕DMX.(EM EN)⊣  Cleanup ⍬
              ⍺.(genValid genStack yieldValue∘←1 ⍬ ⍵)
            ⍝ Call function ⍺⍺. When complete, the generator has stopped.
            ⍝ Cleanup genValid and genStack: caller will be notified if it requests more info.
            ⍝ Share return value as ⍺.value
              ⍺.value←⍺ ⍺⍺ ⍵ ⋄ _← Cleanup 1  ⍝ Do in lockstep.
            1: _←⍺.value                                    
          }
          genClone⊣genClone ⍺⍺ callGenerator&⍵   ⍝ Executed if ⍝SKIP2 is commented out!
      }

  ⍝ gen.erator
  ⍝ Syntax:   g ← {func} gen.erator initialValue
  ⍝ ALIAS for gen.generator
    erator←generator

    ∇ val←next
      ;⎕TRAP
      ⎕TRAP←∆TRAP
      val←NOVALUE send ⎕NULL
    ∇

      sendHandshake←{
          putStatus putValue←⍺ ⋄ getStatus getValue←⍵
          getStatus=HASVALUE:_←getValue⊣putStatus putValue ⎕TPUT genIn
          (getStatus>0)∧0≠≢getValue:⎕SIGNAL/getValue getStatus
          getStatus>0:⎕SIGNAL getStatus
          getStatus=NOVALUE:⎕SIGNAL/'sendHandshake: Generator yielded a token with no value!' 11
          getStatus≠EXITNOW:⎕SIGNAL/('sendHandshake: getStatus of unknown type: ',⍕getStatus)11
          1:_←getValue
      }

    ⍝ {val} ← send value to generator and wait for a yield from generator
      send←{⍺←HASVALUE
          0 1000::⎕SIGNAL/⎕DMX.(EM EN)⊣close
          ×≢genStack:_←⍺ ⍵ sendHandshake(genStack∘←1↓genStack)⊢⊃genStack
          genValid<1:eSTOPITERATIONg ⎕SIGNAL STOPITERATION⊣genStack∘←⍬
          1:_←⍺ ⍵ sendHandshake⊃∆TGET genOut
      }

    ⍝ {val} ← [errNum←EXITNOW] signal errMsg
    ⍝ (Like Python "throw").
      signal←{
          0 1000::⎕SIGNAL/⎕DMX.(EM EN)⊣close
          ⍺←EXITNOW          ⍝ By default, server is no longer listening...
          0=⍺:'signal: Error code 0 not allowed'⎕SIGNAL 11
          ×≢genStack:_←⍺ ⍵ sendHandshake(genStack↓⍨← 1)⊢ ⊃genStack
          genValid<1:eSTOPITERATIONg ⎕SIGNAL STOPITERATION⊣genStack∘←⍬
          1:_←⍺ ⍵ sendHandshake HASVALUE ⎕NULL
      }

  ⍝ ⍺.more
  ⍝ Returns 1 if the next ⍺.next or ⍺.send will return a value.
  ⍝ Returns 0 if it will return ⎕NULL
    ∇ b←more
      ;⎕TRAP
      ⎕TRAP←∆TRAP
      :If ×≢genStack
          b←1
      :ElseIf genValid≤0
          b←0
      :Else
          genStack←∆TGET genOut   ⍝ peek at the next value and then stack it...
          b←genValid>0            ⍝ now verify genValid, which the generator could have altered!
      :EndIf
    ∇

  ⍝ ⍺.done
  ⍝ See ⍺.more.   ⍺.done ≡ ~⍺.more
    ∇ b←done
      ;⎕TRAP
      ⎕TRAP←∆TRAP
      b←~more
    ∇

  ⍝ ⍺.close: "Tells the generator to shutdown. Returns 1 if generator still active; else 0.
  ⍝           Does nothing if generator is inactive/shutdown."
    ∇ {active}←close
      ;⎕TRAP
      ⎕TRAP←∆TRAPI
      active←genId≠0   ⍝ Returns whether the generator stream was active or not (i.e. already closed)
      →0/⍨~active      ⍝ Do nothing if inactive
      shutdown 1
    ∇

 ⍝ shutdown: "Shuts down the generator, cleaning up the generator's threadid (genId) and tokens genIn, genOut.
 ⍝            If terminate/⍵ is 1, will ⎕TKILL the generator.
⍝             If 0, will not do so unless shutdown is called more than once."
    _SEENBEFORE_←0
    ∇ {ignore}←shutdown terminate;_;msg
      ignore←1
      (genId=0)_NOTE_'Asked to shut down thread that was already shutdown. Relaxing.'
      _NOTE_'>>> Shutting down active thread',(⍕⎕THIS),'.',⍕genId
      :If (~terminate)∧_SEENBEFORE_>0
          '>>> Recursive shutdown detected. Forcing thread to terminate!'
          terminate←1
      :EndIf
      _SEENBEFORE_+←1
      _NOTE_'genId now <',genId,'> genIn now<',genIn,'>'
      :If genIn≢⎕NULL ⋄ :AndIf ×genIn
          _NOTE_'Cleaning up token pool and state variables for',genId
          ⎕DL 0
        ⍝ Enable generator to process EXIT, but that's it.
          msg←EXITNOW eSTOPITERATIONg
          genValid←1 ⋄ msg ⎕TPUT genIn genOut
          genValid←0⊣⎕DL 0                    ⍝ Context switch encouraged.
          msg ⎕TPUT ⎕TPOOL∩genIn,genOut
          0 ⎕TGET ⎕TPOOL∩genIn,genOut ⋄ genIn genOut←0    ⍝ ⎕TREQ ⎕TNUMS
      :EndIf
      :If terminate
          :If ×≢genId∩⎕TNUMS
              _NOTE_'>>> the thread',genId,'was active. Will be terminated in',SHUTDOWNDELAY,'seconds.'
              _←SHUTDOWNDELAY{_←_NOTE_'Thread shutdown' ⋄ genValid∘←0⊣⎕DL ⍺ ⋄ genId∘←0⊣⎕TKILL ⍵}&genId
          :Else
              _NOTE_'--- the thread had already terminated.'
          :EndIf
          genId←0
      :EndIf
    ∇

⍝ utility...
⍝  ∆TGET: Workaround for, and same syntax as, ⎕TGET.
⍝    "Since ⎕TGET can't be interrupted, we "pause" every <granularity> seconds so a ^C will be seen.
⍝     When debugging, choose 5 or 10 seconds, otherwise say 30 or 60.
⍝     We also allow an "infinite" wait to be shorter during debugging."
⍝  r ← {waitSec} ∆TGET token
⍝       waitSec, token: as in ⎕TGET.
⍝
    ∇ {r}←{waitSec}∆TGET tok
      ;debug;granularity;monadic
      ;⎕TRAP
      ⎕TRAP←∆TRAPI
      debug←1 ⋄ monadic←(900⌶)0
       ⋄ granularity←debug⊃60 1  ⍝ 60 5
      waitSec←{⍵:debug⊃2147483647 300 ⋄ waitSec}monadic      ⍝ Set infinity, unless waitSec is set.
      :While 1=×waitSec
          :If ⍬≢r←granularity ⎕TGET tok ⋄ :Return ⋄ :EndIf
          _←⎕DL debug×0.1 ⍝ For testing only
          waitSec-←granularity+debug×0.1   ⍝ This may drift a bit.
      :EndWhile
      r←⍬          ⍝ ⍬ means timeout (unless user sent a ⍬)
    ∇

  ⍝ _NOTE_: For printing debugging notes.
    ∇ {null}←{ifAlso}_NOTE_ text
       ⋄ null←⍬
       ⋄ ifAlso←((900⌶)0){⍺:⍵ ⋄ ifAlso}1   ⍝ monadic: ifAlso←1.
      :If DEBUG∧ifAlso ⋄ ⎕←text ⋄ :EndIf
    ∇

   ∇ help;h 
      ⎕ED'h'⊣h←↑2↓'^\h*⍝(\h*$|\h)'⎕R''⊣⎕NR'help'
⍝
⍝ gen: Emulates a python-like generator (iterator function) using Dyalog tokens and threads.
⍝ ∘ Efforts to attach a class to the caller so that its destructor can clean up the generator (e.g. if
⍝   stuck waiting or looping) lead to interpreter problems.
⍝ ∘ The original approach was to use classes entirely, with comparable problems. Instead we use a namespace
⍝   structure to emulate class instances without any destructor. It works.
⍝
⍝
⍝ Overview:
⍝
⍝ A.  Call generator <myGen> with right argument <myArg>:
⍝     mg←myGen gen.erator myArg
⍝     ∘ Note: the right arg is passed to myGen as ⍵.
⍝       ⍺ will always contain the generator namespace.
⍝       Any left arg is stored as ⍺.alpha (and ⍺.hasAlpha=1 if a left argument was passed).
⍝       If no left arg, ⍺.alpha is undefined (and ⍺.hasAlpha is 0).
⍝     ∘ Returns: the value returned from the generator is in
⍝       gen.value (undefined until the function terminates).
⍝       The return value is otherwise UNUSED.
⍝
⍝ B. Key Elements
⍝   0. Setup            gen.TRAP 'gen1 gen2 ...'     ⍝ Setup the trap gen1 etc to cleanup generator (threadids and tokens) on failure.
⍝   1. Initialization:  mg ← [⍺] <generator> gen.erator ⍵
⍝   2. Return value:    mg.value
⍝   3. In caller:
⍝        Receiving/sending values to/from generator
⍝                       <val>←mg.next               ⍝ Waits for value from generator's yield. Sends a dummy ⎕NULL.
⍝                       val←mg.send <newArg>        ⍝ Waits as above, sending arbitrary data (even a ⎕NULL).
⍝                       [errno] mg.signal <message> ⍝ Waits as above, sending a msg which the generator interprets as
⍝                                                     default: exit now: yield immediately returns <message> as "last" value, closing stream.
⍝                                                     errno>0: yield generates  <message> ⎕SIGNAL errno
⍝                                                     other errno (≤0) not allowed.
⍝        Is a msg from generator waiting?
⍝                       mg.more
⍝                       mg.done
⍝        Special Handling via Signals in caller
⍝                       mg.STOPITERATION
⍝                       set:    ⎕TRAP (mg.STOPITERATION)'C' '→done'
⍝                       tradfn: TRAP mg.STOPITERATION ⋄ ...
⍝                       dfn:    mg.STOPITERATION::⍺ ∇ transform* ⍵
⍝                       mg.close
⍝
⍝                                                     * transform is whatever code you want
⍝   4. In generator:
⍝       Did the caller provide a left arg ⍺ to the generator on the gen.erator call?
⍝                       ⍺.hasAlpha, ⍺.alpha
⍝       Sending values to caller (⍺ is always the generator namespace, ⍺.alpha is the caller's left arg):
⍝                       _←⍺.yield valueOut                     ⍝ Always returns shy ⎕NULL. If there is a new valueIn, signals YIELDVALUE
⍝       Special handling via Signals in generator
⍝                       dfn: ⍺.YIELDVALUE:: ⍺ ∇ transform* ⍺.yieldValue  ⍝ When there's a real value from caller.
⍝       Sending values to and receiving values from caller:
⍝                       valueIn←⍺.yieldValue valueOut          ⍝ Won't distinguish caller-sent ⎕NULL and ⎕NULL qua no value...
⍝       Sending values to and receiving values from caller, distinguishing caller-sent ⎕NULL and ⎕NULL qua no value...
⍝       yieldS (yield with status)
⍝                       isData valueIn←⍺.yieldS valueOut       ⍝ isData is 1 if real data; else valueIn=⎕NULL, isData=0.
⍝
⍝                                                     * transform is whatever code you want
⍝ IN CALLER
⍝ ¯¯ ¯¯¯¯¯¯
⍝ ∘ Request next yield-ed (quasi-returned) datum:
⍝     data←mg.next
⍝ ∘ Request next yielded datum, possibly ignored, while sending new value <new> to generator;
⍝   this signals a mg.YIELDVALUE signal to the generator, retrieved as ⍺.yieldValue
⍝     data←mg.send <new>
⍝ ∘ See if there's more data from the generator:
⍝     :IF mg.more
⍝         ...
⍝     :Until mg.done
⍝ ∘ Tell the generator we're done, even if there's more data:
⍝     mg.close
⍝ ∘ Send a signal to the generator with signal <en> and text message <message>:
⍝     en mg.signal message
⍝ ∘ Send a signal to the generator to exit NOW, but quietly, with arbitrary datum <myStuff>
⍝   the value returned by the yield will be <myStuff>.
⍝     mg.signal message
⍝ ∘ Terminate a loop if the generator has no more data:
⍝     :Trap mg.STOPITERATION ⋄ :While 1
⍝         ... stuff in the loop
⍝     :EndWhile ⋄ :EndTrap
⍝     ... stuff after the loop ...
⍝
⍝ IN GENERATOR
⍝ ¯¯ ¯¯¯¯¯¯¯¯¯
⍝  ∘ Send next datum <myStuff> to "yield" (quasi-return) back to the caller.
⍝     ⍺.yield myStuff
⍝  ∘ Normally, yield is sent ⎕NULL data from <next>. When the caller sends data (via <send data>),
⍝    a ⍺.YIELDVALUE is signalled in the generator and ⍺.yieldValue contains the data sent. That is
⍝    ⍺.yield normally returns the value ⎕NULL and ⎕SIGNALs on any value sent via <send>.
⍝      nextIntGen←{
⍝         ⍺.YIELDVALUE:: ⍺ ∇ ⍺.yieldValue
⍝         ⍺ ∇ ⍵+1
⍝      }
⍝      ...OR...
⍝      ∇b←mg nextIntGen first;next
⍝       next←first
⍝       :Repeat ⋄ :Trap mg.YIELDVALUE
⍝           :WHILE 1
⍝               mg.yield next ⋄ next +← 1
⍝           :EndWhile
⍝         :ELSE
⍝             next←mg.yieldValue
⍝         :EndTrap ⋄ :EndRepeat
⍝      ∇
⍝  ∘ yieldValue is like yield, except it simply returns data sent from the caller via <send data>.
⍝    Since a <next> is really a special kind of send, the yield receives a ⎕NULL marked as no data.
⍝    if ⎕NULL is a possible value. (In this case, use the ⍺.YIELDVALUE signal.)
⍝  ∘ yieldValue: hen the generator is called initially with right arg ⍵, ⍺.yieldValue is initially set to ⍵.
⍝    Whenever the caller issues a <send data>, ⍺.yieldValue←data (see ⍺.YIELDVALUE signal above).
⍝  ∘ Returning: Complete the work of the generator and let the caller know we're done;
⍝    simply exit:
⍝      myGen←{...
⍝        _←⍺.yield myYIELDVALUE
⍝       if_true: myreturnvalue
⍝      }
⍝  ∘ Returning a value in the yield with complete control: yieldS, which returns 1|0 depending on whether a value was received.
⍝         ⊃ok newVal←⍺.yieldS val: process newVal
⍝    If a <next> was used in the caller, yieldS will receive (0 ⎕NULL) which can be processed in the usual way.
⍝  ∘ Abnormally terminate the generator itself, signalling the caller with the identical signal;
⍝    here, we terminate the generator with signal 911 and message 'The generator is exhausted'
⍝    and send the same signal to the caller.
⍝      ⎕SIGNAL/'The generator is exhausted' 911
⍝
    ∇

:endNamespace
