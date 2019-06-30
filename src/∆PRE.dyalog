 ∆PRE←{⎕IO←0
     ⍝ Alternative to ∆FIX...

     ⍺←0 ⋄ DEBUG←⍺   ⍝ If 1, the preproc file created __<name>__ is not deleted.
     {
         1=0⊃⍵:(⎕EX⍣(~DEBUG)⊣2⊃⍵)⊢⍵{' '=1↑0⍴⍵:⍵
             11 ⎕SIGNAL⍨'preprocessor error fixing ',(1⊃⍺),' on line ',⍕2⊃⍺
         }⎕FX⍎2⊃⍵
         _←⎕EX⍣(~DEBUG)⊣2⊃⍵
         11 ⎕SIGNAL⍨'preprocessor error  in ',(1⊃⍵),' on line ',⍕(2⊃⍵)
     }{~3 4∊⍨⎕NC ⍵:11 ⎕SIGNAL⍨'preproc: right arg must be funNm of existing fun or op'

         NL←⎕UCS 10 ⋄ PASSTHRU←⎕UCS 1                      ⍝ PASSTHRU as 1st char in vector signals
                                                           ⍝ a line to pass through to target user function
         ∆FLD←{
             ns def←2↑⍺,⊂''
             ' '=1↑0⍴⍵:⍺ ∇ ns.Names⍳⊂⍵
             ⍵=0:ns.Match                                  ⍝ Fast way to get whole match
             ⍵≥≢ns.Lengths:def                             ⍝ Field not defined AT ALL → ''
             ns.Lengths[⍵]=¯1:def                          ⍝ Defined field, but not used HERE (within this submatch) → ''
             ns.(Lengths[⍵]↑Offsets[⍵]↓Block)              ⍝ Simple match
         }
         ∆QT←{'''',⍵,''''}
         ∆QTX←{∆QT ⍵/⍨1+⍵=''''}                            ⍝ Quote each line, "escaping" each quote char.

       ⍝ Append literal strings ⍵:SV.                      ⍝ res@B(←⍺) ← ⍺@B←1 appendRaw ⍵:SV
         appendRaw←{⍺←1 ⋄ ⍺⊣dataFinal,←⍵}

       ⍝ Append quoted string                              ⍝ res@B ←  ⍺@B←1 appendCond ⍵:SV
         appendCond←{
             doPass←PASSTHRU=1↑⍵
             doPass:appendRaw⊂'⍙,←⊂',∆QTX 1↓⍵
             0 appendRaw⊂⍵
         }¨
         padx←{⍺←15 ⋄ ⍺<≢⍵:⍵ ⋄ ⍺↑⍵}

         getDataIn←{
             0=⎕NC srcNm:{(0⊃⎕RSI,#)⍎srcNm,'∘←⍵'}⎕NR funNm
             ⎕←'For fn/op "',funNm,'" has a source file "',srcNm,'"'
             in←1↑' '~⍨⍞↓⍨≢⍞←'Use [s] source to recompile, [f] function body, or [q] quit? [source] '
             in∊'q':909 ⎕SIGNAL⍨'preproc terminated by user for fun/op "',funNm,'"'
             in∊'s ':{
                 0::909 ⎕SIGNAL⍨'preproc: user source is not valid'
                 3 4∊⍨⎕NC ⍵:⎕NR ⍵
                 ↓⍣(2≠|≡∆)⊣∆←⎕OR ⍵
             }srcNm
             in∊'f':⎕NR funNm
         }

       ⍝ MACRO (NAME) PROCESSING
       ⍝ FUNCTIONS
         put←{n v←⍵ ⋄ n~←' ' ⋄ names,⍨←⊂n ⋄ vals,⍨←⊂v ⋄ 1:⍵}  ⍝ add name val
         get←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ p⊃vals}
         del←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ names vals⊢←(⊂p≠⍳≢names)/¨names vals ⋄ n}
         def←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:0 ⋄ 1}
         expand←{str←⍵
           ⍝ Match/Expand...
           ⍝ [1] long names,
             str←pQUOTE_exp pCOM_exp pLONG_NAME_exp ⎕R{
                 f0←⍵ ∆FLD 0 ⋄ nm←⍵.PatternNum∊cName_exp ⋄ get⍣nm⊣f0
             }⍠'UCP' 1⊣str
           ⍝ [2] short names (even within found long names)
             pQUOTE_exp pCOM_exp pSHORT_NAME_exp ⎕R{
                 f0←⍵ ∆FLD 0 ⋄ nm←⍵.PatternNum∊cName_exp ⋄ get⍣nm⊣f0
             }⍠'UCP' 1⊣str
         }

       ⍝ passCommment:   S ←  passComment ⍵:S, where ⍵ starts with /[⍝ ]/
       ⍝    Send (commented ⍵) through to user function, removing "extra" [⍝ ] symbols at start
       ⍝    Each returned commentis marked with a lightbulb...
         passComment←{⍺←'⍝ ' ⋄ PASSTHRU,'⍝💡 ',⍵↓⍨+/∧\⍵∊⍺}   ⍝ Trim '⍝ ' chars, prefix with '⍝💡 '

       ⍝ -------------------------------------------------------------------------
       ⍝ PATTERNS
       ⍝ [1] DEFINITIONS
       ⍝ [2] PATTERN PROCESSING
       ⍝ -------------------------------------------------------------------------

       ⍝ -------------------------------------------------------------------------
       ⍝ [1] DEFINITIONS
       ⍝ -------------------------------------------------------------------------
         _CTR_←0 ⋄ patternList←⍬
         reg←{⍺←'(?xi)' ⋄ patternList,←⊂⍺,⍵ ⋄ (_CTR_+←1)⊢_CTR_}
         cIFDEF←reg'    ^[⍝\h]* :: (IFN?DEF)                    \h+(.*)                     $'
         cIF_STMT←reg'  ^[⍝\h]* :: (IF\h+ | ELSE(?:IF\h+)? | END(?:IF(?:N?DEF)?)?) \b (.*)  $'
         cSET←reg'      ^[⍝\h]* :: [SL]ET   \h* ([^←]+) \h* (?:←\h*(.*))?                   $'
         cCOND←reg'     ^[⍝\h]* :: COND     \h* ([^←]+) \h* (?:←\h*(.*))?                   $'
         cUNSET←reg'    ^[⍝\h]* :: UN[SL]ET \h* ([^←]+) \h*                                 $'
         cCODE←reg'     ^[⍝\h]* :: CODE     \h*                     (.*)                    $'
         cOTHER←reg'    ^                                            .*                     $'

       ⍝ patterns for expand fn
         pQUOTE_exp←'(?x)    (''[^'']*'')+'
         pCOM_exp←'(?x)      ⍝\s*$'
       ⍝ names include ⎕WA, :IF
       ⍝ Long names are of the form #.a or a.b.c
       ⍝ Short names are of the form a or b or c in a.b.c
         cName_exp←2
       ⍝ pINT: Allows both bigInt format and hex format
       ⍝       This is permissive (allows illegal options to be handled by APL),
       ⍝       but also VALID bigInts like 12.34E10 which is equiv to 123400000000
       ⍝       Exponents are invalid for hexadecimals, because the exponential range
       ⍝       is not defined/allowed.
         pINT←'(?xi)  (?<![\dA-F\.])  ¯? [\.\d]  (?: [\d\.]* (?:E\d+)? I | [\dA-F]* X)'
         pLONG_NAME_exp←'(?x)   [⎕:]?([\w∆⍙_][\w∆⍙_0-9]+)(\.(?1))*'
         pSHORT_NAME_exp←'(?x)  [⎕:]?([\w∆⍙_][\w∆⍙_0-9]+)'

       ⍝ -------------------------------------------------------------------------
       ⍝ [2] PATTERN PROCESSING
       ⍝ -------------------------------------------------------------------------
         processPatterns←{
             f0 f1 f2←⍵ ∆FLD¨0 1 2
             case←⍵.PatternNum
             case=cOTHER:PASSTHRU,expand f0
           ⍝ ：：IFDEF name
           ⍝ ：：END[IF[DEF]]
             case=cIFDEF:{
                 not←'~'↑⍨1∊'nN'∊f1
                 ':IF ',not,⍕def f2
             }0
           ⍝ ：：IF cond
           ⍝ ：：ELSEIF cond
           ⍝ ：：ELSE
           ⍝ ：：END[IF]
             case=cIF_STMT:{                        ⍝ IF, ELSEIF, ELSE, END, ENDIF, ENDIFDEF
                 ':',f1,expand f2
             }0
           ⍝ ：：SET/LET name ← val   ==>  name ← 'val'
           ⍝ ：：SET/LET name        ==>  name ← 'name'
           ⍝ Set name to val, unconditionally.
             case=cSET:{

                 f2←f1{0=≢⍵:∆QT ⍺ ⋄ expand ⍵}f2
                 _←put f1 f2
                 ⎕←(padx f1),' ← ',f2
                 passComment f0
             }0
           ⍝ ：：COND name ← val      ==>  name ← 'val'
           ⍝ ：：COND name            ==>  name ← 'name'
           ⍝ Set name to val only if name not already defined.
             case=cCOND:{
                 d←def f1
                 status←'  ',d⊃'(FALSE)' '(TRUE)'
                 ⎕←'  ',(padx f1),' ← ',f2,status
                 ln←passComment f0,status
                 ~d:ln
                 f2←f1{0=≢⍵:∆QT ⍺ ⋄ expand ⍵}f2
                 _←put f1 f2
                 ln
             }0
           ⍝ ：：CODE code string
           ⍝ Pass through code to the preprocessor phase (to pass to user fn, simply enter it!!!)
             case=cCODE:{
                 ln←f1,'⍝ ::CODE ...'
                 ln,NL,passComment f0
             }0
           ⍝ ：：UNSET name  ==> shadow 'name'
           ⍝ Warns if <name> was not set!
             case=cUNSET:{
                 _←del f1⊣{def ⍵:'' ⋄ ⊢⎕←'UNSETting an unset name: ',⍵}f1
                 ⎕←'  ',(padx f1),'   UNSET'
                 passComment f0
             }0
         }

       ⍝ --------------------------------------------------------------------------------
       ⍝ EXECUTIVE
       ⍝ --------------------------------------------------------------------------------
         funNm←⍵
         tmpNm←'__',funNm,'__'
         srcNm←funNm,'_src'

         dataIn←getDataIn 0
         dataFinal←⍬

         _←appendRaw('⍙←',tmpNm)('⍝ Preprocessor for ',funNm)'⍙←⍬'

         names←vals←⍬
         _←appendCond patternList ⎕R processPatterns⍠'UCP' 1⊣dataIn
         fx∆←⎕FX dataFinal
         ' '=1↑0⍴fx∆:1 funNm fx∆   ⍝ f∆ usually is tmpNm
         0 funNm fx∆
     }⍵
⍝∇⍣§./preproc.dyalog§0§ 2019 6 28 21 17 38 542 §dòéMØå§0
 }
