:namespace Generator
⍝!  For description/help, see function ∘help∘ below.
⍝!  For examples, see Demo below.
⍝ 
⍝   gÑ: generator namespace instance, copied in from genLib
⍝   uÑ: generator utilities
 Gen← { 
      ⍺←0 ⋄ gÑ.gÑ← gÑ∘← ⎕NS genLib ⋄ gÑ.(debug em en)← ⍺ 'Generator Active' gÑ.OK
      gÑ.(toGen fromGen) tokÑ.cur∘← tokÑ.(ReserveToks cur) 
      gÑ.genId← ⍺⍺ gÑ.{  
        0:: uÑ.Error ⍬ ⋄ 1000:: uÑ.Interrupt ⍬ 
          _← ⎕DF ⎕TNAME← genName⊢← 'Gen[tid=',(⍕⎕TID),', toGen=',(⍕toGen),']' 
          _← ⎕TPUT fromGen    ⍝ Tell the generator it may start: all vars are set. 
        ⍝    RUN THE GENERATOR (⍺⍺) →→→                   ↓↓↓↓↓↓↓↓↓↓ ⍝   
        ⍝    ↓↓↓↓↓↓↓↓↓↓↓↓ ←←← RETURNING ⎕THIS.result      ↓↓↓↓↓↓↓↓↓↓ ⍝ 
                result resultSet⊢← (⎕THIS ⍺⍺ ⍵) 1  
                em en⊢← 'Generator Terminated Normally' OK ⊣ ⎕DF genName,' [returned]'  
          1: _← result
        ⍝       ¯¯¯¯¯¯                         
      }& ⍵
      gÑ←gÑ  ⍝ Why is this necessary? Dyalog bug?!?!
    0= ≢gÑ.INIT_WAIT ⎕TGET gÑ.fromGen: 11 ⎕SIGNAL⍨'Generator did not start up properly!'
      gÑ 
  }
  ##.Gen← ⎕THIS.Gen

:Namespace genLib
⍝ Const for Generator Objects (cloned)
  ⎕IO ⎕ML←0 1
  STOP← ⊃⌽GENSTOP← 'Generator signalled STOP ITERATION'    901 
  SEND_STOP SEND_FAIL← ¯1 ¯2
  FAIL← ⊃⌽GENFAIL← 'Generator has TERMINATED' 911
         GEN_ONLY← 'Function only valid in generator code' 11 
        USER_ONLY← 'Function not valid in generator code' 11
  OK←   0
⍝ INIT_WAIT: (max) wait <INIT_WAIT> seconds for generator preamble to startup and handshake
⍝ CLEANUP_WAIT: (max) wait after a generator termination (GENFAIL) is requested before
⍝            the generator is actually terminated (⎕TKILL)
  INIT_WAIT←    2 ⍝ sec
  CLEANUP_WAIT← 5 ⍝ sec
⍝ End Const

⍝ Vars for Generator Objects (to be cloned into gÑ)
⍝ debug:     from ⍺ in Gen call. 0 by default.
⍝ stopWait:  wait after a GENSTOP signal to wait before checking if result is available.
⍝            Will wait up to (stopWait×waitCount) seconds, typically 10 ms.
⍝ waitCount: See stopWait. Total tries to get result after signalling generator to STOP
⍝            its iterations.
  debug stopWait waitCount← 0 0.005 20 
⍝ result:    whatever the user generator returned (or ⎕NULL). If set, resultSet←1
⍝ genId:     the clone's thread # (set in Gen)
⍝ gñ:        cloned generator namespace instance (from genLib)
⍝ genName:   a descriptive name for the generator and thread, when initiated.
⍝ fromGen, toGen: 
⍝            the tokens used for synchronizing the generator...
  toGen← fromGen← genName← gÑ← genId← result← ⎕NULL ⋄ resultSet←0
⍝ End Vars

⍝ User "Methods"
  SetStopWait← stopWait∘{ stopWait⊢← ⍵ ⍺⊃⍨ 0=≢⍵ }
  ∇ r←Active  ⍝ goes in user (in generator, always 1)
    r← ~Eof
  ∇
  ∇ e← Eof
    e← genId (~∊) ⎕TNUMS 
  ∇

