 ∆PRE←{⎕IO ⎕ML←0 1
   ⍝ Alternative to ∆FIX... 20190706
   ⍝ Returns (shyly) the list of objects created (possibly none)
   ⍝ ⍺: DEBUG. If 1, the preproc file created __⍵__ is not deleted.
     ⍺←0
     ⍺{   ⍝ ⍵: [0] funNm, [1] tmpNm, [2] lines
              ⍝ ⍺: 1 if DEBUG, else 0
         ___condSave___←{
             _←⎕EX 1⊃⍵
             ⍺:⍎'(0⊃⎕RSI).',(1⊃⍵),'←2⊃⍵'
             2⊃⍵
         }
         0::11 ⎕SIGNAL⍨{
             _←1 ___condSave___ ⍵
             _←'Preprocessor error. Generated object for input "',(0⊃⍵),'" is invalid.',⎕TC[2]
             _,'See preprocessor output: "',(1⊃⍵),'"'
         }⍵
         1:___objs___←2 ⎕FIX ⍺ ___condSave___ ⍵
     }⍺{
         VERBOSE←⍺
         NOTE←{VERBOSE:⎕←⍵ ⋄ ''}
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
         ∆MAP←{'⍎\w+'⎕R{⍎1↓⍵ ∆FLD 0}⊣⍵}

         ∆QT←{⍺←'''' ⋄ ⍺,⍵,⍺}
         ∆DQT←{'"'∆QT ⍵}
         ∆QTX←{∆QT ⍵/⍨1+⍵=''''}                            ⍝ Quote each line, "escaping" each quote char.
         h2d←{                                             ⍝ Decimal from hexadecimal
             11::'h2d: number too large'⎕SIGNAL 11         ⍝ number too big.
             16⊥16|a⍳⍵∩a←'0123456789abcdef0123456789ABCDEF'⍝ Permissive-- ignores non-hex chars!
         }

         ∆TRUE←{
             ans←{0::0⊣⍞←' [ERR] '
                 0=≢⍵~' ':0
                 val←⍎⍵
                 0∊⍴val:0
                 0=≢val:0
                 (,0)≡∊val:0
                 1}⍵
             ⎕←'Is ',⍵,' true? ',(ans⊃'NO' 'YES')
             ans
         }

      ⍝ Append literal strings ⍵:SV.                      ⍝ res@B(←⍺) ← ⍺@B←1 appendRaw ⍵:SV
         appendRaw←{⍺←1 ⋄ ⍺⊣dataFinal,←⍵}
      ⍝ Append quoted string                              ⍝ res@B ←  ⍺@B←1 appendCond ⍵:SV
         appendCond←{PASSTHRU=1↑⍵:appendRaw⊂'⍙,←⊂',∆QTX 1↓⍵ ⋄ 0 appendRaw⊂⍵}¨
      ⍝ Pad str ⍵ to at least ⍺ (15) chars.
         padx←{⍺←15 ⋄ ⍺<≢⍵:⍵ ⋄ ⍺↑⍵}
      ⍝ get function '⍵' or its char. source '⍵_src', if defined.
         getDataIn←{∆∆←∇
             ⍺←{∪{(':'≠⍵)⊆⍵}'.:',1↓∊':',¨{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}¨⍵}'FSPATH' 'WSPATH'
             0=≢⍺:11 ⎕SIGNAL⍨'Unable to find or load source file ',(∆DQT ⍵),' (filetype must be dyapp or dyalog)'
             dir dirs types←(⊃⍺)⍺('dyapp' 'dyalog')
             types{
                 0=≢⍺:(1↓dirs)∆∆ ⍵
                 filenm←dir,'/',⍵,'.',⊃⍺
                 ⎕NEXISTS filenm:filenm(⊃⎕NGET filenm 1)
                 (1↓⍺)∇ ⍵
             }⍵
         }

      ⍝ MACRO (NAME) PROCESSING
      ⍝ FUNCTIONS
         put←{n v←⍵ ⋄ n~←' ' ⋄ names,⍨←⊂n ⋄ vals,⍨←⊂v ⋄ 1:⍵}  ⍝ add name val
         get←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ p⊃vals}
         del←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:n ⋄ names vals⊢←(⊂p≠⍳≢names)/¨names vals ⋄ n}
         def←{n←⍵~' ' ⋄ p←names⍳⊂n ⋄ p≥≢names:0 ⋄ 1}
         expand←{
             else←⊢
           ⍝ Concise variant on dfns:to, allowing start [incr] to end
           ⍝     1 1.5 to 5     →   1 1.5 2 2.5 3 3.5 4 4.5 5
           ⍝ expanded to allow simply (homogeneous) Unicode chars
           ⍝     'ac' to 'g'    →   'aceg'
             ∆TO←{⎕IO←0 ⋄ 0=80|⎕DR ⍬⍴⍺:⎕UCS⊃∇/⎕UCS¨⍺ ⍵ ⋄ f s←1 ¯1×-\2↑⍺,⍺+×⍵-⍺ ⋄ f+s×⍳0⌈1+⌊(⍵-f)÷s+s=0}
             ∆TOcode←'{⎕IO←0 ⋄ 0=80|⎕DR ⍬⍴⍺:⎕UCS⊃∇/⎕UCS¨⍺ ⍵ ⋄ f s←1 ¯1×-\2↑⍺,⍺+×⍵-⍺ ⋄ f+s×⍳0⌈1+⌊(⍵-f)÷s+s=0}'
             str←⍵
             str←{⍺←MAX_EXPAND       ⍝ If 0, macros including hex, bigInt, etc. are NOT expanded!!!
                 strIn←str←⍵
                 0≥⍺:⍵
             ⍝ Match/Expand...
             ⍝ [1] pLNe: long names,
                 str←pQe pCe pLNe ⎕R{
                     f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊

                     case 2:get f0
                     else f0
                 }⍠'UCP' 1⊣str

              ⍝ [2] pSNe: short names (even within found long names)
              ⍝     pIe: Hexadecimals and bigInts
                 cQe cCe cSNe cIe←0 1 2 3
                 str←pQe pCe pSNe pIe ⎕R{
                     f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊

                     case cIe:{⍵∊'xX':⍕h2d f0 ⋄ ∆QT ¯1↓f0}¯1↑f0
                     case cSNe:get f0
                     else f0
                 }⍠'UCP' 1⊣str
                 str≢strIn:(⍺-1)∇ str    ⍝ expand is recursive, but only initial MAX_EXPAND times.
                 str
             }str
         ⍝  Ellipses - constants (pE1e) and variable (pE2e)
         ⍝  Check only after all substitutions, so ellipses with macros that resolve to numeric constants
         ⍝  are optimized.
             str←pQe pCe pE1e pE2e ⎕R{
                 case←⍵.PatternNum∘∊
                 case 0 1:⍵ ∆FLD 0 ⋄
                 case 2:⍕⍎f1,' ∆TO ',f2⊣f1 f2←⍵ ∆FLD¨1 2    ⍝  num [num] .. num
                 case 3:∆TOcode                             ⍝  .. preceded or followed by non-constants⋄
             }⍠'UCP' 1⊣str
             str
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
         _CTR_←0 ⋄ patternList←patternName←⍬
         reg←{⍺←'???' ⋄ p←'(?xi)' ⋄ patternList,←⊂∆MAP p,⍵ ⋄ patternName,←⊂⍺ ⋄ (_CTR_+←1)⊢_CTR_}
         ⋄ ppBegin←'^\h* ::\h*'
         cIFDEF←'ifdef'reg'    ⍎ppBegin (IFN?DEF)   \h+(.*)         $'
         cIF←'if'reg'          ⍎ppBegin IF \b       \h+(.*)         $'
         cELSEIF←'elseif'reg'  ⍎ppBegin ELSEIF \b   \h+(.*)         $'
         cELSE←'else'reg'      ⍎ppBegin ELSE \b         .*          $'
         cEND←'end'reg'        ⍎ppBegin (?:END | ENDIF | ENDIFDEF | ENDIFNDEF)\b  .*    $'
         ⋄ ppName←' \h* ([^←]+) \h*'
         ⋄ ppToken←'\h* ((?| (?:"[^"]+")+ | (?:''[^'']+'')+ | \w+)) \h* .*'
         ⋄ ppArr←'(?:(←)\h*(.*))?'
         cDEF←'def'reg'        ⍎ppBegin  DEF     \b ⍎ppName   ⍎ppArr    $'
         cVAL←'val'reg'        ⍎ppBegin  VAL     \b ⍎ppName   ⍎ppArr    $'
         cINCL←'include'reg'   ⍎ppBegin  INCLUDE \b ⍎ppToken            $'
         cCOND←'cond'reg'      ⍎ppBegin  COND    \b ⍎ppName   ⍎ppArr    $'
         cUNDEF←'undef'reg'    ⍎ppBegin  UNDEF   \b ⍎ppName             $'
         cCODE←'code'reg'      ⍎ppBegin  CODE    \b \h*       (.*)     $'
         cOTHER←'apl'reg'   ^                                .*      $'

      ⍝ patterns for expand fn
         pQe←'(?x)   (|  (?:''[^''\R]*'')+ | (?: "[^"]*")*  )'
         pCe←'(?x)      ⍝\s*$'
         ppNum←' (?: ¯?  (?: \d+ (?: \.\d* )? | \.\d+ ) (?: [eE]¯?\d+ )?  )' ⍝ Non-complex numbers...
         pE1e←∆MAP'(?x)  ( ⍎ppNum (?: \h+ ⍎ppNum)* ) \h* \.{2,} \h* ((?1))'
         pE2e←'(?x)   \.{2,}'

      ⍝ names include ⎕WA, :IF
      ⍝ pLNe Long names are of the form #.a or a.b.c
      ⍝ pSNe Short names are of the form a or b or c in a.b.c
      ⍝ pIe: Allows both bigInt format and hex format
      ⍝       This is permissive (allows illegal options to be handled by APL),
      ⍝       but also VALID bigInts like 12.34E10 which is equiv to 123400000000
      ⍝       Exponents are invalid for hexadecimals, because the exponential range
      ⍝       is not defined/allowed.
         pIe←'(?xi)  (?<![\dA-F\.])  ¯? [\.\d]  (?: [\d\.]* (?:E\d+)? I | [\dA-F]* X)'
         pLNe←'(?x)   [⎕:]?([\pL∆⍙_][\pL∆⍙_0-9]+)(\.(?1))*'
         pSNe←'(?x)  [⎕:]?([\pL∆⍙_][\pL∆⍙_0-9]*)'

      ⍝ -------------------------------------------------------------------------
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------
         processDirectives←{
             T F S←1 0 ¯1    ⍝ true, false, skip
             lineNum+←1
             f0 f1 f2 f3←⍵ ∆FLD¨0 1 2 3
             case←⍵.PatternNum∘∊
             _←NOTE'[',(∊'ZI2'⎕FMT lineNum),'] ',(8 padx∊patternName[⍵.PatternNum]),'| ',f0
             case cOTHER:{
                 T=⊃⌽stack:{str←expand ⍵ ⋄ str≡⍵:str ⋄ '⍝ ',⍵,' 💡↑',NL,'  ',str}f0
                 '⍝ ',f0,' 💡×'
             }0
          ⍝ ：：IFDEF/IFNDEF name
             case cIFDEF:{
                 T≠⊃⌽stack:'⍝ ',f0,' 💡×'⊣stack,←S
                 stack,←c←~⍣(1∊'nN'∊f1)⊣def f2
                 '⍝ ',f0,(c⊃' 💡↓' ' 💡↑')
             }0
          ⍝ ：：IF cond
             case cIF:{                            ⍝ IF
                 T≠⊃⌽stack:'⍝ ',f0,' 💡×'⊣stack,←S
                 stack,←c←∆TRUE expand f1
                 '⍝ ',f0,(c⊃' 💡↓ ' '')
             }0
             case cELSEIF:{                           ⍝ ELSEIF
                 S=⊃⌽stack:'⍝ ',f0,' 💡×'⊣stack,←S
                 T=⊃⌽stack:'⍝ ',f0,' 💡↓'⊣(⊃⌽stack)←F
                 (⊃⌽stack)←c←∆TRUE expand f1
                 '⍝ ',f0,(c⊃' 💡↓' ' 💡↑')
             }0
             case cELSE:{
                 S=⊃⌽stack:'⍝ ',f0,' 💡×'⊣stack,←S
                 T=⊃⌽stack:'⍝ ',f0,' 💡↓'⊣(⊃⌽stack)←F  ⍝ ELSE
                 (⊃⌽stack)←T
                 '⍝ ',f0,' 💡↑'
             }0
             case cEND:{                               ⍝ END(IF(N(DEF)))
                 stack↓⍨←¯1
                 c←S≠⊃⌽stack
                 0=≢stack:'⍝ ',f0,' 💡ERR'⊣stack←,0→⎕←'INVALID ::END statement at line [',lineNum,']'
                 '⍝ ',(c⊃'.....' ''),f0     ⍝ Line up cEND with skipped IF/ELSE
             }0
          ⍝ ：：DEF name ← val    ==>  name ← 'val'
          ⍝ ：：DEF name          ==>  name ← 'name'
          ⍝ ：：DEF name ← ⊢      ==>  name ← '⊢'     Make name a NOP
          ⍝ ：：DEF name ← ⍝...      ==>  name ← '⍝...'
          ⍝ Define name as val, unconditionally.
             case cDEF:{
                 ~⊃⌽stack:'⍝ ',f0,' 💡×'
                 noArrow←1≠≢f2
                 f3 note←f1{noArrow∧0=≢⍵:(∆QT ⍺)'' ⋄ 0=≢⍵:'' '  [EMPTY]' ⋄ (expand ⍵)''}f3
                 _←put f1 f3
                 ⎕←'💡DEF ',(padx f1),' ','←',' ',(30 padx f3),note
                 '⍝ ',f0
             }0
           ⍝  ：：VAL name ← val    ==>  name ← ⍎'val' etc.
           ⍝  ：：VAL i5  ← (⍳5)         i5 set to '(0 1 2 3 4)' (depending on ⎕IO)
           ⍝ Experimental preprocessor-time evaluation
             case cVAL:{
                 ~⊃⌽stack:'⍝ ',f0,' 💡×'
                 noArrow←1≠≢f2
                 f3 note←f1{
                     noArrow∧0=≢⍵:(∆QT ⍺)''
                     0=≢⍵:'' '  [EMPTY]'
                     {0::(⍵,' ∘∘∘')'  [INVALID PREPROCESSOR-TIME EXPRESSION]'
                         (⍕⍎⍵)''
                     }expand ⍵
                 }f3
                 _←put f1 f3
                 ⎕←' ',(padx f1),' ',f2,' ',(30 padx f3),note
                 '⍝ ',f0,' 💡↑'
             }0
          ⍝ ：：COND name ← val      ==>  name ← 'val'
          ⍝ ：：COND name            ==>  name ← 'name'
          ⍝  etc.
          ⍝ Set name to val only if name not already defined.
             case cCOND:{
                 ~⊃⌽stack:'⍝ ',f0,' 💡×'
                 defd←def f1
                 ln←'⍝ ',f0
                 defd:ln,NL,' 💡↓'⊣⎕←'  ',(padx f1),' ',f2,' ',f3,' 💡↓'
                 noArrow←1≠≢f2
                 f3 note←f1{noArrow∧0=≢⍵:(∆QT ⍺)'' ⋄ 0=≢⍵:'' '  💡EMPTY' ⋄ (expand ⍵)''}f3
                 _←put f1 f3
                 ⎕←' ',(padx f1),' ',f2,' ',(30 padx f3),note
                 ln
             }0
          ⍝ ：：CODE code string
          ⍝ Pass through code to the preprocessor phase (to pass to user fn, simply enter it!!!)
             case cCODE:{
                 ⍝⍝⍝⍝⍝ OBSOLETE - REMOVE <CODE> logic...
                 ~⊃⌽stack:'⍝ [×] ',f0
                 ln←f1,'⍝ ::CODE ...'
                 ln,NL,passComment f0
             }0
          ⍝ ：：UNDEF name  ==> shadow 'name'
          ⍝ Warns if <name> was not set!
             case cUNDEF:{
                 ~⊃⌽stack:'⍝ ',f0,' 💡×'
                 _←del f1⊣{def ⍵:'' ⋄ ⊢⎕←'💡💡💡 UNDEFining an undefined name: ',⍵}f1
                 ⎕←' ',(padx f1),' → undefined 💡'
                 '⍝ ',f0,' 💡↑'
             }0
             case cINCL:{
                 ~⊃⌽stack:'⍝ ',f0,' 💡×'
                 funNm←f1
                 ⎕←f0
                 (fullNm dataIn)←getDataIn funNm
                 ⎕←msg←(''↑⍨+/∧\f0=' '),'💡↑ ','File: "',fullNm,'". ',(⍕≢dataIn),' lines'

                 _←fullNm{
                     includedFiles,←⊂⍺
                     ~⍵∊⍨⊂⍺:⍬
                   ⍝ See ::extern INCLUDE_LIMITS
                     count←+/includedFiles≡¨⊂⍺
                     warn err←(⊂':INCLUDE '),¨'WARNING: ' 'ERROR: '
                     count≤1↑INCLUDE_LIMITS:⍬
                     count≤¯1↑INCLUDE_LIMITS:⎕←warn,'File "',⍺,'" included ',(⍕count),' times'
                     11 ⎕SIGNAL⍨err,'File "',⍺,'" included too many times (',(⍕count),')'
                 }includedFiles

                 includeLines∘←dataIn
                 '⍝ ',f0,NL,'⍝ ',msg
             }0
         }

      ⍝ --------------------------------------------------------------------------------
      ⍝ EXECUTIVE
      ⍝ --------------------------------------------------------------------------------
         MAX_EXPAND←5  ⍝ Maximum times to expand macros (if 0, none are expanded!)
         funNm←⍵
         stack←,1
         lineNum←0
         tmpNm←'__',funNm,'__'

         fullNm dataIn←getDataIn funNm       ⍝ dataIn: SV
         includedFiles←⊂fullNm
         NLINES←≢dataIn ⋄ NWIDTH←⌈10⍟NLINES
         INCLUDE_LIMITS←5 10  ⍝ First # is min before warning. Second is max before error.

         ⎕←'Processing object ',(∆DQT funNm),' from file "',∆DQT fullNm
         ⎕←'Object has ',NLINES,' lines'
         dataFinal←⍬

         names←vals←⍬
         includeLines←⍬
         lines←{⍺←⍬
             0=≢⍵:⍺
             l←patternList ⎕R processDirectives⍠'UCP' 1⊣⊃⍵
             (⍺,⊂l)∇(includeLines∘←⍬)⊢includeLines,1↓⍵
         }dataIn
         funNm tmpNm lines
     }⍵
 }
