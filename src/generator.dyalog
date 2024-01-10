:namespace Generator
⍝!  For description/help, see function ∘help∘ below.
⍝!  For examples, see Demo below.
⍝ 
⍝   gNs: generator namespace instance, copied in from genLib
⍝   uNs: generator utilities

⍝H 
⍝H Gen: 
⍝H   Executes a generator ⍺⍺ with argument ⍵.
⍝H   Emulates a python-like generator (iterator function) using Dyalog tokens and threads.
⍝H   ∘ Efforts to attach a class to the caller so that its destructor can clean up the generator (e.g. if
⍝H     stuck waiting or looping) lead to interpreter problems.
⍝H   ∘ The original approach was to use classes entirely, with comparable problems. Instead we use a namespace
⍝H     structure to emulate class instances without any destructor. It works.
⍝H
⍝H   In the generator, ⍺ will be a namespace with Yield, Quit, etc.
⍝H Syntax: result← [⍺←0] ⍺⍺ Gen ⍵
⍝H         ⍺⍺: the generator
⍝H          ⍵: the arg to the generator
⍝H          ⍺: dbgG←⍺, default 0
⍝H
⍝H In the generator code:
⍝H   To accept requests to stop iterating (e.g. to return a useful value), trap the STOP code:
⍝H      { ⍺.STOP:: return_value ⋄ _← ⍺.Yield my_data ... }
⍝H   To accept and trap requests to terminate, trap the FAIL code:
⍝H      { ⍺.FAIL:: 'I have failed' ⋄ _← ... }
⍝H   To note that dbgG has been set, use ⍺.dbgG:
⍝H      { ... ⋄ _← {⍺.dbgG: ⎕←'say this' ⋄ ⍬}⍬ ⋄ ... }
⍝H   To signal the generator has failed:
⍝H      { ... ⋄ ⎕SIGNAL ⍺.GENFAIL ⋄ ... }
⍝H
⍝H In the user code:
⍝H   To await a normal return from the generator
⍝H     r← gen.Return    
⍝H     ⍝ 1st: issues a STOP to the generator 
⍝H     ⍝ 2nd: waits some time for the generator to stop
⍝H     ⍝ 3rd: returns gen.result in ¨r¨ if the generator has stopped promptly
⍝H            else returns ⎕NULL, with gen.resultSet=0
⍝H   To tell the generator <gen> to stop iterating:
⍝H     r← gen.Quit            ⍝ Issues: SENDSTOP Send ⎕NULL  
⍝H
⍝H ===========================
⍝H FUNCTIONS FOR USER ONLY
⍝H ===========================
 Gen← { ⍺←0 
      gNs∘← ⎕NS genLib ⋄ gNs.(gNs dbgG)← gNs ⍺ 
      gNs.(toGen fromGen)← tokNs.(ReserveToks curG)
      gNs.genId← ⍺⍺ gNs.{  
        0::    1 ErrorK   'Generator Error'  
        1000:: InterruptK 'Generator Interrupt' 
        STOP:: 0 ErrorK   'Generator Stopped'  
            _← ⎕DF ⎕TNAME← genName⊢← 'Gen[tid=',(⍕⎕TID),', toGen=',(⍕toGen),']' 
            _← ⎕TPUT fromGen                              ⍝ Tell initiating thread we're ready
            result resultSet⊢← (⎕THIS ⍺⍺ ⍵) 1             ⍝ Run the generator
            _← SendSig DMsg'Generator Terminating Normally'⊣ ⎕DF genName,' [returned]' 
        1: _← result ⊣ SetGenTerm 1                       ⍝ Return the result      
      }& ⍵
    0= ≢gNs.INIT_WAIT ⎕TGET gNs.fromGen: 'Generator did not start up properly!' ⎕SIGNAL 11
      gNs 
  }
  ##.Gen← ⎕THIS.Gen

:Namespace genLib
⍝ Const for Generator Objects (cloned)
  ⎕IO ⎕ML←0 1
  STOP FAIL← 901 911
  GENSTOP←  ⊂'EM' 'EN',⍥⊂¨'Generator signalled STOP ITERATION' STOP 
  GENFAIL←  ⊂'EM' 'EN',⍥⊂¨'Generator has TERMINATED' FAIL
  GENONLY←  ⊂'EM' 'EN',⍥⊂¨'Function only valid in generator code' 11 
  USERONLY← ⊂'EM' 'EN',⍥⊂¨'Function not valid in generator code' 11
