∆FIX←{
  ⍺←0
  opt mâc←{9=⎕NC '⍺': 'i' ⍺  ⋄ ⍺ (⎕NS '')}⍨⍺
  ⍝ See ∆FIX.help for documentation.
  ⍝     result←  options ∆FIX  [filename:@S | lines:@VS]
  ⍝ The result is as for ⎕FIX, i.e. names of objects fixed, unless a "nonce" option (extension) is used (q.v.).
  ⍝
  ⍝ Syntax is as for ⎕FIX, except for 
  ⍝    a) "nonce" options:
  ⍝        'n[ofix]'  Return the translated lines without then ⎕FIXing them.
  ⍝        'e[dit]'   Enter an editing environment to test various code sequences and 
  ⍝                   view the translated lines. Creates:
  ⍝                   ∘ a char var #.FIX_FN_SRC with the current test code, and
  ⍝                   ∘ an executable #.FIX_FN, if successfully ∆FIXed.
  ⍝    b) filename: Automatically supplies :file// prefix (required by ⎕FIX), if a simple character vector (VS).
  ⍝ 
  ⍝ +--------------------------------------------------+
  ⍝ |     CONSTANTS and OPTIONS                        |
  ⍝ +-------------------------------------------- -----+
    DEBUG←1 
    ⎕IO ⎕ML←0 1  
  ⍝ Prefix for any user-visible variable...
    FIX_PFX←'FÍX_'  
  ⍝ Prefix for comments emitted to document directives
    COMMENT_PFX←'⍝F'
  ⍝ See pSink←. 
   SINK_NAME←FIX_PFX,'t'
  ⍝ For CR_INTERNAL, see also \x01 in Pattern Defs (below). Used in DQ sequences and for CRs separating DFN lines.
  ⍝ CR_VISIBLE is a display version of a CR_INTERNAL when displaying preprocessor control statements e.g. via ::DEBUG.
    SQ DQ←'''"' ⋄ NL CR CR_INTERNAL←⎕UCS 10 13 01 ⋄  CR_VISIBLE←'◈' 
    CALR←0⊃⎕RSI
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 
  ⍝ ∆WARN: Warning are emitted as msgs only if DEBUG is active. Else NOP.
    ∆WARN←{⍺←1 ⋄ ⍺∧DEBUG: ''⊣⎕←'∆FIX WARNING: ',⍵ ⋄ 1: ''}
    ∆ASSERT←{⍺←'ASSERTION FAILED' ⋄  ⍵: 0 ⋄ ⍺ ⎕SIGNAL 911}
  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
  ⍝ Add CR to last line to make Regex patterns simpler...
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }

  ⍝ +-------------------------------------------------+
  ⍝ | Patterns                                        +
  ⍝ |   - Utilities                                   +
  ⍝ |   - Definitions, organized by scan              +
  ⍝+--------------------------------------------------+
  ⍝ | Pattern-related Utilities                         +
  ⍝+--------------------------------------------------+
    GenBracePat←{⎕IO←0 ⋄ ⍺←⎕A[,⍉26⊥⍣¯1⊢ ⎕UCS ⍵] ⋄ Nm←⍺  ⍝ ⍺ a generated unique name based on ⍵
          Lb Rb←⍵,⍨¨⊂'\\'                     
          pM←'(?: (?J) (?<Nm> Lb  (?> [^LbRb''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&Nm)* )+ Rb))'~' '
          'Nm' 'Lb' 'Rb'⎕R Nm Lb Rb⊣pM
    }
    ∆R←      {'\$R' ⎕R '\\r\\x01'⊣∊⍵ }
    ∆Anch_L ∆Anch_R←∆R¨'(?:(?<=[$R⋄])|^)' '(?:[$R⋄]|$)' 
    ∆Anchor← { '(?xi)',∆Anch_L,(∆R ⍵),∆Anch_R }
   
  ⍝+--------------------------------------------------+
  ⍝ A. Pattern Defs, MULTIPLE SCANS                   +
  ⍝+--------------------------------------------------+
    pDotsNoCom←∆R'(?:\.{2,3}|…)\h*[$R⋄]\h*'
    pDots←     ∆R'(?:\.{2,3}|…)\h*(⍝[^$R⋄]*)?[$R⋄]\h*'
    pDQ←         '(?:"[^"]*")+' 
    pDAQ←        '(?:«[^»]*)(?:»»[^»]*)*»'   ⍝ Double Angled Quotes = Guillemets  « »
    pSQ←         '(?:''[^'']*'')+'           ⍝ Multiline SQ strings are matched, but disallowed when processed.
    pAllQ←       pDQ,'|',pSQ,'|',pDAQ        ⍝ For Triple Quotes (not matched here), see pTrpQ below.
    pCom←     ∆R'⍝[^$R]*$' 
    pDFn←       GenBracePat '{}'
    pParen←     GenBracePat '()' 
    pBrack←     GenBracePat '[]'
    pBraces3←   '(?:' pDFn '|' pParen '|' pBrack ')'
  ⍝+--------------------------------------------------+
  ⍝ B.Pattern Defs, CONTROL SCANS                     +
  ⍝+--------------------------------------------------+
  ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
  ⍝ These are required to match a SINGLE line each in its entirety OR a line continued implicitly or explicitly (via dot format).
  ⍝ BUG: Does not allow continuation via parens, braces, double quotes, etc.

  ⍝ control CR Family: Multi-line dfns and strings on ::directives. 
  ⍝ \r is carriage return, \x01 is the faux carriage return, 
  ⍝ ◈ is a visible rendering for display purposes distinct from ⋄.
     pCrFamily← ∆R¨'[$R]\z'  '[$R]'  ⋄ actionCrFamily←  '\0' CR_VISIBLE
 
  ⍝⍝⍝ Experimental-- replace pDFn on next 2 lines with pBraces3. 
  ⍝⍝⍝ ... Next, add Dyalog code for extended array definition formats (multiline).
  ⍝⍝⍝    «[^»
    pMULTI_NOCOM←  ∆R '(?x) (?<NOC> (?> [^\{[(⍝''"«$R]+ |' pAllQ '|' pBraces3          ') (?&NOC)*)'
    pMULTI_COM←    ∆R '(?x) (?<ANY> (?> [^\{[(⍝''"«$R]+ |' pAllQ '|' pBraces3 '|' pCom ') (?&ANY)*)'
    pIf←           ∆Anchor'\h* :: IF         \b \h* (\N+) '
    pElIf←         ∆Anchor'\h* :: ELSEIF     \b \h* (\N+) '
    pEl←           ∆Anchor'\h* :: ELSE       \b      \h*  '
    pEndIf←        ∆Anchor'\h* :: END(?:IF)? \b      \h*  '
  ⍝ For ::DEF (define) of the form  ::DEF name←  value, match after the control word:
  ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] 
  ⍝     up to (but not including) a comment or EOL,
  ⍝ where name* is a sequence of chars except spaces, ←, or CR.
  ⍝ The value will be enclosed in parentheses, limiting surprising side effects due to precedence.
  ⍝ Given the expression Pi2
  ⍝      ::DEF Pi2← ○2
  ⍝ when we execute
  ⍝      ⎕← Pi2 + 3  
  ⍝ we get the expected  
  ⍝     (○2) + 3   
  ⍝ NOT  
  ⍝     ○2  + 3, i.e. ○5
  ⍝ Use ::DEFL (literal) to suppress parentheses (and allow comments to be carried into the macro).
    pDef1←         ∆Anchor'\h* :: def  \h+ ((?>[\w∆⍙#.⎕]+)) \h* ← \h*  (' pMULTI_NOCOM '+|) \N* ' 
  ⍝ ::EVAL or synonym ::DEFE 
  ⍝ For ::EVAL (evaluate string value) of form ::EVAL name ← value, match after the control word:
  ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
  ⍝ where name* is a sequence of chars except spaces, ←, or CR. 
  ⍝ The value stored will be determined in the calling namespace CALR as
  ⍝     CALR ⍎ value
  ⍝                                                  F1                            F2
    pEvl←          ∆Anchor'\h* :: (?:eval|defe)  \h+ ((?>[\w∆⍙#.⎕]+))    \h* ← \h? (' pMULTI_NOCOM '+|) \N* '   
  ⍝ ::STATIic name←  value
  ⍝ ::DECLare name←  value
  ⍝    name:      An APL run-time variable
  ⍝    variable:  A Dyalog code value OR a Dyalog new Array or Namespace declaration on one or more lines.
  ⍝ Simple APL declarations are allowed. 
  ⍝    ::STATIC  time←  ⎕TS    ⍝ This will be replaced by its value at ∆FIX/⎕FIX ("compile") time (exactly once).
  ⍝    ::DECLARE time←  ⎕TS    ⍝ This will execute at run-time (each time statement is reached).
  ⍝ More complex declarations may extend over multiple lines or use statment separators (⋄),
  ⍝ using double-quoted multi-line strings, complex declarations in brackets [] or parentheses [].
  ⍝    ::STATIC multiNow←    [ 'iota10'  ⋄ ⍳10   ⍝ Creates a  declaration evaluated at ∆FIX time.
  ⍝                            'revAlph' ⋄ ⌽⎕A
  ⍝                            'when'    ⋄ ⎕TS   ⍝ Set as a constant, when an object is ∆FIXed.
  ⍝                          ]
  ⍝    ::DECLARE multiLater←  [ 'iota10'  ⋄ ⍳10  ⍝ Creates a declaration to be evaluated at run-time
  ⍝                             'revAlph' ⋄ ⌽⎕A
  ⍝                             'when'    ⋄ ⎕TS  ⍝ Changes on each call, if internal to a object.
  ⍝                           ]
  ⍝     ::STATIC variables have access only to named objects created earlier in the same session.
  ⍝
  ⍝  EXAMPLE:
  ⍝  ¯¯¯¯¯¯¯¯
  ⍝>       2 ∆FIX '(TS TSS)←test' '::DECLARE TS←  ⎕TS' '::STATIC TSS←  ⎕TS'
  ⍝>       ⎕CR 'test'              ⍝ Show resulting code from ∆FIX.
  ⍝   (TS TSS)←test                     
  ⍝   ⍝↑::DECLARE TS←  ⎕TS      
  ⍝   TS←⎕TS                       ⍝ Note: Code executed at run-time on each function call.
  ⍝   ⍝↑::STATIC TSS←  ⎕TS      
  ⍝   TSS←2021 2 23 22 44 5 178    ⍝ Note: precalculated, so constant at run-time
  ⍝  
  ⍝>       test
  ⍝   2021 2 23 22 47 21 69   2021 2 23 22 47 18 465    ⍝ TS changes.  TSS is constant.
  ⍝>       test
  ⍝   2021 2 23 22 47 24 283  2021 2 23 22 47 18 465 
  ⍝>       test
  ⍝   2021 2 23 22 47 35 984  2021 2 23 22 47 18 465 
  ⍝
  ⍝ See  https://www.dyalog.com/uploads/conference/dyalog20/presentations/D09_Array_Notation_RC1.pdf
    pStatic←       ∆Anchor'\h* :: (?>stat(?:ic )?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pMULTI_NOCOM '+|) \N* ' 
    pDeclare←      ∆Anchor'\h* :: (?>decl(?:are)?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pMULTI_NOCOM '+|) \N* ' 
    pInclude←      ∆Anchor'\h* :: (?>incl(?:ude)?) \h+ (    [^$R⋄⍝]*  )  (?:⍝ [^$R⋄]* )?'   
  ⍝ For ::DEFL (literal) of the form ::DEFL name←  value, match after the ctl word: 
  ⍝      blanks, word*, blanks,←  value*    ⍝ NOTE: Blanks after ← are significant and kept...
  ⍝ where word* defined as above and value* includes everything up to the EOL, including leading and internal blanks.
  ⍝ The value will not be enclosed in parentheses.
    pDefL←         ∆Anchor'\h* :: defl \h+ ((?>[\w∆⍙#.⎕]+)) \h* ←  (' pMULTI_COM '|) '  
  ⍝ For ::DEF of forms:   
  ⍝     ::DEF name    OR    ::def name value  
  ⍝ we match after the ctl word:
  ⍝ I.     blanks, name*  which is translated to: ::DEF name1* ← name1*
  ⍝    where name* and name1* defined as name* above, name1* the same in both cases.
  ⍝    This is equivalent to undefining name*, i.e. replacing it with itself.
  ⍝ II.    blanks, name*, blanks, value
  ⍝    where name* as above and value* consists of all text to the end of the line, excluding leading blanks.
  ⍝    This is equivalent to ::def name ← value above.
    pDef2←        ∆Anchor'\h* :: (?:def) \h+ ((?>[^\h←\r]+)) \h*? ( [^\h\r]* )'
  ⍝ :DEF, :DEFL (literal), :EVAL (:DEFE, def and eval)  are errors.
    pErr←         ∆Anchor'\h* :(def[el]?|eval) \b \N* '
    pDebug←       ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
    pUCmdC←       ∆Anchor'\h*::(\]{1,2})\h*(\N+)'            ⍝ ::]user_commands or  ::]var←user_commands
    pOther←       ∆R     '(?=[$R]|^)(?!\h*::)'               ⍝ Non-interfering with other cmds on line! Was:  ∆Anchor'\N*'    Removed-- unneeded???
  ⍝+-------------------------------------+
  ⍝ C. Pattern Defs, MAIN SCAN PATTERNS  +  
  ⍝+-------------------------------------+
    pSysDef←       ∆Anchor'^::SysDefø \h ([^←]+?) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
    pUCmd←        '^\h*(\]{1,2})\h*(\N+)$'                    ⍝ ]user_commands or  ]var←user_commands
    pDebug←       ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
  ⍝ """...""".  F1: string, F2: leading blanks on matching line, F3: suffixes. 
  ⍝ """...""".  2nd alternative will trigger an error-- F2 and F3 won't have a value...
    pTrpQ←        '"""(?|\h*\R(.*?)\R(\h*)"""([a-z]*)|)'    
    pDQPlus←      ∊'(?xi) (' pDQ ') ([a-z]*)'
    pDAQPlus←     ∊'(?xi) (' pDAQ') ([a-z]*)'      ⍝ DAQ: Guillemet Quotes! « »
    pWord←        '[\w∆⍙_#.⎕]+'
    pPtr←         ∊'(?ix) \$ \h* (' pParen '|' pDFn '|' pWord ')'
    _pHMID←       '( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
  ⍝ Here-strings and Multiline ("Here-string"-style) comments 
    pHere←        ∊'(?x)       ::: \h*   '_pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
    pHCom←        ∆Anchor '\h* ::: \h* ⍝ '_pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '
    pNumBase←     '(?xi) ¯?0 [box] [\w_]+ (?>\.[\w_]+)?'    ⍝ Use ¯ \w to trap invalid non-decimal numbers
    pNum←         '(?xi) (?<!\d)   (¯? (?: \d\w+ (?: \.\w* )? | \.\w+ ) )  (j (?1))?'
    pSink←'(?xi) (?:^|(?<=[[{(\x01⋄:]))(\h*)(←)'   ⍝ \x01: After CR_INTERNAL (dfn-internal CR)

    ⍝    pMULTI_COM←    ∆R '(?x) (?<ANY> (?> [^\{[(⍝''"«$R]+ |' pAllQ '|' pBraces3 '|' pCom ') (?&ANY)*)'
 
    pMacro←       { 
      ⍝ Matches:  ⎕X012  #.X012 ::X012 or  A.B.⎕X012, ⎕X012.A.B etc. Trailing '.' is not included!    
      ⍝ APL variable name initial letters: 
      ⍝     [ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖØÙÚÛÜ∆⍙_] ==>  [A-ZÀ-ÖØ-Ü∆⍙_]
        _AplName← '(?<APLNAME> (?: ⎕|::?)? [A-ZÀ-ÖØ-Ü∆⍙_] [\dA-ZÀ-ÖØ-Ü∆⍙_]* | \#{1,2} )'  
        ∊_pMac←'(?xi)(' _AplName ' ((\.(?&APLNAME))*))'   ⍝ OK: ::NAME, ⎕NAME, ]NAME
    }⍬
    pNSEmpty← '\(\h*\)'   ⍝ Dyalog APL (future) extension: ⎕NS ⍬.  Other namespace extensions handled via ::DECLARE
    pDump←    '^\h*::DUMP\b\h*$' 
  ⍝+---------------------------------------+
  ⍝ D. Pattern Defs, ATOM SCAN PATTERNS    +  
  ⍝+---------------------------------------+
  ⍝ Atomlist Pattern:    
  ⍝    (` | ``) item, where item: word | number | "quote" | 'quote'
  ⍝         `: Ensures atom list is always a vector, no matter how many atoms.
  ⍝        ``: Encodes a single atom as a scalar; multiple atoms as a list. E.g. for ⎕NC ``item.
  ⍝            Each char atom will be encoded as an enclosed vector (even if an APL scalar `x).
  ⍝            Each numeric atom will be encoded as a simple scalar. 
  ⍝  Uses 1: To allow objects to be defined using ::DEFs, yet presented to fns and ops as quoted strings.
  ⍝            ::IF format=='in_color'
  ⍝               ::DEF MYFUN← GetColors
  ⍝            ::ELSE
  ⍝               ::DEF MYFUN← GetBlackWhite
  ⍝            ::ENDIF 
  ⍝            ⎕FX ``MYFUN
  ⍝   Uses 2: To allow enumerations or word-based classes.
  ⍝           colors←`red orange yellow green
  ⍝           mycolor←`red 
  ⍝           :IF mycolor ∊ colors  ⍝ Is my color valid?
  ⍝           ...     
  ⍝  atomList →  anything
  ⍝  atomList →→ anything
  ⍝            Quotes a list of 1 or more words to left of the arrow, which list will be a peer
  ⍝            item with all that is to the right.
  ⍝            A single arrow ensures even a single item to the left is encoded as a 1-elem list;
  ⍝            a double arrow treats a single item as an independent scalar.
  ⍝  See also ::DECLARE and Dyalog APL namespace declarations like
  ⍝          name ← (var: value ⋄ var2: value2)
  ⍝  Uses 1: Allows simulation of named arguments in function calls or object members:
  ⍝          ((name→"John Smith")(address→"24 Mill Ln")(zip→01426))
  ⍝  is encoded as:
  ⍝         (((,⊂'name')(,⍥⊂)'John Smith')((,⊂'address')(,⍥⊂)'24 Mill Ln')((,⊂'zip')(,⍥⊂)01426)) 
  ⍝  whose value is:
  ⍝         name   John Smith     address   24 Mill Ln     zip   1426 
  ⍝  boxed as:
  ⍝       ┌───────────────────┬──────────────────────┬────────────┐
  ⍝       │┌──────┬──────────┐│┌─────────┬──────────┐│┌─────┬────┐│
  ⍝       ││┌────┐│John Smith│││┌───────┐│24 Mill Ln│││┌───┐│1426││
  ⍝       │││name││          ││││address││          ││││zip││    ││
  ⍝       ││└────┘│          │││└───────┘│          │││└───┘│    ││
  ⍝       │└──────┴──────────┘│└─────────┴──────────┘│└─────┴────┘│
  ⍝       └───────────────────┴──────────────────────┴────────────┘                                
    pAtomList←      ∊'(?x) (`{1,2})  \h* ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ )'     
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
    UnDQ_DAQ←{DQ1←1↑⍵ ⋄  DQ2←'"«?'['"«'⍳DQ1]  ⋄ DQ2='?': '∆FIX UnDQ_DAQ Logic Error' ⎕SIGNAL 11 
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
  ⍝  If ⍺=0, calls ⍙FIX rather than simply including...
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
        FindEach←⍺∘{0:: 11 ⎕SIGNAL⍨eUnexpected⊣⎕←'FindFirstFiles: ⍺' ⍺ ' ⍵' ⍵
            0=≢⍺: ⎕NULL                                 ⍝ Exhausted search
            full←(rel/'/',⍨⊃⍺),⍵ ⊣ rel←'/'≠1↑⍵  
            ⎕NEXISTS full: full 
            rel: (1↓⍺) ∇ ⍵ ⋄ ⎕NULL                      ⍝ Keep searching only if not absolute name                    
        }
        0=≢⍺:  11 ⎕SIGNAL⍨ eNoPath ⋄ 0=≢⍵: ⎕NULL
        FindEach¨⊆⍵
    }
    eNoPath←     '⍙INCLUDE: No search directories were specified [LOGIC ERROR].'
    eUnexpected← '⍙INCLUDE: Unexpected error evaluating filename.'
    eNoFiles←    '⍙INCLUDE: No file(s) to include.'
    eNotFound←   '⍙INCLUDE: At least one file to include was not found in search path:'
  ⍝ ⍙INCLUDE EXECUTIVE
    files←{1=≡⍵:  ' ' (≠⊆⊢)⍵ ⋄ ⍵ },⍵
    0=≢files:          11 ⎕SIGNAL⍨ eNoFiles
    searchPath←setSearchPath 'FSPATH' 'WSPATH'  
    filesFull←searchPath FindFirstFiles files 
    ⎕NULL∊_←filesFull:  22 ⎕SIGNAL⍨ eNotFound,∊' ',¨files/⍨_∊⎕NULL
  ⍝ Read each file as a single string with NLs as linends, concatenating all strings together. Missing => Err
  ⍝ Return (default) single string with NLs as linends. Missing => Err
   ⍺=0: ∊{∊CR,⍨¨mâc ∆FIX ⍵}¨filesFull    ⍝ Pass current macro namespace to each function called (which they may change)
    ⊃,/{⊃⎕NGET ⍵ 0}¨filesFull    ⍝ Omitted: CR@(LF∘=)⊣
} 

  ⍝ SaveRunTime:  SaveRunTime ['NOFORCE' | 'FORCE'], default 'NOFORCE'.
  ⍝ Save Run-time Utilities shown here in ⎕SE if not already there...
  ⍝     ⎕SE.⍙PTR, ⎕SE.⍙FIX_TRADFN   -- not expected to be called by user.
  ⍝     ⎕SE.∆TO                     -- potentially called by user.
  ⍝     ⎕SE.∆NS                     -- see extensions from Adam B on github.
    SaveRunTime←{utils utype←↓⍉↑('∆ASSERT' 3)('⍙FIX_TRADFN' 3)('⍙PTR' 4) ('∆TO' 3)('∆NS' 3)
        (~DEBUG)∧(⍵≢'FORCE')∧utype∧.=⎕SE.⎕NC ↑utils: 0    ⍝ Save Runtime Utils if (DEBUG∨FORCE) or if utils not created...
        2/⍨~DEBUG:: 11 ⎕SIGNAL⍨'∆FIX: Unable to set utilities: ⎕SE.(',utils,')'
      ⍝ ∆ASSERT for Macro ⎕ASSERT 
        ⎕SE.∆ASSERT←{⍺←'Assertion failure' ⋄ 0∊⍵:⍺ ⎕SIGNAL 8 ⋄ shy←0}
      ⍝ ⍙FIX_TRADFN for macro ::TRADFN
      ⍝ If first line of string is blank or a comment, it is ignored.
      ⍝ First line remaining is the header of the resulting function.
      ⍝ Makes it easy to create a tradfn using TQ Strings or DQ Strings.
      ⍝    ::TRADFN """        ::TRADFN " ⍝ Ignore me  
      ⍝          r←pi n        r←pi n     ⍝ header!
      ⍝          r←○n'         r←○n     " ⍝ Last line
      ⍝     """
        ⎕SE.⍙FIX_TRADFN←{
          0:: ⎕SIGNAL/'∆FIX: ::FIX Directive failed. Likely syntax error in code string.' 11
          0=≢⍵: ∘ ⋄ '⍝ '∊⍨1↑' '~⍨⊃⍵: ∇ 1↓⍵ ⋄ 1:_←2 (0⊃⎕RSI).⎕FIX ⍵      
        }
      ⍝ ⍙PTR for "pointer" prefix $
      ⍝ Syntax:   ${code_operand}   |   $(tacit_operand)  |   $named_operand 
      ⍝     ptr← ⍺⍺:operand ⎕SE.⍙PTR ⍵:0
      ⍝          ⍺⍺:operand: Function to "turn into" a pointer, accessed via ptr.Run
      ⍝           ⍵:debug:   If 0, display form is '[⍙PTR]' (fast).
      ⍝                      If 1, display form is an abridged version of the nested 
      ⍝                      representation of <operand>, up to <MAXL:30> chars (slower).
      ⍝
        ⎕SE.⍙PTR←{ ⍝ Place in ⎕SE, with CALR as ⎕THIS namespace
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
        ⎕SE.∆TO←{⎕IO←0
            2∧.≤≢¨⍺ ⍵: 11 ⎕SIGNAL⍨'⎕TO: range←  start [next] ∆TO end [step=1]. Do not include both ¨next¨ and ¨step¨.'
            ∆←-/end start←⊃¨⍵ ⍺ ⋄ step←(×∆)×|⍺{2=≢⍵: 1⊃⍵ ⋄ 2=≢⍺: -/⍺ ⋄ 1}⍵
            start+step×⍳0⌈1+⌊∆÷step+step=0     
        }
        ⍝ ∆NS (from Adam B's github...).
        ⍝ We don't use this directly in macros, but use '{⍺←⊢⋄⍺⎕SE.∆NS⍵}' to allow myNS.⎕NS 
        ⍝ ∆NS modified to point to caller...    
        ⍝ Not used by default... Problem finding dfn-based variables. Switch this to tradfn... 
        ⎕SE.∆NS←{ ⍝ allows ⎕NS names values
            CALR←⊃⎕RSI,#
            ⍺←⊢ ⍝ default to unnamed namespace
            11::⎕SIGNAL 11
            (0=≢⍵)∨2≥|≡⍵:{_←⍵}⍣(2∊⎕NC'⍺')⊢⍺ CALR.⎕NS ⍵ ⍝ default behaviour
            {_←⍵}⍣(2∊⎕NC'⍺')⊃⊃(⍺⊣⍣(2∊⎕NC'⍺')⊢⍺ CALR.⎕NS ⍬){ ⍝ new behaviour
                (,1)≢(⍴,≡)⍵:⍺⍺⍎⍺,'←⍵ ⋄ ⍺⍺' ⍝ non-⎕OR: use value
                4 11::⍺⍺⍎⍺,'←CALR.⎕NS ⍵ ⋄ ⍺⍺' ⍝ object?
                ⍺⍺⍎⍺,'←⍎CALR.⎕FX ⍵ ⋄ ⍺⍺⊣⍺CALR.{⍺≡⍵:⍬ ⋄ ⎕EX ⍵}CALR.⎕FX ⍵' ⍝ function?
            }¨/⍵
        }
        1
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via StringFormat below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{
      INCLUDE_SCAN EDIT_SCAN FULL_SCAN←2 1 0
      ⍺←FULL_SCAN   ⍝ Default  
  ⍝+-------------------------------------------------+
  ⍝ Mac- routines: Handle Macros (see ::DEF, etc.)   +  
  ⍝+-------------------------------------------------+
  ⍝⍝⍝⍝ FIX ME!!! We should NOT have any DQ or DAQ quotes here!!!
        mâc.K←mâc.V←⍬   ⍝ Set at top...   mâc←⎕NS ''
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
        ⍙K←{ ~'⎕:'∊⍨⊃⊃⌽k←'.'(≠⊆⊢)⍵ :⍵ ⋄ k⊣(⊃⌽k)←⎕C ⊃k }  ⍝ Case ignored for ⎕xxx and :xxx
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
            ~DEBUG: _  
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
        _MacSet←{ par←⍺⍺ ParensNeeded ⍵
            val←AddPar⍣par⊣⍵ 
            nKV←≢mâc.K ⋄ p←mâc.K⍳⊂key←⍙K ⍺       
            p<nKV: val⊣ { ⍵: mâc.V[p]←⊂val ⋄ 1: mâc.(K V)/⍨¨←⊂p≠⍳nKV }⍺≢⍵
            ⍺≡⍵: val ⋄ mâc.(K V),← ⊂¨key val ⋄   val
        }  
      ⍝ MacGet ⍵  -- Return macro defined for ⍵, if found;
      ⍝              Else if ⍵ is complex, i.e. of the form ⍵1.⍵2.⍵3 (etc.), 
      ⍝                  Allow and keep trailing dots, e.g. in:  myns.{⎕NS ⍵}
      ⍝                  Return macro for each ⍵N in ⍵1.⍵2.⍵3, else ⍵N itself
      ⍝              Else return ⍵ itself.
      ⍝              If any ⍵N returns null, do not include a period before or after it.
        MacGet←{dot←'.'
            0=≢⍵: ⍵ 
            p←mâc.K⍳⊂⍙K ⍵ 
            p<≢mâc.K: p⊃mâc.V                   ⍝ Full name found, simple or complex
            dot(~∊)⍵: ⍵                         ⍝ Name is simple...   
            dot=¯1↑⍵: ⎕←{  
              'LOGIC ERROR: APL-style name with trailing dot was presented to macro processing'    
            }⍬
            AddDots←{⍺←'' ⋄ noNull←0(~∊)≢¨⍺ ⍵ ⋄ ,⍺,(noNull/dot),⍵ }  
            ⊃AddDots/∇¨'.'(≠⊆⊢)⍵         ⍝ Name is complex. Check for definitions of the pieces! 
        }
        MacDump← {⎕←⍵⋄ ⎕←(⎕PW-1)↑[1]⎕FMT mâc.(K,[0.2]V) ⋄ ''}
      ⍝ ------END MACROS

  ⍝+-------------------------------------------------+
  ⍝ StringFormat - Format Multiline Strings              +  
  ⍝   DQStrings, Here Strings, and related           +
  ⍝+-------------------------------------------------+
      ⍝ StringFormat: 
      ⍝     Convert possibly multiline strings to the requested format and return as an APL code string.
      ⍝ output_string←  ⍺: options (⍺⍺: indent ∇ ) ⍵: input_string
      ⍝ Output format: options '[cnsvm]'.   
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
            0≠≢err←o~∊o1 o2: 11 ⎕SIGNAL⍨'∆FIX String/Here: One or more invalid options "',err,'" in "',⍺,'"' 
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
        Str2SVsOld←{2=|≡⍵:⍵ ⋄ n←⎕UCS 0 ⋄ p←CR=w←⍵ ⋄ (p/w)←⊂n,CR,n ⋄ n~⍨¨CR(≠⊆⊢)∊w}  
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
            controlScanPats←pIf pElIf pEl pEndIf pInclude pDef1 pDef2 pEvl pStatic pDeclare pDefL pErr pDebug pUCmdC pOther 
                            iIf iElIf iEl iEndIf iInclude iDef1 iDef2 iEvl iStatic iDeclare iDefL iErr iDebug iUCmdC iOther ←⍳≢controlScanPats
            SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇' '↓' '↑'
            Poke←{ ⍵⊣(⊃⌽stack)←⍵ ((⍵=1)∨⊃⌽⊃⌽stack)}
            Push←{ ⍵⊣stack,←⊂⍵ (⍵=1)}
            Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 ⋄ 11 ⎕SIGNAL⍨'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0 }  
            Peek←{(⊃⌽⊃⌽stack)⊃⍵ 1}
            CurStateIs←{⍵∊⍨⊃⊃⌽stack}
            stack←,⊂ON ON
            IN_SKIP←0                      ⍝ IN_SKIP: Used in ControlScanAction/PassState
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
                      ~DEBUG: ''  
                      otherMode: IN_SKIP{ IN_SKIP∘←~⍺ ⋄ ⍺: '' ⋄  COMMENT_PFX,(STATES⊃⍨1+⊃∊⍵) }⍵
                      CR,⍨COMMENT_PFX,(STATES⊃⍨1+⊃∊⍵),tidy pCrFamily ⎕R actionCrFamily ⍠reOPTS⊣¯1↓F 0
                  }
                ⍝ Format for PassDef:   "::SysDefø name←value" with the name /[^←]+/ and a single space as shown.
                ⍝ THis "directive" is passed on to the MainScan
                  PassDef←{(PassState ON),'::SysDefø ' ,(F 1),'←',⍵,CR }    

                  CASE iErr: (¯1↓F 0),'∘∘∘ ⍝ ERR: ⍝ Invalid directive. Prefix :: expected.',CR
                ⍝ ON...
                  CurStateIs ON: {             
                      CASE iOther:      ''               ⍝ A NOP when CurStateIs ON
                      CASE iDef1:       PassDef (F 1)  (1 _MacSet)⊣val←MainScan DTB F 2   
                      CASE iDef2:       PassDef (F 1)  (fVal _MacSet) F 1+fVal←0≠≢F 2 
                      CASE iEvl:        PassDef (F 1)  (1 _MacSet)⊣     Eval2Str MainScan DTB F 2  
                      CASE iStatic:    (PassState ON),(F 1),(F 2),CR,⍨ EvalStatic  MainScan DTB F 3  
                      CASE iDeclare:   (PassState ON),(F 1),(F 2),CR,⍨ EvalDeclare MainScan DTB F 3  
                    ⍝ ::INCLUDE: The recursive ControlScan doesn't know calling env.
                    ⍝            So something goes wrong!
                    ⍝ CASE iInclude:   (PassState ON),_CtlScan (1 ⍙INCLUDE F 1)
                      CASE iInclude:   (PassState ON),0 ⍙INCLUDE F 1  
                      CASE iDefL:       PassDef (F 1)  (0 _MacSet)⊣val←AllQScan DTB F 2    
                      CASE iIf:         PassState Push Eval2Bool MacScan F 1
                      CASE iElIf iEl:   PassState Poke SKIP  
                      CASE iEndIf:      PassState Pop ⍵
                      CASE iDebug:      (F 0),PassState ON⊣DEBUG∘←'off'≢⎕C F 1 
                      CASE iUCmdC:     (PassState ON),{
                                           0=≢⍵:'' ⋄ '⍝> ',CR,⍨⍵     ⍝ Report result, if any...
                                        }Eval2Str'⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2    
                      ∘UNREACHABLE∘
                  }ON
                ⍝ When (CurStateIs OFF or SKIP) for iDef1, iEvl, IDefL, iOther, iStatic    
                  ⍵.PatternNum>iEndIf : (CASE iOther) PassState SKIP    ⍝ CASE iOther: See PassState
                  CurStateIs OFF: {
                      CASE iIf:    PassState Push SKIP  
                      CASE iElIf:  PassState Poke Eval2Bool MacScan F 1
                      CASE iEl:    PassState Poke ON
                      CASE iEndIf: PassState Pop Peek ⍵
                      ∘UNREACHABLE∘ 
                  }OFF
                  1: {⍝ CurStateIs SKIP:
                      CASE iIf:       PassState Push SKIP
                      CASE iElIf iEl: PassState SKIP
                      CASE iEndIf:    PassState Pop Peek ⍵
                  }SKIP
                  ∘UNREACHABLE∘
            } ⍝ ControlScanAction
            save←mâc.(K V) DEBUG                          ⍝ Save macros
            ⍝ Merge continued control lines (ONLY) into single lines.
            ⍝ Note: comments are literals on Control lines.
            pNotCtl←'^\h*([^:]|:[^:])\N*$'
            _CtlScan←{
            lines←pNotCtl pAllQ  pDotsNoCom ⎕R  '\0' '\0' ' ' ⍠reOPTS⊣⍵   
            controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣lines     ⍝ Scan- stack must be empty after Pop
            }
            res←Pop _CtlScan ⍵
            mâc.(K V) DEBUG← save                            ⍝ Restore macros
            res
        } ⍝ ControlScan 

  ⍝+--------------------------------------------------+
  ⍝ MAIN SCANS:   translating code in APL Statements  +  
  ⍝     MainScan - most statements                    +
  ⍝     AtomScan - handle Atoms via ` `` → →→         +
  ⍝+--------------------------------------------------+
  ⍝ BEGIN Experimental  ←←  
  ⍝ EXTENDED ASSIGNMENT:   name_expression ←← val        OR  name_expression   simple_fnal_expression ←← val
  ⍝       becomes:        {⍎name_expression',←⍵'}val        {⍎name_expression,'(simple_fnal_expression)←⍵'}val
  ⍝   list←'name1' 'name2' 'name3' 
  ⍝   list[1]←←val        ⋄  list[3]*←←2
  ⍝ is equiv to (⎕IO=0)
  ⍝   name2←val           ⋄  name3*←2
  ⍝ Note: list[2] or 2⊃list will be treated as equivalent here.
  ⍝ 
  ⍝ Despite the complexity of pASGNX, this is only really useful for simple LHS patterns after the name expr.
  ⍝ No parens, quotes or spaces are matched.
  ⍝      v←'abc'  v[1] ←←5  sets b←5
  ⍝               v[1] +←←3 sets b+←3
  ⍝    
  _q←'+-×÷⌊⌈|*⍟<≤=≥>≠∨∧⍱⍲!?~○'           ⍝ scalar fns  
  _q,←'⌷/⌿\⍀∊⍴↑↓⍳⊂⊃∩∪⊣⊢⊥⊤,⍒⍋⍉⌽⊖⌹⍕⍎⍪≡≢⍷'  ⍝ other fns  
  _q,←'∘⍨¨⍣⍤⍥⍬.'                         ⍝ operators and misc
  pASGNX←'([\d\Q',_q,'\E]*)←←'           ⍝ fns/opts/misc quoted via \Q...\E 
  ⎕SE.⍙ASGNX←{0:: ('SYNTAX ERROR (extended assignment)' ⎕SIGNAL 11
      aa←⍺⍺
      calr←⊃⎕RSI
      fn←{⍺←⎕NC ⍵ ⋄ 3=⍺:'(',')',⍨∊⎕NR ⍵ ⋄ 2=⍺: '' ⋄ }'aa'  ⍝ Error causes signal above.
      1:_←calr⍎(∊⍺),fn,'←⍵'
  }
  ⍝ END Experimental

        mainScanPats← pSysDef pUCmd pDebug pTrpQ pDQPlus pDAQPlus pCom pSQ pDots pHere pHCom pNSEmpty pPtr pNumBase pNum pSink pDump pMacro pASGNX  
                      iSysDef iUCmd iDebug iTrpQ iDQPlus iDAQPlus iCom iSQ iDots iHere iHCom iNSEmpty iPtr iNumBase iNum iSink iDump iMacro iASGNX←⍳≢mainScanPats
        MainScan←{ 
            MainScan1←{ 
                macroSeen∘←0
                mainScanPats ⎕R{  
                    ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                    ⋄ CASE←⍵.PatternNum∘∊      
                       ⍝ ⎕←⍵.PatternNum,': ','<',(F 0),'>'           
                    CASE iTrpQ: {
                      4>≢⍵.Lengths: (F 0),'∘∘ Matching Triple Quote Not Found ∘∘'
                      (F 3) ((≢F 2) StringFormat) F 1
                    }⍵ 
                  ⍝ DQ strings indents are left as is. Use Triple Quotes """ when auto-exdent is needed.
                    CASE iDQPlus:  (F 2) (0 StringFormat)  UnDQ_DAQ F 1     ⍝ Removed DQTweak...
                    CASE iDAQPlus: (F 2) (0 StringFormat)  UnDQ_DAQ F 1                  
                    CASE iDots: ' '   ⍝ Keep: this seems redundant, but can be reached when used inside MainScan                             
                    CASE iPtr:  AddPar  (MainScan F 1),' ⎕SE.⍙PTR ',(⍕DEBUG)⊣SaveRunTime 'NOFORCE'  
                    CASE iSQ: ProcSQ F 0  
                    CASE iCom: F 0                
                  ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts←    :c :l :v :m :s
                  ⍝     F 3: body of here_doc, F 2: opNSEmpty,  4: spaces before end_token, 5: code after end-token 
                    CASE iHere: {  
                      opt← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Get option after each :
                      l1←  opt ((≢F 4 ) StringFormat)  F 3
                      l1 {0=≢⍵~' ':⍺ ⋄ ⍺, CR, MainScan ⍵} F 5     ⍝ If no code after endToken, do nothing more...
                    }0   
                    CASE iHCom: (F 2){
                      kp←0≠≢⍺  ⋄ 0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR
                    } DLB F 5 
                    CASE iMacro:   ⊢MacScan MacGet F 1 ⊣ macroSeen∘←1            
                    CASE iSysDef:  ''⊣ (F 1) (0 _MacSet) F 2                ⍝ SysDef: ::DEF, ::DEFL, ::EVAL on 2nd pass
                    CASE iDebug:   ''⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                  ⍝ CASE iDebug:   (DEBUG/'⍝2⍝ ',F 0)⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                    CASE iNumBase: ∆DEC (F 0)~'_'
                    CASE iNum:     (F 0)~'_'
                    CASE iUCmd:     '⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2   
                    CASE iSink:    (F 1),SINK_NAME,(F 2)    ⍝ F1: blanks (keep alignment), SINK_NAME←
                    CASE iNSEmpty: '(⎕NS⍬)'
                    CASE iDump:    ''⊣MacDump '  MACRO DUMP'  
                    CASE iASGNX:   '(',fn,' ⎕SE.⍙ASGNX)'⊣fn←{0=≢⍵~' ':'0'⋄ ⍵ }F 1
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
            ⍺←0 ⋄ MAX←20 ⋄ count strIn←⍺ ⍵
            count≥MAX: ⍵  ⊣⎕←'∆FIX: MainScan macro replacement limit (',(⍕MAX),') reached. Cyclic macro pattern?'
            strOut←AtomScan MainScan1  strIn ⊣ macroSeen←0
            ~macroSeen: strOut ⋄  strOut≡strIn: strOut ⋄ (count+1) ∇ strOut  
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
      ⍝ >>> PREDEFINED MACROS BEGIN             ⍝ Usage / Info
        mâc.⍙DEF←  mâc.{(≢K)>K⍳⊂⍵}              ⍝   mâc: macro internal namespace
      ⍝ Macro-- alias1 [alias2...] Macro macro_text. 
      ⍝ You can specify 1 or more aliases for the same macro text)
        Mâcro←{(⊆⍺) (0 _MacSet)¨ ⊂ ⍵}
        _←'⎕F'     Mâcro '∆F'                   ⍝   APL-ified Python-reminiscent format function
        _←'⎕TO'    Mâcro '⎕SE.∆TO'              ⍝   1 ⎕TO 20 2   "One to 20 by twos'
        _←'⎕ASSERT' Mâcro '⎕SE.∆ASSERT'
      ⍝ ::DEF. Used in sequence ::IF ::DEF "name"
      ⍝        Returns 1 if <name> is active Macro, else 0. Valid only during Control Scan
      ⍝        Note:  "::DEF macro" undefs <name> (its value is "name"). 
      ⍝ Do <<::DEF name 1>> (among many choices) to ensure  «::IF ::DEF "name"» is true.
        _←'::DEF'  Mâcro 'mâc.⍙DEF'   
      ⍝ ⎕MY - a static namespace for each function... Requires accessible namespace '∆MYgrp' (library ∆MY).
        _←'⎕MY'    Mâcro {
                      STATIC_NS← '⍙⍙'  ⋄ STATIC_PREFIX← STATIC_NS,'.∆MY_'     
                         _←'({0:: ⎕SIGNAL/''Requires library ∆MY'' 11 ⋄  0:: ⍵ ∆MYX 1'
                      _⊣ _,←'⋄ ⍵⍎','''',STATIC_PREFIX,'''',',1⊃⎕SI}(0⊃⎕RSI,#))' 
        }⍬
        _←'⎕TMP' '⎕TEMP' Mâcro SINK_NAME
        _←'::TRADFN' Mâcro (SINK_NAME,'←⎕SE.⍙FIX_TRADFN')
      ⍝  _← '⎕NS' Mâcro  '{⍺←⊢⋄⍺⎕SE.∆NS⍵}'  ⍝ Replace ⎕NS with Enhanced version... 
        _←SaveRunTime 'NOFORCE'
      ⍝ <<< PREDEFINED MACROS END 
 
      pDFnDirective←∆R'[$R]\h*::[^$R]*',pDFn,'[^$R]*[$R]'
    ⍝ FirstScanIn:
    ⍝   1. A DFn started on a ::directive line is detected and treated as part of that line.
    ⍝   2. Visible Strand function (⍮) replaced by current APL (,⍥⊂). 
    ⍝      Mnemonic: Like ';' separates/links items of "equal" status
      FirstScanIn←{  
          Align←    {  ⍵.PatternNum≠0: ⍵.Match ⋄ pDFn pAllQ pCom ⎕R SubAlign ⍠reOPTS⊣⍵.Match }
          SubAlign← {  ⍵.PatternNum≠0: ⍵.Match ⋄ {CR_INTERNAL@ (CR∘=)⊢⍵}¨⍵.Match }
          pDFnDirective pAllQ pCom  ⎕R Align ⍠reOPTS⊣⍵
      }
    ⍝ LastScanOut: Moves DFn directives from single-line to standard multi-line format.
      LastScanOut←{
            ⍺←CR            ⍝ Default for CR_OUT
            pCrIn←'\x01'
            pStrand←'⍮'             ⍝ Explicit "strand" function:  ⍮ --> (,⍥⊂), where  ⍮is U+236E
            pSemi←  ';'             ⍝ Implicit strand function within control of parens...
            pLBrak←'[[(]'  
            pRBrak←'[])]'
            STRAND_OUT SEMI_OUT CR_OUT←'(,⍥⊆)' ';' ⍺ 
            STK←,0     ⍝ Value→Out: 0→Strand (outside parens); 1→Semicolon (in brackets); 2→Strand (in parens)
            iCR iStrand iSemi iLBrak iRBrak← 2 3 4 5 6 
            Align← {  CASE←⍵.PatternNum∘∊   ⋄ str←⍵.Match
              CASE iCR:     CR_OUT
              CASE iStrand: STRAND_OUT 
            ⍝ Top of stack: 0        1          2
              CASE iSemi:   SEMI_OUT STRAND_OUT SEMI_OUT ⊃⍨ ⊃⌽STK
              CASE iLBrak:    str⊣STK,←1+str='['
              CASE iRBrak:    str⊣STK↓⍨←¯1×1<≢STK      ⍝ Don't delete leftmost stack entry (0).
            ⍝ ELSE matches (AllQ Com) 
              str   
            }
            scanPats←  pAllQ pCom pCrIn pStrand pSemi pLBrak pRBrak
            scanPats  ⎕R Align ⍠reOPTS⊣⍵ 
      }
      UserEdit←{⍺←0 ⋄ recurs←⍺
          sep←⊂'⍝>⍝',30⍴' -'
          alt←'⍝ Enter ESC to exit with changes (if any)' '⍝ Enter CTL-ESC to exit without changes' 
          Exit←{
            0:: 'User Edit complete. Unable to fix. See variable #.FIX_FN_SRC.' 
            #.FIX_FN_SRC←(⊂'ok←FIX_FN'),(⊂'ok←''>>> FIX_FN done.'''),⍨'^⍝>' '^\h*(?!⍝)' ⎕R '' '⍝' ⊣⍵
            0=1↑0⍴rc←#.⎕FX #.FIX_FN_SRC: ∘∘err∘∘
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
      InclScan←{¯1↓  ControlScan FirstScanIn (DTB¨⊆⍵),⊂'⍝⍝⍝'}

    ⍝ Include scan? Run only the ControlScan...
      INCLUDE_SCAN=⍺:  InclScan ⍵
    ⍝ Edit scan? UserEdit rt arg; otherwise simply use ⍵.
      EDIT_SCAN=⍺:     UserEdit ⍵ 
    ⍝ Full scan (default)...
      FullScan ⍵
    }  

  ⍝ opts:  e, i, 0, 1, 2.
  ⍝   (0 1 2 → F) Valid ⎕FIX option; e→E (edit);  N (don't fix); H (⍵ has a value); i→I: internal call
    F (E I) H ← opt{(⍺∊⍳3)(⍺='ei')⍵}0<≢⍵
  ⍝ Execute 
  I: (2×I)∘Executive LoadLines⍣H ⊣ ⍵ 
    ↑⍣F⊢⍺ CALR.⎕FIX⍣F ⊣ E∘Executive LoadLines⍣H ⊣ ⍵ 
}