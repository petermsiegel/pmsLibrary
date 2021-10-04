∆F←{   
  ⍝   Modes A, B, C...
  ⍝   If ↓↓↓ \ ∆F →→→         Displays            Returns         Shy?   Remarks
  ⍝   A.  ⍵ has 0 items       HELP INFO           0               Yes    ...
  ⍝   B1. ⍺: default          N/A                 formatted str   No     String Formatter
  ⍝   B2. ⍺: ⎕NULL [0]        N/A                 formatted str   No     String Formatter
  ⍝   B3. ⍺: ⎕NULL [1|2|3]    DEBUG INFO          formatted* str  No     String Formatter [(*) See HELP info]
  ⍝   C1. ~0∊⍺                formatted str       1               Yes    Assertion succeeds, so show message
  ⍝   C2. otherwise           N/A                 0               Yes    Assertion fails, so go quietly
 
  0:: ('∆F ',⎕DMX.EM )⎕SIGNAL ⎕DMX.EN  
  ⎕IO←0 ⋄ ⍺←⎕NULL  

⍝ Help... Show HELP info and return shy 0.
  0≡≢⍵:  _←0⊣{ help←'^⍝H((?: .*)?)$' ⎕S '\1' ⊣⍵ ⋄ ''⊣⎕ED 'help' } ⎕NR 0⊃⎕XSI
⍝ Case C2 above. Do nothing. Return shy0.
  (⎕NULL≠⊃⍺)∧(0∊⍺): _←0      

  ⍺ (⎕NS '').{ ⍝ Move us out of the user space...
    ⍝ Section ********* USER-SETTABLE FLAGS...
    ⍝ DBGLVL is ⍺[1] (DOMAIN: 0 1 2 3), only if ⍺[0] is ⎕NULL.
      DBGLVL← (⎕NULL=⊃⍺)⊃0 (⊂⊃2↓0,⍺)       
      (DBGLVL)(~∊)⍳4: '∆F DOMAIN ERROR: Invalid debug option'⎕SIGNAL 11
    ⍝ End Section ***** USER-SETTABLE FLAGS...

    ⍝ Section ********* Utilities
      ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
          def←'' ⋄ isN←0≠⍬⍴0⍴⍵ ⋄ p←N⍳∘⊂⍣isN⊣⍵ 
          0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def ⋄ B[O[p]+⍳L[p]] 
      }
      FIELDS_Append←{           
        ⍝ EXTERN: (RW) FIELDS
          ⍺←''  ⋄  0=≢⍵: ⍺            
          rt ← ('·'@(' '∘=))∘⎕SE.Dyalog.Utils.display⍣(DBGLVL∊2 3)⊢ USER_SPACE.⎕FMT ⍵
          ht←(≢FIELDS)⌈≢rt
          FIELDS⊢←(ht↑FIELDS),ht↑rt
          ⍺
      }
      OMEGA_Pick←{         
      ⍝ EXTERN: (R) OMEGA, (RW) OMEGA_CUR
        ok ix ← {0=1↑0⍴⍵: 1 ⍵ ⋄ ⎕VFI ⍵ } ⍵
        0∊ok:             3 ⎕SIGNAL⍨ '∆F LOGIC ERROR in ⍹ selection: ',' is not a number.',⍨⍕⍵
        (ix<0)∨ix≥≢OMEGA: 3 ⎕SIGNAL⍨ '∆F INDEX ERROR: ⍹','is out of range.',⍨⍕ix
        ('(⍵⊃⍨⎕IO+'∘,')',⍨⊢) ⍕OMEGA_CUR∘←ix
      }
    ⍝ Section ********* Main Loop Functions    
      EscapeText←   '(?<!\\)\\⋄' '\\([{}\\])' ⎕R '\r' '\1' 
      EscapeDQ←     '\\⋄'        '\\\\⋄'      ⎕R '\r' '⋄'  
    ⍝ DQ2SQ: Convert DQ delimiters to SQ, convert doubled "" to single, and provide escapes for DQ strings...
      DQ2SQ←{ DQ2←'""' ⋄ SQ←''''  
          SQ,SQ,⍨(1+SQ=s)/s←(~DQ2⍷s)/s← EscapeDQ 1↓¯1↓⍵ 
      }
      DfnField←{
          esqQP←    '\\"'
          quoteP←  '(?<!\\)(?:"[^"]*")+'
          dispP←    '(?<!\\)\${2,2}'  ⍝ $$ = display (⎕SE.Dyalog.Utils.disp)
          fmtP←     '(?<!\\)\$(?!\$)' ⍝ $  = ⎕FMT Extended (see doc.)
          omDigP←   '[⍹⍵](\d{1,2})'   ⍝ ⍹0, ⍹1, ... ⍹99 or ⍵0... We arbitrarily limit to 2 digits (0..99).
          omPairP←  '⍹|⍵_'            ⍝ ⍹ or ⍵_.                 We don't clip incremental indexing of ⍵ at 99. Go figure.
          comP←     '⍝[^⋄}]*'         ⍝ ⍝..⋄ or ⍝..}
          selfDocP← '[→➤]\h*\}$'      ⍝ Trailing → or ➤ (works like Python =). Self documenting code eval.
          pats←quoteP dispP fmtP omDigP omPairP comP selfDocP esqQP  
               quoteI dispI fmtI omDigI omPairI comI selfDocI esqQI ← ⍳≢pats
          selfDocFlag←0
          dfn←pats ⎕R {CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
              CASE quoteI:    DQ2SQ f 0
              CASE dispI:    ' __LÎB__.DISP ' 
              CASE fmtI:     ' __LÎB__.FMTX '                               
              CASE omDigI:    OMEGA_Pick f 1          
              CASE omPairI:   OMEGA_Pick OMEGA_CUR+1  
              CASE comI:     ' '   ⍝ 1 space         
              CASE selfDocI: '}'⊣ selfDocFlag∘←1
              CASE esqQI:     '"'
              '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
          }⍵
          0:: ⎕DMX.EN ⎕SIGNAL⍨ ⎕DMX.(EM,':',(0≠≢Message)/' ',Message),' ',dfn  
        ⍝ Pass the main local namespace LÎB into the user space (as a local name and as ⍺). See Mapping of $.
          res←⍎{⍵⊣⎕←'Executing Code: ',⍵}⍣(DBGLVL∊1 3)⊣'LÎB USER_SPACE.{__LÎB__←⍺ ⋄ ⍺',dfn,'⍵ }OMEGA' 
        ⍝ selfDoc?   '➤' is U+10148
          selfDocFlag: res FIELDS_Append '[→➤](\h*)$' ⎕R '➤\1'⊣1↓¯1↓⍵           
          res 
      }
    ⍝ EndSection ***** Main Loop Utilities
  ⍝ EndSection ***** Utilities

  ⍝ Section ********* Initializations
    ⍝ Basic Initializations
        USER_SPACE←⊃⌽⎕RSI
        LÎB←⎕THIS 
      ⍝ ⊆⍵ structure:
      ⍝    FORMAT@str OMEGA@V[], where OMEGA scalars (elements) are accessed as 
      ⍝      (a) ⍵0 ⍵1 ... ⍵99; or (b) incremental ⍹.  See code or documentation for aliases for ⍵N and ⍹.
        OMEGA←      ⍵     ⍝ The format string (FORMAT above) is ⊃OMEGA.       
        OMEGA_CUR←  0     ⍝ "Next" ⍹ will always be ⍹1 or later. ⍹0 can only be accessed directly. 
        FIELDS←     ⎕FMT''

      ⍝ Library Routines (User-Accessible)
      ⍝ FMTX, DISP, JOIN
      ⍝ ⍺.FMTX: Extended ⎕FMT. See doc for $ in ∆Format.dyalog.
        FMTX←{ ⍺←⊢
            ∆FMT←USER_SPACE.⎕FMT  ⍝ Pick up caller's ⎕FR and (for 1adic case) ⎕PP.
            4 7::⎕SIGNAL/⎕DMX.(EM EN)     ⍝ RANK ERROR, FORMAT ERROR
            1≡⍺ 1:∆FMT ⍵
            srcP snkR←'^ *(?|([LCR]) *(\d+)[ ,]*|()() *)(.*)$' '\1\n\2\n\3\n'
            xtra wReq std←srcP ⎕R snkR⊢⊆,⍺
            xtra≡'':⍺ ∆FMT ⍵ ⋄  obj←std{''≡⍺: ∆FMT ⍵ ⋄ ⍺ ∆FMT ⍵}⍵
            wReq wObj←⊃∘⌽¨(⎕VFI wReq)(⍴obj) 
            wReq ≤ wObj: obj                                  ⍝ If required width ≤ object width, done!
            pad1←↑⍤1
            xtra∊'LR': (¯1×⍣('R'=⊃xtra)⊢wReq)pad1 obj         ⍝ Left, Right 
            wCtr←wReq-⍨⌈2÷⍨wReq-wObj                          ⍝ Center
            wReq pad1 wCtr pad1 obj                           ⍝ ...
        }
      ⍝ ⍺.DISP: See $$
        DISP← ⎕SE.Dyalog.Utils.disp 
      ⍝ ⍺.JOIN: See HELP info on library routines
        JOIN← { a w←⎕FMT¨⍺ ⍵ ⋄ a w↑⍨←a⌈⍥≢w ⋄ a,w }
      
    ⍝ Top-level Patterns  
        simpleP← '(\\.|[^{])+'
        spacerP← '\{(\h*)(?:⍝[^}]*)?\}'    ⍝ We capture leading spaces, and allow and ignore trailing comments.
      ⍝ dfnP: Don't try to understand dfnP-- it matches outer braces, ignoring DQ strings, other braces, comments, \ escapes.
        dfnP←    '(?<B>\{(?>(?:\\.)+|[^\{\}\\"]+|(?:"[^"]*")+|(?:⍝(?|(?:"[^"]*")+|[^⋄}]+)*)|(?&B)*)+\})' 
  ⍝ EndSection ***** Initializations

  ⍝ Section ********* Main
      pats←simpleP spacerP dfnP
           simpleI spacerI dfnI← ⍳≢pats
      _←pats ⎕R{    
          ⋄ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
          CASE simpleI:    FIELDS_Append EscapeText f 0
          CASE spacerI:    FIELDS_Append f 1    
          CASE dfnI:       FIELDS_Append DfnField f 0
          '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
      }⊣⊃OMEGA     ⍝ Pass the format string only...
      ⎕NULL=⊃⍺:       FIELDS
             1: _←1⊣⎕←FIELDS          
  ⍝ EndSection ***** Main
},⊆⍵

⍝ Section ***** HELP INFO
⍝H DESCRIPTION
⍝H ¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F: "A basic APL-aware formatting function (file: ∆Format.dyalog) expecting in its right argument
⍝H      a format string, followed by 0 or more scalars of any type (within the domain of ⎕FMT).
⍝H      The format string uses any mixture of 3 field types: 
⍝H         text fields, code fields {code}, and space fields {  }
⍝H      each of which builds a character matrix (a field). Fields are concatenated 
⍝H      from left to right, after extending each with blank rows needed to stitch together.
⍝H      Inspired by (but different from) Python f-strings."
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
⍝H         ∆F 'Employee {∊cap1¨fname lname} earns {"⊂$⊃,CF9.2"$salBase} and will earn {"⊂$⊃,CF9.2"$ salBase×1+salPct÷100} next year.'
⍝H     Employee JohnSmith earns $45,020.00 and will earn $46,460.64 next year.     
⍝H   
⍝H #3      planet←   'Mercury' 'Venus'  'Earth'  'Mars'  'Jupiter'  'Saturn'  'Uranus'  'Neptune' 
⍝H         radiusMi← 1516      3760.4   3958.8   2106.1  43441      36184     15759     15299
⍝H         ∆F 'The planet {↑planet} has a radius of {"I5" $ radiusMi} mi. or {"I5" $ radiusMi×1.609344} km.'
⍝H     The planet Mercury has a radius of  1516 mi. or  2440 km.
⍝H                Venus                    3760         6052    
⍝H                Earth                    3959         6371    
⍝H                Mars                     2106         3389    
⍝H                Jupiter                 43441        69912    
⍝H                Saturn                  36184        58233    
⍝H                Uranus                  15759        25362    
⍝H                Neptune                 15299        24621            
⍝H 
⍝H SYNTAX
⍝H ¯¯¯¯¯¯
⍝H         [⍺] ∆F 'format_string' [scalar1 [scalar2 ... [scalarN]]]
⍝H         ⍺:  
⍝H           Omitted     Return the result of formatting specified by format_string with any other scalars of ⍵.
⍝H           ⎕NULL       Same as above.
⍝H          ~0∊⍺         Successful assertion. Print the formatted string and return shy 1.
⍝H           0∊⍺         Failed assertion. Do not format; return shy 0.
⍝H           ⎕NULL 1     As for ⎕NULL case, but provide (terse) debugging info.
⍝H           ⎕NULL 2     Prints a debugging version of the output:
⍝H                       - showing each field independently via display (⎕SE.Dyalog.Utils.disp) in the output.
⍝H                       - with each blank in the output replaced by a center dot (·).
⍝H           ⎕NULL 3     Provides debugging info ⎕NULL 1 and ⎕NULL 2
⍝H                       See below (bottom) for debugging example...
⍝H
⍝H FORMAT STRING DEFINITIONS
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H      ∘ Text fields may have multiple lines, where \⋄ is a "newline" character, \{ and \} are (escaped) braces.
⍝H
⍝H      ∘ Code fields consist of any APL code (beyond simple spaces alone) between (unescaped) braces.
⍝H        Any code valid within a DFN is appropriate, as modified here:
⍝H        - Code fields use double-quotes (") to create strings, rather than single quotes. 
⍝H          That is each double quotes must have a match. 
⍝H          An internal double quote is entered as two consecutive double quotes: 
⍝H               ∆F '{"I can''t believe ""that"" is true!"}' 
⍝H            I can't believe "that" is true! 
⍝H          Single quotes are treated as "ordinary" characters (see details / exceptions below). 
⍝H        - Multiple lines may be created via APL code (e.g.: ↑"one line" "2nd line") or, 
⍝H          within double quotes, via \⋄, the newline character. 
⍝H        - Code fields support $ as a shortcut (pseudo-fn) for ⎕FMT (1- or 2-adic), for padding left or right, 
⍝H          or for centering a field.
⍝H        - Code fields support $$ as a shortcut (pseudo-fn) for the utility "disp" (brief-format boxed display).
⍝H        - Code fields support 
⍝H          ∘ ⍹0, ⍹1,..., ⍹N to index the 0-th, 1-st,..., N-th scalar of the right argument (⍹0 is the format string) or 
⍝H          ∘ ⍹ alone, which selects the NEXT scalar or, on the first use of ⍹ or ⍹N, 
⍝H            ⍹1 (the first argument AFTER the format string). 
⍝H        - Code fields are executed left to right as well in the calling functions namespace.
⍝H        - Special elements $, $$, ⍹, and ⍹N, may all be used in combination.
⍝H
⍝H      ∘ Space fields consist of 0 or more spaces between (unescaped) braces: { }
⍝H        They may be used to separate contiguous text fields or to add spaces between fields.
⍝H        The spaces (if any) may be followed by a comment, consisting of a lamp '⍝' followed
⍝H        by zero or more characters except closing braces '}'.
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
⍝H                 Note: \" is not recognized in a text field (see "Code Fields, Using DQs in a SQ-delimited string").
⍝H 
⍝H   +--------------------+
⍝H   | Code Field: {code} |
⍝H   +--------------------+
⍝H        ∘ APL Code Field. Accesses arguments 0⊃⍵ (1st vector AFTER formatting string), 
⍝H          1⊃⍵ via ⍹N and ⍹ (see below: N is any 1- or 2-digit number 0..99).
⍝H          No blanks are inserted automatically before or after a Code Field. Do so explicitly,
⍝H          via explicit code (e.g. adding a " " string), a Space Field { }, or a Text Field.
⍝H        ∘ Code fields are executed in the calling function's namespace, with access to its
⍝H          variables, functions, ⎕IO, ⎕FR, ⎕PP, etc.
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
⍝H        ∘ DQ strings: "..."
⍝H          ∘ DQ strings begin and end with double quotes, with (optional) 
⍝H            doubled double quotes internally. They only appear within Code fields.
⍝H          ∘ DQ strings are realized as SQ strings when code is executed.
⍝H          ∘ DQ character in Code fields are escaped in the APL way, by doubling. 
⍝H                "abc""def" ==>  'abc"def'
⍝H            Ex:
⍝H                ∆F 'Date: {"Dddd ""the"" Doo ""of"" Mmmm YYYY."(1200⌶)1 ⎕DT⊂2021 10 2 }'
⍝H              Date: Saturday the 2nd of October 2021. 
⍝H          ∘ \⋄  is used to enter a "newline" into a DQ string.
⍝H            \\⋄ may be used to enter a backslash \ followed by '⋄': '\⋄'.
⍝H          ∘ Warning: You may not use \" to escape a DQ within a DQ string! Use APL-style doubling ("abc""def").
⍝H        ∘ SQ characters:  (')
⍝H          ∘ Within Code fields, SQ (') characters are treated as ordinary characters, 
⍝H            not quote characters.
⍝H          ∘ If you do use SQ strings as delimiters, they must be doubled when entered by the user (as always). 
⍝H          ∘ Using DQs within a SQ-delimited string [not encouraged]:
⍝H            As well, to use DQs within a SQ-delimited string, you must specify \" for each DQ desired.
⍝H                ∆F '{↑''ok'' ''but'' ''challenging''}'        ∆F '{↑''ok'' ''yet'' ''very \"awkward\"!''}'
⍝H              ok                                            ok
⍝H              but                                           yet     
⍝H              challenging!                                  very "awkward"!
⍝H            Much easier is: 
⍝H                ∆F '{↑"this" "is the" "easiest!"}' 
⍝H              This 
⍝H              is the
⍝H              easiest!  
⍝H          $ Extended Format (extends dyadic ⎕FMT): $ pseudo-function
⍝H            ∘ $ denotes a special APL-format function, with extended parameters L, C, and R.
⍝H              $ may be used more than once in each Code Field.
⍝H              - Three additional string parameters are allowed ONLY at the beginning of the left argument,
⍝H                in this paradigm:
⍝H                           [LCR]ddd,std    OR  [LCR]ddd      OR    std
⍝H                where ∘ L means left-justify the right argument to $ 
⍝H                      ∘ C means center the right argument to $,
⍝H                      ∘ R means right-justify the right argument to $ 
⍝H                      ∘ ddd (1 or more digits) represent the MINIMUM width of the right argument
⍝H                      ∘ std signifies standard ⎕FMT parameters, executed BEFORE justification specs 
⍝H                        (if present), according to Dyalog's ⎕FMT specifications.
⍝H              - If no L, C, or R is present at the beginning of the left argument to $,
⍝H                then $ functions as the default dyadic ⎕FMT only.
⍝H              - $ (via ⎕FMT) functions as if in the calling function's namespace;
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
⍝H             ∘ Alias for short display form, "disp," viz. ⎕SE.Dyalog.Utils.disp 
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
⍝H                   ∆F '{⍳3 ⍝ iota test ⋄ → }'
⍝H                 ⍳3 ⍝ iota test ⋄ ➤ 0 1 2
⍝H
⍝H   +------------------+
⍝H   | Space Field: { } |
⍝H   +------------------+
⍝H   A Space field consists of 0 or more spaces within braces; 
⍝H   these spaces are inserted into the formatted string as a separate 2D field.
⍝H   An empty Space Field {} may be used to separate  Text fields:
⍝H   Ex. This example has three text fields, separated by (empty) Space Fields.  
⍝H          ∆F 'one\⋄two\⋄three{} and {}four\⋄five\⋄six'
⍝H       one   and four
⍝H       two       five
⍝H       three     six
⍝H   Space fields may include a comment AFTER the defined spaces. It consists of a lamp ⍝ symbol followed
⍝H   by any characters except a closing brace (escaped or not).
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
⍝H        ⎕NULL 3 ∆F 'Officers {↑Names} are in {Locns}'
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
⍝H   ∘ ⍺.DISP    - Dyalog's brief display function, ⎕SE.Dyalog.Utils.disp. See pseudo-builtin $$ above.
⍝H   ∘ ⍺.JOIN    - catenates two objects (formatted as 2-D arrays) left to right, padding with blank rows as necc.
⍝H  
⍝H ○ If you want "local" variables to be consistent across a series of code fields (left to right), you can
⍝H   use reserved local names in the library space. Those names must begin with 
⍝H      ⍺._ followed by 0 or more valid APL variable name letters (e.g. a-z, A-Z, 0-9, or more underscores).
⍝H   Valid names might be:  ⍺._, ⍺.__, ⍺._myExample, ⍺._MyExample, or ⍺._123.
⍝H   E.g. you might have a sequence like:
⍝H        ∆F 'John {⍺._last←"Smith"} knows Mary {⍺._last}.'
⍝H     John Smith knows Mary Smith.
⍝H  
⍝H ○ Other names in the library ought NOT be used.
⍝H
⍝H Some differences from Python F-strings
⍝H ¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯ ¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯
⍝H ∘ Handles arbitrary array expressions, not just simple objects and strings (as Python does).
⍝H ∘ Savvy about namespaces, defaulting to viewing the namespace from which ∆F is called.
⍝H ∘ Feels like a nested array formatter for a nested array language.
⍝H ∘ Easily accesses Dyalog ⎕FMT (via $), rather than using Python formatting.
⍝H ∘ Easily accesses Dyalog "disp" (display) dfn (via $$) to show structure of formatted objects.
⍝H ∘ Has simple extensions via $ for padding of 2D generated objects (left- and right-justified and centered).
⍝H ∘ Works via easy-to-understand 2D "fields," built from left to right.
⍝H ∘ Code fields can include error handling, as well as (for advanced users) local variables 
⍝H   shared across several code fields.
⍝H ∘ Includes a debugging mode to show the field structure of output and more.
⍝H ∘ Has limited use of special characters {}, "", \⋄ for special functions creating the field types and so on.
⍝H ∘ Can be executed unconditionally or only upon the success of an assertion.
⍝H ∘ Rather slow, but that's only because it's a prototype (entirely analyzed at run time).
⍝ EndSection ***** Help Info
}