⍝ Yield  (Generator) Wait for a code and msg <msgIn> and send a msg <msgOut> to the user.
⍝    For typical Yield expressions, code←0 and msgIn←⎕NULL, indicating a request for data only.
⍝ code msgIn← [timeout← infinite] ∇ msgOut
⍝ 1. Wait up to <timeout> seconds (default: infinite) for a code and
⍝    message <msgIn> from the user. 
⍝ 2. If the code is 0, send the msg <msgOut> to the user and return <msgIn>.
⍝    If the code>0, execute (⍕msgIn) ⎕SIGNAL code in the generator.
⍝    Code ⍺.STOP and ⍺.FAIL may be generated via codes ¯1 and ¯2 respectively.
⍝    If the code=¯1, ⎕SIGNAL GENSTOP (901), "stop iterations of generator."
⍝    If the code=¯2, ⎕SIGNAL GENFAIL (911), "tell the generator to terminate itself asap." 
  Yield← {  ⍝ Generator only
        ⍺← ⊢ ⋄ timeout← ⍺
      ⎕TID≠ genId: ⎕SIGNAL/ GEN_ONLY
          code msgIn← ⊃timeout ⎕TGET toGen
      code=0:   _← msgIn⊣ 0 ⍵ ⎕TPUT fromGen
      code>0:   (⍕msgIn) ⎕SIGNAL code 
      code=SEND_STOP:  ⎕SIGNAL/ GENSTOP  ⍝ STOP
      code=SEND_FAIL:  ⎕SIGNAL/ GENFAIL  ⍝ FAIL
          'Yield: Invalid left arg' ⎕SIGNAL 11
  }

⍝  Next (in user code)  Returns next message from generator.
⍝  r← ∇
⍝  Sends a ⎕NULL msg to the generator, returning a (hopefully useful) message from the generator.
⍝  If the generator expects a contentful message, use Send.
⍝  r← Next
 ∇ r←Next  ⍝ user only
    :TRAP 0 ⋄ r←Send ⎕NULL
    :ELSE   ⋄ uÑ.SigDmx⍬
    :Endtrap
∇
⍝  Send (in user code) Send a message to the generator and receive a message (msgIn) in return. 
⍝  msgIn← [code←0] ∇ msgOut
⍝  If code=0 and the generator is active, 
⍝    sends a message to the generator, receiving a messaging in return.
⍝    Otherwise, 
⍝    ∘ if the generator (or user) has issued an error code <⍺.en>,
⍝      then the Send fails with error message ⍺.em and error code ⍺.en,
⍝    ∘ if the generator has terminated, signal an error:
⍝      (GENSTOP if the generator has just terminated successfully;
⍝       GENFAIL otherwise).
⍝  Else, if code is non-zero and the generator is active, 
⍝      issue as a priority (first) message to the generator the pair (code, tomsg) 
⍝      tnen wait for the generator to terminate, returning its result (also ⍺.result).
  Send← { ⍝ user only
        ⍺← 0 ⋄ code← ⍺ ⋄ msgOut← ⍵
    0::  uÑ.SigDmx⍬
      0≠ ⊃0⍴code: 'Domain Error: Send left arg (code) must be an int scalar' ⎕SIGNAL 11
      fast← ∧/~(isGen← IsGen)(isEof← Eof)(nzEn← en≠ 0)(code≢ 0)
    fast: msgIn← ⊃⌽⊃⎕TGET fromGen ⊣ 0 msgOut ⎕TPUT toGen      
    isGen:    ⎕SIGNAL/ USER_ONLY
    isEof: _← ⎕SIGNAL/ {
        en=911:        GENFAIL 
        en∨.= OK STOP: GENSTOP⊣em en⊢← GENFAIL  ⋄
                       em en 
    }⍬ 
    nzEn: _← ⎕SIGNAL/ em en
  ⍝ code≢0?
    1:   _← uÑ.AwaitResult⍬ ⊣ ⎕TGET ⎕TPOOL∩fromGen ⊣ code uÑ.TPutFirst msgOut   
 }

