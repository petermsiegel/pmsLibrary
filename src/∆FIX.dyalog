∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝     result←  options ∆FIX  [filename:@S | lines:@VS]
  ⍝ The result is as for ⎕FIX, i.e. names of objects fixed, unless a "nonce" option (extension) is used (q.v.). 
  ⍝ For internal, recursive calls, ⍺ is a namespace containing defined macros (MACROSñ) used as context for ::INCLUDE statements.
  ⍝ If seen, the FIXf←'i' (internal call).    
  ⍝ Note new feature (unused): ⍵(86⌶)'abc'  returns value of object 'abc' at different stack levels: 0=current  
  ⍺←0
  FIXf←2                         ⍝ Default:  2 ∆FIX object. If ⍺ is missing, default is 0 ∆FIX object, as for ⎕FIX.
  DEBUGf←0                       ⍝ See ::DEBUG [[ON | OFF]]      
  COMPRESSf←0                    ⍝ See ::COMPRESS [[ON | OFF]]
  ABENDf←0                       ⍝ If a directive error is detected, this is set to 1 if and only if a ⎕FIX is scheduled. 
  SetABENDf←{ABENDf∘←Ff ⋄  ⍵}    ⍝ SetABENDf: Sets ABENDf←Ff
  (FIXf DEBUGf COMPRESSf)MACROSñ←FIXf DEBUGf COMPRESSf{fdc←⍵
      fdc m←{9=⎕NC '⍵': 'i' ⍵  ⋄ m←⍎'MACROSñ'⎕NS '' ⋄  m.(K←V←⍬) ⋄ ⍵ m }fdc
      b←¯1=fdc←3↑fdc,¯1 ¯1 ¯1 ⋄ (b/fdc)←b/⍺ ⋄ fdc m  
  }⍺
