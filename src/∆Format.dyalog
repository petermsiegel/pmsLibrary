∆F←{   
  ⍝   If ... \ ∆F ...         Displays            Returns        Shy?   Remarks
  ⍝   A.  ⍵ has 0 items       HELP INFO           ''             No     ...
  ⍝   B.  default/⍺ is ⎕NULL  --                  formatted str  No     String Formatter
  ⍝   C1. 0∊⍺                 formatted str       1              Yes    Assertion fails, so show message
  ⍝   C2. otherwise           --                  0              Yes    Assertion succeeds, so go quietly
 
  0:: ('∆F ',⎕DMX.EM )⎕SIGNAL ⎕DMX.EN  
  ⎕IO←0 
  ⍺←⎕NULL 

⍝ Help...
  0≡≢⍵:  { help←'⍝H'{l←≢⍺ ⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⍵ ⋄ ''⊣⎕ED 'help'} ⎕NR 0⊃⎕XSI
⍝ Case C2 above. Don't format.
  (⍺≢⎕NULL)∧(~0∊⍺): _←0      

  ⍺ (⎕NS '').{ ⍝ Move us out of the user space...
    ⍝ Section ********* USER-SETTABLE FLAGS...
    ⍝ TSP: Trailing space propagation: Are the trailing spaces of the last "line" of a text field propagated to all other lines?
    ⍝      Current view: Leave as 0. It's confusing othewise; better to use Space Fields { } to add blanks.
      TSP←0 
      DEBUG←1 
    ⍝ End Section ***** USER-SETTABLE FLAGS...

    ⍝ Section ********* Utilities
      ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
          def←'' ⋄ isN←0≠⍬⍴0⍴⍵ ⋄ p←N⍳∘⊂⍣isN⊣⍵ 
          0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def ⋄ B[O[p]+⍳L[p]] 
      }
      SetRESULT←{           ⍝ External: RESULT
          0=≢⍵: ''          ⍝ Null ⍵: nothing is to be added to RESULT...
          r← USER_SPACE.⎕FMT ⍵
          h←(≢RESULT)⌈≢r
          RESULT∘←(h↑RESULT),[1]h↑r
          ''
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
          SQ,SQ,⍨(~DQ2⍷s)/s← EscapeDQ 1↓¯1↓⍵ 
      }
      DfnField←{
          quoteP←  '(?<!\\)(?:"[^"]*")+'
          dispP←    '(?<!\\)\${2,2}'  ⍝ $$ = display (⎕SE.Dyalog.Utils.disp)
          fmtP←     '(?<!\\)\$(?!\$)' ⍝ $  = ⎕FMT or (if ⍺ numeric:) pad left (⍺<0), right (⍺>0) or center (⍺≠⌊⍺)
          omDigP←   '⍵(\d{1,2})'      ⍝ ⍵1, ⍵2, ... ⍵99. We arbitrarily assume no more than directly indexable 99 elements...
          omPairP←  '⍵⍵'              ⍝ ⍵⍵               We don't clip incremental indexing of ⍵ at 99. Go figure.
          comP←     '⍝[^⋄}]+'         ⍝ ⍝..⋄ or ⍝..}
          selfDocP← '[→➤]\h*\}$'      ⍝ Trailing → or ➤ (works like Python =). Self documenting code eval.
          pats←quoteP dispP fmtP omDigP omPairP comP selfDocP 
               quoteI dispI fmtI omDigI omPairI comI selfDocI← ⍳≢pats
          selfDocB←0
          dfn←pats ⎕R{CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
              CASE quoteI:   DQ2SQ f 0
              CASE dispI:    ' ⎕SE.Dyalog.Utils.disp ' 
              CASE fmtI:     '(__LÎB__.FMTX)'                               ⍝ See below.
              CASE omDigI:   '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS (f 0)  OmSelect f 1
              CASE omPairI:  '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS '⍵⍵'   OmSelect OMEGA_CUR+1   ⍝ ⍵⍵ could be clipped here vial 100|...
              CASE comI:     ' '             
              CASE selfDocI: '}'⊣ selfDocB∘←1
          }⍵
          0:: ⎕DMX.EN ⎕SIGNAL⍨ ⎕DMX.(EM,':',(0≠≢Message)/' ',Message),' ',dfn  
        ⍝ Pass the main local namespace LÎB into the user space (as a local name and as ⍺). See Mapping of $.
          res←⍎{⊢⎕←⍵}⍣DEBUG⊣'LÎB USER_SPACE.{__LÎB__←⍺⋄⍺',dfn,'⍵}OMEGAS' 
          selfDocB: res⊣(SetRESULT '[→➤](\h*)$'⎕R '➤\1'⊣1↓¯1↓⍵)          ⍝  '➤' aka U+10148
          res 
      }
    ⍝ EndSection ***** Main Loop Utilities
  ⍝ EndSection ***** Utilities

  ⍝ Section ********* Initializations
    ⍝ Basic Initializations
        USER_SPACE←⊃⌽⎕RSI
        LÎB←⎕THIS 
      ⍝ ⊆⍵ structure:
      ⍝    FORMAT@str OMEGAS@V[], where OMEGAS are accessed as ⍵0 ⍵1 ... ⍵99, or as incremental ⍵⍵.
        FORMAT←     ⊃⍵  
        OMEGAS←     1↓⍵          
        OMEGA_CUR←  ¯1
        RESULT←     ⎕FMT''
      ⍝ FMTX: Extended ⎕FMT that pads RHS (⍵) with spaces, if LHS (⍺) is numeric.
      ⍝ See also pseudo-builtin function $.
      ⍝ If ⍺ is numeric: pad left (⍺<0), right (⍺>0) or center (⍺≠⌊⍺). OTHERWISE (1adic, 2adic): use ⎕FMT.
        FMTX←{⍺←⍕⋄0≠⊃0⍴⍺,1:⍺⎕FMT⍵⋄m←⎕FMT⍵⋄⍺=⌊⍺:⍺↑⍤1⊢m⋄w←⌊|⍺⋄∆←w-⍨⌊2÷⍨w-1↓⍴m⋄w↑⍤1⊢∆↑⍤1⊢m}
    ⍝ Top-level Patterns  
        simpleP← '(\\.|[^{])+'
        spacerP← '\{(\h*)\}',TSP/'(\h*)' 
      ⍝ dfnP: Don't try to understand dfnP-- it matches braces, ignoring DQ strings, comments, \ escapes.
        dfnP←    '(?<B>\{(?>(?:\\.)+|[^\{\}\\"]+|(?:"[^"]*")+|(?:⍝(?|(?:"[^"]*")+|[^⋄}]+)*)|(?&B)*)+\})',TSP/'h*'
  ⍝ EndSection ***** Initializations

  ⍝ Section ********* Main
      Tsp←0∘({-+/∧\⌽' '=⍺}⍣TSP⍨)   ⍝ See TSP. Let ⍵@CV, with potentially trailing spaces. 
      pats←simpleP spacerP dfnP
           simpleI spacerI dfnI← ⍳≢pats
      _←pats ⎕R{    
          ⋄ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
          CASE simpleI:''⊣{trail← Tsp ⍵    
            SetRESULT¨ (EscapeText trail↓⍵)(trail↑⍵)  ⍝ Two fields text and sss in 'textsss' (given s, a space)
          }f 0
          CASE spacerI:SetRESULT ∊f¨ 1 2              ⍝ Include spaces xxx and yyy in {xxx}yyy
          CASE dfnI:''⊣{trail← Tsp ⍵      
            SetRESULT¨ (DfnField trail↓⍵)(trail↑⍵)
          }f 0
          '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
      }⊣FORMAT
      ⍺≡⎕NULL:     RESULT
               1⊣⎕←RESULT          
  ⍝ EndSection ***** Main
}⊆⍵

