∆F←{  ⎕IO←0
  ⍝   If ... \ ∆F ...         Displays            Returns        Shy?   Remarks
  ⍝   A.  ⍵ has 0 items       HELP INFO           ''             No     ...
  ⍝   B.  default/⍺ is ⎕NULL  --                  formatted str  No     String Formatter
  ⍝   C1. 0∊⍺                 formatted str       1              Yes    Assertion fails, so show message
  ⍝   C2. otherwise           --                  0              Yes    Assertion succeeds, so go quietly
  0:: ('∆F ',⎕DMX.EM )⎕SIGNAL ⎕DMX.EN 
  ⍺←⎕NULL 

⍝ Help...
  0≡≢⍵:  { help←'⍝H'{l←≢⍺ ⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⍵ ⋄ ''⊣⎕ED 'help'} ⎕NR 0⊃⎕XSI
⍝ Case C2 above. Don't format.
  (⍺≢⎕NULL)∧(~0∊⍺): _←0      

  ⍺ (⎕NS '').{ ⍝ Move us out of the user space...
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
    ⍝ Section ********* Main Loop Utilities     
      EscapeText←   '(?<!\\)\\n' '\\([{}\\])' ⎕R '\r' '\1' 
      EscapeDQ←     '\\n'        '\\\\n'      ⎕R '\r' 'n' 
      DQ2SQ←{ ⍝ Convert DQ delimiters to SQ, convert doubled "" to single, and provide escapes for DQ strings...
          DQ2←'""' ⋄ SQ←''''  
          SQ,SQ,⍨(~DQ2⍷s)/s← EscapeDQ 1↓¯1↓⍵ 
      }
      DfnField←{
          omDigP←   '⍵(\d{1,2})' 
          omPairP←  '⍵⍵'
          dispP←    '(?<!\\)\${2,2}'  ⍝ $$ = display (⎕SE.Dyalog.Utils.disp)
          fmtP←     '(?<!\\)\$(?!\$)' ⍝ $  = ⎕FMT
          comP←     '⍝[^⋄}]+' 
          selfDocP← '[→➤]\h*\}$'    ⍝ Trailing → or ➤ (like Python =) creates selfDoc format: dfn_text➤ ⍎dfn
          pats←quoteP dispP fmtP omDigP omPairP comP selfDocP 
               quoteI dispI fmtI omDigI omPairI comI selfDocI← ⍳≢pats
          selfDocB←0
          dfn←pats ⎕R{CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
              CASE quoteI: DQ2SQ f 0
              CASE dispI:    ' ⎕SE.Dyalog.Utils.disp ' 
              CASE fmtI:     ' ⎕FMT '
              CASE omDigI:   '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS (f 0)  OmSelect f 1
              CASE omPairI:  '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS '⍵⍵'   OmSelect OMEGA_CUR+1
              CASE comI:     ' '             
              CASE selfDocI: '}'⊣ selfDocB∘←1
          }⍵
          0:: msg ⎕SIGNAL ⎕DMX.EN⊣ msg←⎕DMX.(EM,':',(0≠≢Message)/' ',Message),' ',dfn
          res←⍎'USER_SPACE.',dfn,'OMEGAS'
          selfDocB: res⊣(SetRESULT '[→➤](\h*)$'⎕R '➤\1'⊣1↓¯1↓⍵)          ⍝  '➤' aka U+10148
          res 
      }
    ⍝ EndSection ***** Main Loop Utilities
  ⍝ EndSection ***** Utilities

  ⍝ Section ********* Initializations
    ⍝ Top-level Patterns  
    ⍝ dfnP: Don't try to understand dfnP-- it matches braces, ignoring DQ strings, comments, \ escapes.
      dfnP←    '(?<B>\{(?>(?:\\.)+|[^\{\}\\"]+|(?:"[^"]*")+|(?:⍝(?|(?:"[^"]*")+|[^⋄}]+)*)|(?&B)*)+\})\h*'
      quoteP←  '(?<!\\)(?:"[^"]*")+'
      simpleP← '(\\.|[^{])+'
      spacerP← '\{(\h*)\}(\h*)'
    ⍝ Basic Initializations
      USER_SPACE←⊃⌽⎕RSI
    ⍝ ⊆⍵ expected to be:
    ⍝    FORMAT@str OMEGAS@V[], where OMEGAS are accessed as ⍵0 ⍵1 ... ⍵N, or as incremental ⍵⍵.
      FORMAT←⊃⍵  
      OMEGAS←1↓⍵          
      OMEGA_CUR←¯1
      RESULT←⎕FMT''
    ⍝ TSP: Trailing space propagation: Are the trailing spaces of the last line of a field propagated to all other lines?
      TSP←0       
  ⍝ EndSection ***** Initializations

  ⍝ Section ********* Main
      Tsp←0∘({-+/∧\⌽' '=⍺}⍣TSP⍨)   ⍝ See TSP. Let ⍵@CV, with potentially trailing spaces. 
      pats←simpleP spacerP dfnP
           simpleI spacerI dfnI← ⍳≢pats
      _←pats ⎕R{    
          ⋄ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD ⋄ 
          CASE simpleI:''⊣{trail← Tsp ⍵    
            SetRESULT¨ (EscapeText trail↓⍵)(trail↑⍵)  ⍝ Two fields text and sss in 'textsss' (given s, a space)
          }f 0
          CASE spacerI:SetRESULT ∊f¨ 1 2              ⍝ Include spaces xxx and yyy in {xxx}yyy
          CASE dfnI:''⊣{trail← Tsp ⍵      
            SetRESULT¨(DfnField trail↓⍵)(trail↑⍵)
          }f 0
          '∆F LOGIC ERROR: UNREACHABLE STMT' ⎕SIGNAL 911
      }⊣FORMAT
      ⍺≡⎕NULL:     RESULT
               1⊣⎕←RESULT          
  ⍝ EndSection ***** Main
}⊆⍵

⍝ Section ***** HELP INFO
⍝H ∆F: A basic APL-aware formatting function (file: ∆Format.dyalog).
⍝H     [⎕←]  [option]  ∆F 'formatting_string' ⍵0 ⍵1 ⍵2 ...
⍝H ∘ 'formatting_string
⍝H   Formatting strings consist of text fields, code fields, and space fields. 
⍝H    ∘ Code fields are APL "dfns" surrounded by (unescaped) braces {}.
⍝H    ∘ Space fields consist of (unescaped) braces with 0 or more internal spaces.
⍝H    ∘ Text fields are everything else. A text field is terminated:
⍝H      ∘ At the end of the formatting string;
⍝H      ∘ If a code or space field is encountered.
⍝H ∘ ⍵0 ⍵1 ⍵2 ...
⍝H   Each (complex or simple) scalar (⍵N) after the format string can be referenced in any {code} field, see below.
⍝H   See ⍵N and ⍵⍵ below. 
⍝H ∘ option (⍺) has three options. 
⍝H   With option (a) below, ∆F is a simple format command.
⍝H   With option (b) below, ∆F is an "assertion".
⍝H   (a) If the <option> is omitted or is ⎕NULL, the resulting format string is returned.
⍝H   (b) i. If the <option> contains any 0s, the resulting format string is printed (⎕←) and 1 is returned,
⍝H          indicating the assertion (resulting in ⍺) failed.
⍝H      ii. Otherwise, the format string is not generated and 0 is returned, 
⍝H          indicating the assertion (resulting in ⍺) succeeded.
⍝H          { ⍝ Prints message only if y>10.
⍝H            (y≤10) ∆F 'Error: y≤{⍵⍵} ← {⍵⍵}x**2 + {⍵⍵}x + ⍵⍵' 10 3 5 9
⍝H          }
⍝H 
⍝H Special symbols:
⍝H     Code Field: {code}
⍝H                   APL Code Field. Accesses arguments ⍵0 (1st vector after formatting string), ⍵1, ⍵2, through ⍵N.
⍝H                   Trailing blanks will be interpreted as if a space field.
⍝H          Within a {code} field...
⍝H          ⍵N       Returns, for N an integer 0≤N≤99, a value of Nth vector of ⍵, i.e. (⍵⊃⍨N+⎕IO).
⍝H          ⍵⍵       Returns the "next" vector in ⍵. By definition, 
⍝H                   ⍵⍵ is ⍵0 or 1 past the last field referenced via ⍵N (e.g. ⍵3).
⍝H                   Ex:
⍝H                       ∆F '0: {⍵⍵} 1: {⍵⍵} 3: {⍵3} 4: {⍵⍵}' 'zero' 'one' 'two' 'three' 'four' 
⍝H                   0: zero 1: one 3: three 4: four
⍝H          DQ strings: "..."
⍝H                   DQ strings begin and end with double quotes, with (optional) doubled double quotes internally.
⍝H                   They only appear within Code fields.
⍝H                   DQ strings are realized as SQ strings when code is executed.
⍝H                   DQ character in Code fields are escaped in the APL way, by doubling. "abc""def" ==>  'abc"def'
⍝H                   \n in a DQ string results in a newline. \\n may be used to enter a backslash followed by 'n'.
⍝H                   Warning: Do not use \" to escape a DQ within a DQ string! Use APL-style doubling ("abc""def").
⍝H          SQ characters:  (')
⍝H                   There are no SQ strings in Code Fields. See DQ strings.
⍝H                   SQ (') characters are treated as ordinary characters within Code Fields, not quote characters.
⍝H                   Do not use SQ characters to delimit code fields! Use DQ strings (above).
⍝H          $        Alias for ⎕FMT, used with a format string on the left:
⍝H                   Ex:
⍝H                       ∆F 'Using $: {"F12.10" $ *1} <==> Using ⎕FMT: {"F12.10" ⎕FMT *1}'
⍝H                   Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H                   Ex: 
⍝H                       ⎕PP ⎕FR←12 645
⍝H                       ∆F '{$○1}'
⍝H                   3.14159265359 
⍝H                       ∆F '{ ⎕PP ⎕FR←34 1287 ⋄  $○1}'      ⍝ Equiv to: ∆F '{ ⎕PP ⎕FR←34 1287 ⋄ ⎕FMT ○1}' 
⍝H                   3.141592653589793238462643383279503
⍝H          $$       Alias for display (short form "disp"), viz. ⎕SE.Dyalog.Utils.disp 
⍝H                   Ex:
⍝H                       ∆F '\none {$$ 1 2 ("1" "2")} \ntwo'
⍝H                       ┌→┬─┬──┐    
⍝H                   one │1│2│12│ two
⍝H                       └─┴─┴─→┘    
⍝H          ⍝        Code-sequence comments...
⍝H                   Begins a comment within code sequence, terminated SOLELY by: 
⍝H                   a ⋄ or } character.
⍝H                   Ex:
⍝H                       ∆F'Using $: {"F12.10" $ *1 ⍝ Dollar!} <==> Using ⎕FMT: {ok←"F12.10" ⎕FMT *1 ⍝ ⎕FMT! ⋄ ok}'
⍝H                   Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H          →        Self-documenting {code} expressions...
⍝H                   A right arrow (→ or ➤) trailing a code sequence, just before (possible blanks and a) final right brace:
⍝H                   Creates two "fields," one with the code text as written, followed by the executed code.
⍝H                   Ex:
⍝H                        ∆F 'Pi is {○1→}'             ∆F 'Pi is {○1 → }'            ∆F 'Pi is {○1 ➤ }'
⍝H                   Pi is ○1➤3.141592654         Pi is ○1 ➤ 3.141592654        Pi is ○1 ➤ 3.141592654
⍝H     Space Field:  { }
⍝H                   Space field: contains 0 or more spaces, which are inserted into the formatted string.
⍝H     Text Field:   Everything else is a text field. These characters have special meaning
⍝H                   within a text field OR separate one text field from another.
⍝H        \n         A new line within a text field or DQ string within a code field (
⍝H                   Note: Actually represented as an \r U+0c given the behavior of APL ⎕FMT)
⍝H        \{         A literal { character.
⍝H        \}         A literal } character.
⍝H    
⍝ EndSection ***** Help Info
}