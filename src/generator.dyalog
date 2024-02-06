:namespace Generator
  ⎕IO ⎕ML←0 1
⍝!  For description/help, see function ∘help∘ below or ⍝H comments.
⍝!  For examples, see Demo below.

⍝H 
⍝H Gen: 
⍝H   Executes a generator ⍺⍺ with argument ⍵.
⍝H Quick Syntax:
⍝H         genNs← myGen Gen omega 
⍝H   Emulates a Python-like generator (iterator function) using Dyalog tokens and threads.
⍝H         Calls myGen with right arg omega and left arg (⍺) a namespace.
⍝H
⍝H   In the generator, ⍺ is the namespace with generator and user functions and variables:
⍝H         See ⍺.Yield, ⍺.Terminate, ⍺.STOP...
⍝H Syntax: result← [⍺←0] ⍺⍺ Gen ⍵
⍝H         ⍺⍺: the generator
⍝H          ⍵: the arg to the generator
⍝H          ⍺: debug←⍺, default 0
⍝H
⍝H In the generator code:
⍝H   To accept requests to stop iterating (e.g. to return a useful value), trap the STOP code:
⍝H      { ⍺.STOP:: return_value ⋄ _← ⍺.Yield my_data ... }
⍝H   To accept and trap requests to terminate, trap the FAIL code:
⍝H      { ⍺.FAIL:: 'I have failed' ⋄ _← ... }
⍝H   To note that debug has been set, use ⍺.debug:
⍝H      { ... ⋄ _← {⍺.debug: ⎕←'say this' ⋄ ⍬}⍬ ⋄ ... }
⍝H   To signal the generator has failed:
⍝H      { ... ⋄ ⎕SIGNAL ⍺.SIGFAIL ⋄ ... }
⍝H
⍝H In the user code:
⍝H   To await a normal return from the generator
⍝H     r← gen.Return    
⍝H     ⍝ 1st: issues a STOP to the generator 
⍝H     ⍝ 2nd: waits some time for the generator to stop
⍝H     ⍝ 3rd: returns gen.result in ¨r¨ if the generator has stopped promptly
⍝H            else returns ⎕NULL, with gen.resultSet=0
⍝H   To tell the generator <gen> to stop iterating:
⍝H     r← gen.Terminate            ⍝ Issues: SENDSTOP Send ⎕NULL  
⍝H
⍝H ===========================
⍝H FUNCTIONS FOR USER ONLY
⍝H ===========================
  Gen← { ⍺←0 
      0:: ⎕SIGNAL/⎕DMX.(EM EN)  
    ⍝ gNs: generator namespace instance, copied in from genLib
      gNs← ⎕NS genLib                   
      gNs.((toGen fromGen)← tokNs.ReserveToks ⍺)
      gNs.genId← ⍺ (⍺⍺ gNs.{   
        0::         ⎕SIGNAL 1∘uNs.Dmx⍬⊣ ⍺ tokNs.FreeToks toGen fromGen 
        FAIL STOP:: ⎕SIGNAL uNs.ErrorK ⎕DMX.EM 
          ⍝ Initialise
            debug← ⍺ ⋄ _← uNs.SetGenNm ⎕TID toGen fromGen  
          ⍝ Start the user's generator...
          ⍝ ... after signalling the user we're starting up
            result resultSet⊢← (⎕THIS ⍺⍺ ⍵) 1 ⊣ ⎕TPUT fromGen               
          ⍝ Prepare to return normally
            _← ⎕DF genName,' [returned]'     ⋄ _← uNs.DMsg MSGNORMAL 
            _← debug tokNs.FreeToks toGen fromGen  ⋄ _← uNs.SetGenTerm SIGSTOP  
          ⍝ Return the result
        1:  _← result                                       
      })& ⍵ 
    ⍝ Await msg to proceed from generator (above) & Return...
    ⍝ gNs← gNs: Deal with Dyalog bug??? 
      (gNs←gNs).(fromGen≡ INITWAIT_SEC ⎕TGET fromGen): gNs 
      ⎕SIGNAL gNs.SIGBADSTART                           ⍝ Gen never msg'd us. => Error.
  }
  ##.Gen←  ⎕THIS.Gen

