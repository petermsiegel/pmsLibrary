 ∆PRE←{⎕IO ⎕ML ⎕PP←0 1 34
  ⍝H ∆PRE
  ⍝H - Preprocesses contents of codeFileName (a 2∘⎕FIX-format file) and fixes in
  ⍝H   the workspace (via 2 ⎕FIX ppData, where ppData is the processed version of the contents).
  ⍝H - Returns: (shyly) the list of objects created (possibly none).
  ⍝H
  ⍝H names ← [⍺:opts] ∆PRE ⍵:codeFileName
  ⍝H
  ⍝H ⍺:opts   Contains one or more of the following letters:
  ⍝H
  ⍝H Verbosity
  ⍝H    'V' (Verbose)The default
  ⍝H                 Preprocessor directives and APL lines with macro replacements
  ⍝H                 are shown in the ⎕FIXed output code as comments
  ⍝H Debugging output
  ⍝H    'D' (Debug)
  ⍝H                 Details on the flow of execution are showed in the stdout (⎕←...)
  ⍝H                 For function ⍵, the function __⍵__, which shows all the details, is preserved.
  ⍝H    'DV'
  ⍝H                 Both V and D above
  ⍝H Are multi-line double-quoted strings treated as
  ⍝H multiple strings or a single strings with NLs
  ⍝H        str ← "line1
  ⍝H               line2
  ⍝H               line three"
  ⍝H    'M' (Mult)   The default
  ⍝H                 A multiline DQ string ends up as multiple char vectors
  ⍝H                 str←'line1' 'line2' 'line3'
  ⍝H    'S' (Single) A multiline DQ string ends up as a single string with embedded newlines
  ⍝H                 str←('line1',(⎕UCS 13),'line2',(⎕UCS 13),'line three')
  ⍝H    'Q' or ''
  ⍝H                 None of 'DVS' above.
  ⍝H                 put no extra comments in output and no details on the console
  ⍝H Help Information
  ⍝H    'H'          Show this HELP information
  ⍝H    '?' | 'h'    Same as 'H'
  ⍝H ⍵:codeFN
  ⍝H    The simple name, name.ext, or full filename
  ⍝H    of the function or cluster of ⎕FIXable objects, whose source will be loaded from:
  ⍝H    [a] if ⍵ has no filetype/extension,
  ⍝H            ⍵.dyapp, then (if not found),   ⍵.dyalog
  ⍝H    [b] else
  ⍝H            ⍵ by itself.
  ⍝H    THese directories are searched:
  ⍝H           .  ..  followed by names in env vars FSPATH and WSPATH (: separates dirs)
  ⍝H Returns (shyly) the names of 0 or more objects fixed via (2 ⎕FIX code).
  ⍝H
  ⍝H Features:
  ⍝H    implicit macros
  ⍝H       Hex number converted to decimal
  ⍝H            0FACX /[\d][\dA-F]*[xX]/
  ⍝H       Big integers (any length) /¯?\d+[iI]/ converted to quoted numeric string.
  ⍝H            04441433566767657I →  '04441433566767657'
  ⍝H    explicit macros replaced
  ⍝H       See ::DEF, ::CDEF
  ⍝H    Directives
  ⍝H       ::IF      cond         If cond is an undefined name, returns false, as if ::IF 0
  ⍝H       ::IFDEF   name         If name is defined, returns true even if name has value 0
  ⍝H       ::IFNDEF  name
  ⍝H       ::ELSEIF  cond
  ⍝H       ::ELIF                 Alias for ::ELSEIF
  ⍝H       ::ELSE
  ⍝H       ::END                  ::ENDIF, ::ENDIFDEF; allows ::END followed by ANY text
  ⍝H       ::DEF     name ← [VAL] VAL may be an APL code sequence, including comments
  ⍝H                              or nullstring. If parens are needed, use them.
  ⍝H       ::DEF     name ←       Sets name to a nullstring, not its quoted value.
  ⍝H       ::DEF     name         Same as ::DEF name ← 'name'
  ⍝H       ::DEFINE  name ...     Alias for ::DEF ...
  ⍝H       ::CDEF    name ...     Like ::DEF, except executed only if name is undefined
  ⍝H       ::UNDEF   name         Undefines name, warning if already undefined
  ⍝H       ::VAL     name ...     Same as ::DEF, except name ← ⍎val
  ⍝H       ::INCLUDE [name[.ext] | "dir/file" | 'dir/file']
  ⍝H       ::INCL    name
  ⍝H       ----------------
  ⍝H       cond: Is 0 if value of expr is 0, '', or undefined! Else 1.
  ⍝H       ext:  For ::INCLUDE/::INCL, extensions checked first are .dyapp and .dyalog.
  ⍝H             Paths checked are '.', '..', then dirs in env vars FSPATH and WSPATH.

     ⍺←'V'  ⍝  (2↑[1]↑'⍝H ab' 'fred' 'ted⍝H')∧.='⍝H'
     1∊'Hh?'∊⍺:{⎕ED'___'⊣___←↑⍵/⍨(↑2↑¨⍵)∧.='⍝H'}2↓¨⎕NR'∆PRE'

     0≠≢⍺~'VDQSM':11 ⎕SIGNAL⍨'∆PRE: Options are any of {V or D, S or M}, Q, or H (default ''VM'')'

     1:_←(1∊'DV'∊⍺){   ⍝ ⍵: [0] funNm, [1] tmpNm, [2] lines
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
         1:2 ⎕FIX{
             EMPTY←,⎕UCS 0
             (⍵≢¨⊂EMPTY)/⍵
         }(#.SAVE←⍺ ___condSave___ ⍵)
     }⍺{

       ⍝ ∆GENERAL ∆UTILITY ∆FUNCTIONS
         ∆NOTE←{⍺←0 ⋄ ⍺∧DEBUG:⍞←⍵ ⋄ DEBUG:⎕←⍵ ⋄ ''}
         ∆PASS←{VERBOSE:⍵ ⋄ EMPTY}                         ⍝ See EMPTY above. Generated only if VERBOSE
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
         ∆DEQUOTE←{⍺←'"''' ⋄ ⍺∊⍨1↑⍵:1↓¯1↓⍵ ⋄ ⍵}
         ∆QTX←{⍺←'''' ⋄ ⍺ ∆QT ⍵/⍨1+⍵=⍺}

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
                 1
             }⍵
             _←∆NOTE INFO,' Is (',⍵,') true? ',(ans⊃'NO' 'YES')
             ans
         }

       ⍝ GENERAL CONSTANTS
         NL←⎕UCS 10 ⋄ EMPTY←,⎕UCS 0                        ⍝ An EMPTY line will be deleted before ⎕FIXing
         VERBOSE DEBUG←'VD'∊⍺ ⋄ QUIET←VERBOSE⍱DEBUG
         DQ_SINGLE←'S'∊⍺
         YES NO SKIP INFO←'  ' ' 😞' ' 🚫' ' 💡'

       ⍝ Process double quotes based on DQ_SINGLE flag.

         processDQ←{⍺←DQ_SINGLE   ⍝ If 1, create a single string. If 0, create char vectors.
             u13←''',(⎕UCS 13),'''                           ⍝ "xx\nyy\nzz'
             opts←('Mode' 'M')('EOL' 'LF')                   ⍝ Do not convert CR, NEL, to LF
             ⍺:'(',')',⍨∆QT'\n\h+'⎕R u13⍠opts⊢'"'∆DEQUOTE ⍵  ⍝ → ('xx',(⎕UCS 13),'yy',(⎕UCS 13),'zz')
             ∆QT'\n\h+'⎕R''' '''⍠opts⊢'"'∆DEQUOTE ⍵          ⍝ → 'xx' 'yy' 'zz'
         }
      ⍝ Append literal strings ⍵:SV.                      ⍝ res@B(←⍺) ← ⍺@B←1 appendRaw ⍵:SV
         appendRaw←{⍺←1 ⋄ ⍺⊣dataFinal,←⍵}
      ⍝ Append quoted string                              ⍝ res@B ←  ⍺@B←1 appendCond ⍵:SV
         appendCond←{PASSTHRU=1↑⍵:appendRaw⊂'⍙,←⊂',∆QTX 1↓⍵ ⋄ 0 appendRaw⊂⍵}¨
      ⍝ Pad str ⍵ to at least ⍺ (15) chars.
         padx←{⍺←15 ⋄ ⍺<≢⍵:⍵ ⋄ ⍺↑⍵}
      ⍝ get function '⍵' or its char. source '⍵_src', if defined.
         getDataIn←{∆∆←∇
             ⍺←{∪{(':'≠⍵)⊆⍵}'.:..',∊':',¨{⊢2 ⎕NQ'.' 'GetEnvironment'⍵}¨⍵}'FSPATH' 'WSPATH'
             0=≢⍺:11 ⎕SIGNAL⍨'Unable to find or load source file ',(∆DQT ⍵),' (filetype must be dyapp or dyalog)'
             dir dirs←(⊃⍺)⍺
             types←{
                 0≠≢⊃⌽⎕NPARTS ⍵:⊂''     ⍝ If the file has an explicit type, use only it...
                 '.dyapp' '.dyalog'
             }⍵
             types{
                 0=≢⍺:(1↓dirs)∆∆ ⍵
                 filenm←(2×dir≡,'.')↓dir,'/',⍵,⊃⍺
                 ⎕NEXISTS filenm:filenm(⊃⎕NGET filenm 1)
                 (1↓⍺)∇ ⍵
             }⍵
         }

      ⍝ MACRO (NAME) PROCESSING
      ⍝ functions...
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
                 cSQe cCe cLNe←0 1 2
                 str←expSQuote expCom pLNe ⎕R{
                     f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊
                     case cSQe:f0
                     case cLNe:get f0
                     else f0                ⍝ expCom
                 }⍠'UCP' 1⊣str

              ⍝ [2] pSNe: short names (even within found long names)
              ⍝     expInt: Hexadecimals and bigInts
                 cSQe cCe cSNe cIe←0 1 2 3
                 str←expSQuote expCom pSNe expInt ⎕R{
                     f0←⍵ ∆FLD 0 ⋄ case←⍵.PatternNum∘∊

                     case cIe:{⍵∊'xX':⍕h2d f0 ⋄ ∆QT ¯1↓f0}¯1↑f0
                     case cSNe:get f0
                     else f0     ⍝ expSQuote or expCom
                 }⍠'UCP' 1⊣str
                 str≢strIn:(⍺-1)∇ str    ⍝ expand is recursive, but only initial MAX_EXPAND times.
                 str
             }str
         ⍝  Ellipses - constants (expEllipses1) and variable (expEllipses2)
         ⍝  Check only after all substitutions, so ellipses with macros that resolve to numeric constants
         ⍝  are optimized.
             cSQe cCe cE1e cE2e←0 1 2 3
             str←expSQuote expCom expEllipses1 expEllipses2 ⎕R{
                 case←⍵.PatternNum∘∊
                 case cSQe cCe:⍵ ∆FLD 0
                 case cE1e:⍕⍎f1,' ∆TO ',f2⊣f1 f2←⍵ ∆FLD¨1 2  ⍝  num [num] .. num
                 case cE2e:∆TOcode                           ⍝  .. preceded or followed by non-constants
             }⍠'UCP' 1⊣str
             str
         }


      ⍝ -------------------------------------------------------------------------
      ⍝ PATTERNS
      ⍝ [1] DEFINITIONS -
      ⍝ [2] PATTERN PROCESSING
      ⍝ -------------------------------------------------------------------------

      ⍝ -------------------------------------------------------------------------
      ⍝ [1] DEFINITIONS
      ⍝ -------------------------------------------------------------------------
         _CTR_←0 ⋄ patternList←patternName←⍬
         reg←{⍺←'???' ⋄ p←'(?xi)' ⋄ patternList,←⊂∆MAP p,⍵ ⋄ patternName,←⊂⍺ ⋄ (_CTR_+←1)⊢_CTR_}
         ⋄ ppBegin←'^\h* ::\h*'
         cIFDEF←'ifdef'reg'    ⍎ppBegin  IF(N?)DEF         \h+(.*)         $'
         cIF←'if'reg'          ⍎ppBegin  IF                \h+(.*)         $'
         cELSEIF←'elseif'reg'  ⍎ppBegin  EL(?:SE)?IF \b    \h+(.*)         $'
         cELSE←'else'reg'      ⍎ppBegin  ELSE         \b       .*          $'
         cEND←'end'reg'        ⍎ppBegin  END                   .*          $'
         ⋄ ppName←' \h* ([^←]+) \h*'
         ⋄ ppToken←'\h* ((?| (?:"[^"]+")+ | (?:''[^'']+'')+ | \w+)) \h* .*'
         ⋄ ppArr←'(?:(←)\h*(.*))?'
         cDEF←'def'reg'        ⍎ppBegin  DEF(?:INE)? \b ⍎ppName   ⍎ppArr   $'
         cVAL←'val'reg'        ⍎ppBegin  E?VAL       \b ⍎ppName   ⍎ppArr   $'
         cINCL←'include'reg'   ⍎ppBegin  INCL(?:UDE)?\b ⍎ppToken           $'
         cCDEF←'cond'reg'      ⍎ppBegin  CDEF        \b ⍎ppName   ⍎ppArr   $'
         cUNDEF←'undef'reg'    ⍎ppBegin  UNDEF       \b ⍎ppName            $'
         cOTHER←'apl'reg'   ^                                     .*       $'

      ⍝ patterns for the ∇expand∇ fn
         expDQuote←'(?x)   (    (?: " [^"]*     "  )+  )'
         expSQuote←'(?x)   (    (?: ''[^''\n\r]*'' )+  )'    ⍝ Don't allow multi-line SQ strings...
         expCom←'(?x)     ⍝ .*  $'
         ppNum←' (?: ¯?  (?: \d+ (?: \.\d* )? | \.\d+ ) (?: [eE]¯?\d+ )?  )'~' ' ⍝ Non-complex numbers...
         expEllipses1←∆MAP'(?x)  ( ⍎ppNum (?: \h+ ⍎ppNum)* ) \h* (?: … |\.{2,} \h* ((?1))'
         expEllipses2←'(?x)   (?: … | \.{2,}}'

      ⍝ names include ⎕WA, :IF
      ⍝ pLNe Long names are of the form #.a or a.b.c
      ⍝ pSNe Short names are of the form a or b or c in a.b.c
      ⍝ expInt: Allows both bigInt format and hex format
      ⍝       This is permissive (allows illegal options to be handled by APL),
      ⍝       but also VALID bigInts like 12.34E10 which is equiv to 123400000000
      ⍝       Exponents are invalid for hexadecimals, because the exponential range
      ⍝       is not defined/allowed.
         expInt←'(?xi)  (?<![\dA-F\.])  ¯? [\.\d]  (?: [\d\.]* (?:E\d+)? I | [\dA-F]* X)'
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
             _←∆NOTE'[',(∊'ZI2'⎕FMT lineNum),'] ',(8 padx∊patternName[⍵.PatternNum]),'| ',f0
          ⍝  Any non-directive, i.e. APL statement, comment, or blank line...
             case cOTHER:{
                 T=⊃⌽stack:{str←expand ⍵ ⋄ QUIET∨str≡⍵:str ⋄ '⍝ ',⍵,YES,NL,'  ',str}f0
                 ∆PASS'⍝ ',f0,SKIP     ⍝ See ∆PASS, QUIET
             }0
           ⍝ ::IFDEF/IFNDEF name
             case cIFDEF:{
                 T≠⊃⌽stack:∆PASS'⍝ ',f0,SKIP⊣stack,←S
                 stack,←c←~⍣(1∊'nN'∊f1)⊣def f2
                 ∆PASS'⍝ ',f0,(c⊃NO YES)
             }0
           ⍝ ::IF cond
             case cIF:{
                 T≠⊃⌽stack:∆PASS'⍝ ',f0,SKIP⊣stack,←S
                 stack,←c←∆TRUE expand f1
                 ∆PASS'⍝ ',f0,(c⊃NO YES)
             }0
          ⍝  ::ELSEIF
             case cELSEIF:{
                 S=⊃⌽stack:∆PASS'⍝ ',f0,SKIP⊣stack,←S
                 T=⊃⌽stack:∆PASS'⍝ ',f0,NO⊣(⊃⌽stack)←F
                 (⊃⌽stack)←c←∆TRUE expand f1
                 ∆PASS'⍝ ',f0,(c⊃NO YES)
             }0
           ⍝ ::ELSE
             case cELSE:{
                 S=⊃⌽stack:∆PASS'⍝ ',f0,SKIP⊣stack,←S
                 T=⊃⌽stack:∆PASS'⍝ ',f0,NO⊣(⊃⌽stack)←F
                 (⊃⌽stack)←T
                 ∆PASS'⍝ ',f0,YES
             }0
           ⍝ ::END(IF(N)(DEF))
             case cEND:{
                 stack↓⍨←¯1
                 c←S≠⊃⌽stack
                 0=≢stack:∆PASS'⍝ ',f0,ERR⊣stack←,0⊣∆NOTE'INVALID ::END statement at line [',lineNum,']'
                 ∆PASS'⍝ ',(c⊃'     ' ''),f0     ⍝ Line up cEND with skipped IF/ELSE
             }0
          ⍝ ：：DEF name ← val    ==>  name ← 'val'
          ⍝ ：：DEF name          ==>  name ← 'name'
          ⍝ ：：DEF name ← ⊢      ==>  name ← '⊢'     Make name a NOP
          ⍝ ：：DEF name ← ⍝...      ==>  name ← '⍝...'
          ⍝ Define name as val, unconditionally.
             case cDEF:{
                 T≠stk←⊃⌽stack:∆PASS'⍝ ',f0,(SKIP NO⊃⍨F=stk)
                 noArrow←1≠≢f2
                 f3 note←f1{noArrow∧0=≢⍵:(∆QT ⍺)'' ⋄ 0=≢⍵:'' '  [EMPTY]' ⋄ (expand ⍵)''}f3
                 _←put f1 f3
                 _←∆NOTE INFO,'DEF   ',(padx f1),' ','←',' ',(30 padx f3),note
                 ∆PASS'⍝ ',f0
             }0
           ⍝  ::VAL name ← val    ==>  name ← ⍎'val' etc.
           ⍝  ::VAL i5  ← (⍳5)         i5 set to '(0 1 2 3 4)' (depending on ⎕IO)
           ⍝ Experimental preprocessor-time evaluation
             case cVAL:{
                 T≠stk←⊃⌽stack:∆PASS'⍝ ',f0,(SKIP NO⊃⍨F=stk)
                 noArrow←1≠≢f2
                 f3 note←f1{
                     noArrow∧0=≢⍵:(∆QT ⍺)''
                     0=≢⍵:'' '  [EMPTY]'
                     {0::(⍵,' ∘∘∘')'  [INVALID EXPRESSION DURING PREPROCESSING]'
                         (⍕⍎⍵)''
                     }expand ⍵
                 }f3
                 _←put f1 f3
                 _←∆NOTE INFO,'VAL   ',(padx f1),' ','←',' ',(30 padx f3),note
                 ∆PASS'⍝ ',f0,YES
             }0
          ⍝ ::CDEF name ← val      ==>  name ← 'val'
          ⍝ ::CDEF name            ==>  name ← 'name'
          ⍝  etc.
          ⍝ Set name to val only if name not already defined.
             case cCDEF:{
                 T≠stk←⊃⌽stack:∆PASS'⍝ ',f0,(SKIP NO⊃⍨F=stk)
                 defd←def f1
                 ln←'⍝ ',f0
                 defd:∆PASS ln,NO,NL⊣∆NOTE'  ',(padx f1),' ',f2,' ',f3,NO
                 noArrow←1≠≢f2
                 f3 note←f1{noArrow∧0=≢⍵:(∆QT ⍺)'' ⋄ 0=≢⍵:''('  ',INFO,'EMPTY') ⋄ (expand ⍵)''}f3
                 _←put f1 f3
                 _←∆NOTE' ',(padx f1),' ',f2,' ',(30 padx f3),note
                 ∆PASS ln
             }0
           ⍝ ::UNDEF name
           ⍝ Warns if <name> was not set!
             case cUNDEF:{
                 T≠stk←⊃⌽stack:∆PASS'⍝ ',f0,(SKIP NO⊃⍨F=stk)
                 _←del f1⊣{def ⍵:'' ⋄ ⊢∆NOTE INFO,' UNDEFining an undefined name: ',⍵}f1
                 _←∆NOTE INFO,'UNDEF ',(padx f1)
                 ∆PASS'⍝ ',f0,YES
             }0
           ⍝ ::INCLUDE file or "file with spaces" or 'file with spaces'
           ⍝ If file has no type, .dyapp [dyalog preprocessor] or .dyalog are assumed
             case cINCL:{
                 T≠stk←⊃⌽stack:∆PASS'⍝ ',f0,(SKIP NO⊃⍨F=stk)
                 funNm←∆DEQUOTE f1
                 1 ∆NOTE INFO,2↓(bl←+/∧\f0=' ')↓f0
                 (fullNm dataIn)←getDataIn funNm
                 1 ∆NOTE',',msg←' file "',fullNm,'", ',(⍕≢dataIn),' lines',NL

                 _←fullNm{
                     includedFiles,←⊂⍺
                     ~⍵∊⍨⊂⍺:⍬
                   ⍝ See ::extern INCLUDE_LIMITS
                     count←+/includedFiles≡¨⊂⍺
                     warn err←(⊂INFO,'::INCLUDE '),¨'WARNING: ' 'ERROR: '
                     count≤1↑INCLUDE_LIMITS:⍬
                     count≤¯1↑INCLUDE_LIMITS:⎕←warn,'File "',⍺,'" included ',(⍕count),' times'
                     11 ⎕SIGNAL⍨err,'File "',⍺,'" included too many times (',(⍕count),')'
                 }includedFiles

                 includeLines∘←dataIn
                 ∆PASS'⍝ ',f0,'  ',INFO,msg
             }0
         }

      ⍝ --------------------------------------------------------------------------------
      ⍝ EXECUTIVE
      ⍝ --------------------------------------------------------------------------------
       ⍝ User-settable options
         MAX_EXPAND←5  ⍝ Maximum times to expand macros (if 0, none are expanded!)
         INCLUDE_LIMITS←5 10  ⍝ First # is min before warning. Second is max before error.

       ⍝ Initialization
         funNm←⍵
         stack←,1
         lineNum←0
         tmpNm←'__',funNm,'__'

         fullNm dataIn←getDataIn funNm       ⍝ dataIn: SV
         includedFiles←⊂fullNm
         NLINES←≢dataIn ⋄ NWIDTH←⌈10⍟NLINES

         _←∆NOTE'Processing object ',(∆DQT funNm),' from file "',∆DQT fullNm
         _←∆NOTE'Object has ',NLINES,' lines'
         dataFinal←⍬

         names←vals←⍬
         includeLines←⍬
       ⍝ Go!
       ⍝ Convert multiline quoted strings "..." to single lines ('...',(⎕UCS 13),'...')
         expCont←'(?x) \h* \.{2,} \h* (⍝ .*)? \n\h*'
         pEOL←'(?x)              \h* (⍝ .*)? \n'

         comment←⍬
         lines←expDQuote expCont expSQuote pEOL ⎕R{
             f0 f1←⍵ ∆FLD¨0 1 ⋄ case←⍵.PatternNum∘∊
             case 0:processDQ f0   ⍝ DQ, w/ possible newlines...
             case 1:' '⊣comment,←(' '/⍨0≠≢f1),f1
             case 2:f0
           ⍝ case 3
             0=≢comment:f0
             ln←comment,' ',f1,NL ⋄ comment⊢←⍬
           ⍝ If the commment is more than (⎕PW÷2), put on newline
             (' 'NL⊃⍨(⎕PW×0.5)<≢ln),1↓ln
         }⍠('Mode' 'M')('EOL' 'LF')('NEOL' 1)⊣dataIn
       ⍝ Process macros... one line at a time, so state is dependent only on lines before...
         lines←{⍺←⍬
             0=≢⍵:⍺
             l←patternList ⎕R processDirectives⍠'UCP' 1⊣⊃⍵
             (⍺,⊂l)∇(includeLines∘←⍬)⊢includeLines,1↓⍵
         }lines
       ⍝ Return specifics to next phase for ⎕FIXing
         funNm tmpNm lines
     }⍵
 }