⍝ INIT_WAIT: (max) wait <INIT_WAIT> seconds for generator preamble to startup and handshake
⍝ CLEANUP_WAIT: (max) wait after a generator termination (GENFAIL) is requested before
⍝            the generator is actually terminated (⎕TKILL)
  INIT_WAIT←    2 ⍝ sec
  CLEANUP_WAIT← 5 ⍝ sec
⍝ End Const

⍝ Vars for Generator Objects (to be cloned into gNs)
⍝ Begin genLib vars
  ⍝ dbgG:     from ⍺ in Gen call. 0 by default.
  ⍝ stopWait:  wait after a GENSTOP signal to wait before checking if result is available.
  ⍝            Will wait up to stopWait seconds, perhaps 100 ms.
  ⍝ waitCount: See stopWait. Total tries to get result after signalling generator to STOP
  ⍝            its iterations. After each stop, wait stopWait÷waitCount seconds.
    stopWaitEach waitCount← 0.005 20 
    dbgG stopWait← 0 (stopWaitEach×waitCount)
    genDead← 0    ⍝ If 1, the generator has terminated
  ⍝ result:    whatever the user generator returned (or ⎕NULL). If set, resultSet←1
  ⍝ genId:     the clone's thread # (set in Gen)
  ⍝ gNs:       cloned generator namespace instance (from genLib)
  ⍝ genName:   a descriptive name for the generator and thread, when initiated.
  ⍝ fromGen, toGen: 
  ⍝            the tokens used for synchronizing the generator...
    toGen← fromGen← genName← gNs← genId← ⎕NULL 
    result resultSet← ⎕NULL 0 
⍝ End genLib Vars

⍝ User "Methods"
  SetStopWait← stopWait∘{ stopWait⊢← ⍵ ⍺⊃⍨ 0=≢⍵ ⋄ stopWaitEach⊢← stopWait÷waitCount }
  ∇ r←Active  ⍝ use in user code (valid in generator, but always 1)
    r← ~GenDead
  ∇
⍝H  GenDead (User only)
⍝H    Determine if generator thread is still active
⍝H  Syntax: r← ∇
⍝H    Returns 0 if the generator is still active; else 1
⍝H 
  ∇ e← GenDead
    :If ~genDead  
      genDead← genId (~∊) ⎕TNUMS 
    :EndIf 
    e← genDead 
  ∇

⍝H  Next (in user code)  
⍝H    Returns next message from generator.
⍝H  Syntax: r← ∇
⍝H    Sends a ⎕NULL msg to the generator, returning a (hopefully useful) message from the generator.
⍝H    If the generator expects a contentful message, use Send.
⍝H    ¨r← Next¨ is equiv. to ¨⊢Send ⎕NULL¨
⍝H
 ∇ r←Next  ⍝ user only
    :TRAP 0 ⋄ r←Send ⎕NULL
    :ELSE   ⋄ ⎕SIGNAL 0 Dmx⍬
    :Endtrap
∇