⍝  ∆SIG: [EN | 11] ∆SIG Message   OR    [EN | 11] ∆SIG EM Message
  ∆SIG←⎕SIGNAL {⍺←11 ⋄ EM Msg← (2=≢⊆⍵)⊃('∆FIX ERROR' ⍵)⍵ ⋄  ⊂('EN' ⍺)('EM' EM)('Message' Msg)}      
  2.1∨.≠MACROSñ.⎕NC,¨'KV':  ∆SIG'Macro namespace invalid: "','"',⍨⍕MACROSñ
  FIXf(~∊)0 1 2,'eiv':      ∆SIG'Invalid option: "','"',⍨⍕FIXf
  
  ⍝ +--------------------------------------------------+
  ⍝ |    CONSTANTS                                     |
  ⍝ +-------------------------------------------- -----+
    ⎕IO ⎕ML←0 1  
  ⍝ ⎕SE.⍙⍙: Top level contains ∆FIX Library. Other libraries may exist.
  ⍝ Ensure this NS (directory) exists.
    _←'⎕SE.⍙⍙' ⎕NS ''
  ⍝ Major scan types...
    SCAN_INCLUDEt SCAN_EDITt SCAN_FULLt←2 1 0
  ⍝ Prefix for any user-visible variable...
    FIX_PFX←'__'  
  ⍝ See pSink←. 
    SINK_NAME←FIX_PFX,'tmp'
  ⍝ For CR_INTERNAL, see also \x01 in Pattern Defs (below). Used in DQ sequences and for CRs separating DFN lines.
  ⍝ CR_VISIBLE is a display version of a CR_INTERNAL when displaying preprocessor control statements e.g. via ::DEBUGf.
    SQ DQ←'''"' ⋄ NL CR NUL CR_INTERNAL←⎕UCS 10 13 00 01 ⋄  CR_VISIBLE←'◈' 
    CALR←0⊃⎕RSI
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUGf::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 
  ⍝  DDCLNp  "Directive Double Colons pat":  '::directive' | ':: directive'  
  ⍝  Note: We reject spacing between :: and  directives-- in case used in DFNs.
     DDCLNp ← '(?<!:)::(?!:)'
  ⍝ Prefix for comments emitted internally for code or directives on deactivated paths.
  ⍝    At end of processing: ⍝\0F ==> ''     ⍝\0E ==> ''
    SPECIAL_COM SPECIAL_COM2←∊¨('⍝',NUL),¨'F' 'E'    
    pSpecCom←'⍝\x00\N*\r'
  ⍝ Case 1: Remove '⍝\0Fc ', where c is any char (actually only a few expected)
  ⍝ Case 2: Remove '⍝\0E' exactly
    pSpecComKludge←'⍝\x00(F\N\h|E)'    ⍝ See LastScanOut: very kludgey...
  ⍝ ∆WARN: Warning are emitted as msgs only if DEBUGf is active or ⍺=1. Else NOP.
    ∆WARN←{⍺←1 ⋄ ⍺∧DEBUGf: ''⊣⎕←'∆FIX WARNING: ',⍵ ⋄ 1: ''}
    ∆ASSERT←{⍺←'ASSERTION FAILED' ⋄  ⍵: 0 ⋄ ⍺ ⎕SIGNAL 911}
  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
  ⍝ Add CR to last line to make Regex patterns simpler...
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }
  ⍝ See ControlScan/PassState, MainScan/pHereNF
    IN_SKIP←0
  ⍝ +-------------------------------------------------+
  ⍝ | Patterns                                        +
  ⍝ |   - Utilities                                   +
  ⍝ |   - Definitions, organized by scan type         +
  ⍝+--------------------------------------------------+
  ⍝ A. Pattern-related Utilities                         +
  ⍝+--------------------------------------------------+
    GenBracePat←{⎕IO←0 ⋄ ⍺←⎕A[,⍉26⊥⍣¯1⊢ ⎕UCS ⍵] ⋄ Nm←⍺  ⍝ ⍺ a generated unique name based on ⍵
          Lb Rb←⍵,⍨¨⊂'\\'                     
          pM←'(?: (?J) (?<Nm> Lb  (?> [^LbRb''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&Nm)* )+ Rb))'~' '
          'Nm' 'Lb' 'Rb'⎕R Nm Lb Rb⊣pM
    }
  ⍝ ∆R ⍵:   Allows pattern ⍵ to use $R to match \r and \01, our faux carriage return. 
  ⍝         Note: PCRE's \R matches any std newline, not \01.
    ∆R←      {'\$R' ⎕R '\\r\\x01'⊣∊⍵ }          
  ⍝ ∆Anchor ⍵: Ensures single pattern ⍵ is matched only if it is preceded and followed by statement boundaries
  ⍝ (⍵ may itself match multiple lines via embedded \r or \01 chars.
  ⍝ A statement boundary is defined herein as matching
  ⍝     \r, \01, ⋄,  the beginning (^) or end ($) of a line as determined by ⎕R 'Mode M'.  
  ⍝ Note ∆Anchor assumes CASE I, so use (?-i) when case must be respected in pattern matching.    
    _∆Anchor_L _∆Anchor_R←∆R¨'(?:(?<=[$R⋄])|^)' '(?:[$R⋄]|$)'  
    ∆Anchor← {'(?xi)',_∆Anchor_L,⍵,_∆Anchor_R }∆R        
   
  ⍝+--------------------------------------------------+
  ⍝ B. Pattern Defs, MULTIPLE SCANS                   +
  ⍝+--------------------------------------------------+
    pDotsNC←∆R'(?:\.{2,3}|…)\h*[$R⋄]\h*'
    pDotsC←     ∆R'(?:\.{2,3}|…)\h*(⍝[^$R⋄]*)?[$R⋄]\h*'  ⍝ DotsC: Matches continuation chars at end of poss. commented lines.
    pDQ←         '(?:"[^"]*")+'              ⍝ DQ:  "..."
    pDAQ←        '(?:«[^»]*)(?:»»[^»]*)*»'   ⍝ DAQ: Double Angled Quotes = Guillemets  « »
    pSQ←         '(?:''[^'']*'')+'           ⍝ Multiline SQ strings are matched, but disallowed when processed.
    pAllQ←    pDQ,'|',pSQ,'|',pDAQ           ⍝ For Triple Quotes (not matched here), see pTrpQ below.
    pCom←     ∆R'⍝[^$R]*$'                   ⍝ Comments even at end of internal "line" ending with \01.
    pDFn←       GenBracePat '{}'
    pParen←     GenBracePat '()' 
    pBrack←     GenBracePat '[]'
    pAllBr←   '(?:' pDFn '|' pParen '|' pBrack ')'
  ⍝+--------------------------------------------------+
  ⍝ C.Pattern Defs, CONTROL SCANS                     +
  ⍝+--------------------------------------------------+
  ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
  ⍝ These are required to match a SINGLE line each in its entirety OR a line continued implicitly or explicitly (via dot format).
  ⍝ BUG: Does not allow continuation via parens, braces, double quotes, etc.

  ⍝ pCrFamily, actionCrFamily: 
  ⍝ Handle multi-line dfns and (quoted) strings within ::directives. 
  ⍝ See $R and ∆R above.
  ⍝ CR_VISIBLE (◈) is a visible rendering of \r and \01 for display purposes only, e.g. in comments and debugging.
     pCrFamily← ∆R¨'[$R]\z'  '[$R]'  ⋄ actionCrFamily←  '\0' CR_VISIBLE
 
  ⍝ +------------------------------------------------+
  ⍝   Handle multiline enclosures, 
  ⍝     i.e. sequences starting with { ( or [ (
  ⍝     and ending 0 or more lines later with } ) ].
  ⍝   pEnclosNC - Enclosure w/o comments allowed
  ⍝   pEnclosC  - Enclosure w/ internal comments allowed
  ⍝ +-------------------------------------------------+
    pEnclosNC← ∆R  '(?x) (?<NOC> (?> [^\{[(⍝''"«$R]+ |' pAllQ '|' pAllBr          ') (?&NOC)*)'
    pEnclosC←  ∆R  '(?x) (?<ANY> (?> [^\{[(⍝''"«$R]+ |' pAllQ '|' pAllBr '|' pCom ') (?&ANY)*)'
  ⍝ +-----------------------------------------+
  ⍝ + ::If, ::ElseIf, ::Else, ::EndIf         +
  ⍝ +-----------------------------------------+
    pIf←      ∆Anchor'\h* '  DDCLNp  'IF         \b \h* (\N+) '
    pElseIf←  ∆Anchor'\h* '  DDCLNp  'ELSEIF     \b \h* (\N+) '
    pElse←    ∆Anchor'\h* '  DDCLNp  'ELSE       \b      \h*  '
    pEndIf←   ∆Anchor'\h* '  DDCLNp  'END(?:IF)? \b      \h*  '
  ⍝ +-------------------------------------------------------------------+
  ⍝ + ::DEF, ::DEFL, ::DEFE/EVAL                                        +
  ⍝ +        ::DEF aplName← code      Case I                            +
  ⍝ +        ::DEF aplName            Case II
  ⍝ + ::DEF  Definition may go across multiple lines (via pEnclosNC),   +
  ⍝ +        and ends before any comment. 
  ⍝ +        CASE I:  The code value will be placed in parens.
  ⍝ +        CASE II: Deletes macro entry for aplName; equivalently,
  ⍝ +                 sets value for aplName to aplName (w/o parens).
  ⍝ + ::DEFL Definition is like ::DEF, 
  ⍝ +        but the "code" sequence is stored literally:
  ⍝ +        - blanks between the ← and the value are significant.
  ⍝ +        - trailing comments and/or spaces are maintained.
  ⍝ + ::DEFE or ::EVAL
  ⍝ +        Like ::DEF, except evaluates the code once, via CALR⍎code, +
  ⍝ +        and uses those results as the macro value.                 +
  ⍝ +-------------------------------------------------------------------+
    pDef1←         ∆Anchor'\h* '  DDCLNp  'def  \h+ ((?>[\w∆⍙#.⎕]+)) \h* ← \h*  (' pEnclosNC '+|) \N* ' 
    pDefL←         ∆Anchor'\h* '  DDCLNp  'defl \h+ ((?>[\w∆⍙#.⎕]+)) \h* ←  (' pEnclosC '|) '  
    pEvl←          ∆Anchor'\h* '  DDCLNp  '(?:eval|defe)  \h+ ((?>[\w∆⍙#.⎕]+))    \h* ← \h? (' pEnclosNC '+|) \N* '  
    pDef2←         ∆Anchor'\h* '  DDCLNp  '(?:def) \h+ ((?>[^\h←\r]+)) \h*? ( [^\h\r]* )'
    pDefWarn←      '(?xi) (?<!:) ((?: : | :: \h+)  (?: def[el]?|eval|fn|op|fix|stat(?:ic)?|decl(?:are)?|incl(?:ude)?|debug|compress)\b \N*)(\r?)'
  
  ⍝ ::STATic  name←  value
  ⍝ ::DECLare name←  value
  ⍝ See  https://www.dyalog.com/uploads/conference/dyalog20/presentations/D09_Array_Notation_RC1.pdf
    pStatic←       ∆Anchor'\h* '  DDCLNp  '(?>stat(?:ic )?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pEnclosNC '+|) \N* ' 
    pDeclare←      ∆Anchor'\h* '  DDCLNp  '(?>decl(?:are)?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pEnclosNC '+|) \N* ' 
  ⍝ ::INCLUDE filename1 filename2 ...
    pInclude←      ∆Anchor'\h* '  DDCLNp  '(?>incl(?:ude)?) \h+ (    [^$R⋄⍝]*  )  (?:⍝ [^$R⋄]* )?'   
  ⍝ ::DEBUG, ::COMPRESS
  ⍝ ::]user_command 
  ⍝ ::]var←user_command
    pDebug←       ∆Anchor'\h* '  DDCLNp  'debug    \h* \b (?:\h+(ON|OFF)|)  (?:\h*⍝\N*)? '  ⍝ Ignore comments
    pCompress←    ∆Anchor'\h* '  DDCLNp  'compress \h* \b (?:\h+(ON|OFF)|)  (?:\h*⍝\N*)? '  ⍝ Ignore comments
    pUCmdC←       ∆Anchor'\h* '  DDCLNp  '\h*(\]{1,2})\h*(\N+)'            ⍝ ::]user_commands or  ::]var←user_commands
  ⍝ pOther: Matches other code segments
    pOther←       ∆R     '(?=[$R]|^)(?!\h*::)'              
  
  ⍝+-------------------------------------+
  ⍝ D. Pattern Defs, MAIN SCAN PATTERNS  +  
  ⍝+-------------------------------------+
    pSysDef← ∆Anchor '^::SysDefø \h ([^←]+?) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
    pUCmd←           '^\h*(\]{1,2})\h*(\N+)$'                    ⍝ ]user_commands or  ]var←user_commands
  ⍝ """Triple Quote Strings"""[a-z]*
  ⍝ Triple Quote lines are of this format, optionally preceded by arbitrary code: 
  ⍝    """              ⍝ Opening """ must be last non-blank items on the line
  ⍝      line1          ⍝ lines must not start with \h*""" 
  ⍝      line2...       ⍝ """ may otherwise appear within lines. No escape sequence exists.
  ⍝    """[a-z]*        ⍝ Closing """ must be first non-blank item on line to be recognized.
  ⍝
    pTrpQ←        ∊'(?xi) """ (?| \h*\R (.*?) \R (\h*) """ ([a-z]*) | )'   
  ⍝ "Double Quote Strings"[a-z]*     
  ⍝ «Guillemet Quotes»[a-z]*
  ⍝    Both treated identically, allowing multi-line strings (internal comment symbols are text).
  ⍝    Escapes: "" and »» respectively.
    pDQPlus←      ∊'(?xi) (' pDQ ') ([a-z]*)'
    pDAQPlus←     ∊'(?xi) (' pDAQ') ([a-z]*)'      ⍝ DAQ: Guillemet Quotes! « »
    pWord←        '[\w∆⍙_#.⎕]+'
    pPtr←         ∊'(?ix) \$ \h* (' pParen '|' pDFn '|' pWord ')'
  ⍝ ::: Here strings 
  ⍝ ::: ⍝ Here comments 
  ⍝ Format:
  ⍝    var ← ::: Token         ::: ⍝ Doc
  ⍝        lines                   lines
  ⍝    [:]EndToken[:]        [⍝][:] EndDoc[:]
  ⍝
    _pHMID←       '( [\w∆⍙_.#⎕]+ ) :? ( \N* ) \R ( .*? ) \R ( \h* )'
    pHere←   ∊'(?x)  ::: \h*                        ' _pHMID'       :? (?i:END)(?-i:\1) (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
    pTradFn← ∊'(?x)'  DDCLNp  '(?i:fn|op|fix) \h*   ' _pHMID'       :? (?i:END)(?-i:\1) (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline 
    pHereC←   ∆Anchor '\h* ::: \h* ⍝\h* '             _pHMID' ⍝?\h* :? (?i:END)(?-i:\1) (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '    ⍝ Include newline
  ⍝ pHereNF -  The matching string EndXXX not found
  ⍝ pHereNF:   F1 - 1st line matched, F2- name of directive, F3 - "string" to match, F4 - following lines
    pHereNF←∊'(?ix) (  (::: | 'DDCLNp' (?:fn|op|fix) )\b \h* ([^\h\r]*)\N*\r) (.*)'
  ⍝                 1  2                            -2       3       -3    -1 4 -4

  ⍝ Number spacers (_), hex, octal, and binary numbers
  ⍝   Valid for simple integers only.
  ⍝   Hex numbers must start with a digit in \d (⎕D).
  ⍝     123_456 => 123456     hex: 123x 0FFX   octal: 177o 771O   binary: 010010b 
    pNumBase←     '(?xi) ¯?0 [box] [\w_]+ (?>\.[\w_]+)?'    ⍝ Use ¯ \w to trap invalid non-decimal numbers
    pNum←         '(?xi) (?<!\d)   (¯? (?: \d\w+ (?: \.\w* )? | \.\w+ ) )  (j (?1))?'
  ⍝ ← sink
  ⍝   Allows expressions of form  ←code, automatically provided a "sink" temporary variable name.
  ⍝   Valid in dfns or tradfns.
    pSink←'(?xi) (?:^|(?<=[[{(\x01⋄:]))(\h*)(←)'   ⍝ \x01: After CR_INTERNAL (dfn-internal CR)
 
  ⍝ pMacro: matches any valid name, including qualified names (one.two), system names,
  ⍝         plus extensions :name, ::name, :one.two, ::one.two
    pMacro←       { 
      ⍝ Matches:  ⎕X012  #.X012 ::X012 or  A.B.⎕X012, ⎕X012.A.B etc. Trailing '.' is not included!    
      ⍝ APL variable name initial letters: 
      ⍝     [ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜ∆⍙_] ==>  [A-ZÀ-ÖØ-Ü∆⍙_]
        _AplName← '(?<APLNAME> (?: ⎕|::?)? [A-ZÀ-ÖØ-Ü∆⍙_] [\dA-ZÀ-ÖØ-Ü∆⍙_]* | \#{1,2} )'  
        ∊_pMac←'(?xi)(' _AplName ' ((\.(?&APLNAME))*))'   ⍝ OK: ::NAME, ⎕NAME, ]NAME
    }⍬
  ⍝ () is treated as (⎕NS ⍬). See also ::DECLARE extensions.
    pNSEmpty← '\(\h*\)'   
  ⍝ ::MACROS - list all macro definitions in the (⎕←...) output. 
    pMacDump←    ∊'(?i)^\h*'  DDCLNp  'MACROS\b\h*$' 
  ⍝ ∉ NOTIN  (see also macro ⎕NOTIN)
    NOTINch←   '∉'     ⍝ ⎕UCS 8713
  ⍝ Under / Dual (⎕SE.⍙⍙.UNDER)
    UNDERch←'⍢'                ⍝ ⎕UCS 9058: See Abrudz Extended APL 
  ⍝ OBVERSE (DELTILDE)
    OBVERSEch←'⍫'             ⍝ See DELTILDE, Abrudz Extended APL 
    pSymbol←    '[',NOTINch,UNDERch,OBVERSEch,']'   
  ⍝ SYMBOL_MAP: [0] list of symbols; [1] their values (spacing, case: respected)
    SYMBOL_MAP← ↑(NOTINch,UNDERch OBVERSEch)('(~∊)' ' ⎕SE.⍙⍙.UNDER ' ' ⎕SE.⍙⍙.OBVERSE ')
  ⍝+---------------------------------------+
  ⍝ Pattern Defs, ATOM SCAN PATTERNS       +  
  ⍝    See ∆FIX.HELP for details.          ÷
  ⍝+---------------------------------------+                            
    pAtomList←     ∊'(?x) (`{1,2})  \h* ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ )'     
    pAtomsArrow←   ∊'(?x) ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ ) (→{1,2}) '          
  ⍝+--------------------------------------------------+
  ⍝ END Pattern Definitions                           +
  ⍝+--------------------------------------------------+

  ⍝+--------------------------------------------------+
  ⍝ Utilities, Miscellaneous                          +
  ⍝+--------------------------------------------------+
    DTB←{⍵↓⍨-+/∧\' '=⌽⍵}                           ⍝ Delete trailing blanks from one line
    DLB←{⍵↓⍨ +/∧\' '= ⍵}                           ⍝ Delete leading blanks...
    AddPar← {'(',⍵,')'}
    DblSQ←  {⍺←0 ⋄ s←⍵/⍨1+⍵=SQ ⋄ ⍺=0: s ⋄ SQ,s,SQ }  ⍝ Double single quotes. If ⍺=1, add outer quotes.
  ⍝ UnDQ_DAQ: Remove surrounding DQs and APL-escaped DQs, then double SQs.  Allow for alternate DQ pairs as ⍺.
    UnDQ_DAQ←{DQ1←1↑⍵ ⋄  DQ2←'"«?'['"«'⍳DQ1]  ⋄ DQ2='?': ∆SIG'UnDQ_DAQ Logic Error'  
          s/⍨~(2⍴DQ2)⍷s←1↓¯1↓⍵
    }   
  ⍝ ∆DEC: 
  ⍝ Read hex, binary, octal numbers (e.g. 0x09DF, 0b0111, and 0o0137, with suffixes [boxBOX], converting to decimal.
  ⍝ Converts up to 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF (28 hex digits) as integer strings.
  ⍝ Returns right arg (⍵) AS IS [w/o error] if  
  ⍝   (a) the base is unknown, not b|o|x UC or LC (base 2, 8, 16 resp.),
  ⍝   (b) the number is negative, or its digits are out of range,
  ⍝   (c) the number can't be represented in an integer of 34 decimal digits...
  ⍝ Note: Numbers like 0X123E0 are valid, since E is a valid hex digit.
    ∆DEC←{⎕PP ⎕FR←34 1287  ⍝ Ensures largest # of decimal digits.
        0:: ⍵⊣⎕←'∆FIX DOMAIN ERROR: NON-DECIMAL CONSTANTS MUST BE NON-NEGATIVE INTEGERS: "',⍵,'"'
        canon←⎕C ⍵ ⋄ base←2 8 16 0['box'⍳1↑1↓canon]
        '¯'∊⍵: ∘ ⋄ 0=base: ∘    ⋄ '0'≠⊃canon: ∘
        res←(base↑'0123456789abcdef')⍳2↓canon  
        ∨/res≥base: ∘ 
         0:: ⍵⊣⎕←'∆FIX CONVERSION ERROR: NON-DECIMAL CONSTANT TOO LARGE TO REPRESENT: "',⍵,'"'
        'E'∊res←⍕base⊥res: ∘  ⋄ res
    }
⍙INCLUDE←{  ⍺←1 
  ⍝  lines@SV ←   ⍙INCLUDE files
  ⍝  Stripped down version of ∆INCLUDE utility(PMS): ⍺ formatting options omitted ('N' newline formatting hardwired).
  ⍝  Finds specified files fileN in directories named in FSPATH and WSPATH, starting with '.' and '..'.
  ⍝      files: file1 [file2 ... [fileN]]
  ⍝           - a single vector with files file1 ... fileN separated by blanks, or
  ⍝           - a vector of separate strings, file1 through fileN,
  ⍝      Each string must include any suffixes and appropriate prefixes (parent directories) to be prefixed
  ⍝      by (ie. found in) the parent directories per above.
  ⍝  Returns:
  ⍝      All lines from files catenated to a single char vector, each input line terminated by LF (⎕UCS 10). 
  ⍝      Error if any file not found.
  ⍝  If ⍺=0, calls ∆FIX rather than simply including...
  ⍝  Errors
  ⍝    If files were not found and spec≠¯1, signals error number 22 and msg eNotFound below.
  ⍝    For other errors, signals 11 with various messages (below).
    ⎕IO ⎕ML←0 1 ⋄ CR LF←⎕UCS 13 10
    FIRST_DIRS←'.' '..'
  ⍝ Get search path from FSPATH if present, else WSPATH. Always start with search path: '.' and '..'.
  ⍝ If paths are repeated, only the first is used.
    setSearchPath←{⍺←FIRST_DIRS ⋄ first←,¨⊆⍺ 
        0=≢⍵: first ⋄ 0≠≢p←{2 ⎕NQ'.' 'GetEnvironment' ⍵}⊃⍵: ∪first,':'(≠⊆⊢)⊣p ⋄ first∇ 1↓⍵
    } 
  ⍝ FindFirstFiles:  fullPaths ← searchPath FindFirstFiles files
  ⍝    Returns fullPaths where each file is found in searchPath, or ⎕NULL if not found.
    FindFirstFiles←{ ⍺←⍬
        FindEach←⍺∘{0:: ∆SIG eUnexpected⊣⎕←'FindFirstFiles: ⍺' ⍺ ' ⍵' ⍵
            0=≢⍺: ⎕NULL                                 ⍝ Exhausted search
            full←(rel/'/',⍨⊃⍺),⍵ ⊣ rel←'/'≠1↑⍵  
            ⎕NEXISTS full: full 
            rel: (1↓⍺) ∇ ⍵ ⋄ ⎕NULL                      ⍝ Keep searching only if not absolute name                    
        }
        0=≢⍺:  ∆SIG eNoPath ⋄ 0=≢⍵: ⎕NULL
        FindEach¨⊆⍵
    }
    eNoPath←     '⍙INCLUDE' 'No search directories were specified [LOGIC ERROR].'
    eUnexpected← '⍙INCLUDE' 'Unexpected error evaluating filename.'
    eNoFiles←    '⍙INCLUDE' 'No file(s) to include.'
    eNotFound←   '⍙INCLUDE' 'At least one file to include was not found in search path:'
  ⍝ ⍙INCLUDE EXECUTIVE
    files←{1=≡⍵:  ' ' (≠⊆⊢)⍵ ⋄ ⍵ },⍵
    0=≢files:          ∆SIG eNoFiles
    searchPath←setSearchPath 'FSPATH' 'WSPATH'  
    filesFull←searchPath FindFirstFiles files 
    ⎕NULL∊_f←filesFull:  ∆SIG eNotFound,¨'' (∊' ',¨files/⍨_f∊⎕NULL)
  ⍝ Read each file as a single string with NLs as linends, concatenating all strings together. Missing => Err
  ⍝ Return (default) single string with NLs as linends. Missing => Err
   ⍺=0: ∊{∊CR,⍨¨MACROSñ ∆FIX ⍵}¨filesFull    ⍝ Pass current macro namespace to each function called (which they may change)
    ⊃,/{⊃⎕NGET ⍵ 0}¨filesFull    ⍝ Omitted: CR@(LF∘=)⊣
} 

  ⍝ SaveRunTime:  SaveRunTime ['NOFORCE' | 'FORCE'], default 'NOFORCE'.
  ⍝ Save Run-time Utilities shown here in ⎕SE if not already there...
  ⍝     ⍙PTR, ⍙FIX                -- ⍙... not expected to be called by user.
  ⍝     ∆ASSERT, ∆TO, ∆UNDER             -- ∆... potentially called by user.
    RUNTIME_MAP←↓⍉↑('ASSERT' 3)('FIX' 3)('PTR' 4) ('TO' 3)('UNDER' 4) ('OBVERSE' 4)
    SaveRunTime←{utils utype←RUNTIME_MAP
        (~DEBUGf)∧(⍵≢'FORCE')∧utype∧.=⎕SE.⍙⍙.⎕NC ↑utils: 0    ⍝ Save Runtime Utils if (DEBUGf∨FORCE) or if utils not created...
        2/⍨~DEBUGf:: ∆SIG'Unable to set utilities: ⎕SE.⍙⍙.(',utils,')'
      ⍝ ∆ASSERT for Macro ⎕ASSERT 
        ⎕SE.⍙⍙.ASSERT←{⍺←'Assertion failure' ⋄ 0∊⍵:⍺ ⎕SIGNAL 8 ⋄ shy←0}
      ⍝ ⍙FIXX for directive ::FN, ::OP, ::FIX
      ⍝ ⍙FIXX fixes anything valid for 2 ⎕FIX ...
      ⍝ If leading lines of string are blank or comments, they are removed before ⎕FIXing.
      ⍝ Makes it easy to create a tradfn or detailed namespace using directives:
      ⍝    ::FN PI         ⍝ PI here is solely text to match via EndPI. The name itself has no significance.          
      ⍝          r←pi n         
      ⍝          r←○n'          
      ⍝    EndPI
        ⎕SE.⍙⍙.FIXX←{⎕IO←0
          0:: ∆SIG '::FIX or related directive failed. Likely syntax error in code string.' 
          1≥|≡⍵: ∇ ⊆⍵                                                   ⍝ Ensure vector of vectors
          '⍝ '∊⍨1↑' '~⍨⊃⍵: _←∇ 1↓⍵ ⋄ 0≠≢⍵:_←2 (1⊃⎕RSI,#).⎕FIX ⍵,⊂''     ⍝ Ensure at least 2 vectors passed to ⎕FIX
          ∘ 
        }
      ⍝ ⍙PTR for "pointer" prefix $
      ⍝ Syntax:   ${code_operand}   |   $(tacit_operand)  |   $named_operand 
      ⍝     ptr← ⍺⍺:operand ⎕SE.⍙⍙.PTR ⍵:0
      ⍝          ⍺⍺:operand: Function to "turn into" a pointer, accessed via ptr.Run
      ⍝           ⍵:debug:   If 0, display form is '[⍙PTR]' (fast).
      ⍝                      If 1, display form is an abridged version of the nested 
      ⍝                      representation of <operand>, up to <MAXL:30> chars (slower).
      ⍝
        ⎕SE.⍙⍙.PTR←{ ⍝ Place in ⎕SE.⍙⍙, with CALR as ⎕THIS namespace
            debug←⍵ 
            0::'$ POINTER DOMAIN ERROR'⎕SIGNAL 11 
            MAXL←30
            (ns←⎕NS'').Run←⍺⍺ ⋄ _←ns.⎕FX 'r←Exec' 'r←Run ⍬'
            ~debug: ns⊣ns.⎕DF'[$⍙PTR]'
            Fit←MAXL∘{⍺>≢⍵:⍵ ⋄ '⋯',⍨⍵↑⍨⍺-1}    
            Shrink←{'''[^'']*''|⍝.*$' '^Run←' '\{⋄' '⋄\}' '\h+⋄\h+'⎕R'&' '' '{' '}' '⋄'⊣¯1↓∊'⋄',⍨¨⍵} 
            Dlb←{⍵↓⍨+/∧\' '=⍵}¨  ⋄ Sane←{0<≢⍵: ⍵ ⋄ err∘}     
            ns⊣ns.⎕DF '[$', (Fit Shrink Dlb Sane⊆ns.⎕NR 'Run'), ']'
        }
        ⍝ ∆TO: for function ⎕TO
        ⍝ range←  start [next]  ∆TO  end [step]   
        ⍝         start: starting numeric value.
        ⍝         next: first element after <start> used to calculate <step>. 
        ⍝               If omitted*, next is (start+×end-start), unless <step> is specified.
        ⍝         end:  ending numeric value.
        ⍝         step: in-/decrement start first value to next. 
        ⍝               If omitted*, (×end-start) is assumed, unless <next> is specified. 
        ⍝               The sign of <step> passed is ignored and the signum (×end-start) is used.
        ⍝ ________________________________
        ⍝ * Specifying both <next> and <step> is an error.  
        ⍝   If next is specified, the actual step is (×end-start)×|next-start.    
        ⎕SE.⍙⍙.TO←{⎕IO←0
            2∧.≤≢¨⍺ ⍵: ∆SIG'⎕TO: range←  start [next] ∆TO end [step=1]. Do not include both ¨next¨ and ¨step¨.'
            ∆←-/end start←⊃¨⍵ ⍺ ⋄ step←(×∆)×|⍺{2=≢⍵: 1⊃⍵ ⋄ 2=≢⍺: -/⍺ ⋄ 1}⍵
            start+step×⍳0⌈1+⌊∆÷step+step=0     
        }
        ⍝ Under (from dfns) symbol: ⍢  Alias: Dual  
        ⍝ ⎕SE.⍙⍙.UNDER←{0=⎕nc'⍺': ⍵⍵⍣¯1⊢⍺⍺ ⍵⍵ ⍵ ⋄ ⍵⍵⍣¯1⊢(⍵⍵ ⍺)⍺⍺(⍵⍵ ⍵)} 
        ⎕SE.⍙⍙.UNDER←{ ⍝ DelDiaeresis ⍢ Under or Dual. From {Abrudz APL Extended}
              ns←⎕NULL⍴⍨15⍴0
              0::⎕SIGNAL ⎕EN
              2 2≡⎕NC↑'⍺' '⍺⍺':⎕SIGNAL⊂('EN' 2)('Message' 'Array left argument conflicts with array left operand')
              ⍺←{⍵ ⋄ ⍺⍺}      ⍝ no ⍺: pass through
              ⍵⍵{
                  aa←⍺⍺
                  3::0
                  (⎕SE.⍙⍙.⎕CR'OBVERSE')≡2⊃⎕CR'aa'       ⍝ For OBVERSE, Adam A. uses the char name 'DelTilde' here.
              }⍬:ww.InvFn(ww.NrmFn ⍺)⍺⍺(ww←⍵⍵ ns).NrmFn ⍵
              ⍵ ⍵⍵{           ⍝ pass in original ⍵
                  A←⍺             ⍝ modifiable array
                  11::A⊣((⍺⍺)A)←⍵ ⍝ structural inversion on error...
                  NoOp←{0::0 ⋄ ⍵≡⍺⍺ ⍵} ⍝ Is ⍺⍺ a no-op? (or fails)
                  ~(⍺⍺⍣¯1 ⍺⍺)NoOp ⍺:!# ⍝ ... or if imperfect inverse
                  ⍺⍺⍣¯1⊢⍵         ⍝ try computational inverse
              }(⍵⍵ ⍺)⍺⍺{          ⍝ ⍺⍺, but:
                  ⍺←⊢                    ⍝ no ⍺: pass through
                  2=⎕NC'⍺⍺':⍺(⍺⍺⊣⊢)⍤0⊢⍵ ⍝ if array: treat as scalar fn
                  ⍺ ⍺⍺ ⍵                ⍝ else: just apply
              }⍵⍵ ⍵           ⍝ ⍺ ⍺⍺ over ⍵⍵ ⍵
        }
        ⎕SE.⍙⍙.OBVERSE←{ ⍝ Obverse, DelTilde, ⍫ ⍺⍺ but with inverse ⍵⍵ represented as ns.  From {Abrudz APL Extended}
            0::⎕SIGNAL⊂⎕DMX.(('EN'EN)('Message'Message))
            ns←⎕NULL⍴⍨15⍴0
            ⍺←⊢
            ⍵≢ns:⍺ ⍺⍺ ⍵
            Fn←⎕NS ⍬
            Fn.NrmFn←⍺⍺
            Fn.InvFn←⍵⍵
            Fn.Obv←1
            Fn
        }
        1 
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via StringFormat below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{
      ⍺←SCAN_FULLt   ⍝ Default  
  ⍝+-------------------------------------------------+
  ⍝ Mac- routines: Handle Macros (see ::DEF, etc.)   +  
  ⍝+-------------------------------------------------+
  ⍝⍝⍝⍝ FIX ME!!! We should NOT have any DQ or DAQ quotes here!!!
        MacScan←{
          ⍺←5    ⍝ Max of total times to scan entire line (prevents runaway replacements)
          ⍺≤0: ⍵  
          pList←pSQ pCom pDQ pMacro
                iSQ iCom iDQ iMacro←⍳≢pList
          str←pList ⎕R { F0← ⍵.Match ⋄ CASE←⍵.PatternNum∘∊ 
              CASE iMacro: MacGet F0 ⋄ CASE iDQ: SQ,SQ,⍨UnDQ_DAQ F0⊣⎕←'MacScan DQ seen'  ⋄ F0 } ⍵
          ⍵≢str: (⍺-1) ∇ str ⋄ str        ⍝ If any changes, scan again up to <⍺> times.
        }
      ⍝ Note: macro names whose last component starts with ⎕ or :  are case-insensitive.
      ⍝       E.g. ⎕NaMe, :myIF, or a.b.⎕NaMe 
      ⍝ val←  ⍙K key, key: a string.
        ⍙K←{ ~'⎕:'∊⍨⊃⊃⌽k←'.'(≠⊆⊢)⍵ :⍵ ⋄ k⊣(⊃⌽k)←⎕C ⊃k}  ⍝ Case ignored for ⎕xxx and :xxx
      ⍝ val←  key (flag _MacSet) val
      ⍝   flag=0:  Sets macro <key> to have value <val>, a string.         See :DEF
      ⍝   flag=1:  Sets macro <key> to have value '(',<val>,')', a string. See :DEFL
      ⍝            Special case: If <val> is a nullstring, value is <val> alone (no parentheses).
        AllQScan←{
            iDQ     iDAQ     iSQ iCom← ⍳4
            pDQPlus pDAQPlus pSQ pCom ⎕R { 
              F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}  
              CASE←⍵.PatternNum∘∊  
            ⍝ SQ: No suffixes or multiline strings allowed. Warning only???
              CASE iSQ: ProcSQ F 0     
              CASE iCom: F 0
              (F 2) (0 StringFormat) UnDQ_DAQ F 1         ⍝ Convert double [angle] quotes
            }⍠reOPTS⊣⍵
        }
      ⍝ ProcSQ:    strRep ← ProcSQ strCR
      ⍝     strCR: Must include explicit surrounding SQs. 
      ⍝ SQ Strings are defined as single-line only with no suffix modifier extensions.
      ⍝ Here we detect a multiple line SQ string and 
      ⍝ 1) Warn the user.
      ⍝ 2) Fix it up so that 'abc\rdef\rghi'  => 'abc' 'def' 'ghi'
      ⍝ I.e. multiline SQ strings ==> a vector of char strings in code form.
        ProcSQ←{ 
            ∆ASSERT 0(~∊)SQ=(⊃⍵)(⊃⌽⍵):
            1(~∊)CR CR_INTERNAL∊⍵: ⍵ 
            _←∊SQ,¨SQ_SP,⍨¨Str2SVs 1↓¯1↓⍵  
            ~DEBUGf: _  
            _ ⊣  (⎕←⎕SE.UCMD 'Disp ',_)   ⊣ ∆WARN eProcSQ
        }
        SQ_SP← ⊂SQ,' ' 
        eProcSQ←'Error: Multiline strings with single quotes detected.'
      ⍝ ⍺ (⍺⍺ _MacSet) ⍵. Set key <⍺> to have value <⍵>, or ⍺ if key <⍺> doesn't exit.
      ⍝ If ⍺≡⍵, delete key <⍺>.
      ⍝ If ⍺⍺=1, put ⍵ in parens, unless ⍵ is a non-simple "expression" 
      ⍝          i.e. neither an APL user/system name, number, or null.
      ⍝ ParensNeeded: returns 0 for ⍵: FrEd, #.JaCk, FrEd.Jack, ⎕SE, 12345J45 123.45J¯4 ⎕IO 
      ⍝                             "Fred Jack"  "1 2"   "3 PI R"
      ⍝               returns 0 for any single-char ⍵ (so, e.g.,  ::DEF semi←; is replaced by ';', not '(;)')
      ⍝               returns 1 for ⍵: "",  "FRED+JACK", ":DIRECTIVE"
        ParensNeeded←{⍺=0: 0 ⋄ 1=≢⍵: 0 ⋄ ¯1=⎕NC ⊂'X',⍵~'⎕#.¯ '}  
      ⍝ Initialize MACROSñ above
         MacroLiteral←{(⊆⍺) (0 _MacSet)¨ ⊂ ⍵}    
         _MacSet←{ par←⍺⍺ ParensNeeded ⍵
            val←AddPar⍣par⊣⍵ 
            nKV←≢MACROSñ.K ⋄ p←MACROSñ.K⍳⊂key←⍙K ⍺       
            p<nKV: val⊣ { ⍵: MACROSñ.V[p]←⊂val ⋄ 1: MACROSñ.(K V)/⍨¨←⊂p≠⍳nKV }⍺≢⍵
            ⍺≡⍵: val ⋄ MACROSñ.(K V),← ⊂¨key val ⋄   val
        }  
      ⍝ MacGet ⍵  -- Return macro defined for ⍵, if found;
      ⍝              Else if ⍵ is complex, i.e. of the form ⍵1.⍵2.⍵3 (etc.), 
      ⍝                  Allow and keep trailing dots, e.g. in:  myns.{⎕NS ⍵}
      ⍝                  Return macro for each ⍵N in ⍵1.⍵2.⍵3, else ⍵N itself
      ⍝              Else return ⍵ itself.
      ⍝              If any ⍵N returns null, do not include a period before or after it.
        MacGet←{DOT←'.'
            0=≢⍵: ⍵ 
            p←MACROSñ.K⍳⊂⍙K ⍵ 
            p<≢MACROSñ.K: p⊃MACROSñ.V             ⍝ Full name found, simple or complex
            DOT(~∊)⍵: ⍵                         ⍝ Name is simple...   
            DOT=¯1↑⍵: ∆SIG'APL-style name with trailing dot was presented to macro processing'    
            AddDots←{⍺←'' ⋄ noNull←0(~∊)≢¨⍺ ⍵ ⋄ ,⍺,(noNull/DOT),⍵ }  
            ⊃AddDots/∇¨'.'(≠⊆⊢)⍵         ⍝ Name is complex. Check for definitions of the pieces! 
        }
        MacDump← {⎕←⍵⋄ ⎕←(⎕PW-1)↑[1]⎕FMT MACROSñ.(K,[0.2]V) ⋄ ''}
      ⍝ ------END MACROSñ

  ⍝+-------------------------------------------------+
  ⍝ StringFormat - Format Multiline Strings              +  
  ⍝   DQStrings, Here Strings, and related           +
  ⍝+-------------------------------------------------+
      ⍝ StringFormat: 
      ⍝     Convert possibly multiline strings to the requested format and return as an APL code string.
      ⍝ output_string←  ⍺: options (⍺⍺: indent ∇ ) ⍵: input_string
      ⍝ Output format: options '[rnsvm]'.   
      ⍝    'r' carriage return (\r) for linends  
      ⍝    'n' linefeed (\n) for linends 
      ⍝    's' spaces replace linends 
      ⍝    'v' vector of vectors;    'm' APL matrix;   
      ⍝     DEFAULT: Set below to 'v' 
      ⍝ Escape option. Works with any one above. 
      ⍝    'e' backslash (\) escape as last non-blank char on the line is converted to a single space. Otherwise, as above.
      ⍝    'c' string is a comment treated in toto as a singleblank.
      ⍝ Exdent option. Useful for DQString "..." only. Triple quote strings and here docs already use ¯1.
      ⍝    'x' Force indent←¯1, ignoring any actual setting... (Will work even on a single-line DQ string)
      ⍝ indent: ⍺⍺>0,  remove ⍺⍺ leading blanks from each line presented
      ⍝         ⍺⍺=¯1  remove left_in, the indent of left-most line for indent, from each line presented...
      ⍝         ⍺⍺=0   leave lines as is.
      ⍝         See also 'x' exdent option.
          StringFormat←{ ⍺←''   
          ⍝ options--   o1 (options1) (r|l|s|v|m); o2 (options2): [ec]; od(efault): 'v'.
            DEF_TYPE←'v'
            o1 o2 od← 'rnsvm' 'ecx' DEF_TYPE  ⋄ o←(o1{1∊⍵∊⍺⍺: ⍵ ⋄ ⍵⍵,⍵}od)⊣⎕C ⍺
          ⍝ R: CRs    N: LFs    S: Spaces   V: Vectors   M: Matrix
          ⍝ E: Escape (\)       C: Comment (⍝)
            R N S V M E C X←o∊⍨∊o1 o2
            0≠≢err←o~∊o1 o2: ∆SIG'For DQ or Here string, one or more invalid options "',err,'" in "',⍺,'"' 
            indent←X⊃⍺⍺  ¯1   ⍝ Allow for x (exdent option)
            C: ' '
            SlashScan←  { '\\(\r|$)'⎕R' '⍠reOPTS⊣⍵ }  ⍝ backsl + EOL  => space given e (escape) mode.
            TrimL←     { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\' '=↑⍵  ⋄  ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺ }   
            FormatPerOpt← {multi←⍺
              AddSQ←SQ∘,∘⊢,∘SQ 
              V∨M: ('↑'/⍨M∧multi) ,¯1↓∊' ',⍨∘AddSQ¨ ⍵ ⋄  S: AddSQ 1↓∊' ',¨⍵ 
              R∨N: AddSQ ∊{⍺,nlc,⍵}/⍵ ⊣ nlc←SQ,',(⎕UCS ',(⍕R⊃10 13 ),'),',SQ  
              ∘Unreachable∘  
            }
            0=≢⍵: 2⍴SQ
            multi←1<≢lines←Str2SVs ⍵  ⍝ Don't add parens, if just one line...
            AddPar⍣(multi∧~V)⊣ multi FormatPerOpt (SlashScan⍣E)DblSQ¨ indent∘TrimL lines
        }
      ⍝ Str2SVs: Ensures a vector of strings.
      ⍝       ⍵: Vector of strings or a single flat string with CRs.
      ⍝ Note: Ensure split sees                # partitions
      ⍝         "abc"         as    abc        1
      ⍝         "\rabc "      as   |abc        2
      ⍝         "abc\r"       as    abc|       2
      ⍝         "abc\r\rdef"  as    abc||def   3
      ⍝         "\r\rabc\r\r" as  ||abc||      5
        Str2SVs←{2=|≡⍵:⍵ ⋄ CR∘{r←1⍴⍨q←1++/∧\p←⍵=⍺ ⋄ ⍺~⍨¨⍵⊂⍨r,q↓p } ⍵}       
       
      ⍝ See iDQPlus (below) and StringFormat above...
      ⍝ We add a "spurious" CR_INTERNAL so StringFormat sees leading and trailing bare " on separate lines... 
      ⍝ DQTweak←CR_INTERNAL∘{ (⍺/⍨CR=⊃⍵),⍵,⍺/⍨CR=⊃⌽⍵ }   
      ⍝ DQUntweak←{⍵~¨CR_INTERNAL}        

  ⍝+-------------------------------------------------+
  ⍝ Other Routines                                   +
  ⍝+-------------------------------------------------+ 
      ⍝ pat←  GenBracePat ⍵, where ⍵ is a pair of braces: ⍵='()', '[]', or '{}'.  
      ⍝ Generates a pattern to match unquoted balanced braces across newlines, skipping
      ⍝   (a) comments to the end of the current line, (b) quoted strings (single or double).
      ⍝ Uses a name based on the braces and the ?J option, so PCRE functions properly[*].
      ⍝    * Any repeat definitions of these names MUST be identical.
    
      ⍝ Ensure max precision possible for numeric results for routine ⍺⍺ called in env ⍵⍵ (usu: CALR)
      ⍝ See Eval2Str, EvalStat.
        _MaxPrecision←{save←⍵⍵.(⎕FR ⎕PP) ⋄ ⍵⍵.(⎕FR ⎕PP)←1287 34 
                 r←  ⍺⍺ ⍵ ⋄ CALR.(⎕FR ⎕PP)←save ⋄ r 
        }
      ⍝ Eval2Str: In CALR env., execute a string and return a string rep of the result.
        Eval2Str←CALR∘{ 0:: ⍵,' ∘EVALUATION ERROR∘'  ⋄ res2←⍺.⎕FMT res←⍺⍎'⋄' LastScanOut ⍵  
           ⍝  0≠80|⎕DR res: 1↓∊CR,res2 ⋄ ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
           0≠80|⎕DR res: 1↓∊CR,res2 ⋄ ,1↓∊CR,¨1∘DblSQ¨↓res2
        } _MaxPrecision CALR
      ⍝ Eval2Bool: Execute and return 1 True, 0 False, ¯1 Error.
        Eval2Bool←CALR∘{0:: ¯1  ⋄ (,0)≡v←,⍺⍎'⋄' LastScanOut ⍵: 0 ⋄  (0≠≢v)}  

      ⍝ EvalDeclare, EvalStatic:
      ⍝    Evaluate APL Declarations using Array and Namespace Notation (based on ⎕SE.Link.Deserialise).
      ⍝    Declare: converts a declaration to executable APL code.
      ⍝    Static:  Evaluates and sets that same code at ∆FIX ("Compile") time.
      ⍝ For more details, see definitions of pStatic and pDeclare

      ⍝ [OLD. Delete after final test]
      ⍝ EvalStatic←  CALR∘{0:: ⍵ ⋄ 0 ⎕SE.Dyalog.Utils.repObj ⍺⍎⍵} _MaxPrecision CALR 
        EvalStatic← CALR∘{
           0 ⎕SE.Dyalog.Utils.repObj ⍺⍎_EvalDeclare ⍵
        } _MaxPrecision CALR 
        _EvalDeclare← CALR∘{0:: ⍵ 
            tidy←{ pSQ pCom '\h+' ⎕R '&' '' ' '⍠reOPTS⊣⍵ }
            doc← tidy ⍵  ⍝ Remove comments and extra blanks  
            doc←  1∘DblSQ '⋄'@(CR∘=)⊣ doc          ⍝ Enquote and escape internal quotes
            ⍺⍎'0 ⎕SE.Link.Deserialise ', doc       ⍝ Convert to Dyalog deserialized code...
        } 
        EvalDeclare←_EvalDeclare _MaxPrecision CALR 

  ⍝+-------------------------------------------------+
  ⍝ Control Scans - handle :: Directives             +  
  ⍝+-------------------------------------------------+
        ControlScan←{ 
          ⍝ |< ::Directive    Conditionals     >|<  ::Directive Other                             >|< APL code   Modified: pOther
            controlScanPats←pIf pElseIf pElse pEndIf pInclude pDef1 pDef2 pEvl pStatic pDeclare pDefL  pDefWarn pDebug pCompress pUCmdC pOther 
                            iIf iElseIf iElse iEndIf iInclude iDef1 iDef2 iEvl iStatic iDeclare iDefL  iDefWarn iDebug iCompress iUCmdC iOther ←⍳≢controlScanPats
            SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇ ' '↓ ' '↑ '
            Poke←{ ⍵⊣(⊃⌽stack)←⍵ ((⍵=1)∨⊃⌽⊃⌽stack)}
            Push←{ ⍵⊣stack,←⊂⍵ (⍵=1)}
            Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 ⋄ ∆SIG'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0 }  
            Peek←{(⊃⌽⊃⌽stack)⊃⍵ 1}
            CurStateIs←{⍵∊⍨⊃⊃⌽stack}
            stack←,⊂ON ON
            IN_SKIP∘←0                      ⍝ IN_SKIP: Used in ControlScanAction/PassState
            ControlScanAction←{
                  F←⍵.{0:: '' ⋄ Lengths[⍵]↑Offsets[⍵]↓Block}
                  CASE←⍵.PatternNum∘∊ 
                  PassState←{ ⍺←0 ⋄ otherMode←⍺
                    ⍝ EXTERN: IN_SKIP.   ⍝ Above. 
                    ⍝ If otherMode and we aren't (yet) in a skip, 
                    ⍝     issue the PassState comment expected and issue an IN_SKIP.
                    ⍝ If otherMode and we see an IN_SKIP, then we are at the end of a line also in otherMode same line. 
                    ⍝     issue '' (a NOP) and terminate the IN_SKIP.
                      tidy← { pAllQ pCom '\h+' ⎕R '&' '' ' '⍠reOPTS⊣⍵ }  
                      otherMode: IN_SKIP{ IN_SKIP∘←~⍺ ⋄ ⍺: '' ⋄  SPECIAL_COM,(STATES⊃⍨1+⊃∊⍵)}⍵
                      CR,⍨SPECIAL_COM,(STATES⊃⍨1+⊃∊⍵),tidy pCrFamily ⎕R actionCrFamily ⍠reOPTS⊣¯1↓F 0
                  }
                ⍝ Format for PassDef:   "::SysDefø name←value" with the name /[^←]+/ and a single space as shown.
                ⍝ THis "directive" is passed on to the MainScan
                  PassDef←{⍺←F 1 ⋄ (PassState ON),'::SysDefø ',⍺,'←',⍵,CR }    

                  CASE  iDefWarn: F1,' ⍝ WARNING: ',_,'.',F2⊣∆WARN (_←'Possible directive detected in improper context'),': "',F1,'"'⊣F1 F2←F¨1 2
                ⍝ ON...
                  CurStateIs ON: {         
                      CASE iOther:      ''               ⍝ A NOP when CurStateIs ON
                      CASE iDef1:       PassDef (F 1)  (1 _MacSet)⊣val←MainScan DTB F 2   
                      CASE iDef2:       PassDef (F 1)  (fVal _MacSet) F 1+fVal←0≠≢F 2 
                      CASE iEvl:        PassDef (F 1)  (1 _MacSet)⊣    Eval2Str MainScan DTB F 2  
                      CASE iStatic:    (PassState ON),(F 1),(F 2),CR,⍨ EvalStatic  MainScan DTB F 3  
                      CASE iDeclare:   (PassState ON),(F 1),(F 2),CR,⍨ EvalDeclare MainScan DTB F 3  
                      CASE iInclude:   (PassState ON),0 ⍙INCLUDE F 1  
                      CASE iDefL:       PassDef (F 1)  (0 _MacSet)⊣val←AllQScan DTB F 2    
                      CASE iIf:         PassState Push Eval2Bool MacScan F 1
                      CASE iElseIf iElse: PassState Poke SKIP  
                      CASE iEndIf:      PassState Pop ⍵
                    ⍝ Setting ::DEBUG ON/OFF sets variable ::DEBUG as well
                    ⍝ Setting ::COMPRESS ON/OFF ditto...
                      CASE iDebug:   '::DEBUG'    PassDef ⍕DEBUGf∘←   'off'≢⎕C F 1 
                      CASE iCompress:'::COMPRESS' PassDef ⍕COMPRESSf∘←'off'≢⎕C F 1 
                      CASE iUCmdC:      (PassState ON),{
                                           0=≢⍵:'' ⋄ '⍝> ',CR,⍨⍵     ⍝ Report result, if any...
                                        }Eval2Str'⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2    
                      ∘UNREACHABLE∘
                  }ON
                ⍝ When (CurStateIs OFF or SKIP) for iDef1, iEvl, IDefL, iOther, iStatic   
                  ⍵.PatternNum>iEndIf : (CASE iOther) PassState SKIP 
                  CurStateIs OFF: {
                      CASE iIf:      PassState Push SKIP  
                      CASE iElseIf:  PassState Poke Eval2Bool MacScan F 1
                      CASE iElse:    PassState Poke ON
                      CASE iEndIf:   PassState Pop Peek ⍵
                      ∘UNREACHABLE∘ 
                  }OFF
                  1: {⍝ CurStateIs SKIP:
                      CASE iIf:        PassState Push SKIP
                      CASE iElseIf iElse: PassState SKIP
                      CASE iEndIf:     PassState Pop Peek ⍵
                  }SKIP
                  ∘UNREACHABLE∘
            } ⍝ End ControlScanAction
            save←MACROSñ.(K V) DEBUGf                          ⍝ Save macros
            ⍝ Merge continued control lines (ONLY) into single lines.
            ⍝ Note: comments are treated as literals on Control lines.
            pNotCtl←'^\h*([^:]|:[^:])\N*$'
            _CtlScan←{
                lines←pNotCtl pAllQ  pDotsNC ⎕R  '\0' '\0' ' ' ⍠reOPTS⊣⍵   
                controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣lines    
            }
            res←Pop _CtlScan ⍵
            MACROSñ.(K V) DEBUGf← save                        ⍝ Restore MACROSñ
            res
        } ⍝ End ControlScan 

  ⍝+-----------------------------------------------------+
  ⍝ Primary Scans:   translating code in APL Statements  +  
  ⍝     MainScan - most statements                       +
  ⍝     AtomScan - handle Atoms via ` `` → →→            +
  ⍝+-----------------------------------------------------+
  ⍝ BEGIN Experimental  ←←  
  ⍝ EXTENDED ASSIGNMENT:   name_expression ←← val        OR  name_expression   simple_fnal_expression ←← val
  ⍝       becomes:        {⍎name_expression',←⍵'}val        {⍎name_expression,'(simple_fnal_expression)←⍵'}val
  ⍝   list←'name1' 'name2' 'name3' 
  ⍝   list[1]←←val        ⋄  list[3]*←←2      ⋄  list←←10 20 30
  ⍝ is equiv to (⎕IO=0) 
  ⍝   name2←val           ⋄  name3*←2         ⋄  name1 name2 name3←10 20 30
  ⍝ Note: list[2] or 2⊃list will be treated as equivalent here.
  ⍝ 
  ⍝ Despite the complexity of pAssignX, this is only really useful for simple LHS patterns after the name expr.
  ⍝ No parens, quotes or spaces are matched.
  ⍝      v←'abc'  v[1] ←←5  sets b←5
  ⍝               v[1] +←←3 sets b+←3
  ⍝    
  _q←'+-×÷⌊⌈|*⍟<≤=≥>≠∨∧⍱⍲!?~○'             ⍝ scalar fns  
  _q,←'⌷/⌿\⍀∊⍴↑↓⍳⊂⊃∩∪⊣⊢⊥⊤,⍒⍋⍉⌽⊖⌹⍕⍎⍪≡≢⍷'    ⍝ other fns  
  _q,←'∘⍨¨⍣⍤⍥⍬.'                           ⍝ operators and misc
  pAssignX←'([\d\Q',_q,'\E]*)←←'           ⍝ fns/opts/misc quoted via \Q...\E 
  ⎕SE.⍙⍙.ASGNX←{ 0:: ∆SIG 'SYNTAX ERROR (extended assignment)'  
      nm←⊆⍺ ⋄ 1≠≢nm: nm ∇¨ ⍵ 
      aa←⍺⍺ ⋄ calr←⊃⎕RSI
      fn←{⍺←⎕NC ⍵ ⋄ 3=⍺:'(',')',⍨∊⎕NR ⍵ ⋄ 2=⍺: '' ⋄ }'aa'  ⍝ Error causes signal above.
      1:_←calr⍎(∊⍺),fn,'←⍵'
  }
  ⍝ END Experimental

        mainScanPats← pSysDef pUCmd pDebug pTrpQ pDQPlus pDAQPlus pCom pSQ pDotsC pHere pTradFn pHereC pHereNF pNSEmpty pPtr pNumBase pNum pSink pMacDump pMacro pSymbol pAssignX  
                      iSysDef iUCmd iDebug iTrpQ iDQPlus iDAQPlus iCom iSQ iDotsC iHere iTradFn iHereC iHereNF iNSEmpty iPtr iNumBase iNum iSink iMacDump iMacro iSymbol iAssignX←⍳≢mainScanPats
        MainScan←{ 
            MainScan1←{ 
                macroSeen∘←0
                mainScanPats ⎕R{  
                    ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                    ⋄ CASE←⍵.PatternNum∘∊      
                       ⍝ ⎕←⍵.PatternNum,': ','<',(F 0),'>'           
                    CASE iTrpQ: {
                      4>≢⍵.Lengths: SetABENDf ⎕←(F 0),SPECIAL_COM2,'∘∘ERR∘∘ ⍝ Matching Triple Quote Not Found'
                      (F 3) ((≢F 2) StringFormat) F 1
                    }⍵ 
                  ⍝ DQ strings indents are left as is. Use Triple Quotes """ when auto-exdent is needed.
                    CASE iDQPlus:  (F 2) (0 StringFormat)  UnDQ_DAQ F 1     ⍝ Removed DQTweak...
                    CASE iDAQPlus: (F 2) (0 StringFormat)  UnDQ_DAQ F 1                  
                    CASE iDotsC: ' '   ⍝ Keep: this seems redundant, but can be reached when used inside MainScan                             
                    CASE iPtr:  AddPar  (MainScan F 1),' ⎕SE.⍙⍙.PTR ',(⍕DEBUGf)⊣SaveRunTime 'NOFORCE'  
                    CASE iSQ: ProcSQ F 0  
                    CASE iCom: F 0                
                    CASE iHere iTradFn: { 
                      opts← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Pick up single-letter option after each :
                      l1←opts((≢F 4)StringFormat)F 3 
                      l1←{ 
                        Unpack←⍎ ⋄ Repack←{∊SQ,¨⍵,¨SQ_SP}DblSQ¨
                        isTrad←CASE iTradFn
                        isTrad: SINK_NAME,'←⎕SE.⍙⍙.FIXX ',Repack MainScan  ⊆Unpack ⍵ ⋄ ⍵
                      } l1
                      l1 {0=≢⍵~' ':⍺ ⋄ ⍺, MainScan ⍵} F 5       ⍝ If no code after endToken, do nothing more...
                    } 0 
                  ⍝ ::: ⍝ Here Comment...
                    CASE iHereC: (F 2){
                      kp←0≠≢⍺  ⋄ 0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR
                    } DLB F 5 
                  ⍝ iHereNF: One of these failed: iHere, iTradFn, iHereC. No matching endstring.
                    CASE iHereNF:  { F1 F2 F3 rest ←F¨ 1 2 3 4  
                       (IN_SKIP∘←~IN_SKIP)⊢IN_SKIP:''          ⍝ Avoid duplicate error msgs on same line...
                       direct←F2,' ',F3  ⋄ endStr←'"END',F3,'".'
                       ⎕←'Error on line:' ⋄   ⎕←F1~CR ⋄ ⎕←_←'EOF reached w/o finding matching ',endStr
                       SetABENDf direct,SPECIAL_COM2,' ∘∘ERR∘∘ ⍝ ERROR: ',_,CR,rest
                    }⍬                 
                    CASE iMacro:   ⊢MacScan MacGet F 1 ⊣ macroSeen∘←1            
                    CASE iSysDef:  ''⊣ (F 1) (0 _MacSet) F 2                ⍝ SysDef: ::DEF, ::DEFL, ::EVAL on 2nd pass
                    CASE iDebug:   ''⊣ DEBUGf∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                    CASE iNumBase: ∆DEC (F 0)~'_'
                    CASE iNum:     (F 0)~'_'
                    CASE iUCmd:     '⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2   
                    CASE iSink:    (F 1),SINK_NAME,(F 2)    ⍝ F1: blanks (keep alignment), SINK_NAME←
                    CASE iNSEmpty: '(⎕NS⍬)'
                    CASE iMacDump:    ''⊣MacDump '  MACRO DUMP'  
                    CASE iAssignX:  '(',fn,' ⎕SE.⍙⍙.ASGNX)'⊣fn←{0=≢⍵~' ':'0'⋄ ⍵ }F 1
                    CASE iSymbol:    ∊SYMBOL_MAP[1;SYMBOL_MAP[0;]⍳F 0]       
                    ∘∘UNREACHABLE∘∘
                }⍠reOPTS⊣⍵  
            }
            AtomScan←{ ⍝ Atom Punctuation:  `  → and variants: `` and →→ .
                       ⍝ Atom List:   ` (var | number | 'qt' | "qt")+
                       ⍝             `` ...
                       ⍝ Atom Map:      (var | number | 'qt' | "qt")+  →  any_code     
                       ⍝                  ...                         →→  ...   
                iSkip←2 3
                pAtomList pAtomsArrow pCom pSQ  ⎕R  {
                  F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} 
                  FAll←F 0 
                  ⍵.PatternNum∊iSkip:  FAll  
                ⍝ ⍵.PatternNum? (0) Simple Atom quote (`) or (1) Atom map  quote (→).
                  (FGlyph FAtoms) arr←{⍵=0: (F¨1 2) 0 ⋄ (F¨2 1) 1}⍵.PatternNum 
                ⍝ If the ` is single (`), treat a single atom as a one-element list.
                  promoteSingle←1=≢FGlyph    
                  pAtomEach← pSQ '[¯\d\.]\H*' '\H+' 
                             iSQ iNum         iLet←⍳≢pAtomEach
                  count←0 ⋄ allNum←1 ⋄ atomErr←0  
                  list←pAtomEach ⎕R {oneStr←1=≢⍵ ⋄  F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ CASE←⍵.PatternNum∘∊
                      F0← F 0 ⋄ count+←1
                      CASE iSQ:   {3=≢⍵: AddPar ',', ⍵ ⋄ ⍵} F0 
                      CASE iNum:  {(,1)≡⊃⎕VFI ⍵: ⍵ ⋄ atomErr∘←1 ⋄ ⍵⊣∆WARN 'Invalid numeric atom'} F 0
                      CASE iLet:  {3=≢⍵: AddPar ',' , ⍵ ⋄  ⍵} SQ,F0,SQ 
                      ∘∘UNREACHABLE∘∘
                  }⊣FAtoms 
                  atomErr: FAll
                  (AddPar (',⊂'/⍨promoteSingle∧1=count), list), (arr/'(,⍥⊂)')
              }⍠reOPTS⊣⍵
            }

            MULTI_SCAN_MODE←0    ⍝ Problems with rescanning???
            ⍺←0 ⋄ MAX←20 ⋄ count strIn←⍺ ⍵ ⋄ IN_SKIP∘←0
            count≥MAX: ⍵  ⊣⎕←'∆FIX: MainScan macro replacement limit (',(⍕MAX),') reached. Cyclic macro pattern?'
            strOut←AtomScan MainScan1  strIn ⊣ macroSeen←0
            ~macroSeen∧MULTI_SCAN_MODE: strOut ⋄  strOut≡strIn: strOut ⋄ (count+1) ∇ strOut  
        } ⍝ End MainScan 

  ⍝+-------------------------------------------------+
  ⍝ Begin Execution                                  +  
  ⍝   Predefine Macros                               + 
  ⍝   Start Scans                                    + 
  ⍝      DFN Scan In                                 + 
  ⍝      Control Scan                                + 
  ⍝      Main Scan                                   + 
  ⍝      DFN Scan Out                                + 
  ⍝   FIX if requested.                              + 
  ⍝+-------------------------------------------------+
  ⍝
  ⍝+-------------------------------------------------+
  ⍝ Predefined User MACROs                           +  
  ⍝+-------------------------------------------------+
      ⍝ >>> PREDEFINED MACROS BEGIN                    
        MACROSñ.⍙DEF←  MACROSñ.{(≢K)>K⍳⊂⍵}              ⍝   MACROSñ: macro internal namespace
      ⍝ Macro-- alias1 [alias2...] Macro macro_text: specify 1 or more aliases on left for macro text on right. 
        _SetBuiltinMacros←{       
            _←'⎕F'            MacroLiteral '∆F'                   ⍝   APL-ified Python-reminiscent format function
            _←'⎕TO'           MacroLiteral '⎕SE.⍙⍙.TO'              ⍝   1 ⎕TO 20 2   "One to 20 by twos'
            _←'⎕ASSERT'       MacroLiteral '⎕SE.⍙⍙.ASSERT'
          ⍝ ::DEF. Used in sequence ::IF ::DEF "name"
          ⍝        Returns 1 if <name> is active Macro, else 0. Valid only during Control Scan
          ⍝        Note:  "::DEF macro" undefs <name> (its value is "name"). 
          ⍝ Do <<::DEF name 1>> (among many choices) to ensure  «::IF ::DEF "name"» is true.
            _←'::DEF'         MacroLiteral 'MACROSñ.⍙DEF'   
            _←'::COMPRESS'    MacroLiteral ⍕COMPRESSf
            _←'::DEBUG'       MacroLiteral ⍕DEBUGf 
          ⍝ ⎕MY - a static namespace for each function... Requires accessible namespace '∆MYgrp' (library ∆MY).
            _←'⎕MY'           MacroLiteral {
                                STATIC_NS← '⍙⍙'  ⋄ STATIC_PREFIX← STATIC_NS,'.∆MY_'     
                                _←'({0:: ⎕SIGNAL/''Requires library ∆MY'' 11 ⋄  0:: ⍵ ∆MYX 1'
                                _⊣ _,←'⋄ ⍵⍎','''',STATIC_PREFIX,'''',',1⊃⎕SI}(0⊃⎕RSI,#))' 
            }⍬
            _←'⎕T'            MacroLiteral SINK_NAME         ⍝ ⎕T (temp. var)
            _←'⎕MONADIC' '⎕M' MacroLiteral '(900⌶⍬)'         ⍝ Monadic Function
            _←'⎕NOTIN'        MacroLiteral '(~∊)'
            _←'⎕NOTINch'      MacroLiteral ' ''',NOTINch,''' '
            _←'⎕UNDER' '⎕DUAL'      MacroLiteral '⎕SE.⍙⍙.UNDER'       
            _←'⎕UNDERch' '⎕DUALch'  MacroLiteral ' ''',UNDERch,''' '      
             _←SaveRunTime 'NOFORCE'
            1: ⍵
        }
      ⍝ <<< PREDEFINED MACROS END 
 
      pDFnDirective←∆R'[$R]\h*::[^$R]*',pDFn,'[^$R]*[$R]'
    ⍝ FirstScanIn:
    ⍝   1. A DFn started on a ::directive line is detected and treated as part of that line.
    ⍝   2. Visible Pseudo-Strand function (⍮) replaced by current APL (,⍥⊂). This is not quite a Strand, in fact.
    ⍝      Mnemonic: Like ';' separates/links items of "equal" status
      FirstScanIn←{  
          Align←    {  ⍵.PatternNum≠0: ⍵.Match ⋄ pDFn pAllQ pCom ⎕R SubAlign ⍠reOPTS⊣⍵.Match }
          SubAlign← {  ⍵.PatternNum≠0: ⍵.Match ⋄ {CR_INTERNAL@ (CR∘=)⊢⍵}¨⍵.Match }
          pDFnDirective pAllQ pCom  ⎕R Align ⍠reOPTS⊣⍵
      }
    ⍝ LastScanOut: Moves DFn directives from single-line to standard multi-line format.
      LastScanOut←{
            ⍺←CR            ⍝ Default for CR_OUT
            NUL←⎕UCS 0
            pCrIn←'\x01'
            pStrand←'⍮'             ⍝ Explicit "strand" function:  ⍮ --> (,⍥⊂), where  ⍮is U+236E
            pSemi←  ';'             ⍝ Implicit strand function within control of parens...
            pLBrak←'[[(]'  
            pRBrak←'[])]'
            STRAND_OUT SEMI_OUT CR_OUT←'(,⍥⊆)' ';' ⍺ 
          ⍝ pSpecCom: Special Internally Generated Comments
            STK←,0     ⍝ Value→Out: 0→Strand (outside parens); 1→Semicolon (in brackets); 2→Strand (in parens)
            scanPats←  pAllQ pSpecCom pCom pCrIn pStrand pSemi pLBrak pRBrak
                       _     iSpecCom _    iCrIn iStrand iSemi iLBrak iRBrak← ⍳≢scanPats
            Align← {  CASE←⍵.PatternNum∘∊   ⋄ str←⍵.Match
              CASE iSpecCom:DEBUGf/(1↑str),2↓str       
              CASE iCrIn:   CR_OUT
              CASE iStrand: STRAND_OUT 
            ⍝ Top of stack: 0        1          2
              CASE iSemi:   SEMI_OUT STRAND_OUT SEMI_OUT ⊃⍨ ⊃⌽STK
              CASE iLBrak:  str⊣STK,←1+str='['
              CASE iRBrak:  str⊣STK↓⍨←¯1×1<≢STK      ⍝ Don't delete leftmost stack entry (0).
            ⍝ ELSE matches (AllQ Com) 
              str   
            }
            pSpecComKludge  ⎕R '' ⊣scanPats  ⎕R Align ⍠reOPTS⊣⍵ 
      }
      UserEdit←{⍺←0 ⋄ recurs←⍺
          sep←⊂'⍝>⍝',30⍴' -'
          alt←'⍝ Enter ESC to exit with changes (if any)' '⍝ Enter CTL-ESC to exit without changes' 
          Exit←{
            0:: 'User Edit complete. Unable to fix. See variable #.FIX_FN_SRC.' 
            #.FIX_FN_SRC←(⊂'ok←FIX_FN'),(⊂'ok←''>>> FIX_FN done.'''),⍨'^⍝>' '^\h*(?!⍝)' ⎕R '' '⍝' ⊣⍵
            0=1↑0⍴rc←#.⎕FX #.FIX_FN_SRC: ∘∘ERR∘∘
            'User Edit complete. See function #.',rc,'.'
          }
          FormIn←{'^⍝>.*$\R?' '^⍝(.*)$'  ⎕R '' '⍝>⍝\1' ⍠('Mode' 'M')⊣⍵}
          FormOut←{'^ *⍝'  '^' ⎕R  '\0'  '⍝> '⊣⍵}
          
          edit←cur←⊆(0<≢⍵)⊃alt ⍵ 
          _←⎕ED 'edit'   
          recurs∧edit≡cur: Exit cur
          (recurs←1) ∇ {⍵,sep,FormOut ⍵}FullScan FormIn edit
      }
      ⍝ Add (and remove) an extra line so every internal line has a linend at each stage...
      FullScan←{¯1↓ LastScanOut MainScan ControlScan FirstScanIn (DTB¨⊆⍵),⊂'⍝⍝⍝'}
      IncludeScan←{¯1↓  ControlScan FirstScanIn (DTB¨⊆⍵),⊂'⍝⍝⍝'}

    ⍝ Include scan? Run only the ControlScan...
      SCAN_INCLUDEt=⍺:  IncludeScan ⍵

    ⍝ Initial (Non-recursive) Scan: Initialize Macros
      _←_SetBuiltinMacros ⍬
    ⍝ Edit scan? UserEdit rt arg; otherwise simply use ⍵.
      SCAN_EDITt=⍺: UserEdit ⍵ 
    ⍝ Full scan (default)...
      FullScan ⍵
    }  

  ⍝ Compress ⍵: Remove from string <⍵> all extra spaces (beyond 1), blank and empty lines, and comments...
    Compress←{  ⍺←1 
        0=⍺: ⍵ ⋄ F0 NUL SP←'\0' '' ' '          
        pList← '''[^'']*'''  '^[\h⋄]*(⍝.*)?\R?'  '[\h⋄]*(⍝.*)?$' '\h+' 
        aList← F0            NUL                 NUL             SP
        pList ⎕R aList ⍠'Mode' 'M'⊣⍵
    }  
  ⍝  options are set by the user as ⍺[0] (default 2)
  ⍝  option   flag  meaning of flag if 1
  ⍝  ⍳3       Ff    ⍺[0]is ∊⍳3, so valid ⍺ for ⎕FIX; call ⎕FIX.
  ⍝ 'e'       Ef    Edit the source and preprocess; don't ⎕FIX.
  ⍝ 'i'       If    This is an ::include object or file; so return a vector of vectors, don't ⎕FIX.
  ⍝ 'v'       Vf    Users wants to see code in mixed (matrix) format; don't ⎕FIX.
  ⍝  -        Wf    ⍵ has at least one line (otherwise start with empty code list). 
    Ff (Ef If  Vf) Wf ← FIXf{(⍺∊⍳3)(⍺='eiv')⍵}0<≢⍵
  ⍝ Execute.  ABENDf might be set above to Ff, to avoid a ⎕FIX that might succeed despite directive failures. 
  If: SCAN_INCLUDEt∘Executive LoadLines ⊣ ⍵ 
  _← ↑⍣Vf⊢FIXf CALR.⎕FIX⍣Ff⊣ __←(Ff∧COMPRESSf) Compress (Ef×SCAN_EDITt)∘Executive LoadLines⍣Wf ⊣ ⍵ 
  ~ABENDf: _ ⋄ #.FIX_LINES←↑__
  ∆SIG 'Invalid directive. Unable to ⎕FIX. See variable #.FIX_LINES.'
}