∆F←{ 
    0=≢⍵: { help←'⍝H'{l←≢⍺⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⍵ ⋄ ''⊣⎕ED 'help'} ⎕NR 0⊃⎕XSI

      (⎕NS '').{ ⍝ Move us out of the user space...
      0:: ⎕SIGNAL/⎕DMX.(EM EN)
      
      ⍝Section ********* Utilities
          ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
              def←'' ⋄ isN←0≠⍬⍴0⍴⍵
              p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
              B[O[p]+⍳L[p]]
          }
          __gbCtr←1     ⍝ Counter to ensure unique names (See pcre (?J)) option).
          GenBalanced←{
            ⍝ GenBalanced '()' or equiv. balanced delimiters...
            ⍝ import: __gbCtr
            ⍝ L is left brace, R is right brace, N is unique pattern name GB1, GB2. See __gbCtr
              L R←⊂¨'\',¨⍵
              N←⊂'GB',⍕__gbCtr ⋄ __gbCtr+←1
              _p←'(?x) (?<N> '                                 ⍝ N←'GB1' [first call] and L R←'{}'
              _p,←'L'                                          ⍝ ∘ Match "{", then atomically 1 or more of:
              _p,←'       (?> (?: \\.)+     | [^LR\\"]+ '      ⍝     ∘ (\.)+ | [^{}\\''"]+ OR
              _p,←'         | (?: "[^"]*")+ '                  ⍝     ∘ QT anything QT  OR
              _p,←'         | (?: ⍝ (?|(?: "[^"]*")+|[^⋄}]+)*)' ⍝     ∘ Comments up to ⋄ (outside quotes) 
              _p,←'         | (?&N)*'                          ⍝     ∘ bal1 {...} recursively 0 or more times
              _p,←'       )+'                                  ⍝     ∘ Else submatch done. Finally,
              _p,←'R   )'                                      ⍝ ∘ Match "}"
              ∊N@('N'∘=)⊣∊L@('L'∘=)⊣∊R@('R'∘=)⊣_p              ⍝ 'R'→R, 'L'→L, 'N'→N
          }
          SetResult←{
              0=≢⍵: ''          ⍝ Null ⍵ means nothing added to RESULT...
              r← USER_SPACE.⎕FMT ⍵
              h←(≢RESULT)⌈≢r
              RESULT∘←(h↑RESULT),[1]h↑r
              ''
          }
          GetOmega←{
            omvec lit←⍺
            (ok ix) ixstr ← {0=1↑0⍴⍵: (1 ⍵)(⍕⍵) ⋄ (⎕VFI ⍵) ⍵}⍵
            0∊ok: ⎕SIGNAL/('LOGIC error: ',lit,' is not a number.')3
            (ix<0)∨ix≥≢omvec: ⎕SIGNAL/('Index error accessing ⍵⍵/⍵',(⍕ix),'.') 3
            OMEGA_IX∘←ix
            ixstr
            }
            ⍝Section ********* Main Loop Utilities     
              Escape←{
                    '(?<!\\)\\n' '\\([{}⋄])'⎕R'\r' '\1'⊣⍵
                }
              DQ2SQ←{
                  DQ2←'""' ⋄ SQ←''''
                  SQ,SQ,⍨(~DQ2⍷str)/str←'(?<!\\)\\n' ⎕R '\r'⊣1↓¯1↓⍵ 
              }
              DfnField←{
                  omDigP← '⍵(\d{1,2})' 
                  om2P←   '⍵⍵'
                  fmtP←   '(?<!\\)\$'
                  comP←  '(?x) (?:⍝ (?| (?:"[^"]*")+ | [^⋄}]+)* )'
                  noteP←     '[→➤]\h*\}$'    ⍝ Trailing → or ➤ (like Python =) creates note format: dfn_text➤ ⍎dfn
                  pats←quoteP fmtP omDigP om2P comP noteP 
                  quoteI fmtI omDigI om2I comI noteI ←⍳≢pats
                  noteF←0
                  dfn←pats ⎕R{CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD
                      CASE quoteI: DQ2SQ f 0
                      CASE fmtI:   ' ⎕FMT '
                      CASE omDigI: '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS (f 0)  GetOmega f 1
                      CASE om2I:   '(⍵⊃⍨⎕IO+',')',⍨ OMEGAS '⍵⍵'   GetOmega OMEGA_IX+1
                      CASE comI:   ' '             
                      CASE noteI:  '}'⊣ noteF∘←1
                  }⍵
                  0::⎕SIGNAL/⎕DMX.(EM EN)   
                  res←⍎'(USER_SPACE.',dfn,'OMEGAS)'
                  noteF: res⊣(SetResult '([→➤]) ?(\h*)$'⎕R '➤ \2'⊣1↓¯1↓⍵)          ⍝  '➤' is U+10148
                  res 
              }
            ⍝EndSection ***** Main Loop Utilities
      ⍝EndSection ***** Utilities

      ⍝Section ********* Initializations
        ⍝ Top-level Patterns
          dfnP←    (GenBalanced'{}'),'\h*'
          quoteP←  '(?<!\\)(?:"[^"]*")+'
          simpleP← '(\\.|[^{⋄])+'
          spacerP← '(?|\{(\h*)\}(\h*)|⋄(\h*))'
          miscP←   '.'
        ⍝ Basic Initializations
          ⎕IO←0
          USER_SPACE←⊃⌽⎕RSI
          FORMAT←⊃⊆⍵
          OMEGAS←1↓⊆⍵ 
          OMEGA_IX←¯1
          RESULT←⎕FMT''
      ⍝EndSection ***** Initializations

      ⍝Section ********* Main
          pats←simpleP spacerP dfnP miscP
          simpleI spacerI dfnI miscI←⍳≢pats
          _←pats ⎕R{    
              ⋄ CASE←⍵.PatternNum∘= ⋄ f←⍵∘⍙FLD 
              CASE simpleI:''⊣{trail←-+/∧\⌽⍵=' ' 
                SetResult¨ (Escape trail↓⍵)(trail↑⍵)
                }f 0
              CASE spacerI:SetResult ∊f¨ 1 2
              CASE dfnI:''⊣{trail←-+/∧\⌽⍵=' '
                SetResult¨(DfnField trail↓⍵)(trail↑⍵)
              }f 0
              CASE miscI: SetResult f 0
          }⊣FORMAT
      RESULT
  }⍵
 ⍝EndSection ***** Main

⍝Section ***** HELP INFO
⍝H ∆F: A basic APL-aware formatting function (file: ∆Format.dyalog).
⍝H     [⎕←] ∆F 'formatting_string' ⍵0 ⍵1 ⍵2 ...
⍝H Formatting strings consist of text fields, code fields, and space fields. 
⍝H    ∘ Code fields are APL "dfns" surrounded by (unescaped) braces {}.
⍝H    ∘ Space fields consist of (unescaped) braces with 0 or more internal spaces.
⍝H    ∘ Text fields are everything else. A text field is terminated:
⍝H      ∘ At the end of the formatting string;
⍝H      ∘ When an (unescaped) ⋄ symbol is encountered, or if a code or space field is encountered.
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
⍝H          DQ characters: "..."
⍝H                   DQ strings are realized as SQ strings when code is executed.
⍝H          SQ characters: '...'
⍝H                   SQ (') characters are treated as ordinary characters, not quote characters.
⍝H                   Do not use SQ characters to delimit code strings! Use DQ strings (above).
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
⍝H          ⍝        Begins a comment within code sequence, terminated SOLELY by: 
⍝H                   a ⋄ or } character outside a DQ string ("...").
⍝H                   Ex:
⍝H                       ∆F'Using $: {"F12.10" $ *1 ⍝ Dollar!} <==> Using ⎕FMT: {ok←"F12.10" ⎕FMT *1 ⍝ ⎕FMT! ⋄ ok}'
⍝H                   Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H          →        A right arrow trailing a code sequence, just before (possible blanks and a) final right brace:
⍝H                   Creates two "fields," one with the code text as written, followed by the executed code.
⍝H     Space Field:  { }
⍝H                   Space field: contains 0 or more spaces, which are inserted into the formatted string.
⍝H     Text Field:   Everything else is a text field. These characters have special meaning
⍝H                   within a text field OR separate one text field from another.
⍝H        ⋄          Field separator: separates text (and other) fields, one from the next. 
⍝H                   Any trailing blanks will be interpreted as in space fields (above).
⍝H        \n         A new line within a text field or DQ string within a code field (
⍝H                   Note: Actually represented as an \r given the behavior of APL ⎕FMT)
⍝H        \⋄         A literal ⋄ character.
⍝H        \{         A literal { character.
⍝H        \}         A literal } character.
⍝H    
⍝EndSection ***** Help Info
}