⍝H  Send (in user code) 
⍝H  Syntax: {msgIn}← [isSig←0] ∇ msgOut
⍝H    isSig=0: Send a message to the generator and receive a message (msgIn) in return. 
⍝H    isSig=1: Send a signal to the generator as the next queued message and return ⎕NULL.
⍝H      
  Send← { ⍝ user only
      ⍺← 0 ⋄ sigOutFlag msgOut← ⍺ ⍵ 
    0::  ⎕SIGNAL Dmx⍬
      sigOutFlag _SendRaw msgOut  
 }
 SendSig← { 1 _SendRaw ⍵}
 _SendRaw←{ 
      sigOutFlag msgOut← ⍺ ⍵
    GenDead:    ⎕SIGNAL GENSTOP 
      to from← IsGen⌽ toGen fromGen
    sigOutFlag: { 
        _← ⎕TGET ⎕TPOOL∩to 
        _← sigOutFlag msgOut ⎕TPUT to 
      GenDead: ⎕SIGNAL GENSTOP 
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
⍝H    Signals the generator to stop (via ⎕SIGNAL/ GENSTOP), 
⍝H    returning the generator's result as ¨result¨.
⍝H  Syntax: r← ∇
⍝H          If Return traps the GENSTOP signal, returning normally within waitCount×stopWait seconds,
⍝H          then
⍝H          ∘ resultSet=1 and result will be whatever the generator function returned;
⍝H          otherwise, 
⍝H          ∘ ¨result¯ will be ⎕NULL and resultSet←0.  
⍝H
∇ r← Return    ⍝ user or generator
  :If IsGen ⋄  ⎕SIGNAL GENSTOP ⋄ :EndIf ⍝ generator 
  :TRAP 0
    :If GenDead
      :IF resultSet ⋄ r← result
      :Else ⋄ ⎕SIGNAL GENSTOP
      :EndIf 
    :Else 
      SendSig SetGenTerm 0 
      r← AwaitResult
    :Endif 
  :Else
     ⎕SIGNAL Dmx⍬
  :EndTrap 
∇ 

⍝H  Quit:  (User or Generator)
⍝H    Terminate the generator immediately
⍝H  Syntax: r← ∇
⍝H  Returns: 
⍝H    In User:
⍝H       If the generator is not dead, terminate it and return 1.
⍝H       Else return 0.
⍝H    In Generator: Issues a GENFAIL signal to itself, rather than returning.
⍝H
∇ {r}← Quit   ⍝ user or generator 
    :IF IsGen ⋄ ⎕SIGNAL GENFAIL DMsg 'Generator is terminating now' ⋄ :ENDIF
    :IF r← ~GenDead  
      :TRAP 0 
        GenKill DMsg 'Killing generator',genId,'in',CLEANUP_WAIT,'sec'
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
  IsGen: toGen  ∊ ⎕TPOOL
         fromGen∊ ⎕TPOOL
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
⍝H    In such a case, an infinitely-running generator might be terminated via a Quit function.
⍝H  Syntax:  msgIn← [timeout← infinite] ∇ msgOut
⍝H    1. Wait up to <timeout> seconds (default: infinite) for a code and
⍝H      message <msgIn> from the user. 
⍝H    2. Expecting a message of the form <code msgIn>, 
⍝H       if code=0, returns msgIn, after sending msgOut to the user code.
⍝H       otherwise, does a *LOCAL* ⎕SIGNAL msgIn.
⍝H
  Yield← {  ⍝ Generator only
        ⍺← ⊢ ⋄ timeout←⍺ ⋄  msgOut← ⍵
    GenDead:       ⎕SIGNAL GENSTOP                  ⍝ See if generator active before ⎕TGET
    ⎕TID≠ genId:   ⎕SIGNAL GENONLY
        r← timeout ⎕TGET toGen  
    0=≢r: 11 ⎕SIGNAL⍨ 'Yield: No message was received (timeout)'   
        isSig msgIn← ⊃r                             ⍝ Get the code and msgIn from user
    GenDead:       ⎕SIGNAL GENSTOP                  ⍝ See if generator active after ⎕TGET
    isSig:         ⎕SIGNAL msgIn 
    1:             _← msgIn⊣ 0 msgOut ⎕TPUT fromGen  
   }

 :Section utilities
    DMsg← { ⍺←⍵ ⋄ dbgG∧0≠≢⍵: _← ⍺⊣ ⎕← 'Gen: ',⍵ ⋄ 1: _←⍺ }
    Dmx← { ⍺←1 ⋄ ⎕DMX.(⊂'EN' 'Message' 'EM',⍥⊂¨ EN Message ((⍺/'Gen: '),EM)) }
    ∇ {r}← SetGenTerm fail  
       r← GENSTOP GENFAIL⊃⍨ fail
       genDead← 1
    ∇
    GenKill← {  ⍺←0 
        _K←  {⎕TGET ⎕TPOOL∩(toGen,fromGen)⊣ ⎕TKILL ⍵⊣  ⎕DL CLEANUP_WAIT}
        _← ⎕DL 0⊣ 0 ⎕TPUT toGen ⋄ _← ⎕TGET ⎕TPOOL∩(toGen,fromGen)  
        _← ⎕DF genName,' [terminated]' 
      genId∊ ⎕TNUMS: SendSig SetGenTerm ⍺⊣ _K & genId 
        SendSig SetGenTerm ⍺ 
    }
   ⍝ AwaitResult: (no args)
   ⍝ Reads global resultSet and waits up to stopWait sec,
   ⍝    returning r←result 
   ⍝ If ~resultSet after the wait, result is ⎕NULL, its initial value.
    ∇r← AwaitResult; wc  
      wc←  waitCount  
      :While (wc>0)∧ ~resultSet   
          :IF GenDead ⋄ ⎕SIGNAL GENSTOP ⋄ :ENDIF 
          ⎕DL stopWaitEach ⋄ wc-← 1 
      :EndWhile
      r← result 
    ∇
    ErrorK← ⎕SIGNAL { Dmx ⊣ ⍺ GenKill DMsg ⍵ }
    _IK← {
       _← GenKill ⍬ DMsg ⍵ 
       ⊂⎕DMX.(('EM' 'Gen: INTERRUPT ',⍕EN)('EN' 999)('Message' EM))
    } 
    InterruptK← ⎕SIGNAL _IK 
  :EndSection utilities 

:EndNamespace ⍝ gNs

⍝ Token management
:namespace tokNs 
  BASE N_EACH COUNT←1003741824 2 100000  
⍝ BASE:   The start of the token range we manage
⍝ N_EACH: How many tokens per generator
⍝ COUNT:  How many tokens in the range we manage
⍝ curG:   What is the start of the free positions in the range we manage
⍝ * We will only allocate tokens if we don't see them active in ⎕TPOOL (not very useful).
⍝   Otherwise, we'll skip those tokens.
⍝ * Once we exhaust our <COUNT> tokens, we start at <BASE> again. Caveat programmer.
⍝   Dyalog's new token allocation scheme will resolve this!
⍝   If COUNT is 100,000, that means we can have 50,000 active generators...
⍝                  cur  nEach  base cnt 
  NDEF← ≢DEFAULTS← BASE N_EACH BASE COUNT
  curG← BASE 
⍝ ReserveToks: ReserveToks a pair of contiguous threadids from a range of "reserved" thread ids.
⍝ Returns the new set of tokens
  ReserveToks← {  ⍝ Internal use only 
      cur nEach base cnt← NDEF↑ ⍵, DEFAULTS↑⍨ 0⌊ NDEF-⍨ ≢⍵
      new cur← 0{  
        tries← ⍺
        tries≥ cnt:11 ⎕SIGNAL⍨'GetNext: Can''t find ',(⍕nEach),' tokens in range [',(⍕base),',',(⍕base+cnt-1),']'
        cur⊢← base+ cnt| |base- ⍵⌈base
        1∊⎕TPOOL∊⍨ new← cur+ ⍳nEach: ⊃∇/ tries cur+ 1 nEach  
        new (cur+nEach) 
      }cur 
      curG⊢← cur 
      new
  }
:EndNamespace ⍝ tokNs

:Section Examples
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
        big ⎕PP ndig nrequests←(2*31)34 34 0
        ⎕←'RandG starting with',ndig,'digits per request (Next)'
      ⍺.STOP:: nrequests    ⍝ Return value 
        Exec← ⍺.Yield{ ndig> ≢⍵: ∇ ⍵, ⍕?big ⋄ ⍵↑⍨ -ndig}
        Rcv←{ nrequests+← 1 ⋄ ⎕NULL≡ ⍵: ⍵ ⋄ ⊢ndig⊢← ⍵ 34⊃⍨ 0=⍵} 
        {∇ Rcv Exec ⍬} ⍬  ⍝ This will go forever until an x.Return or ¯1 x.Send 'Msg'
    }
    ⎕←'Created fn Shake to demonstrate ShakespeareG Gen⍬'
  ∇
  ∇  Shake
    ;s;Ask; Say

    Say←{ ⍺←0 ⋄          ⎕←(⍺/⎕UCS 13), '***** ',⍵}
    Ask←{ ⍺←1 ⋄  1: _←⍞⊣ ⍞←(⍺/⎕UCS 13), '***** ',⍵,' ' }

    Ask'Start Generator'
    '      s← Shakespeare Gen ⍬'
    s←ShakespeareG Gen 0
    1 Say 'Tell (Send) the generator'
    Say '∘ the smallest paragraph to keep and'
    Say '∘ the largest par. fragment to display on each ¨Next¨'
    0 Ask 'Ready?'

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

    Ask'Return'
    '      s.Return'
    s.Return
    ''
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
