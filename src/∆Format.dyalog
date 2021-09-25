∆F←{   
  ⍝   If ↓↓↓ \ ∆F →→→         Displays            Returns        Shy?   Remarks
  ⍝   A.  ⍵ has 0 items       HELP INFO           ''             No     ...
  ⍝   B1. default             --                  formatted str  No     String Formatter
  ⍝   B2. ⎕NULL [0]           --                  formatted str  No     String Formatter
  ⍝   B3. ⎕NULL  1            DEBUG INFO          formatted str  No     String Formatter
  ⍝   C1. 0∊⍺                 formatted str       1              Yes    Assertion fails, so show message
  ⍝   C2. otherwise           --                  0              Yes    Assertion succeeds, so go quietly
 
  0:: ('∆F ',⎕DMX.EM )⎕SIGNAL ⎕DMX.EN  
  ⎕IO←0 ⋄ ⍺←⎕NULL 

⍝ Help...
  0≡≢⍵:  { help←'⍝H'{l←≢⍺ ⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⍵ ⋄ ''⊣⎕ED 'help'} ⎕NR 0⊃⎕XSI
⍝ Case C2 above. Don't format.
  (⎕NULL≠⊃⍺)∧(~0∊⍺): _←0      

  ⍺ (⎕NS '').{ ⍝ Move us out of the user space...
    ⍝ Section ********* USER-SETTABLE FLAGS...
      DEBUG←1=⊃⌽⍺
    ⍝ End Section ***** USER-SETTABLE FLAGS...

    ⍝ Section ********* Utilities
      ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
          def←'' ⋄ isN←0≠⍬⍴0⍴⍵ ⋄ p←N⍳∘⊂⍣isN⊣⍵ 
          0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def ⋄ B[O[p]+⍳L[p]] 
      }
      FIELDS_Append←{           ⍝ External: FIELDS
          ⍺←''              ⍝
          0=≢⍵: ⍺           ⍝ Null ⍵: nothing is to be added to FIELDS...
          r← USER_SPACE.⎕FMT ⍵
          h←(≢FIELDS)⌈≢r
          FIELDS∘←(h↑FIELDS),[1]h↑r
          ⍺
      }
      OmSelect←{
        omvec lit←⍺
        (ok ix) ixstr ← {0=1↑0⍴⍵: (1 ⍵)(⍕⍵) ⋄ (⎕VFI ⍵) ⍵}⍵
        0∊ok: ⎕SIGNAL/('∆F LOGIC error: ',lit,' is not a number.')3
        (ix<0)∨ix≥≢omvec: ⎕SIGNAL/('∆F Index error accessing ⍵',ixstr) 3 
        OMEGA_CUR∘←ix
        ixstr
      }
    ⍝ Section ********* Main Loop Functions    
      EscapeText←   '(?<!\\)\\⋄' '\\([{}\\])' ⎕R '\r' '\1' 
      EscapeDQ←     '\\⋄'        '\\\\⋄'      ⎕R '\r' '⋄'  
    ⍝ DQ2SQ: Convert DQ delimiters to SQ, convert doubled "" to single, and provide escapes for DQ strings...
      DQ2SQ←{ 
          DQ2←'""' ⋄ SQ←''''  
          SQ,SQ,⍨(1+SQ=s)/s←(~DQ2⍷s)/s← EscapeDQ 1↓¯1↓⍵ 
      }
      DfnField←{
          quoteP←  '(?<!\\)(?:"[^"]*")+'
          dispP←    '(?<!\\)\${2,2}'  ⍝ $$ = display (⎕SE.Dyalog.Utils.disp)
          fmtP←     '(?<!\\)\$(?!\$)' ⍝ $  = ⎕FMT or (if ⍺ numeric:) pad left (⍺<0), right (⍺>0) or center (⍺≠⌊⍺)
          omDigP←   '[⍹⍵](\d{1,2})'   ⍝ ⍵0, ⍵1, ... ⍵99. We arbitrarily assume no more than directly indexable 99 elements...
          omPairP←  '⍹|⍵_'            ⍝ ⍹                We don't clip incremental indexing of ⍵ at 99. Go figure.
          comP←     '⍝[^⋄}]+'         ⍝ ⍝..⋄ or ⍝..}
          selfDocP← '[→➤]\h*\}$'      ⍝ Trailing → or ➤ (works like Python =). Self documenting code eval.
          pats←quoteP dispP fmtP omDigP omPairP comP selfDocP 
               quoteI dispI fmtI omDigI omPairI comI selfDocI← ⍳≢pats
          selfDocFlag←0
          dfn←pats ⎕R{CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
              CASE quoteI:    DQ2SQ f 0
              CASE dispI:    '(__LÎB__.DISP)' 
              CASE fmtI:     '(__LÎB__.FMTX)'                               
              CASE omDigI:   '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS (f 0)  OmSelect f 1
              CASE omPairI:  '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS (f 0)   OmSelect OMEGA_CUR+1    
              CASE comI:     ' '   ⍝ 1 space         
              CASE selfDocI: '}'⊣ selfDocFlag∘←1
              '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
          }⍵
          0:: ⎕DMX.EN ⎕SIGNAL⍨ ⎕DMX.(EM,':',(0≠≢Message)/' ',Message),' ',dfn  
        ⍝ Pass the main local namespace LÎB into the user space (as a local name and as ⍺). See Mapping of $.
          res←⍎{⍵⊣⎕←'Evaluating: ',⍵}⍣DEBUG⊣'LÎB USER_SPACE.{__LÎB__←⍺⋄⍺',dfn,'⍵}OMEGAS' 
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
      ⍝    FORMAT@str OMEGAS@V[], where OMEGAS are accessed as 
      ⍝      (a) ⍵0 ⍵1 ... ⍵99; or (b) incremental ⍹.   (See code or documentation for aliases for ⍵N and ⍹.)
        FORMAT←     ⊃⍵  
        OMEGAS←     ⍵          
        OMEGA_CUR←  0
        FIELDS←     ⎕FMT''
      ⍝ FMTX: Extended ⎕FMT that pads RHS (⍵) with spaces, if LHS (⍺) is numeric.
      ⍝ See also pseudo-builtin function $.
      ⍝ If ⍺ is numeric: pad left (⍺<0), right (⍺>0) or center (⍺≠⌊⍺). OTHERWISE (1adic, 2adic): use ⎕FMT.
        FMTX←{⍺←⍕⋄0≠⊃0⍴⍺,1:⍺⎕FMT⍵⋄m←⎕FMT⍵⋄⍺=⌊⍺:⍺↑⍤1⊢m⋄w←⌊|⍺⋄∆←w-⍨⌊2÷⍨w-1↓⍴m⋄w↑⍤1⊢∆↑⍤1⊢m}
        DISP← ⎕SE.Dyalog.Utils.disp 
    ⍝ Top-level Patterns  
        simpleP← '(\\.|[^{])+'
        spacerP← '\{(\h*)\}' 
      ⍝ dfnP: Don't try to understand dfnP-- it matches braces, ignoring DQ strings, comments, \ escapes.
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
      }⊣FORMAT
      ⎕NULL=⊃⍺:       FIELDS
             1: _←1⊣⎕←FIELDS          
  ⍝ EndSection ***** Main
}⊆⍵

⍝ Section ***** HELP INFO
⍝H DESCRIPTION
⍝H ¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F: "A basic APL-aware formatting function (file: ∆Format.dyalog) expecting in its right argument
⍝H      a format string, followed by 0 or more scalars of any type (within the domain of ⎕FMT).
⍝H      The format string uses any mixture of 3 field types: 
⍝H         text fields, code fields {code}, and space fields {  }
⍝H      each of which builds a character matrix (a field). Fields are concatenated 
⍝H      from left to right, after extending each with blank rows needed to stitch together."
⍝H
⍝H SYNTAX
⍝H ¯¯¯¯¯¯
⍝H         [⍺] ∆F 'format_string' [scalar1 [scalar2 ... [scalarN]]]
⍝H         ⍺:  
⍝H           Omitted     Return the result of formatting specified by format_string with any other scalars of ⍵.
⍝H           ⎕NULL       Same as above.
⍝H          ~0∊⍺         Treat as a successful assertion. Return shy 0 and ignore the format_string.
⍝H           0∊⍺         Treat as a failed assertion. Print the result of formatting (⎕←...) and return shy 0.
⍝H           ⎕NULL 1     As for ⎕NULL case, but provide (terse) debugging info.
⍝H
⍝H FORMAT STRING DEFINITIONS
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯¯¯¯¯¯
⍝H      ∘ Text fields may have multiple lines, where \⋄ is a "newline" character, \{ and \} are (escaped) braces.
⍝H
⍝H      ∘ Code fields consist of any APL code (beyond simple spaces alone) between (unescaped) braces.
⍝H        Any code valid within a DFN is appropriate, as modified here:
⍝H        - Code fields use double-quotes (") to create strings, rather than single quotes. 
⍝H          That is each double quotes must have a match. 
⍝H          An internal double quote is formed two consecutive double quotes: 
⍝H               ∆F '{"I can''t believe ""that"" is true!"}' 
⍝H            I can't believe "that" is true! 
⍝H          Single quotes are treated as "ordinary" characters:  
⍝H        - Multiple lines may be created via APL code (e.g.: ↑"one line" "2nd line") or, 
⍝H          within double quotes, via \⋄, the newline character. 
⍝H        - Code fields support $ as a shortcut for ⎕FMT (1- or 2-adic), for padding left or right, 
⍝H          or for centering a field.
⍝H        - Code fields support $$ as a shortcut for the utility "disp" (brief-format boxed display).
⍝H        - Code fields support 
⍝H          ∘ ⍹0, ⍹1,..., ⍹N to index the 0-th, 1-st,..., N-th scalar of the right argument (⍹0 is the format string) or 
⍝H          ∘ ⍹ alone, which selects the NEXT scalar or, on the first use of ⍹ or ⍹N, 
⍝H            ⍹1 (the first argument AFTER the format string). 
⍝H        - Code fields are executed left to right as well in the calling functions namespace.
⍝H        - Special elements $, $$, ⍹, and ⍹N, may all be used in combination.
⍝H          ($ with a character left arg calls ⎕FMT, which is only valid with an appropriate numeric right argument).
⍝H
⍝H      ∘ Space fields consist of 0 or more spaces between (unescaped) braces: { }
⍝H        They may be used to separate contiguous text fields or to add spaces between fields.
⍝H
⍝H Returns: a character matrix of 1 or more rows and 0 or more columns."
⍝H
⍝H SIMPLE EXAMPLE
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H         ∆F'A format string {⍪⎕TS}{ }More stuff\⋄2nd line{ }1\⋄2\⋄three {⍪⍹1×⍹}' ⎕AI 5 'NOT USED'
⍝H     A format string 2021 More stuff 1        2515
⍝H                        9 2nd line   2        5345
⍝H                       23            three 7167540
⍝H                       12                  7032865
⍝H                       38                         
⍝H                       50                         
⍝H                      526       
⍝H 
⍝H FORMAT STRING FIELDS: Field Types and Associated Special symbols:
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯ ¯¯¯¯¯¯
⍝H     Code Field: {code}
⍝H                   ∘ APL Code Field. Accesses arguments ⍵0 (1st vector AFTER formatting string), 
⍝H                     ⍵1, ⍵2, through ⍵N (N is any 1- or 2-digit number 0..99).
⍝H                     No blanks are inserted automatically before or after a Code Field. Do so explicitly,
⍝H                     via explicit code (e.g. adding a " " string), a Space Field { }, or a Text Field.
⍝H          Referring to ∆F explicit arguments...
⍝H          ⍹N⎱     ∘ Returns, for N an integer or 1 or 2 digits, 0≤N≤99, a value of Nth vector of ⍵, i.e. (⍵⊃⍨N+⎕IO).
⍝H          ⍵N⎰       ⍵N is a convenient way to type ⍹N. 
⍝H                     Note: ⍹ or ⍵ must be  followed immediately by 1 or 2 digits w/o intervening spaces, etc.
⍝H                           ⍹ 9 is (⍹ followed by a space and then the number 9), and 
⍝H                           is interpreted as requesting the "next" word in ⍵ (see below).
⍝H          ⍹ ⎱     ∘ Returns the "next" vector in ⍵. 
⍝H          ⍵_⎰       By definition, ⍹ has the value of a word in the right arg, 
⍝H                    if not followed immediately by 1 or 2 digits, specifically:
⍝H                         -  the word immediately AFTER the last word referenced via ⍹N or ⍹ (e.g ⍹3 if the last was ⍹3); 
⍝H                         -  ⍹1, the first word after the format string, if no field has been referenced yet via ⍹N or ⍹. 
⍝H                     ⍵_ is equivalent to ⍹ (when you don't have the Unicode character ⍹ handy).
⍝H                     Ex:          0th    1st    3rd     4th
⍝H                          ∆F '0: {⍹} 1: {⍹} 3: {⍵3} 4: {⍹}' 'zero' 'one' 'two' 'three' 'four' 
⍝H                       0: zero 1: one 3: three 4: four
⍝H                     Ex:                           0 1 2 3
⍝H                          ∆F 'All together:{ ∊" ",¨⍹ ⍹ ⍹ ⍹ }' 'zero' 'one' 'two' 'three' 'four' 
⍝H                       All together: zero one two three   
⍝H                     Ex:
⍝H                       ⍝  Remember, using ⍹N "sets" the last field referenced to N, so the next  via ⍹ will be N+1.
⍝H                                                   0 1 0  1
⍝H                          ∆F 'Return again:{ ∊" ",¨⍹ ⍹ ⍹0 ⍹ }' 'zero' 'one' 'two' 'three' 'four' 
⍝H                       Return again: zero one zero one  
⍝H          DQ strings: "..."
⍝H                   ∘ DQ strings begin and end with double quotes, with (optional) 
⍝H                     doubled double quotes internally. They only appear within Code fields.
⍝H                   ∘ DQ strings are realized as SQ strings when code is executed.
⍝H                   ∘ DQ character in Code fields are escaped in the APL way, by doubling. 
⍝H                     "abc""def" ==>  'abc"def'
⍝H                   ∘ \⋄  is used to enter a "newline" into a DQ string.
⍝H                     \\⋄ may be used to enter a backslash \ followed by '⋄': '\⋄'.
⍝H                   ∘ Warning: Do not use \" to escape a DQ within a DQ string! Use APL-style doubling ("abc""def").
⍝H          SQ characters:  (')
⍝H                   ∘ There are no SQ strings in Code Fields. See DQ strings.
⍝H                   ∘ SQ (') characters are treated as ordinary characters within Code Fields, 
⍝H                     not quote characters.
⍝H                   ∘ Do not use SQ characters to delimit code fields! Use DQ strings (above).
⍝H          $          Format (⎕FMT) or Pad/Center
⍝H                   ∘ $ denotes a special function, depending on its left arg. 
⍝H                     It may be used more than once in each Code Field call.
⍝H                     a.  "str"  $ value    =>   Executes dyadic 'str' ⎕FMT value*   
⍝H                                                * If value is a vector, it is treated as a 1-column matrix, per ⎕FMT.
⍝H                     b.         $ value    =>   Executes monadic ⎕FMT value
⍝H                     c.   int   $ value    =>   Pads <⎕FMT value> 
⍝H                                                  If int>0: adds spaces on the right;
⍝H                                                  If int<0: adds spaces on the left.
⍝H                                                Truncates  to width <int> if <|int> is less than ⊃⌽⍴value.
⍝H                     d.   float $ value    =>   Centers <⎕FMT value> in the width <|float>.
⍝H                                                Truncates if <|float> is less than ⊃⌽⍴value.                                  
⍝H                   + Ex:
⍝H                        ∆F 'Using $: {"⊂<⊃,F12.10,⊂>⊃" $ *1 2} <==> Using ⎕FMT: {"⊂<⊃,F12.10,⊂>⊃" ⎕FMT *1 2}'
⍝H                     Using $: <2.7182818285> <==> Using ⎕FMT: <2.7182818285>
⍝H                              <7.3890560989>                  <7.3890560989>
⍝H                   + Ex: 
⍝H                       ⎕PP ⎕FR←12 645
⍝H                       ∆F '{$○1}'
⍝H                     3.14159265359 
⍝H                       ∆F '{ ⎕PP ⎕FR←34 1287 ⋄  $○1}'      ⍝ Equiv to: ∆F '{ ⎕PP ⎕FR←34 1287 ⋄ ⎕FMT ○1}' 
⍝H                     3.141592653589793238462643383279503
⍝H                   + Ex:
⍝H                       ⎕pp←6  ⍝ Ignored for dyadic ⎕FMT (as the example shows)
⍝H                       ⍝     Pad     ⎕FMT              ⎕FMT             Pad
⍝H                       ∆F '<{20.5 $ "F12.10" $ ○1}> <{"F12.10" $ ○1}> <{20.5 $ ○1}>'
⍝H                     <    3.1415926536    > <3.1415926536> <       3.14159      >
⍝H                   + Ex:
⍝H                       ∆F '<{30.2 $ "cats"}>'             ⍝ $ emits blanks
⍝H                     <             cats             >
⍝H                       ∆F '<{"_"@(" "∘=)⊣30.2 $ "cats"}>' ⍝ Replace blanks with "_".
⍝H                     <_____________cats_____________> 
⍝H                   + Ex: 
⍝H                     ⍝ $ returns a matrix. @ handles transparently...
⍝H                       ∆F'<{"_"@(" "∘=)⊣ 30.2 $ "F9.5" $ ○1 2 3}>'
⍝H                     <_____________3.14159__________>
⍝H                      _____________6.28319__________ 
⍝H                      _____________9.42478__________ 
⍝H                     ⍝ For ⎕R, convert the matrix to a vector of strings.
⍝H                       ∆F'<{↑" "⎕R"_"↓30.2 $ "F9.5" $ ○1 2 3}>'
⍝H                     <_____________3.14159__________>
⍝H                      _____________6.28319__________ 
⍝H                      _____________9.42478__________ 
      
⍝H          $$       Display
⍝H                   ∘ Alias for short display form, "disp," viz. ⎕SE.Dyalog.Utils.disp 
⍝H                     Ex:
⍝H                       ∆F '\⋄one {$$ 1 2 ("1" "2")} \⋄two' 
⍝H                         ┌→┬─┬──┐    
⍝H                     one │1│2│12│ two
⍝H                         └─┴─┴─→┘    
⍝H          ⍝        ∘ Code-sequence comments...
⍝H                     Begins a comment within code sequence, terminated SOLELY by: 
⍝H                     a ⋄ or } character. Within a comment, double quotes MUST be balanced.
⍝H                     Do not use ⋄, \⋄, }, or \} within comments.
⍝H                     Ex:
⍝H                       ∆F 'Using $: {"F12.10" $ *1 ⍝ Dollar!} <==> Using ⎕FMT: {ok←"F12.10" ⎕FMT *1 ⍝ ⎕FMT! ⋄ ok}'
⍝H                     Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H          →        ∘ Self-documenting {code} expressions...
⍝H                   ∘ A right arrow (→ or ➤) trailing a code sequence, 
⍝H                     just before (possible blanks and a) final right brace:
⍝H                   ∘ Creates two "fields," one with the code text as written, followed by the executed code.
⍝H                     Ex:
⍝H                        ∆F 'Pi is {○1→}'             ∆F 'Pi is {○1 → }'            ∆F 'Pi is {○1 ➤ }'
⍝H                     Pi is ○1➤3.141592654         Pi is ○1 ➤ 3.141592654        Pi is ○1 ➤ 3.141592654
⍝H                   ∘ A self-documenting expression arrow MAY follow a comment, but only one terminated via a ⋄ character:
⍝H                        ∆F '{⍳3 ⍝ iota test ⋄ → }'
⍝H                     ⍳3 ⍝ iota test ⋄ ➤ 0 1 2
⍝H     Space Field:  { }
⍝H                   ∘ A Space field contains 0 or more spaces within braces; 
⍝H                     these spaces are inserted into the formatted string as part of a separate 2D field.
⍝H     Text Field:   ∘ Everything else is a text field. The following characters have special meaning
⍝H                     within a text field:
⍝H        \⋄         ∘ Inserts a newline within a text field (see also \⋄ in DQ string within a code field).
⍝H                     Use newlines to build multiline text fields.
⍝H                   ∘ Note: A CR (⎕UCS 13; hex OC) in the text field is equivalent to \⋄.
⍝H        \{         ∘ A literal { character, which does NOT initiate a code field or space field.
⍝H        \}         ∘ A literal } character, which does NOT end a code field or space field.
⍝H        \\         ∘ Within a text field, a single backslash character is normally treated as the usual APL backslash.
⍝H                     The double backslash '\\' is required ONLY before one of the character ⋄, {, or }, or
⍝H                     to produce multiple contiguous backslashes:
⍝H                         '\⋄' => newline    '\\⋄' => '⋄'   
⍝H                         '\' => '\'         '\\'  => '\',     '\\\\' => '\\'
⍝H    
⍝H OBSCURE POINTS
⍝H ¯¯¯¯¯¯¯ ¯¯¯¯¯¯
⍝H ○ The current ∆Format "library" (namespace) reference is passed as the LHS (⍺) argument of each Code Field dfn called.
⍝H   Right now, the "library" includes
⍝H   ∘ ⍺.FMTX which includes standard ⎕FMT and padding ⍵ with spaces. See pseudo-builtin $ above.
⍝H   ∘ ⍺.DISP which calls the brief display function, ⎕SE.Dyalog.Utils.disp. See $$ above.
⍝H ○ If you want "local" variables to use within a series of code fields (left to right), you can
⍝H   use ⍺._ or any APL name prefixed with a single underscore (e.g. ⍺._test, ⍺._MyCode).
⍝H   Other names could conflict with active ∆F names.
⍝H        ∆F 'They are John {⍺._last←"Smith"} and Mary {⍺._last}'
⍝H     They are John Smith and Mary Smith
⍝ EndSection ***** Help Info
}