:Namespace genLib   ⍝ These will be copied to gNs (the generator's private namespace, aka ⍺)
⍝ ========================================================================================= ⍝
⍝ Constants for Generator Objects (cloned)
  STOP FAIL← 901 911   
  SIGSTOP←      ⊂'EM' 'EN',⍥⊂¨'Generator signalled STOP ITERATION' STOP 
  SIGFAIL←      ⊂'EM' 'EN',⍥⊂¨'Generator has failed' FAIL
  SIGBADSTART←  ⊂'EM' 'EN',⍥⊂¨'Generator did not start up properly' 11
  SIGGENONLY←   ⊂'EM' 'EN',⍥⊂¨'Function only valid in generator code' 11 
  MSGNORMAL←    'Generator returned normally' 
⍝ INITWAIT_SEC:    (max) wait <INITWAIT_SEC> seconds for generator preamble to startup and handshake
⍝ CLEANUPWAIT_SEC: (max) wait after a generator termination (SIGFAIL) is requested before
⍝                 the generator is actually terminated (⎕TKILL)
  INITWAIT_SEC←    1 ⍝ sec
  CLEANUPWAIT_SEC← 1 ⍝ sec
⍝ Default return wait in milliseconds. See returnWaitMs
  RETURNWAITMS_DEF← 100
⍝ RETURNWAIT_TRIES: See returnWaitMs. Total tries to get result after signalling generator to STOP
⍝            its iterations. After each stop, wait returnWaitMs÷RETURNWAIT_TRIES ms.
  RETURNWAIT_TRIES← 20 
⍝ End Const
⍝ ========================================================================================= ⍝

⍝ ========================================================================================= ⍝
⍝ Vars for Generator Objects (to be cloned into gNs)
⍝ Begin genLib vars
  ⍝ debug:     from ⍺ in Gen call. 0 by default.
    debug← 0
  ⍝ returnWaitMs:  wait after a SIGSTOP signal to wait before checking if result is available.
  ⍝            Will wait up to returnWaitMs ms, perhaps 100 ms.
  ⍝            RETURNWAIT_TRIES (see Constants above).
    returnWaitMs← RETURNWAITMS_DEF  
    returnWaitSecEach← 0.001× returnWaitMs÷ RETURNWAIT_TRIES 

    genDead← 0        ⍝ If 1, the generator has terminated
  ⍝ result:    whatever the user generator returned (or ⎕NULL). If set, resultSet←1
  ⍝ genId:     the clone's thread # (set in Gen)
  ⍝ genName:   a descriptive name for the generator and thread, when initiated.
  ⍝ fromGen, toGen: 
  ⍝            the tokens used for synchronizing the generator...
    toGen← fromGen← genName← genId← ⎕NULL 
    result resultSet← ⎕NULL 0 
⍝ End genLib Vars
⍝ ========================================================================================= ⍝

⍝ ========================================================================================= ⍝
⍝H User "Methods"
⍝H --------------
⍝H  SetReturnWaitMs  
⍝H    Sets amount of time to wait in seconds in a g.Return call 
⍝H    for the generator to return a value, where resultSet← 1. 
⍝H    If it times out, ⎕NULL is returned, and resultSet← 0.
⍝H  Syntax: ∇ SetReturnWaitMs
⍝H      SetReturnWaitMs ⍬   - Sets returnWaitMs to its default value
⍝H      SetReturnWaitMs num - Sets returnWaitMs to <num> ms
⍝H    ∘ Returns: Prior returnWaitMs value (not the default value, unless the prior as well).
⍝H 
  SetReturnWaitMs← { was← returnWaitMs ⋄ returnWaitMs⊢← ⍵ RETURNWAITMS_DEF⊃⍨ 0=≢⍵  
    returnWaitSecEach⊢← 0.001× returnWaitMs÷ RETURNWAIT_TRIES 
     1: _← was 
  }
 
⍝H  GenDead (User only)
⍝H    Determine if generator thread is still active
⍝H  Syntax: b← ∇
⍝H    Returns 0 if the generator is still active; else 1.
⍝H 
  ∇ b← GenDead
    :If ~b← genDead ⋄ b← genDead← genId (~∊) ⎕TNUMS ⋄ :EndIf 
  ∇
⍝H GenActive
⍝H   Used in user code to determine if generator is active.
⍝H   In the generator, can be 0 if genDead←1, but it hasn't terminated yet.
⍝H Syntax: b← ∇
⍝H 
  ∇ b← GenActive  
    b← ~GenDead 
  ∇

⍝H  Next (in user code)  
⍝H    Returns next message from generator.
⍝H  Syntax: r← ∇
⍝H  ∘ Sends a ⎕NULL msg to the generator, returning a (hopefully useful) message from the generator.
⍝H  ∘ If the generator expects a contentful message, use Send.
⍝H  ∘ If an error occurs during the transaction, a signal is generated locally, reporting the error.
⍝H  ∘ The code ¨r← Next¨ is equiv. to ¨⊢Send ⎕NULL¨
⍝H 
  ∇ r←Next   
    :Trap 0 ⋄ r←Send ⎕NULL
    :Else   ⋄ ⎕SIGNAL 0∘uNs.Dmx⍬
    :Endtrap
  ∇
⍝H  NextN  (in user code)  
⍝H    Returns next message from generator.
⍝H  Syntax: results← ∇ count
⍝H  ∘ Sends a ⎕NULL msg to the generator <count> times, returning all <count> return messages from the generator.
⍝H  ∘ If the generator expects to receive a specific message besides ⎕NULL, use Send.
⍝H  ∘ If an error occurs during any transaction, a signal is generated locally, reporting the error.
⍝H
  NextN← { 0:: ⎕SIGNAL 0∘uNs.Dmx⍬ ⋄ { Send ⎕NULL }¨⍳⍵ }

⍝H  Send (in user code) 
⍝H  Syntax: {msgIn}← [isSig←0] ∇ msgOut
⍝H    isSig=0: Send a message to the generator and receive a message (msgIn) in return. 
⍝H    isSig=1: Send a signal to the generator as the next queued message and return ⎕NULL.
⍝H      
  Send← { ⍝ user only
      ⍺← 0 ⋄ sigOutFlag msgOut← ⍺ ⍵ 
    0::  ⎕SIGNAL 0∘uNs.Dmx⍬
      1: _← sigOutFlag SendRaw msgOut  
  }
⍝H  SendSig (in gen or user code) 
⍝H  Syntax: {msgIn}←  ∇ signal
⍝H    Sends a signal to the user (if send by gen) or gen (if by user); then,
⍝H    - signals a local stop signal, if the generator has been terminated;
⍝H    - signals a local <signalIn>, if we received a signal from the other party.
⍝H    Otherwise, returns any message <msgIn> received.
⍝H 
 SendSig← { 0:: ⎕SIGNAL 0∘uNs.Dmx⍬ ⋄ 1 SendRaw ⍵}
⍝H  SendRaw (in gen or user code) 
⍝H  Syntax: {msgIn}←  <sigOutFlag> ∇ <msg | signal>
⍝H    Sends a message (if sigOutFlag=0) or signal (if sigOutFlag=1)
⍝H      to the user (if send by gen) or gen (if by user); then,
⍝H    - signals a local stop signal, if the generator has been terminated;
⍝H    - signals a local <signalIn>, if we received a signal from the other party.
⍝H    Otherwise, returns any message <msgIn> received.
⍝H 
  SendRaw←{ 
      sigOutFlag msgOut← ⍺ ⍵
    GenDead:    ⎕SIGNAL SIGSTOP 
      to from← IsGen⌽ toGen fromGen
    sigOutFlag: { 
        _← ⎕TGET ⎕TPOOL∩to 
        _← sigOutFlag msgOut ⎕TPUT to 
      GenDead: ⎕SIGNAL SIGSTOP 
        1: _← msgOut
    } ⍬  
      sigInFlag msgIn← ⊃⎕TGET from ⊣ sigOutFlag msgOut ⎕TPUT to  
    sigInFlag: ⎕SIGNAL msgIn  
      msgIn               
 }

  
⍝H ============================
⍝H FNS FOR USER OR GENERATOR
⍝H ============================
⍝H 
⍝H  Return  (User or Generator) 
⍝H    Signals the generator to stop (via ⎕SIGNAL/ SIGSTOP), 
⍝H    returning the generator's result as ¨result¨ after waiting <returnWaitMs>
⍝H    If the generator HAS (already) stopped, returns result quietly.
⍝H  Syntax: r← ∇
⍝H          If Return traps the SIGSTOP signal, 
⍝H          returning normally within RETURNWAIT_TRIES×returnWaitMs ms, then
⍝H          ∘ ⍺.resultSet=1* and ⍺.result will be whatever the generator function returned; 
⍝H          otherwise, 
⍝H          ∘ ⍺.result* will be ⎕NULL and ⍺.resultSet←0.  
⍝H          Returns ⍺.result*.
⍝H                          * ⍺ is the generator namespace returned from operator Gen.
⍝H 
∇ r← Return    ⍝ user or generator
  ;tries 
  :If IsGen ⋄  ⎕SIGNAL SIGSTOP  ⍝ generator 
  :ElseIf GenDead ⋄ r← result 
  :Else 
    :Trap STOP 
      SendSig uNs.SetGenTerm SIGSTOP 
      tries←  RETURNWAIT_TRIES  
      :While (tries>0)∧ (~resultSet) ⋄ :AndIf ~GenDead    
          ⎕DL returnWaitSecEach 
          tries-← 1 
      :EndWhile
    :EndTrap 
    uNs.Cleanup⍬  
    r← result 
  :EndIf 
∇ 
⍝H  Terminate:  (User or Generator)
⍝H    Terminate the generator immediately, with a SIGFAIL signal as required.
⍝H  Syntax: r← ∇
⍝H  Returns: 
⍝H    In User:
⍝H       If the generator is not dead, terminate it and return 1.
⍝H       Else return 0.
⍝H    In Generator: Issues a SIGFAIL signal to itself, rather than returning.
⍝H
∇ {r}← Terminate   ⍝ user or generator 
  :If IsGen ⋄ ⎕SIGNAL SIGFAIL uNs.DMsg '[Gen] Processing a FAILURE signal'  
  :ElseIf r← ~GenDead  
    :Trap 0 
      SendSig SIGFAIL uNs.DMsg '[Usr] Sending generator a FAILURE signal'
      uNs.Cleanup uNs.DMsg '[Usr] Terminating generator',genId,'in',CLEANUPWAIT_SEC,'sec'
    :Else 
      ⎕SIGNAL 0∘uNs.Dmx⍬ 
    :EndTrap
  :EndIf
∇ 

⍝H  IsGen:  (User or Generator) 
⍝H     Returns 1 if in the generator; else 0.
⍝H  Syntax: r← ∇
⍝H
∇ r← IsGen
  r← genId= ⎕TID
∇
⍝H  MsgWaiting (user or generator)
⍝H    Check if there is a message waiting for me.
⍝H  Syntax: r← ∇
⍝H  Returns 1 if there is a message waiting for me, else 0.
⍝H
∇ r← MsgWaiting
  r← ⎕TPOOL∊⍨ IsGen⊃ fromGen toGen 
∇

⍝H ==========================
⍝H FNS FOR GENERATOR ONLY 
⍝H ==========================
⍝H
⍝H  Yield (Generator)  
⍝H    Wait for a code and msg <msgIn> and send a msg <msgOut> to the user.
⍝H    For typical Yield expressions, timeout is omitted and code and msgIn are ignored,
⍝H    indicating we are sharing data only!
⍝H         _← Yield my_next_result
⍝H    In such a case, an infinitely-running generator might be terminated via a Terminate function.
⍝H  Syntax:  msgIn← [timeout← infinite] ∇ msgOut
⍝H    1. Wait up to <timeout> seconds (default: infinite) for a code and
⍝H      message <msgIn> from the user. 
⍝H    2. Expecting a message of the form <code msgIn>, 
⍝H       if code=0, returns msgIn, after sending msgOut to the user code.
⍝H       otherwise, does a *LOCAL* ⎕SIGNAL msgIn.
⍝H
  Yield← {  ⍝ Generator only
    ⎕TID≠ genId:   ⎕SIGNAL SIGGENONLY
        ⍺← ⊢ ⋄ timeout←⍺ ⋄  msgOut← ⍵
    GenDead:       ⎕SIGNAL SIGSTOP                  ⍝ See if generator active before ⎕TGET
        r← timeout ⎕TGET toGen  
    0=≢r: 11 ⎕SIGNAL⍨ 'Yield: No message was received (timeout)'   
        isSig msgIn← ⊃r                           ⍝ Get the code and msgIn from user
    GenDead:       ⎕SIGNAL SIGSTOP                  ⍝ See if generator active after ⎕TGET
    isSig:         ⎕SIGNAL msgIn 
    1:             _← msgIn⊣ 0 msgOut ⎕TPUT fromGen  
  }

  :Section Generator utilities ⍝ (uNs)  
    :Namespace uNs
      SetGenNm←##.{ ⎕DF ⎕TNAME← genName⊢←'Gen[thread:',t,', tokens:[',gf,', ',g2,']]'⊣ t gf g2←⍵}⍕¨
      DMsg← { ⍺←⍵ ⋄ ##.debug∧0≠≢⍵: _← ⍺⊣ ⎕← 'Gen (debug): ',⍵ ⋄ 1: _←⍺ }
      Dmx← { ⍺←1 ⋄ ⎕DMX.(⊂'EN' 'Message' 'EM',⍥⊂¨ EN Message ((⍺/'Gen: '),EM)) }
      ∇ {errSpec}← SetGenTerm errSpec
        ##.genDead← 1
      ∇
      Cleanup← {  
            _← ⎕DL 0⊣ 0 ⎕TPUT ##.toGen 
            _← ⎕TGET ⎕TPOOL∩##.(toGen,fromGen)  
            _← ##.(debug tokNs.FreeToks toGen fromGen⊣ ⎕DF genName,' [terminated]') 
        ##.IsGen: _←0 ⋄ ~##.genId∊ ⎕TNUMS: _← 0  
        1:        _←1⊣ ##.{ 
                      ⎕TGET ⎕TPOOL∩(toGen,fromGen)⊣ ⎕TKILL ⍵⊣ ⎕DL CLEANUPWAIT_SEC 
                  }& ##.genId 
      }        
      ErrorK← { 0 Dmx ⍬⊣ Cleanup DMsg ⍵ } 
    :EndNamespace ⍝ uNs
  :EndSection Generator utilities ⍝ uNs 

  :Section tokNs  ⍝ Token Management
    :Namespace tokNs
    ⍝ TOK_BASE:    The start of the token range we manage
    ⍝ TOK_PER_GEN: How many tokens per generator
    ⍝ TOK_COUNT:   How many tokens in the range we manage
      TOK_BASE TOK_PER_GEN← 103741824 2  
      TOK_COUNT← 1000× TOK_PER_GEN 
    ⍝ tokCurBase:  What is the start of the free positions in the range we manage
    ⍝ * We will only allocate tokens if we don't see them active in tokActive  
    ⍝   Otherwise, we'll skip those tokens.
    ⍝ * Once we exhaust our <TOK_COUNT> tokens, we start at <TOK_BASE> again.  
    ⍝   Dyalog's new token allocation scheme will avoid collisions with other apps.
    ⍝   If TOK_COUNT is 10,000, that means we can have 5,000 active generators...
      tokCurBase← TOK_BASE 
      tokActive← ⍬
    ⍝ ReserveToks: ReserveToks a pair of contiguous threadids from a range of "reserved" thread ids.
    ⍝ Returns the new set of tokens
      ∇ newPair← ReserveToks debug   ⍝ Internal use only 
        :Hold 'Generator_Tokens' 
          newPair newFreeStart← {  
            ⍺←0 ⋄ tries← ⍺  
            tries≥ TOK_COUNT: 11 ⎕SIGNAL⍨ TOK_PER_GEN { tg (tb tc)← ⍺ ⍵ 
              'Gen: Can''t acquire ',(⍕tg),' tokens in range [',(⍕tb),',',(⍕tb+tc-1),']'
            } TOK_BASE TOK_COUNT
            free← TOK_BASE+ TOK_COUNT| |TOK_BASE- ⍵⌈TOK_BASE
            ∨/tokActive∊⍨ new← free+ ⍳TOK_PER_GEN: ⊃∇/ tries free+ 1 TOK_PER_GEN  
            new (free+TOK_PER_GEN) 
          }tokCurBase 
          tokActive,←  newPair ⋄ tokCurBase⊢← newFreeStart 
          :If debug ⋄ ⎕← '[Gen] Reserved tokens',newPair ⋄ :EndIf 
        :EndHold
      ∇
    ⍝ Free tokens, updating tokActive as needed...
      ∇ toks← {debug} FreeToks toks  
        :IF 0= ⎕NC 'debug' ⋄ debug←0 ⋄ :ENDIF  
        :Hold 'Generator_Tokens'
          :If ∨/toks∊ tokActive   
              tokActive~← toks 
            :If debug ⋄ ⎕← '[Gen] Freed tokens',toks ⋄ :EndIf
          :EndIf 
        :EndHold
      ∇
    :EndNamespace ⍝ tokNs
  :EndSection tokNs ⍝ Token Management 
  
:EndNamespace ⍝ genLib

⍝-------------------------------------------------------------------------------------------⍝
⍝-------------------------------------------------------------------------------------------⍝
:Section Examples
⍝-------------------------------------------------------------------------------------------⍝
⍝-------------------------------------------------------------------------------------------⍝
⍝ Demo will create two generators: ShakespeareG and RandG
  ∇ Demo
    ⎕←'TrueRand gets the next of a "truly" random number from random.org'
    ⎕←'Not built yet'
    ⎕←'t← TrueRand Generator 0'
    TrueRand←{ ⍝ num≤10000
      ⎕←urlText←'https://www.random.org/integers/?num=10000&min=1&max=1000000000&col=1&base=10&format=plain&rnd=new'
      0::  ⎕←'Done'⊣ ⎕DMX.(⎕←↑DM⊣ ⎕← EN EM)
      1: nums← ⎕SH 'Curl --fail ',urlText  
    }
    ⎕←''
    ⎕←'Shakespeare is a generator that returns a ''paragraph'' from Shakespeare''s works.'
    ⎕←'  s← ShakespeareG Gen 2 999'
    ⎕←'To see a demonstration, type (with no arguments):'
    ⎕←'  Shake'
    ⎕←'Hit return after each text prompt starting with "*****"'
    ⎕←''
    ShakespeareG← {   ⎕io←0 ⋄ offset←194 ⋄ NL2← 2⍴ NL← ⎕UCS 10
      urlText← 'https://ocw.mit.edu/ans7870/6/6.006/s08/lecturenotes/files/t8.shakespeare.txt' 
      0::  ⎕←'Done'⊣ ⎕DMX.(⎕←↑DM⊣ ⎕← EN EM)
        ⎕←'Reading large textfile from url:'
        ⎕←'  ',urlText
      ⍝ Prime the pump by retrieving the text file 
      ⍝ and performing initial processing...
        FindFirst← ⊃⍸⍤⍷⍨
        NoCom← '(?s)<<.*?>>' ⎕R ''⍠('Mode' 'M')       ⍝ Remove <<...>> comments
        wa←⎕WA 
        lines← NoCom ⎕SH 'Curl --fail ',urlText       ⍝ Reading in text file from URL
        lines↓⍨← 3+ lines FindFirst ⊂'THE SONNETS'     ⍝ Skip past first header...
        zeroes2← 1,⍨ 0 0⍷≢¨lines                      ⍝ 1 if a pair of blank lines
        wa← 1⍕ 1E6÷⍨ wa- ⎕WA  

        ⎕←'There are',(≢lines),'total text lines in our Shakespeare file'
        ⎕←'The text file and metadata take up',wa,' MB...'
        
        defSL← 2↑ (2 25↓⍨-0⌈≢⍵), ⍵                   ⍝ Get short and long paragraph parameters first
        t← ⍺.Yield ⍬  
        short long← 2↑(defSL↓⍨-0⌈≢t),t 
        
        (short=0)∨short≥long: 'Invalid parameters!' ⎕SIGNAL 11
         ⎕←'We are ignoring paragraphs with',short,'or fewer lines...'
         ⎕←'We will subdivide paragraphs with',long,'or more lines'
     
        bye1← '*** Parting is such sweet sorrow,'  
        bye2← '*** that I shall say good night till it be morrow.'
        Divvy← {0=l← long⌊ ≢⍵: ⍬ ⋄ ⍺ ∇ l↓ ⍵⊣ ⍺.Yield ↑l↑ ⍵} ⍝ Subdivide long paragraphs
      ⍝ Prepare for incremental processing, i.e. of a single "paragraph"
        ⍺{
          ⍺.STOP::  ↑bye1 bye2
            p z2←⍵                                     ⍝ p=start posn, z2=remaining zeroes
          0=≢z2: t⊣ ⍺.Yield t← '*** Shakespeare ran out of things to say!'
          0=≢p⊃lines: ⍺ ∇ (p+1)(1↓z2)                  ⍝ Skip blank lines
            n2← 2+ n← z2⍳1                             ⍝ Find next paragraph (pair of blank lines)
          short≥ n: ⍺ ∇ (p+ n2) (n2↓ z2)               ⍝ Skip short paragraphs 
            _← ⍺ Divvy lines[p+ ⍳n]                    ⍝ Send back a paragraph (divided if needed)
            ⍺ ∇ (p+ n2) (n2↓ z2)                       ⍝ Move past paragraph and blank lines
        }0 zeroes2
    }
    ##.ShakespeareG← ShakespeareG
    ⎕←''
    ⎕←'RandG is  sample generator that can return random numbers of very large sizes as text strings.'
    ⎕←'By default, RandG starts with 34-character random numbers for each ⍺.Next'
    ⎕←'  r← RandG Gen⍬' 
    ⎕←'To retrieve a random number of the current length, do'
    ⎕←'  r.Next' 
    ⎕←'To change the length to 50 (retrieving the already generated value), do' 
    ⎕←'  ⊢r.Send 50'
    ⎕←'then'
    ⎕←'  r.Next'
    ⎕←'Terminate with'
    ⎕←'  r.Return'
    ⎕←'(which shows the # of random numbers returned).' 
    RandG←{ ⍝ Sample generator'
        big ⎕PP ndig nlast nrequests←(2*31)34 34 0 0
        Verbose← ⍺∘{⍺.debug∧ ndig≠nlast: ⍵⊣ ⎕←'RandG now at',ndig,'digits per request (Next)' ⋄ ⍵}
      ⍺.STOP:: nrequests    ⍝ Return value 
        _← Verbose ⍬
        Exec← ⍺.Yield{ ndig> ≢⍵: ∇ ⍵, ⍕?big ⋄ ⍵↑⍨ -ndig}
        Rcv←{ nrequests+← 1 ⋄ ⎕NULL≡ ⍵: ⍵ ⋄ ⊢Verbose ⊃ndig nlast⊢← (⍵ 34⊃⍨ 0=⍵) ndig} 
        {∇ Rcv Exec ⍬} ⍬  ⍝ This will go forever until an x.Return or ¯1 x.Send 'Msg'
    }
    ⎕←'Created fn Shake to demonstrate ShakespeareG Gen⍬'
  ∇
  ∇  Shake
    ;s;Ask; Say

    :TRAP 999
        Say←{ ⍺←0 ⋄ ⎕←(⍺/⎕UCS 13), '***** ',⍵}
        Ask←{ 
            ⍺←1 ⋄ ⍞←⍺/⎕UCS 13
           'n'=⊃⎕C' '~⍨⍞↓⍨≢⍞←'***** ',⍵,'? ': ⎕SIGNAL 999 
            _←⍬ 
        }
        Do← { ⎕←⍵ ⋄ ⍎⍵}

        Ask'Start Generator'
        '      s← Shakespeare Gen ⍬'
        s←ShakespeareG Gen 0
        1 Say 'Tell (Send) the generator'
        Say '∘ the smallest paragraph to keep and'
        Say '∘ the largest par. fragment to display on each ¨Next¨'
        0 Ask 'Ready'

        r← (2+?5) (10×1+?4)
        '      s.Send',r
        s.Send r

        Ask'Skip a random # of paragraphs between 1 and 100'
        '      {}{0⍴s.Next}¨ ⍳ ⎕← 1+ ?100'
        {}{0⍴s.Next}¨ ⍳⎕← 1+?100
        '>>> Done'

        Ask'Read two paragraph sections'
        '      s.Next ⋄ s.Next'
        s.Next ⋄ ⎕←'*****' ⋄ s.Next
        Ask'Skip 100 paragraphs'
        '      {}{0⍴s.Next}¨100⍴0'
        {}{0⍴s.Next}¨100⍴0
        '>>> Done'

        Ask'Read two paragraph sections'
        '      s.Next ⋄ s.Next'
        s.Next ⋄ ⎕←'*****' ⋄ s.Next

        Ask'Return (and exit)'
        '      s.Return'
        s.Return
        ''
    :EndTrap 
    '***** Bye!'
    
 ∇
  _← ##.⎕FX ⎕NR 'Demo'
   _← ##.⎕FX ⎕NR 'Shake'
:EndSection ⍝ Examples

:Section Help
  ∇ Help ;h
    ⎕ED'h'⊣h← '^\h*⍝H\h?(.*)'⎕S '\1'⊣⎕SRC ⎕THIS 
  ∇
:EndSection Help
:endNamespace