⍝ Section ***** HELP INFO
⍝H DESCRIPTION
⍝H ¯¯¯¯¯¯¯¯¯¯¯
⍝H ∆F: "A basic APL-aware formatting function (file: ∆Format.dyalog) using 3 field types-- 
⍝H     a code field, a text field, and a space field-- each of which builds a  
⍝H     character matrix (known as a field). Fields are concatenated from left to right, after 
⍝H     extending each with blank rows needed to join together. 
⍝H     Code fields are executed left to right as well in the calling functions namespace.
⍝H Returns: a character matrix of 1 or more rows and 0 or more columns."
⍝H
⍝H SIMPLE EXAMPLE
⍝H ¯¯¯¯¯¯ ¯¯¯¯¯¯¯
⍝H         first← 'John'  'Mary'  'Ted'
⍝H         last←  'Smith' 'Jones' 'Allen'
⍝H         smoker← 0       0       1
⍝H         ∆F'Status: {↑last}{⍪","⍴⍨≢last} {↑first}: {"nonsmoker" "smoker"[⍪smoker]}'
⍝H     Status: Smith, John: nonsmoker
⍝H             Jones, Mary  nonsmoker
⍝H             Allen, Ted   smoker 
⍝H     The FIELDS in this example are:
⍝H     ⍝      7  FIELDS   
⍝H     ⍝      1.......2......3............45.......6.7..............................
⍝H     ⍝      Text....Code...Code.........TCode....T.Code...........................
⍝H         ∆F'Status: {↑last}{⍪","⍴⍨≢last} {↑first}: {"nonsmoker" "smoker"[⍪smoker]}'
⍝H 
⍝H SYNTAX
⍝H ¯¯¯¯¯¯
⍝H     [⎕←]  [option]  ∆F 'formatting_string' ⍵0 ⍵1 ⍵2 ...
⍝H     ∘ 'formatting_string'
⍝H       Formatting strings consist of text fields, code fields, and space fields. 
⍝H       - Code fields are APL "dfns" surrounded by (unescaped) braces {}.
⍝H       - Space fields consist of (unescaped) braces with 0 or more internal spaces.
⍝H       - Text fields are everything else. A text field is terminated:
⍝H         + At the end of the formatting string;
⍝H         + If a code or space field is encountered.
⍝H     ∘ ⍵0 ⍵1 ⍵2 ...
⍝H       ⍵⍵
⍝H       Each (complex or simple) scalar (⍵N) after the format string can be referenced 
⍝H       in any {code} field, see below. See ⍵N and ⍵⍵ below. 
⍝H     ∘ ⍺: option, ⍺, has three options. 
⍝H       With option (A) below, ∆F is a simple format command.
⍝H       With option (B) below, ∆F is an "assertion".
⍝H       (A) If the <option> is omitted or is ⎕NULL, the resulting format string is returned.
⍝H       (B) i. The assertion "fails" if ⍺ <option> contains any 0s, 
⍝H              with the resulting format string printed (via ⎕) and 1 returned shyly.
⍝H          ii. Otherwise, the assertion "succeeds," 
⍝H              with no format string generated and 0 returned shyly.
⍝H 
⍝H FIELDS: Field Types and Associated Special symbols:
⍝H ¯¯¯¯¯¯
⍝H     Code Field: {code}
⍝H                   ∘ APL Code Field. Accesses arguments ⍵0 (1st vector after formatting string), 
⍝H                     ⍵1, ⍵2, through ⍵N.
⍝H                   ∘ Trailing blanks will be interpreted as if a space field.
⍝H          Within a {code} field...
⍝H          ⍵N       ∘ Returns, for N an integer 0≤N≤99, a value of Nth vector of ⍵, i.e. (⍵⊃⍨N+⎕IO).
⍝H          ⍵⍵       ∘ Returns the "next" vector in ⍵. By definition, 
⍝H                     ⍵⍵ is ⍵0 or 1 past the last field referenced via ⍵N (e.g. ⍵3).
⍝H                     Ex:
⍝H                       ∆F '0: {⍵⍵} 1: {⍵⍵} 3: {⍵3} 4: {⍵⍵}' 'zero' 'one' 'two' 'three' 'four' 
⍝H                     0: zero 1: one 3: three 4: four
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
⍝H          $        Format (⎕FMT) or Pad/Center
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
⍝H                     a ⋄ or } character.
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
⍝H     Space Field:  { }
⍝H                   ∘ A Space field contains 0 or more spaces within braces; 
⍝H                     these spaces are inserted into the formatted string.
⍝H     Text Field:   ∘ Everything else is a text field. The following characters have special meaning
⍝H                     within a text field:
⍝H        \⋄         ∘ Inserts a newline within a text field (see also \⋄ in DQ string within a code field).
⍝H                     Use newlines to build multiline text fields.
⍝H                   ∘ Note: A CR (⎕UCS 13; hex OC) in the text field is equivalent to \⋄.
⍝H        \{         ∘ A literal { character, which does NOT initiate a code field or space field.
⍝H        \}         ∘ A literal } character, which does NOT end a code field or space field.
⍝H        \\         ∘ Within a text field, a single backslash character is normally treated as the usual APL backslash.
⍝H                     The double backslash '\\' is required ONLY before one of the character n, {, or }, or
⍝H                     to produce multiple contiguous backslashes:
⍝H                         '\⋄' => newline    '\\⋄' => '⋄'   
⍝H                         '\' => '\'         '\\'  => '\',     '\\\\' => '\\'
⍝H    
⍝H +------------------+
⍝H | Advanced/Obscure |
⍝H +------------------+
⍝H   The current ∆Format "library" (namespace) reference is passed as the LHS (⍺) argument of each Code Field dfn called.
⍝H   Right now, you can call
⍝H   ∘ ⍺.FMTX which includes standard ⎕FMT and padding ⍵ with spaces. See pseudo-builtin $ above.
⍝ EndSection ***** Help Info
}