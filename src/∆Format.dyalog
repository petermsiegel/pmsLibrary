∆F←{ ⍝ See SYNTAX under HELP INFORMATION (below) for arguments and call specifications.
  0:: ('∆F ',⎕DMX.EM )⎕SIGNAL ⎕DMX.EN  
  ⎕IO←0 ⋄ ⍺←⍬         ⍝ Same as 'Default'
  0≠80|⎕DR ⊃⊆⍵: 11 ⎕SIGNAL⍨ '∆F DOMAIN ERROR: First Element of Right Arg not a valid Format String'
⍝ If ⍺ is an assertion (⍺ is numeric) and contains at least one 0 (is false), return immediately with shy 0 (false).
  ⍺{⍵: 0∊⍺ ⋄ 0 } 2|⎕DR ⍺: _←0    ⍝ ASSERT_FALSE

⍝ Otherwise, move us to a private namespace in the # domain.
  ⍺ (#.⎕NS '').{  
  ⍝ Section ********* SUPPORT FUNCTION DEFINITIONS
  ⍝ General Functions
    ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
        def←'' ⋄ isN←0≠⍬⍴0⍴⍵ ⋄ p←N⍳∘⊂⍣isN⊣⍵ 
        0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def ⋄ B[O[p]+⍳L[p]] 
    }
    DebugDisplay← ('·'@(' '∘=))∘⎕SE.Dyalog.Utils.display
    LoadRuntimeLib←{⍺←COMPILE
        ~⍺∧⍵: 0
        ⎕←↑'>> LOADING RUNTIME LIB "⎕SE.⍙FLÎB"' '>> UTIL FNS ARE: JOIN, ⍙;  FMTX; DISP'
        ⎕SE.⍙FLÎB←⎕SE.⎕NS ''
        ⎕SE.⍙FLÎB.JOIN← JOIN
        ⎕SE.⍙FLÎB.⍙← JOIN      ⍝ Short version of "join"
        ⎕SE.⍙FLÎB.FMTX← FMTX
        ⎕SE.⍙FLÎB.DISP← DISP
        0
    }
  ⍝ SetOptions: Passed the options (user argument ⍺), which may have an assertion (boolean array) or option strings.
    ⍝ If an assertion that is false (has at least one 0), it is already detected at the start of the fn (to be fast).
    ⍝ Otherwise...   
    ⍝   Returns 4 booleans: ASSERT_TRUE DEBUG COMPILE HELP
    ⍝ where:
    ⍝   ASSERT_TRUE:  ⍵ is numeric, but containing no 0s.
    ⍝ and, for option strings, case is ignored and abbreviations are allowed:
    ⍝   DEBUG (D):      Fields are displayed in boxes to see how they are formed. IGNORED if COMPILE=1.
    ⍝   COMPILE (C):    Result is emitted as a string containing code c, 
    ⍝                   such that (⍎c)⍵ will produce the same as the default result.
    ⍝   HELP (H):       Enters help mode (⎕ED). Returns ⍬. 
    ⍝   DEFAULT (DE):   Result is formatted as a char matrix and returned. The default.
    ⍝ If none of the above is set, the DEFAULT is inferred from: (~DEBUG∨COMPILE∨HELP).
    SetOptions← 'debug' 'compile' 'help' 'default'∘{ 
        0=≢⍵:0 0 0 0 ⋄ 2|⎕DR ⍵:1 0 0 0 
        p←⍺∘{(⎕C(≢⍵)↑¨⎕C ⊆⍺)⍳⊂,⍵}¨⎕C ⊆⍵
        Whoops←{'∆F DOMAIN ERROR: Invalid option(s): ',¯2↓∊(⊂'", '),⍨¨'"',¨⍺/⊆⍵}
        1∊bad←p≥≢⊆⍺:11 ⎕SIGNAL⍨bad Whoops ⍵
        0,¯1↓1@p⊢4⍴0          ⍝ default is implicit,  not returned. It's (~debug∨compile∨help)
    }
    Help←{
      ⍝ Help... Show HELP info and return ⍵
      ⍵⊣{ help←'^⍝H((?: .*)?)$' ⎕S '\1' ⊣⍵ ⋄ ''⊣⎕ED 'help' } ⎕NR 0⊃⎕XSI
    }
  ⍝ Functions Manipulating "Globals": gRESULT(RW), gOMEGA_CUR(RW), nOMEGA(W)
    gRESULT_Format←{           
      ⍝ EXTERN: (RW) gRESULT
        ⍺←''  ⋄  0=≢⍵: ⍺   
        g←gRESULT   
        w← DebugDisplay⍣DEBUG ⊢ USER_SPACE.⎕FMT ⍵
        g w↑⍨←g⌈⍥≢w 
        gRESULT⊢←g,w 
        ⍺
    }
    gRESULT_CodeGen←{ 
        ⍺←''  ⋄  0=≢⍵: ⍺  
        0∊⍴gRESULT: ⍺⊣ gRESULT∘←'(',⍵,')'
                    ⍺⊣ gRESULT∘← gRESULT, '⍺.⍙(', ⍵, ')'
    }
    gOMEGA_Pick←{         
    ⍝ EXTERN: (R) nOMEGA, (RW) gOMEGA_CUR
      ok ix ← {0=1↑0⍴⍵: 1 ⍵ ⋄ ⎕VFI ⍵ } ⍵
      0∊ok:             3 ⎕SIGNAL⍨ '∆F LOGIC ERROR in ⍹ selection: ',' is not a number.',⍨⍕⍵
      (ix<0)∨ix≥nOMEGA: 3 ⎕SIGNAL⍨ '∆F INDEX ERROR: ⍹','is out of range.',⍨⍕ix
      ('(⍵⊃⍨⎕IO+'∘,')',⍨⊢) ⍕gOMEGA_CUR∘←ix         
    }    
  ⍝ Handling Escapes \⋄ etc.
    EscapeText←   '(?<!\\)\\⋄' '\\([{}\\])' ⎕R '\r' '\1' 
    EscapeDQ←     '\\⋄'        '\\\\⋄'      ⎕R '\r' '⋄'  
  ⍝ DQ2SQ: Convert DQ delimiters to SQ, convert doubled "" to single, and provide escapes for DQ strings...
    DQ2SQ←{ DQ2←'""' ⋄ SQ←'''' ⋄ SQ,SQ,⍨(1+SQ=s)/s←(~DQ2⍷s)/s← EscapeDQ 1↓¯1↓⍵ }
  ⍝ SQuote: Return code for a simple char. vector from a char scalar or vector (doubling single quotes per APL) 
    SQuote← {QT←'''' ⋄ QT,QT,⍨(⍵/⍨1+⍵=QT)}∘,
  ⍝ Generate code for a simple char matrix given a simple char scalar or vector ⍵, possibly containing ⎕UCS 13
     GenCode_String←(⎕UCS 13)∘{⍺∊⍵: '↑',1↓∊' ',¨SQuote¨⍺(≠⊆⊢)⍵ ⋄ (⍕1,⍴⍵),'⍴',SQuote ⍵ }∘,
    ⍝ Works, but if CRs in input, generates a 1-row mx with embedded CRs (to be processed by subsequent ⎕FMT).
    ⍝   GenCode_String←{ (⍕1,⍴⍵),'⍴',SQuote ⍵ }∘,
  ⍝ Generate code for the same # of spaces as the width (≢) of ⍵.
    GenCode_Spaces←{('1 ',⍕≢⍵),'⍴'''''} 
  ⍝ EndSection ***** SUPPORT FUNCTION DEFINITIONS
 
  ⍝ SECTION ***** Library Routines (User-Accessible)
    ⍝ FMTX, DISP, JOIN
    ⍝ ⍺.FMTX: Extended ⎕FMT. See doc for $ in ∆Format.dyalog.
    FMTX←{ ⍺←⊢
      ⍝ Bug: If ⎕FR is set LOCALLY in the code field (⎕FR←nnn), ∆FMT won't see it: it picks up whatever's in the caller.
        ∆FMT←(⊃⌽⎕RSI).⎕FMT  ⍝ Pick up caller's ⎕FR and (for 1adic case) ⎕PP. 
        4 7::⎕SIGNAL/⎕DMX.(EM EN)     ⍝ RANK ERROR, FORMAT ERROR
        1≡⍺ 1:∆FMT ⍵
        srcP snkR←'^ *(?|([LCR]) *(\d+)[ ,]*|()() *)(.*)$' '\1\n\2\n\3\n'
        xtra wReq std←srcP ⎕R snkR⊢⊆,⍺
        xtra≡'':⍺ ∆FMT ⍵ 
        obj←std{''≡⍺: ∆FMT ⍵ ⋄ ⍺ ∆FMT ⍵}⍵
        wReq wObj←⊃∘⌽¨(⎕VFI wReq)(⍴obj) 
        wReq ≤ wObj: obj                                  ⍝ If required width ≤ object width, done!
        pad1←↑⍤1
        xtra∊'LR': (¯1×⍣('R'=⊃xtra)⊢wReq)pad1 obj         ⍝ Left, Right 
        wCtr←wReq-⍨⌈2÷⍨wReq-wObj                          ⍝ Center 1
        wReq pad1 wCtr pad1 obj                           ⍝ ...    2
    }
    ⍝ ⍺.DISP: A synonym for Dyalog utility <display>. See $$
    DISP← ⎕SE.Dyalog.Utils.display
    ⍝ ⍺.JOIN: Return a matrix with ⍺ on left and ⍵ on right, first applying ⎕FMT to each and catenaing left to right,
    ⍝         "padding" the shorter object with blank rows. See HELP info on library routines
    JOIN← { a w←⎕FMT¨⍺ ⍵ ⋄ a w↑⍨←a⌈⍥≢w ⋄ a,w }
  ⍝ END SECTION ***** LIBRARY ROUTINES

  ⍝ DfnField: Once we have a Dfn sequence {...}, this decodes syntax within 
    DfnField←{
        pats←quoteP dispP fmtP omDigP omPairP comP selfDocP escDQP  
              quoteI dispI fmtI omDigI omPairI comI selfDocI escDQI ← ⍳≢pats
        selfDocFlag←0
        dfn←pats ⎕R {CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
            CASE quoteI:    DQ2SQ f 0
            CASE dispI:    ' ⍙FLÎB.DISP ' 
            CASE fmtI:     ' ⍙FLÎB.FMTX '                               
            CASE omDigI:    gOMEGA_Pick f 1          
            CASE omPairI:   gOMEGA_Pick gOMEGA_CUR+1  
            CASE comI:     ' '   ⍝ 1 space         
            CASE selfDocI: '}'⊣ selfDocFlag∘←1
            CASE escDQI:   '"'
            '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
        }⍵
      ⍝ Pass the main local namespace ⍙FLÎB into the user space (as a local name and as ⍺). See Mapping of $.
        res←{
          COMPILE: '⍺∘{⍙FLÎB←⍺ ⋄ ⍺', ⍵ ,'⍵ }⍵'    ⍝ ⍺: ⎕SE.⍙FLÎB
                  ⍎'⍙FLÎB∘USER_SPACE.{(⍙FLÎB←⍺)', ⍵ ,'⍵ }gOMEGA'
        }dfn 
      ⍝ selfDoc?   '➤' is U+10148
        selfDocFlag: res {COMPILE: ⍺ gRESULT_CodeGen GenCode_String ⍵ ⋄ ⍺ gRESULT_Format ⍵}'[→➤](\h*)$' ⎕R '➤\1'⊣1↓¯1↓⍵           
        res 
    }

  ⍝ Top-level Patterns  
    simpleP← '(\\.|[^{])+'
    spacerP← '\{(\h*)(?:⍝[^}]*)?\}'      ⍝ We capture leading spaces, and allow and ignore trailing comments.
    ⍝ dfnP: Don't try to understand dfnP-- 
    ⍝       it matches outer braces, ignoring DQ strings, other braces, comments, \ escapes.
    dfnP←    '(?<B>\{(?>(?:\\.)+|[^\{\}\\"]+|(?:"[^"]*")+|(?:⍝(?|(?:"[^"]*")+|[^⋄}]+)*)|(?&B)*)+\})' 
  ⍝ DfnField Patterns...
    escDQP←  '\\"'
    quoteP←  '(?<!\\)(?:"[^"]*")+'
    dispP←    '(?<!\\)\${2,2}'  ⍝ $$ = display (⎕SE.Dyalog.Utils.display)
    fmtP←     '(?<!\\)\$(?!\$)' ⍝ $  = ⎕FMT Extended (see doc.)
    omDigP←   '[⍹⍵](\d{1,2})'   ⍝ ⍹0, ⍹1, ... ⍹99 or ⍵0... We arbitrarily limit to 2 digits (0..99).
    omPairP←  '⍹|⍵_'            ⍝ ⍹ or ⍵_.                 We don't clip incremental indexing of ⍵ at 99. Go figure.
    comP←     '⍝[^⋄}]*'         ⍝ ⍝..⋄ or ⍝..}
    selfDocP← '[→➤]\h*\}$'      ⍝ Trailing → or ➤ (works like Python =). Self documenting code eval.
  
  ⍝----------------------------------------⍝ 
  ⍝ Section ******** EXECUTIVE   ********* ⍝
  ⍝----------------------------------------⍝ 
  ⍝ Basic Initializations
    ASSERT_TRUE DEBUG COMPILE HELP← SetOptions ⍺
    HELP: _←Help ⍬
    _←LoadRuntimeLib 9≠⎕NC '⎕SE.⍙FLÎB'
    USER_SPACE←⊃⌽⎕RSI
    ⍙FLÎB←⎕THIS⊣⎕DF '∆F[⍙FLÎB]'       
  ⍝ Globals (externals) used within utility functions.    
  ⍝ Set up internal mirror of format string (⍹0) and its right args (⍹1, ⍹2, etc.)
    gOMEGA←      ⍵                      ⍝ Named to be visible at various scopes. The format string (⍹0) is ⊃gOMEGA. 
    nOMEGA←      COMPILE⊃ (≢⍵) 9999     ⍝ If we're compiling, we don't know gOMEGA or ≢gOMEGA until runtime.
    gOMEGA_CUR←  0                      ⍝ "Next" ⍹ will always be ⍹1 or later. ⍹0 can only be accessed directly. 
    gRESULT←     1 0⍴' '                ⍝ Initialize global result list of fields.
    
    pats←simpleP spacerP dfnP
         simpleI spacerI dfnI← ⍳≢pats
    _←pats ⎕R{    
        ⋄ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
        COMPILE: {
          CASE simpleI:    gRESULT_CodeGen GenCode_String EscapeText f 0  
          CASE spacerI:    gRESULT_CodeGen GenCode_Spaces f 1
          CASE dfnI:       gRESULT_CodeGen DfnField  f 0
          '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
        }0
          CASE simpleI:    gRESULT_Format EscapeText f 0
          CASE spacerI:    gRESULT_Format            f 1    
          CASE dfnI:       gRESULT_Format DfnField   f 0
          '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
    }⊣⊃⍵     ⍝ Pass the format string only...
⍝    COMPILE: Insert ⍵0 (format string) in code string format
    COMPILE:              '{⎕SE.⍙FLÎB∘{',gRESULT,'}(⊂,',(SQuote ⊃⍵),'),⍵}'  
    ASSERT_TRUE : _←1⊣                 ⎕←gRESULT    
    1:                                   gRESULT      
⍝ EndSection ***** EXECUTIVEx
},⊆⍵

⍝ Section ***** HELP INFO
⍝H DESCRIPTION
⍝H ¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F: "A basic APL-aware formatting function expecting in its right argument
⍝H      a format string, followed by 0 or more scalars of any type (within the domain of ⎕FMT).
⍝H      The format string defines formatted output via fields of 3 types: 
⍝H         text fields, code fields {code}, and space fields {  }
⍝H      each of which builds a character matrix (a field). Fields are concatenated 
⍝H      from left to right, after extending each with blank rows required to stitch them together.
⍝H      Reminiscent of Python F-strings, but reconceived for Dyalog APL."
⍝H
⍝H INTRODUCTORY EXAMPLES
⍝H ¯¯¯¯¯¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯
⍝H #1      ∆F 'Jack\⋄and\⋄Jill{} went up the {↑"hill" "mountain" "street" ⍝code} to fetch{ }a mop?\⋄a pail of water.\⋄something!'
⍝H     Jack went up the hill     to fetch a mop?         
⍝H     and              mountain          a pail of water.
⍝H     Jill             street            something!     
⍝H
⍝H #2      fname lname← 'john' 'smith'  ⋄  age←    34  
⍝H         salBase←     45020           ⋄  salPct←  3.2        
⍝H         cap1← {(1 ⎕C 1↑⍵),1↓⍵}
⍝H         ∆F 'Employee {cap1 fname} {cap1 lname} earns {"⊂$⊃,CF9.2"$salBase} and will earn {"⊂$⊃,CF9.2"$ salBase×1+salPct÷100} next year.'
⍝H     Employee John Smith earns $45,020.00 and will earn $46,460.64 next year.     
⍝H   
⍝H #3      planet←   'Mercury' 'Venus'  'Earth'  'Mars'  'Jupiter'  'Saturn'  'Uranus'  'Neptune' 
⍝H         radiusMi← 1516      3760.4   3958.8   2106.1  43441      36184     15759     15299
⍝H         mi2Km←    ×∘1.609344
⍝H         ∆F 'The planet {↑planet ⍝ No Pluto!} has a radius of {"I5,⊂ mi⊃" $ radiusMi} or {"I5,⊂ km⊃" $ mi2Km radiusMi}.'
⍝H     The planet Mercury has a radius of  1516 mi or  2440 km.
⍝H                Venus                    3760 mi     6052 km 
⍝H                Earth                    3959 mi     6371 km 
⍝H                Mars                     2106 mi     3389 km 
⍝H                Jupiter                 43441 mi    69912 km 
⍝H                Saturn                  36184 mi    58233 km 
⍝H                Uranus                  15759 mi    25362 km 
⍝H                Neptune                 15299 mi    24621 km               
⍝H 
⍝H SYNTAX
⍝H ¯¯¯¯¯¯
⍝H    [⍺] ∆F 'format_string' [scalar1 [scalar2 ... [scalarN]]]
⍝H     ⍺:  
⍝H     If ⍺ is...     then ∆F...  Displays            Returns         Shy?   Remarks
⍝H         'help'                 HELP INFO           0               Yes    ...
⍝H         ⍬ | 'default'          N/A                 formatted str   No     String Formatter
⍝H         'debug'                DEBUG INFO          formatted* str  No     String Formatter [(*) See HELP info]
⍝H         'compile'              --                  executable code        9-10x more efficient for repeat calls
⍝H                                                    sequence y:            Note: ⍺0 is unavailable (an error)
⍝H                                                    (⍎y)⍵1 ⍵2 ...                if 'Compile' is set.
⍝H         where ~0∊⍺             formatted str       1               Yes    Assertion succeeds, so show message
⍝H         where 0∊⍺              N/A                 0               Yes    Assertion fails, so go quietly
⍝H
⍝H FORMAT STRING DEFINITIONS
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H      ∘ Text fields may represent multiple lines, where \⋄ is a "newline" character, \{ and \} are (escaped) braces.
⍝H        Note: ⋄ is an ordinary character. { and } begin and end Code or Space fields, below.
⍝H
⍝H      ∘ Code fields consist of any APL code between (unescaped) braces (beyond simple spaces [w/ optional comments] alone).
⍝H        Any code valid within a DFN is appropriate, as modified below.
⍝H
⍝H      ∘ Space fields consist of 0 or more spaces between (unescaped) braces: { }
⍝H        They may be used to separate contiguous text fields or to add spaces between fields.
⍝H   
⍝H Returns: a character matrix of 1 or more rows and 0 or more columns."
⍝H
⍝H FORMAT STRING FIELDS: Field Types and Associated Special symbols:
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯
⍝H   +-------------+
⍝H   | Text Field  |
⍝H   +-------------+  
⍝H   Everything outside of (unescaped) braces is in a Text field. 
⍝H   The following characters have special meaning within a text field:
⍝H        \⋄     ∘ Inserts a newline within a text field (see also \⋄ in DQ string within a code field).
⍝H                 Use newlines to build multiline text fields.
⍝H               ∘ Note: A CR (⎕UCS 13; hex OC) in the text field is equivalent to \⋄.
⍝H        \{     ∘ A literal { character, which does NOT initiate a code field or space field.
⍝H        \}     ∘ A literal } character, which does NOT end a code field or space field.
⍝H        \\     ∘ Within a text field, a single backslash character is normally treated as the usual APL backslash.
⍝H                 The double backslash '\\' is required ONLY before one of the character ⋄, {, or }, or
⍝H                 to produce multiple contiguous backslashes:
⍝H                     '\⋄' => newline    '\\⋄' => '⋄'   
⍝H                     '\' => '\'         '\\'  => '\',     '\\\\' => '\\'
⍝H                 Note: \" is ordinary text in a text field (see "Code Fields, Using DQs in a SQ-delimited string").
⍝H 
⍝H   +--------------------+
⍝H   | Code Field: {code} |
⍝H   +--------------------+
⍝H        ∘ APL Code Field inserts the value of variables {myVar} into the output (formatted) string,
⍝H          or evaluate sand inserts the value of the code specified following dfn conventions.
⍝H          ∘ Code fields are executed in the calling function's namespace, with access to its
⍝H            variables, functions, ⎕IO, ⎕FR, ⎕PP, etc.
⍝H        ∘ Accesses ∆F right arguments:  0⊃⍵ (1st vector AFTER formatting string), 
⍝H          1⊃⍵ via ⍹N and ⍹ (see below: N is any 1- or 2-digit number 0..99).
⍝H          No blanks are inserted automatically before or after a Code Field. Do so explicitly,
⍝H          via explicit code (e.g. adding a " " string), a Space Field { }, or a Text Field.
⍝H        ∘ Referring to ∆F explicit arguments in a Code field...
⍝H          ⍹N⎱  ∘ Returns, for N an integer of 1 or 2 digits, 0≤N≤99, a value of Nth vector of ⍵, i.e. (⍵⊃⍨N+⎕IO).
⍝H          ⍵N⎰    - ⍵N is allowed as an alias for ⍹N, e.g. ⍵9 ≡ ⍹9, in case you don't have the Unicode character ⍹ handy.
⍝H                  - ⍵1 is the first "appended" word, with ⍵0 reserved as the format string itself (see example below).
⍝H                  - ⍹ or ⍵ must be  followed immediately by 1 or 2 digits w/o any intervening spaces.
⍝H                    ⍹ 9 is (⍹ followed by a space and then the number 9), and 
⍝H                    ⍹ is interpreted as requesting the "next" word in ⍵ (see below).
⍝H          ⍹ ⎱  ∘ Returns the "next" vector in ⍵ (unless followed immediately by a number).
⍝H          ⍵_⎰    By definition, ⍹ has the value of a word in the right arg, 
⍝H                  if not followed immediately by 1 or 2 digits, specifically:
⍝H                  -  the word immediately AFTER the last word referenced via ⍹N or ⍹ (e.g ⍹3 if the last was ⍹3); 
⍝H                  -  ⍹1, the first word after the format string, if no field has been referenced yet via ⍹N or ⍹. 
⍝H                     ⍵_ is a convenient alias for simple ⍹, in case you don't have the Unicode character ⍹ handy.
⍝H                  Ex:          1st    2rd    4th     5th
⍝H                       ∆F '1: {⍹} 2: {⍹} 4: {⍵4} 5: {⍹}'  'one' 'two' 'three' 'four' 'fifth'
⍝H                    1: zero 2: one 4: three 5: fifth
⍝H                  Ex:                           1 2 3 4
⍝H                       ∆F 'All together:{ ∊" ",¨⍹ ⍹ ⍹ ⍹ }' 'one' 'two' 'three' 'four' 'extra' 
⍝H                    All together: one two three four 
⍝H                  Ex:
⍝H                    ⍝  Remember, using ⍹N "sets" the last field referenced to N, so the next  via ⍹ will be N+1.
⍝H                    ⍝                           1 2 1  2
⍝H                       ∆F 'Return again:{ ∊" ",¨⍹ ⍹ ⍹1 ⍹ }'  'one' 'two' 'three' 'four' 
⍝H                    Return again: one two one two 
⍝H                  Ex: 
⍝H                    ⍝ ⍹0 (or ⍵0) refers to the format string itself (the 0th string in ⎕IO=0)
⍝H                      ∆F 'The format string:  {⍹0}'
⍝H                    The format string:  The format string:  {⍹0}
⍝H        ∘ The left arg (⍺) of a Code field refers to a namespace with library routines and local variables.
⍝H          See Obscure Points below.
⍝H        ∘ DQ strings: "..."
⍝H          Strings within Code Fields are DQ strings:
⍝H          ∘ DQ strings begin and end with double quotes, with (optional) 
⍝H            doubled double quotes internally. They only appear within Code fields.
⍝H          ∘ DQ strings are realized as SQ strings when code is executed.
⍝H          ∘ DQ character in Code fields are escaped in the APL way, by doubling. 
⍝H              "abc""def" ==>  'abc"def'
⍝H          Ex:
⍝H              ∆F 'Date: {"Dddd ""the"" Doo ""of"" Mmmm YYYY."(1200⌶)1 ⎕DT⊂2021 10 2 }'
⍝H            Date: Saturday the 2nd of October 2021. 
⍝H          ∘ \⋄  is used to enter a "newline" into a DQ string.
⍝H            \\⋄ may be used to enter a backslash \ followed by '⋄': '\⋄'.
⍝H        ∘ Warning: You may not use \" to escape a DQ within a DQ string! Use APL-style doubling ("abc""def").
⍝H        ∘ SQ characters:  (')
⍝H          ∘ Within Code fields, SQ (') characters are treated as ordinary characters, 
⍝H            not quote characters.
⍝H          ∘ If you insist on using SQ strings as delimiters, double them and watch out for confusion. 
⍝H            Note: to use DQs within a SQ-delimited string, you must specify \" for each DQ desired.
⍝H          $ Extended Format (extends dyadic ⎕FMT): $ pseudo-function
⍝H            ∘ $ denotes a special APL "format" function, with extended parameters L, C, and R.
⍝H              $ may be used more than once in each Code Field, following Dyalog's rules for ⎕FMT.
⍝H              - Three additional string parameters are allowed ONLY at the beginning of the left argument,
⍝H                in this paradigm:
⍝H                           [LCR]ddd,std    OR  [LCR]ddd      OR    std
⍝H                where ∘ L means left-justify the right argument to $ (the arg may be of any type), 
⍝H                      ∘ C means center the right argument to $,
⍝H                      ∘ R means right-justify the right argument to $ 
⍝H                      ∘ ddd (1 or more digits) represent the MINIMUM width of the right argument
⍝H                      ∘ std signifies standard ⎕FMT parameters, executed BEFORE justification specs 
⍝H                        (if present), according to Dyalog's ⎕FMT specifications.
⍝H              - If no L, C, or R is present at the beginning of the left argument to $,
⍝H                then $ functions as the default dyadic ⎕FMT only.
⍝H              - $ (via ⎕FMT) executes in the calling function's namespace;
⍝H                this normally has impact for ⎕FR and (for monadic ⎕FMT) ⎕PP.
⍝H              - If there is no left argument to $, then the default monadic ⎕FMT is called.
⍝H              - Extra spaces before or after the prefix [LCR] or following comma are IGNORED. 
⍝H                The use of L,C,R here cannot be confused with their uses in the ⎕FMT standard.       
⍝H                + Ex:
⍝H                     ∆F 'Using $: {"⊂<⊃,F12.10,⊂>⊃" $ *1 2} <==> Using ⎕FMT: {"⊂<⊃,F12.10,⊂>⊃" ⎕FMT *1 2}'
⍝H                  Using $: <2.7182818285> <==> Using ⎕FMT: <2.7182818285>
⍝H                           <7.3890560989>                  <7.3890560989>
⍝H                + Ex: 
⍝H                    ⎕PP ⎕FR←12 645
⍝H                    ∆F '{$○1}'
⍝H                  3.14159265359 
⍝H                    ∆F '{ ⎕PP ⎕FR←34 1287 ⋄  $○1}'      ⍝ Equiv to: ∆F '{ ⎕PP ⎕FR←34 1287 ⋄ ⎕FMT ○1}' 
⍝H                  3.141592653589793238462643383279503
⍝H                + Ex:
⍝H                    ⎕pp←6  ⍝ Ignored for dyadic ⎕FMT (as the example shows)
⍝H                    ⍝     Pad     ⎕FMT              ⎕FMT             Pad
⍝H                    ∆F '<{"C20,F12.10" $ ○1}> <{"F12.10" $ ○1}> <{"C20" $ ○1}>'
⍝H                  <    3.1415926536    > <3.1415926536> <       3.14159      >
⍝H                + Ex:
⍝H                    ∆F '<{"C30" $ "cats"}>'             ⍝ $ emits blanks
⍝H                  <             cats             >
⍝H                       ∆F '<{"·"@(" "∘=)⊣"C30" $ "cats"}>' ⍝ Replace blanks with middle dot "·".
⍝H                  <·············cats·············> 
⍝H                + Ex: 
⍝H                  ⍝ $ returns a matrix. @ handles transparently...
⍝H                    ∆F'<{"·"@(" "∘=)⊣ "C30,F9.5" $ ○1 2 3}>'
⍝H                  <·············3.14159··········>
⍝H                   ·············6.28319·········· 
⍝H                   ·············9.42478·········· 
⍝H                  ⍝ For ⎕R, convert the matrix to a vector of strings.
⍝H                    ∆F'<{↑" "⎕R"·"↓"C30,F9.5" $ ○1 2 3}>'
⍝H                  <·············3.14159··········>
⍝H                   ·············6.28319·········· 
⍝H                   ·············9.42478·········· 
⍝H 
⍝H          $$ Display
⍝H             ∘ Alias for long display form, "display," viz. ⎕SE.Dyalog.Utils.display
⍝H                     Ex:
⍝H                       ∆F '\⋄one {$$ 1 2 ("1" "2")} \⋄two' 
⍝H                         ┌→┬─┬──┐    
⍝H                     one │1│2│12│ two
⍝H                         └─┴─┴─→┘    
⍝H          ⍝ Code field comments...
⍝H            - Begins a comment within code sequence, terminated SOLELY by: 
⍝H             a ⋄ or } character. Within a comment, double quotes MUST be balanced.
⍝H            - Do not use ⋄, \⋄, }, or \} within comments.
⍝H              Ex:
⍝H                  ∆F 'Using $: {"F12.10" $ *1 ⍝ Dollar!} <==> Using ⎕FMT: {ok←"F12.10" ⎕FMT *1 ⍝ ⎕FMT! ⋄ ok}'
⍝H                Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H          →  Self-documenting {code} expressions...
⍝H             - A right arrow (→ or ➤) trailing a code sequence, 
⍝H               just before (possible blanks and a) final right brace:
⍝H             - Creates two "fields," one with the code text as written, followed by the executed code.
⍝H                   ∆F 'Pi is {○1→}'             ∆F 'Pi is {○1 → }'            ∆F 'Pi is {○1 ➤ }'
⍝H                 Pi is ○1➤3.141592654         Pi is ○1 ➤ 3.141592654        Pi is ○1 ➤ 3.141592654
⍝H             - A self-documenting expression arrow MAY follow a comment, but only one terminated via a ⋄ character:
⍝H                   ∆F '{⍳3 ⍝ iota test ⋄ → }'             ∆F '{⍳3 ⍝ iota test → }'  ⍝ → is eaten by comment
⍝H                 ⍳3 ⍝ iota test ⋄ ➤ 0 1 2               0 1 2
⍝H
⍝H   +------------------+
⍝H   | Space Field: { } |
⍝H   +------------------+
⍝H   A Space field consists of 0 or more spaces within braces; 
⍝H   these spaces are inserted into the formatted string as a separate 2D field.
⍝H   An empty Space Field {} may be used to separate Text fields w/o extra spaces.
⍝H   Ex. This example has three text fields, separated by (empty) Space Fields.  
⍝H          ∆F 'one\⋄two\⋄three{} and {}four\⋄five\⋄six'
⍝H       one   and four
⍝H       two       five
⍝H       three     six
⍝H   Space fields may include a comment AFTER the defined spaces. It consists of a lamp ⍝ symbol followed
⍝H   by any characters except a closing brace (escaped or not).
⍝H   The space field here inserts six spaces:   ∆F '<{      ⍝ Six spaces}>'  ==>   '<      >'
⍝H    
⍝H DEBUGGING EXAMPLE
⍝H ¯¯¯¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H ○ This is a simple example shown first without debugging activated, then at debugging level 3.
⍝H   ⍝ No debugging
⍝H        Names←'John Smith' 'Mary Jones' 'Terry Hawk'
⍝H        Locns←'NY' 'London' 'Paris'
⍝H        ∆F 'Officers {↑Names} are in {↑Locns}'
⍝H     Officers John Smith are in  NY   
⍝H              Mary Jones         London                  
⍝H              Terry Hawk         Paris  
⍝H   ⍝ DEBUGGING LEVEL 3...                
⍝H        ⎕NULL 1 ∆F 'Officers {↑Names} are in {Locns}'
⍝H     ┌→────────┐┌→─────────┐┌→───────┐┌→──────┐
⍝H     ↓Officers·│↓John·Smith│↓·are·in·│↓·NY   ·│
⍝H     └─────────┘│Mary·Jones│└────────┘│ London│
⍝H                │Terry·Hawk│          │ Paris │                    
⍝H                └──────────┘          └──── ──┘
⍝H 
⍝H OBSCURE POINTS
⍝H ¯¯¯¯¯¯¯ ¯¯¯¯¯¯
⍝H ○ The current ∆F "library" (active namespace) reference is passed as the LHS (⍺) argument of each 
⍝H   Code Field dfn called. Right now, the "library" includes
⍝H   ∘ ⍺.FMTX    - an extended ⎕FMT that can justify/center its right argument. See pseudo-builtin $ above.
⍝H   ∘ ⍺.DISP    - Dyalog's long display function, ⎕SE.Dyalog.Utils.display. See pseudo-builtin $$ above.
⍝H   ∘ ⍺.JOIN    - catenates two objects (formatted as 2-D arrays) left to right, padding with blank rows as necc.
⍝H   ∘ ⍺.DEBUG   - 1 if DEBUG is set; otherwise 0. May be set (only to 0 or 1): '...{⍺.DEBUG←1 ⋄ RunCode Dataset}...'
⍝H  
⍝H ○ If you want to use your own "local" objects across Code fields, simply use "library" names prefixed with ⍺._
⍝H   (If you call subsequent functions, be sure to pass ⍺ in some format to those functions).
⍝H   Valid object names might be:  
⍝H        ⍺._, ⍺.__, ⍺._myExample, ⍺._MyFunction, or ⍺._123.
⍝H   E.g. you might have a sequence like:
⍝H        ∆F 'John {⍺._last←"Smith"} knows Mary {⍺._last}.'
⍝H     John Smith knows Mary Smith.
⍝H ○ Other objects in the namespace in ⍺ are used by ∆F and bad things will happen if you change them.
⍝H   (Note: it is trivial to create a truly private namespace, but we didn't bother).
⍝H
⍝H Some differences from Python F-strings
⍝H ¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯ ¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯
⍝H ∘ Handles arbitrary arrays and arbitrary APL expressions, not just simple objects and strings (as Python does).
⍝H ∘ Works via easy-to-understand 2D "fields," built from left to right.
⍝H ∘ Savvy about namespaces, defaulting to viewing the namespace from which ∆F is called.
⍝H ∘ Concisely accesses Dyalog ⎕FMT (via $), rather than using incompatible Python formatting.
⍝H ∘ Has simple extensions to $ for padding 2D generated objects (left- and right-justified and centered).
⍝H ∘ Easily accesses Dyalog "display"  dfn (via $$) to show structure of formatted objects under your control.
⍝H ∘ Code fields can include error handling, as well as (for advanced users) local variables 
⍝H   shared across several code fields.
⍝H ∘ Includes a debugging mode to show the field structure of output.
⍝H ∘ Has limited use of special characters {, }, ", \⋄ for special functions creating the field types and so on.
⍝H   Avoids the hassle of too many exceptional characters in a format string.
⍝H ∘ Can be executed unconditionally or only upon the success of an assertion (no 0∊⍺ in ⍺ ∆F ...).
⍝H ∘ Rather slow, but that's only because it's a prototype (entirely analyzed at run time).
⍝ EndSection ***** Help Info
}