⍝ Return  (generator or user) Signals the generator to stop (via ⎕SIGNAL/ GENSTOP), 
⍝         returning the generator's result as ¨result¨.
⍝ r← ∇
⍝         If Return traps the GENSTOP signal, returning normally within waitCount×stopWait seconds,
⍝         then
⍝         ∘ resultSet=1 and result will be whatever the generator function returned;
⍝         otherwise, 
⍝         ∘ ¨result¯ will be ⎕NULL and resultSet←0.  
∇ r← Return    ⍝ user or generator
  :IF IsGen ⋄  ⎕SIGNAL/ GENSTOP ⋄ :ENDIF ⍝ generator 
  :IF Eof 
    :IF  resultSet ⋄ :Andif en∊ 0 STOP 
         r← result  
    :Else 
         ⎕SIGNAL/em en
    :EndIf
  :Else 
    r← SEND_STOP Send ⎕NULL  
    r← uÑ.(AwaitResult Cleanup 0)  
  :Endif 
∇ 
∇ {r}← Quit   ⍝ user or generator
  :IF IsGen    ⋄ ⎕SIGNAL/ GENSTOP        ⍝ generator 
  :ELSEIF ~Eof ⋄ _← SEND_STOP Send ⎕NULL ⋄  r← 'GENERATOR REQUESTED TO TERMINATE' 0
  :ELSE        ⋄ ⎕SIGNAL/GENFAIL
  :ENDIF 
∇ 
∇ r← IsGen
  r← genId= ⎕TID
∇

⍝ Internal Utilities
  :Namespace uÑ
      FAIL STOP← ##.(FAIL STOP)
      ⍙Blab← ##.{ ⍺←⍬ ⋄ debug: ⍺⊣ ⎕← ⍵ ⋄ ⍺ }
      Dmx← { ⎕DMX.(⊂'EN' 'Message' 'EM',⍥⊂¨ EN Message EM) }
      Cleanup← { 
          _← 1 ⎕TGET ⎕TPOOL∩##.(toGen,fromGen) ⋄ _← ##.(⎕DF genName,' [terminated]')
          TK← { ⎕TKILL ##.genId ⊣ ⎕DL ##.CLEANUP_WAIT }
        ~##.Eof: TK& 0 ⍙Blab⊢ em← TermMsg ⊃1 2⊃⍨ ⍵=2 ⊣ en← FAIL
        1:           0 ⍙Blab⊢ em← TermMsg ⊃0 2⊃⍨ ⍵=2 ⊣ en← STOP
      }
  ⍝ TPutFirst: Send msg ahead of all others. Internal only
    TPutFirst← ##.{ V← ⎕TGET T← ⎕TPOOL∩ toGen ⋄ ((⍺ ⍵),V) ⎕TPUT (toGen, T) }
  ⍝ AwaitResult:  ⍺⍺ ∇ ⍬
    AwaitResult← ##.waitCount ##.{⍺⍺≤0: ⎕NULL ⋄ resultSet: result⋄1: (⍺⍺-1)∇∇⍵⊣⎕DL stopWait}
    Error← ⎕SIGNAL { Dmx ⊣ Cleanup 0 }
    Interrupt← ⎕SIGNAL {##.(em en)⊢← (TermMsg 2) FAIL ⋄ ⊂'EM' 'EN' ,⍥⊂¨ ##.(em en)⊣ Cleanup 2 }
    SigDmx← ⎕SIGNAL Dmx  
      termMsgs← 'has been terminated' 'terminating' 'was interrupted' 'LOGIC ERROR!'
    TermMsg← termMsgs∘ ##.{'Generator thread ',(⍕genId),' ', ⍺⊃⍨ 0⌈3⌊⍵}
  :EndNamespace ⍝ uÑ

:EndNamespace ⍝ gÑ

⍝ Token management
:namespace tokÑ 
  EACH MIN COUNT←2 1003741824 10000  
  DEFAULTS← MIN EACH MIN COUNT
  cur← MIN 
⍝ ReserveToks: ReserveToks a pair of contiguous threadids from a range of "reserved" thread ids.
⍝ Returns (the new set of tokens)(the updated tokÑ.cur)
  ReserveToks← {  ⍝ Internal use only 
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
:EndNamespace ⍝ tokÑ

:Section Examples
⍝ Demo will create two generators: ShakespeareG and RandG
  ∇ Demo
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
⍝H ∘ TermMsg a loop if the generator has no more data:
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
