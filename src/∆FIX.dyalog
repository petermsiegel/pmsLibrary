∆FIX←{
  ⍝ See ∆FIX.help for documentation.
  ⍝     result ← options ∆FIX  [filename:@S | lines:@VS]
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
    DEBUG←1 
    ⎕IO ⎕ML←0 1  
    FIX_PFX←'FÍX_'  

  ⍝ See pSink ←
   SINK_NAME←FIX_PFX,'t'
  ⍝ For CR_INTERNAL, see also \x01 in Pattern Defs (below). Used in DQ sequences and for CRs separating DFN lines.
  ⍝ CR_VISIBLE is a display version of a CR_INTERNAL when displayinh preprocessor control statments.
    SQ DQ←'''"' ⋄ CR CR_INTERNAL←⎕UCS 13 01 ⋄  CR_VISIBLE←'◈'  
    CALR←0⊃⎕RSI
    reOPTS←('Mode' 'M')('DotAll' 1)('EOL' 'CR')('UCP' 1)
    0/⍨~DEBUG::  ⎕SIGNAL ⊂⎕DMX.(('EN' EN) ('EM' EM)('Message' Message)('OSError' OSError)) 

  ⍝ Warnings-- only if DEBUG is active...
    ∆WARN←{⍺←1 ⋄ ⍺∧DEBUG: ''⊣⎕←'∆FIX WARNING: ',⍵ ⋄ 1: ''}
  ⍝ Per ⎕FIX, a single vector is the name of a file to be read. We tolerate missing 'file://' prefix.
  ⍝ Add CR to last line to make Regex patterns simpler...
    LoadLines←'file://'∘{ 1<|≡⍵: ⍵ ⋄ ⊃⎕NGET fn 1 ⊣ fn←⍵↓⍨n×⍺≡⍵↑⍨n←≢⍺ }

  ⍝+--------------------------------------------------+
  ⍝ BEGIN Pattern Definitions   (organized by scan)   +
  ⍝+--------------------------------------------------+
  ⍝ Pattern-related Utilities                         +
  ⍝+--------------------------------------------------+
    GenBracePat←{⎕IO←0 ⋄ ⍺←⎕A[,⍉26⊥⍣¯1⊢ ⎕UCS ⍵] ⋄ Nm←⍺  ⍝ ⍺ a generated unique name based on ⍵
          Lb Rb←⍵,⍨¨⊂'\\'                     
          pM←'(?: (?J) (?<Nm> Lb  (?> [^LbRb''"⍝]+ | ⍝\N*\R | (?: "[^"]*")+  | (?:''[^'']*'')+ | (?&Nm)* )+ Rb))'~' '
          'Nm' 'Lb' 'Rb'⎕R Nm Lb Rb⊣pM
    }
    ∆Anchor←{∊'(?xi) ^',⍵,'$\r'}
  ⍝+--------------------------------------------------+
  ⍝ A. MULTIPLE SCANS                                 +
  ⍝+--------------------------------------------------+
    pDotsNoCom ← '(?:\.{2,3}|…)\h*[\r\x01]\h*'
    pDots     ← '(?:\.{2,3}|…)\h*(⍝[^\r\x01]*)?[\r\x01]\h*'
    pDQ       ← '(?:"[^"]*")+' 
    pDAQ      ← '(?:«[^»]*)(?:»»[^»]*)*»'   ⍝ Double Angled Quotes = Guillemets  « »
  ⍝   pSQ       ← '(?:''[^''\r\x01]*'')+'   ⍝ Allow multi-line pSQ.
    pSQ       ← '(?:''[^'']*'')+'           ⍝ Match multiline SQ strings, but detect and warn...
    pAllQ     ← pDQ,'|',pSQ,'|',pDAQ
    pCom      ←'⍝[^\r\x01]*$' 
    pDFn      ← GenBracePat '{}'
    pParen    ← GenBracePat '()' 
    pBrack    ← GenBracePat '[]'
    pBraces3  ← '(?:' pDFn '|' pParen '|' pBrack ')'
  ⍝+--------------------------------------------------+
  ⍝ B.CONTROL SCANS                                   +
  ⍝+--------------------------------------------------+
  ⍝ ControlScan: Process ONLY ::IF, ::ELSEIF, ::ELSE, ::ENDIF, ::DEF, ::DEFL, and ::EVAL statements
  ⍝ These are required to match a SINGLE line each in its entirety OR a line continued explicitly using dot format.
  ⍝ BUG: Does not allow continuation via parens, braces, double quotes, etc.

  ⍝ control CR Family: Multi-line dfns and strings on ::directives. 
  ⍝ \r is carriage return, \x01 is the faux carriage return, 
  ⍝ ◈ is a visible rendering for display purposes distinct from ⋄.
    pCrFamily← '\r\z'  '[\r\x01]'  ⋄ actCrFamily←  '\0' CR_VISIBLE
 
  ⍝⍝⍝ Experimental-- replace pDFn on next 2 lines with pBraces3. 
  ⍝⍝⍝ ... Next, add Dyalog code for extended array definition formats (multiline).
  ⍝⍝⍝    «[^»
    pMULTI_NOCOM ←∊'(?x) (?<NOC> (?> [^\{[(⍝''"«\r]+ |' pAllQ '|' pBraces3          ') (?&NOC)*)'
    pMULTI_COM   ←∊'(?x) (?<ANY> (?> [^\{[(⍝''"«\r]+ |' pAllQ '|' pBraces3 '|' pCom ') (?&ANY)*)'
    pIf          ← ∆Anchor'\h* :: IF         \b \h* (\N+) '
    pElIf        ← ∆Anchor'\h* :: ELSEIF     \b \h* (\N+) '
    pEl          ← ∆Anchor'\h* :: ELSE       \b      \h*  '
    pEndIf       ← ∆Anchor'\h* :: END(?:IF)? \b      \h*  '
  ⍝ For ::DEF (define) of the form  ::DEF name ← value, match after the control word:
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
    pDef1        ← ∆Anchor'\h* :: def  \h+ ((?>[\w∆⍙#.⎕]+)) \h* ← \h*  (' pMULTI_NOCOM '+|) \N* ' 
  ⍝ ::EVAL or synonym ::DEFE 
  ⍝ For ::EVAL (evaluate string value) of form ::EVAL name ← value, match after the control word:
  ⍝     blanks, name*, blanks, ←, optional blanks, any text [excluding leading blanks] up to a comment or EOL,
  ⍝ where name* is a sequence of chars except spaces, ←, or CR. 
  ⍝ The value stored will be determined in the calling namespace CALR as
  ⍝     CALR ⍎ value
  ⍝                                                  F1                            F2
    pEvl         ← ∆Anchor'\h* :: (?:eval|defe)  \h+ ((?>[\w∆⍙#.⎕]+))    \h* ← \h? (' pMULTI_NOCOM '+|) \N* '   
  ⍝ ::STATIic name ← value
  ⍝ ::DECLare name ← value
  ⍝    name:      An APL run-time variable
  ⍝    variable:  A Dyalog code value OR a Dyalog new Array or Namespace declaration on one or more lines.
  ⍝ Simple APL declarations are allowed. 
  ⍝    ::DECLARE time ← ⎕TS    ⍝ This will execute at run-time (each time statement is reached).
  ⍝    ::STATIC  time ← ⎕TS    ⍝ This will be replaced by its value at ∆FIX/⎕FIX ("compile") time (exactly once).
  ⍝ More complex declarations may extend over multiple lines or use statment separators (⋄),
  ⍝ using double-quoted multi-line strings, complex declarations in brackets [] or parentheses [].
  ⍝    ::DECLARE multiLater ← [ 'iota10   ⋄ ⍳10  ⍝ Creates a declaration to be evaluated at run-time
  ⍝                             'revAlph' ⋄ ⌽⎕A
  ⍝                             'when'    ⋄ ⎕TS  ⍝ Changes on each call, if internal to a object.
  ⍝                          ]
  ⍝    ::STATIC multiNow ←   [ 'iota10   ⋄ ⍳10   ⍝ Creates a  declaration evaluated at ∆FIX time.
  ⍝                            'revAlph' ⋄ ⌽⎕A
  ⍝                            'when'    ⋄ ⎕TS   ⍝ Set as a constant, when an object is ∆FIXed.
  ⍝                         ]
  ⍝     ::STATIC variables have access only to named objects created earlier in the same session.
  ⍝
  ⍝  EXAMPLE:
  ⍝  ¯¯¯¯¯¯¯¯
  ⍝>       2 ∆FIX '(TS TSS)←test' '::DECLARE TS ← ⎕TS' '::STATIC TSS ← ⎕TS'
  ⍝>       ⎕CR 'test'              ⍝ Show resulting code from ∆FIX.
  ⍝   (TS TSS)←test                     
  ⍝   ⍝↑::DECLARE TS ← ⎕TS      
  ⍝   TS←⎕TS                       ⍝ Note: Code executed at run-time on each function call.
  ⍝   ⍝↑::STATIC TSS ← ⎕TS      
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
    pStatic      ← ∆Anchor'\h* :: (?:stat(?:ic )?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pMULTI_NOCOM '+|) \N* ' 
    pDeclare     ← ∆Anchor'\h* :: (?:decl(?:are)?) \h  (\h*(?>[\w∆⍙#.⎕]+)) \h* ([∘⊢]?←) \h? (' pMULTI_NOCOM '+|) \N* ' 
  ⍝ For ::DEFL (literal) of the form ::DEFL name ← value, match after the ctl word: 
  ⍝      blanks, word*, blanks, ← optional blank, value*
  ⍝ where word* defined as above and value* includes everything up to the EOL, including leading and internal blanks.
  ⍝ The value will not be enclosed in parentheses.
    pDefL        ← ∆Anchor'\h* :: defl \h+ ((?>[\w∆⍙#.⎕]+)) \h* ← \h? (' pMULTI_COM '|) '  
  ⍝ For ::DEF of forms:   
  ⍝     ::DEF name    OR    ::def name value  
  ⍝ we match after the ctl word:
  ⍝ I.     blanks, name*  which is translated to: ::DEF name1* ← name1*
  ⍝    where name* and name1* defined as name* above, name1* the same in both cases.
  ⍝    This is equivalent to undefining name*, i.e. replacing it with itself.
  ⍝ II.    blanks, name*, blanks, value
  ⍝    where name* as above and value* consists of all text to the end of the line, excluding leading blanks.
  ⍝    This is equivalent to ::def name ← value above.
    pDef2       ← ∆Anchor'\h* :: (?:def) \h+ ((?>[^\h←\r]+)) \h*? ( [^\h\r]* )'
  ⍝ :DEF, :DEFL (literal), :EVAL (:DEFE, def and eval)  are errors.
    pErr        ← ∆Anchor'\h* :(def[el]?|eval) \b \N* '
    pDebug      ← ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
    pUCmdC      ← ∆Anchor '\h*::(\]{1,2})\h*(\N+)'            ⍝ ::]user_commands or  ::]var←user_commands
    pOther      ← ∆Anchor'\N*' 
  ⍝+-----------------------------------+
  ⍝ C. MAIN SCAN PATTERNS              +  
  ⍝+-----------------------------------+
    pSysDef     ←  ∆Anchor'^::SysDefø \h ([^←]+?) ← (\N*)'   ⍝ Internal Def simple here-- note spelling
    pUCmd       ← '^\h*(\]{1,2})\h*(\N+)$'                    ⍝ ]user_commands or  ]var←user_commands
    pDebug      ← ∆Anchor'\h* ::debug \b \h*  (ON|OFF|) \h* '
  ⍝ """...""".  F1: string, F2: leading blanks on matching line, F3: suffixes. 
  ⍝ """...""".  2nd alternative will trigger an error-- F2 and F3 won't have a value...
    pTrpQ       ← '"""(?|\h*\R(.*?)\R(\h*)"""([a-z]*)|)'    
    pDQPlus     ← ∊'(?xi) (' pDQ ') ([a-z]*)'
    pDAQPlus    ← ∊'(?xi) (' pDAQ') ([a-z]*)'      ⍝ DAQ: Guillemet Quotes! « »
    pWord       ← '[\w∆⍙_#.⎕]+'
    pPtr        ← ∊'(?ix) \$ \h* (' pParen '|' pDFn '|' pWord ')'
    _pHMID      ← '( [\w∆⍙_.#⎕]+ :? ) ( \N* ) \R ( .*? ) \R ( \h* )'
  ⍝ Here-strings and Multiline ("Here-string"-style) comments 
    pHere       ← ∊'(?x)       ::: \h*   '_pHMID' :? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) $'   ⍝ Match just before newline
    pHCom       ← ∆Anchor∊'\h* ::: \h* ⍝ '_pHMID' ⍝? \1 (?! [\w∆⍙_.#⎕] ) :? \h? (\N*) '
    pNumBase    ← '(?xi) 0 [xbo] [\w_]+'
    pNum        ← '(?xi) (?<!\d)   (¯? (?: \d\w+ (?: \.\w* )? | \.\w+ ) )  (j (?1))?'
    pSink←'(?xi) (?:^|(?<=[]{(⋄\x01:]))(\h*)(←)'   ⍝ \x01: After CR_INTERNAL (dfn-internal CR)
    pMacro      ← {
        APL_LET1←'ABCDEFGHIJKLMNOPQRSTUVWXYZÀÁÂÃÅÈÉÊËÒÓÔÕÖØÙÚÛÄÆÜÌÍÎÏÐÇÑ∆⍙_#'
        _pVarName← '(?i)[',APL_LET1,'][⎕.\d',APL_LET1,']*'
        _pMac←'(?:[]⎕]|:{1,2}|)',_pVarName     ⍝ OK: ::NAME, ⎕NAME, ]NAME
        _pMac
    }⍬
  ⍝+-----------------------------------+
  ⍝ D. ATOM SCAN PATTERNS              +  
  ⍝+-----------------------------------+
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
    pAtomList     ← ∊'(?x) (`{1,2})  \h* ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ )'     
    pAtomsArrow  ← ∊'(?x) ( (?> ' pSQ ' \h* | [\w∆⍙_#\.⎕¯]+  \h*  )+ ) (→{1,2}) '          
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
  ⍝ Read hex, binary, octal numbers (e.g. 0x09DF, 0b0111, and 0o0137), converting to decimal.
  ⍝ Converts up to 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF (28 hex digits) as integer strings.
  ⍝ Returns right arg (⍵) if  
  ⍝      (a) not a known base (b|o|x) (b: 2, o: 8, x: 16); (b) number is negative, or (c) digits are out of range,
  ⍝ or if it can't represent in an integer of 34 decimal digits...
    ∆DEC←{⎕PP ⎕FR←34 1287  ⍝ Ensures largest # of decimal digits.
        canon←⎕C ⍵ 
        0=base←2 8 16 0['box'⍳1↑1↓canon]: ⍵    ⋄ '0'≠⊃canon: ⍵
        res←(base↑'0123456789abcdef')⍳2↓canon  ⋄ ∨/res≥base: ⍵
        'E'∊res←⍕base⊥res: ⍵ ⋄ res
    }
  ⍝ SaveRunTime:  SaveRunTime ['FORCE' | 'NOFORCE']
  ⍝ Save Run-time Utilities in ⎕SE if not already...
  ⍝     ⎕SE.⍙PTR
  ⍝ CALR.⎕PATH←1↓∊' ',¨∪'⎕SE',' '(≠⊆⊢)CALR.⎕PATH
    SaveRunTime←{utils utype←↓⍉↑('⍙PTR' 4) ('∆TO' 3) 
        (~DEBUG)∧(⍵≡'FORCE')∧utype∧.=⎕SE.⎕NC ↑utils: 0 
        2/⍨~DEBUG:: 11 ⎕SIGNAL⍨'∆FIX: Unable to set utilities: ⎕SE.(',utils,')'
      ⍝  Runtime Ptr. See $ Ptr prefix: ${operand}, $(operand), $operand_name...
      ⍝     ptr← ⍺⍺:operand ⎕SE.⍙PTR ⍵:0
      ⍝          ⍺⍺:operand: Function to "turn into" a pointer, accessed via ptr.Run
      ⍝           ⍵:debug:   If 0, display form is '[⍙PTR]' (fast).
      ⍝                      If 1, display form is an abridged version of the nested 
      ⍝                      representation of <operand>, up to 30 chars (slower).
      ⍝
      ⍝ Was: ⎕SE.⍙PTR←{(ns←⎕NS '').Run←⍺⍺ ⋄ ns⊣ns.⎕DF '[⍙PTR]'}
        ⎕SE.⍙PTR←{ ⍝ Place in ⎕SE, with CALR as ⎕THIS namespace
            0::'$ POINTER DOMAIN ERROR'⎕SIGNAL 11 
            MAXL←30
            (ns←⎕NS'').Run←⍺⍺ ⋄ _←ns.⎕FX 'r←Exec' 'r←Run ⍬'
            0=⍵: ns⊣ns.⎕DF'[$⍙PTR]'
            Fit←MAXL∘{⍺>≢⍵:⍵ ⋄ '⋯',⍨⍵↑⍨⍺-1}    
            Shrink←{'^Run←' '\{⋄' '⋄\}' '\h+⋄\h+'⎕R'' '{' '}' '⋄'⊣¯1↓∊'⋄',⍨¨⍵} 
            Dlb←{⍵↓⍨+/∧\' '=⍵}¨  ⋄ Sane←{0<≢⍵: ⍵ ⋄ err∘}     
            ns⊣ns.⎕DF '[$', (Fit Shrink Dlb Sane⊆ns.⎕NR 'Run'), ']'
        }
        ⍝ range ← start [next]  ∆TO  end [step]   
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
            2∧.≤≢¨⍺ ⍵: 11⎕SIGNAL⍨'⎕TO: range ← start [next] ∆TO end [step=1]. Do not include both ¨next¨ and ¨step¨.'
            (start next)(end step)←2↑¨⍺ ⍵ ⋄ step←(×∆←end-start)×|1↑(2=≢⍺)↓step,(start-next)
            start+step×⍳0⌈1+⌊∆÷step+step=0     
        }
        ⎕←'SaveRunTime called'
        1
    }
  ⍝ Executive: Search through lines (vector of vectors) for: 
  ⍝     "double-quoted strings", triple-quoted ("""\n...\n"""), and  ::: here-strings.
  ⍝     Return executable APL single-quoted equivalents, encoded into various format via StringFormat below.
  ⍝     Returns one or more vectors of vectors... (Use ⊃res if one line expected/required).
    Executive←{⍺←0   ⍝ If 1, Edit for input...
    
  ⍝+-------------------------------------------------+
  ⍝ Mac- routines: Handle Macros (see ::DEF, etc.)   +  
  ⍝+-------------------------------------------------+
  ⍝⍝⍝⍝ FIX ME!!! We should NOT have any DQ or DAQ quotes here!!!
        mâc.K←mâc.V←⍬ ⊣  mâc←⎕NS ''
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
      ⍝ val ← ⍙K key, key: a string.
        ⍙K←{ ~'⎕:'∊⍨⊃⊃⌽k←'.'(≠⊆⊢)⍵ :⍵ ⋄ k⊣(⊃⌽k)←⎕C ⊃k }  ⍝ Case ignored for ⎕xxx and :xxx
      ⍝ val ← key (flag _MacSet) val
      ⍝   flag=0:  Sets macro <key> to have value <val>, a string.         See :DEF
      ⍝   flag=1:  Sets macro <key> to have value '(',<val>,')', a string. See :DEFL
      ⍝            Special case: If <val> is a nullstring, value is <val> alone (no parentheses).
        AllQScan←{
            iDQ     iDAQ     iSQ iCom ←⍳4
            pDQPlus pDAQPlus pSQ pCom ⎕R { 
              F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}  
              CASE←⍵.PatternNum∘∊  
            ⍝ SQ: No suffixes or multiline strings allowed. Warning only???
              CASE iSQ: ProcSQ F 0     
              CASE iCom: F 0
              (F 2) (0 StringFormat) UnDQ_DAQ F 1         ⍝ Convert double [angle] quotes
            }⍠reOPTS⊣⍵
        }
        ProcSQ←{ ⍝ SQ Strings don't allow multiple lines or suffix chars.
            wMsg←'Multi-line std (single-quote) APL Strings disallowed'
            multi←1∊CR CR_INTERNAL∊⍵
            ('v' (0 StringFormat) 1↓¯1↓⍵) ⊣ multi ∆WARN wMsg
        }
      ⍝ ⍺ (⍺⍺ _MacSet) ⍵. Set key <⍺> to have value <⍵>, or ⍺ if key <⍺> doesn't exit.
      ⍝ If ⍺≡⍵, delete key <⍺>.
      ⍝ If ⍺⍺=1, put ⍵ in parens, unless ⍵ is a non-simple "expression" 
      ⍝          i.e. neither an APL user/system name, number, or null.
      ⍝ NonSimple: returns 0 for ⍵: FrEd, #.JaCk, FrEd.Jack, ⎕SE, 12345J45 123.45J¯4 ⎕IO 
      ⍝                             "Fred Jack"  "1 2"   "3 PI R"
      ⍝            returns 1 for ⍵: "",  "FRED+JACK", ":DIRECTIVE"
        NonSimple←{¯1=⎕NC ⊂'X',⍵~'⎕#.¯ '}  
        _MacSet←{ par←⍺⍺∧NonSimple ⍵
            val←AddPar⍣par⊣⍵ 
            nKV←≢mâc.K ⋄ p←mâc.K⍳⊂key←⍙K ⍺       
            p<nKV: val⊣ { ⍵: mâc.V[p]←⊂val ⋄ 1: mâc.(K V)/⍨¨←⊂p≠⍳nKV }⍺≢⍵
            ⍺≡⍵: val ⋄ mâc.(K V),← ⊂¨key val ⋄   val
        }  
      ⍝ MacGet ⍵  -- Return macro defined for ⍵, if found;
      ⍝              Else if ⍵ is complex, i.e. of the form ⍵1.⍵2.⍵3 (etc.), 
      ⍝                  Return macro for each ⍵N in ⍵1.⍵2.⍵3, else ⍵N itself
      ⍝              Else return ⍵ itself.
      ⍝              If any ⍵N returns null, do not include a period before or after it.
        MacGet←{
            0=≢⍵: ⍵ 
            p←mâc.K⍳⊂⍙K ⍵ 
            p<≢mâc.K: p⊃mâc.V          ⍝ Full name found, simple or complex
            '.'(~∊)⍵: ⍵                ⍝ Name is simple...    
            AddDots←{⍺←'' ⋄ noNull←0(~∊)≢¨⍺ ⍵ ⋄ ⍺,(noNull/'.'),⍵ }   
            ⊃AddDots/∇¨'.'(≠⊆⊢)⍵       ⍝ Name is complex. Check for definitions of the pieces! 
        }
      ⍝ ------END MACROS

  ⍝+-------------------------------------------------+
  ⍝ StringFormat - Format Multiline Strings              +  
  ⍝   DQStrings, Here Strings, and related           +
  ⍝+-------------------------------------------------+
      ⍝ StringFormat: 
      ⍝     Convert possibly multiline strings to the requested format and return as an APL code string.
      ⍝ output_string ← ⍺: options (⍺⍺: indent ∇ ) ⍵: input_string
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
            o1 o2 od ←'rnsvm' 'ecx' DEF_TYPE  ⋄ o←(o1{1∊⍵∊⍺⍺: ⍵ ⋄ ⍵⍵,⍵}od)⊣⎕C ⍺
          ⍝ R: CRs    N: LFs    S: Spaces   V: Vectors   M: Matrix
          ⍝ E: Escape (\)       C: Comment (⍝)
            R N S V M E C X←o∊⍨∊o1 o2
            0≠≢err←o~∊o1 o2: 11 ⎕SIGNAL⍨'∆FIX String/Here: One or more invalid options "',err,'" in "',⍺,'"' 
            indent←X⊃⍺⍺  ¯1   ⍝ Allow for x (exdent option)
            C: ' '
            SlashScan←  { '\\(\r|$)'⎕R' '⍠reOPTS⊣⍵ }  ⍝ backsl + EOL  => space given e (escape) mode.
          ⍝ Str2SVs: Ensures a vector of strings.
          ⍝       ⍵: Vector of strings or a single flat string with CRs.
          ⍝ Note: Ensure split sees "\rabc as 2 lines, not 1 line; ditto abc\r"; ditto abc\r\rdef'
            Str2SVs←{2=|≡⍵:⍵ ⋄ n←⎕UCS 0 ⋄ p←CR=w←⍵ ⋄ (p/w)←⊂n,CR,n ⋄ n~⍨¨CR(≠⊆⊢)∊w}                
            TrimL←     { 0=⍺: ⍵ ⋄ 0=≢⍵: ⍵ ⋄ lb←+/∧\' '=↑⍵  ⋄  ⍺<0: ⍵↓⍨¨lb⌊⌊/lb ⋄ ⍵↓⍨¨lb⌊⍺ }   
            FormatPerOpt← {multi←⍺
             ⍝  0=≢⍵: 2⍴SQ
              AddSQ←SQ∘,∘⊢,∘SQ 
              V∨M: ('↑'/⍨M∧multi) ,¯1↓∊' ',⍨∘AddSQ¨ ⍵ ⋄  S: AddSQ 1↓∊' ',¨⍵ 
              R∨N: AddSQ ∊{⍺,nlc,⍵}/⍵ ⊣ nlc←SQ,',(⎕UCS ',(⍕R⊃10 13 ),'),',SQ  
              ∘Unreachable∘  
            }
            0=≢⍵: 2⍴SQ
            multi←1<≢lines←Str2SVs ⍵  ⍝ Don't add parens, if just one line...
            AddPar⍣(multi∧~V)⊣ multi FormatPerOpt (SlashScan⍣E)DblSQ¨ indent∘TrimL lines
        }
      ⍝ See iDQPlus (below) and StringFormat above...
      ⍝ We add a "spurious" CR_INTERNAL so StringFormat sees leading and trailing bare " on separate lines... 
      ⍝ DQTweak←CR_INTERNAL∘{ (⍺/⍨CR=⊃⍵),⍵,⍺/⍨CR=⊃⌽⍵ }   
      ⍝ DQUntweak←{⍵~¨CR_INTERNAL}        

  ⍝+-------------------------------------------------+
  ⍝ Other Routines                                   +
  ⍝+-------------------------------------------------+ 
      ⍝ pat ← GenBracePat ⍵, where ⍵ is a pair of braces: ⍵='()', '[]', or '{}'.  
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
        Eval2Str←CALR∘{ 0:: ⍵,' ∘EVALUATION ERROR∘'  ⋄ res2←⎕FMT res←⍺⍎'⋄' DFnScanOut ⍵  
           ⍝  0≠80|⎕DR res: 1↓∊CR,res2 ⋄ ,1↓∊CR,¨SQ,¨SQ,⍨¨{ ⍵/⍨1+⍵=SQ }¨↓res2
           0≠80|⎕DR res: 1↓∊CR,res2 ⋄ ,1↓∊CR,¨1∘DblSQ¨↓res2
        } _MaxPrecision CALR
      ⍝ Eval2Bool: Execute and return 1 True, 0 False, ¯1 Error.
        Eval2Bool←CALR∘{0:: ¯1  ⋄ (,0)≡v←,⍺⍎'⋄' DFnScanOut ⍵: 0 ⋄  (0≠≢v)}  

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
            doc ← pSQ pCom ⎕R '&' ''⍠'Mode' 'M'⊣⍵  ⍝ Remove comments
            doc ← 1∘DblSQ '⋄'@(CR∘=)⊣ doc          ⍝ Enquote and escape internal quotes
            ⍺⍎'0 ⎕SE.Link.Deserialise ', doc       ⍝ Convert to Dyalog deserialized code...
        } 
        EvalDeclare←_EvalDeclare _MaxPrecision CALR 

  ⍝+-------------------------------------------------+
  ⍝ Control Scans - handle :: Directives             +  
  ⍝+-------------------------------------------------+
        ControlScan←{ 
          ⍝ |< ::Directive    Conditionals     >|<  ::Directive Other                             >|< APL code
            controlScanPats←pIf pElIf pEl pEndIf pDef1 pDef2 pEvl pStatic pDeclare pDefL pErr pDebug pUCmdC pOther
                            iIf iElIf iEl iEndIf iDef1 iDef2 iEvl iStatic iDeclare iDefL iErr iDebug iUCmdC iOther←⍳≢controlScanPats
            SKIP OFF ON←¯1 0 1 ⋄ STATES←'∇' '↓' '↑'
            Poke←{ ⍵⊣(⊃⌽stack)←⍵ ((⍵=1)∨⊃⌽⊃⌽stack)}
            Push←{ ⍵⊣stack,←⊂⍵ (⍵=1)}
            Pop←{0<s←≢stack: ⍵⊣stack↓⍨←¯1 ⋄ 11 ⎕SIGNAL⍨'Closing "::ENDIF" not found' 'Extra "::ENDIF" detected'⊃⍨s=0 }  
            Peek←{(⊃⌽⊃⌽stack)⊃⍵ 1}
            CurStateIs←{⍵∊⍨⊃⊃⌽stack}
            stack←,⊂ON ON
            ControlScanAction←{
                  F←⍵.{0:: '' ⋄ Lengths[⍵]↑Offsets[⍵]↓Block}
                  CASE←⍵.PatternNum∘∊ 
                  PassState←{ ⍺←0 ⋄ ~DEBUG: ''  
                    ⍝ ControlScan: Keep final CR; otherwise: CR and CR_INTERNAL become display_CR 
                    ⍝ See:  pCrFamily,  actCrFamily above.
                     '⍝', (STATES⊃⍨1+⊃∊⍵), pCrFamily ⎕R actCrFamily ⍠reOPTS⊣F 0  
                  }
                ⍝ Format for PassDef:   "::SysDefø name←value" with the name /[^←]+/ and a single space as shown.
                  PassDef←{(PassState ON),'::SysDefø ' ,(F 1),'←',⍵,CR }    

                  CASE iErr: (¯1↓F 0),'∘∘∘ ⍝ ERR: ⍝ Invalid directive. Prefix :: expected.',CR
                ⍝ ON...
                  CurStateIs ON: {   chk←{⎕←'<',⍵,'>' ⋄ ⍵}
                      CASE iOther:      F 0  
                      CASE iDef1:       PassDef (F 1)  (1 _MacSet)⊣val←MainScan DTB F 2   
                      CASE iDef2:       PassDef (F 1)  (fVal _MacSet) F 1+fVal←0≠≢F 2 
                      CASE iEvl:        PassDef (F 1)  (1 _MacSet)⊣     Eval2Str MainScan DTB F 2  
                      CASE iStatic:     (PassState ON),(F 1),(F 2),CR,⍨ EvalStatic  MainScan DTB F 3  
                      CASE iDeclare:    (PassState ON),(F 1),(F 2),CR,⍨ EvalDeclare MainScan DTB F 3  
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
                  ⍵.PatternNum>iEndIf : PassState SKIP    
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
              lines←pNotCtl pAllQ  pDotsNoCom ⎕R  '\0' '\0' ' ' ⍠reOPTS⊣⍵      
              res←Pop controlScanPats ⎕R ControlScanAction ⍠reOPTS⊣lines     ⍝ Scan- stack must be empty after Pop
            mâc.(K V) DEBUG← save                            ⍝ Restore macros
            res
        } ⍝ ControlScan 
  
  ⍝+--------------------------------------------------+
  ⍝ MAIN SCANS:   translating code in APL Statements  +  
  ⍝     MainScan - most statements                    +
  ⍝     AtomScan - handle Atoms via ` `` → →→         +
  ⍝+--------------------------------------------------+
        mainScanPats← pSysDef pUCmd pDebug pTrpQ pDQPlus pDAQPlus pCom pSQ pDots pHere pHCom pPtr pMacro pNumBase pNum pSink
                      iSysDef iUCmd iDebug iTrpQ iDQPlus iDAQPlus iCom iSQ iDots iHere iHCom iPtr iMacro iNumBase iNum iSink←⍳≢mainScanPats
        MainScan←{
            MainScan1←{  
                mainScanPats ⎕R{  
                    ⋄ F←⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
                    ⋄ CASE←⍵.PatternNum∘∊                 
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
                  ⍝ ::: ENDH...ENDH  Here-doc  Y   Via Opts   ← :c :l :v :m :s
                  ⍝     F 3: body of here_doc, F 2: opns,  4: spaces before end_token, 5: code after end-token 
                    CASE iHere: {  
                      opt← {⍵/⍨¯1⌽⍵=':'}F 2                       ⍝ Get option after each :
                      l1←  opt ((≢F 4 ) StringFormat)  F 3
                      l1 {0=≢⍵~' ':⍺ ⋄ ⍺, CR, MainScan ⍵} F 5     ⍝ If no code after endToken, do nothing more...
                    }0   
                    CASE iHCom: (F 2){
                      kp←0≠≢⍺  ⋄ 0=≢⍵~' ': kp/'⍝',⍺ ⋄ (kp/'⍝',⍺,CR),('⍝ '/⍨'⍝'≠⊃⍵), ⍵,CR
                    } DLB F 5 
                    CASE iMacro:  ⊢MacScan MacGet F 0                     
                    CASE iSysDef: ''⊣ (F 1) (0 _MacSet) F 2                ⍝ SysDef: ::DEF, ::DEFL, ::EVAL on 2nd pass
                    CASE iDebug:  ''⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                  ⍝ CASE iDebug:  (DEBUG/'⍝2⍝ ',F 0)⊣ DEBUG∘←'off'≢⎕C F 1     ⍝ Turns ∆FIX's debug on or off. Otherwise ignored...
                    CASE iNumBase: ∆DEC (F 0)~'_'
                    CASE iNum:     (F 0)~'_'
                    CASE iUCmd:     '⎕SE.UCMD ',1 DblSQ ('←'/⍨2=≢F 1),F 2   
                    CASE iSink:    (F 1),SINK_NAME,(F 2)    ⍝ F1: blanks (keep alignment), SINK_NAME←
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
            AtomScan MainScan1  ⍵
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
        mâc.⍙DEF← mâc.{(≢K)>K⍳⊂⍵}              ⍝   mâc: macro internal namespace
        mâc.⍙DUMP← mâc.{K,[-0.2]V}
        macro←(0 _MacSet)
        _←'⎕F'     macro '∆F'                   ⍝   APL-ified Python-reminiscent format function
        _←'⎕TO'    macro '⎕SE.∆TO'              ⍝   1 ⎕TO 20 2   "One to 20 by twos'
      ⍝ ::DEF. Used in sequence ::IF ::DEF "name"
      ⍝        Returns 1 if <name> is active Macro, else 0. Valid only during Control Scan
      ⍝        Note:  "::DEF macro" undefs <name> (its value is "name"). 
      ⍝ Do <<::DEF name 1>> (among many choices) to ensure  «::IF ::DEF "name"» is true.
        _←'::DEF'  macro 'mâc.⍙DEF'            
      ⍝ ⎕MY - a static namespace for each function... Requires accessible namespace '∆MYgrp' (library ∆MY).
        _←'⎕MY'    macro {
                      STATIC_NS← '⍙⍙'  ⋄ STATIC_PREFIX← STATIC_NS,'.∆MY_'     
                         _←'({0:: ⎕SIGNAL/''Requires library ∆MY'' 11 ⋄  0:: ⍵ ∆MYX 1'
                      _⊣ _,←'⋄ ⍵⍎','''',STATIC_PREFIX,'''',',1⊃⎕SI}(0⊃⎕RSI,#))' 
        }⍬
        _←'⎕TMP'  macro SINK_NAME
        _←SaveRunTime 'NOFORCE'
      ⍝ <<< PREDEFINED MACROS END 

      DFnScanIn←{ pDFn pAllQ pCom ⎕R { iDFn←0
          F0←⍵.Match ⋄  iDFn≠⍵.PatternNum: F0 ⋄ {CR_INTERNAL@ (CR∘=)⊢⍵}¨F0 
      }⍠reOPTS⊣⍵ }
      DFnScanOut←{⍺←CR ⋄ ⍺{ ⍺@ (CR_INTERNAL∘=)⊢⍵ }¨⍵}
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
      FullScan←{¯1↓ DFnScanOut MainScan ControlScan DFnScanIn (DTB¨⊆⍵),⊂'⍝⍝⍝'}

    ⍝ If ⍺=1, UserEdit for rt arg; otherwise simply use ⍵.
      ⍺:  UserEdit ⍵ 
          FullScan ⍵
    }  

  ⍝ opts:  S (std): Valid ⎕FIX option; E (edit);  N (don't fix); H (⍵ has a value).
    ⍺←0 ⋄ F E H← (⍬⍴⍺){(⍺∊⍳3)(⍺='e')⍵}0<≢⍵
  ⍝ Execute 
    ⍺ CALR.⎕FIX⍣F ⊣ E∘Executive LoadLines⍣H ⊣ ⍵ 
}