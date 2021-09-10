∆F←{
format_omegas←⍵
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
⍝H     Code Field
⍝H     {code}        APL Code Field. Accesses arguments ⍵0 (1st vector after formatting string), ⍵1, ⍵2, through ⍵N.
⍝H                   Trailing blanks will be interpreted as if a space field.
⍝H          Within {code} sequence...
⍝H          ⍵N       Returns, for N an integer 0≤N≤99, a value of Nth vector of ⍵, i.e. (⍵⊃⍨N+⎕IO).
⍝H          ⍵⍵       Returns the "next" vector in ⍵. By definition, 
⍝H                   ⍵⍵ is ⍵0 or 1 past the last field referenced via ⍵N (e.g. ⍵3).
⍝H                   Ex:
⍝H                      ∆F '0: {⍵⍵} 1: {⍵⍵} 3: {⍵3} 4: {⍵⍵}' 'zero' 'one' 'two' 'three' 'four' 
⍝H                   0: zero 1: one 3: three 4: four
⍝H          "..."    DQ strings are realized as SQ strings when code is executed.
⍝H          '        SQ (') characters are treated as ordinary characters, not quote characters.
⍝H          $ ...    Alias for ⎕FMT, used with a format string on the left:
⍝H                   Ex:
⍝H                      ∆F 'Using $: {"F12.10" $ *1} <==> Using ⎕FMT: {"F12.10" ⎕FMT *1}'
⍝H                   Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H          ⍝ ...    Comment within code sequence, terminated SOLELY by a ⋄ or } char outside DQ strings ("...").
⍝H                   Ex:
⍝H                      ∆F'Using $: {"F12.10" $ *1 ⍝ Dollar!} <==> Using ⎕FMT: {ok←"F12.10" ⎕FMT *1 ⍝ ⎕FMT! ⋄ ok}'
⍝H                   Using $: 2.7182818285 <==> Using ⎕FMT: 2.7182818285
⍝H     Space Field
⍝H     { }           Space field: contains 0 or more spaces, which are inserted into the formatted string.
⍝H     Text Field    Everything else is a text field. These characters have special meaning
⍝H                   within a text field OR separate one text field from another.
⍝H     ⋄             Field separator: separates text (and other) fields, one from the next. 
⍝H                   Any trailing blanks will be interpreted as in space fields (above).
⍝H     \n            A new line within a text field or DQ string within a code field (
⍝H                   Note: Actually represented as an \r given the behavior of APL ⎕FMT)
⍝H     \⋄            A literal ⋄ character.
⍝H     \{            A literal { character.
⍝H     \}            A literal } character.
⍝H    

 0:: ⎕SIGNAL/⎕DMX.(EM EN)
 ⎕IO←0

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
     ∆result←{
         r←⎕FMT ⍵
         h←(≢result)⌈≢r
         result∘←(h↑result),[1]h↑r
         ''
     }
     getOmega←{
       omvec lit←⍺
       (ok ix) ixstr ← {0=1↑0⍴⍵: (1 ⍵)(⍕⍵) ⋄ (⎕VFI ⍵) ⍵}⍵
       0∊ok: ⎕SIGNAL/('LOGIC error: ',lit,' is not a number.')3
       (ix<0)∨ix≥≢omvec: ⎕SIGNAL/('Index error: Not enough elements in ⍵ for ',lit,'.') 3
       omegaN∘←ix
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
            omegaNumP← '⍵(\d{1,2})' 
            omega2P←   '⍵⍵'
            formatP←   '(?<!\\)\$'
            commentP←  '(?x) (?:⍝ (?| (?:"[^"]*")+ | [^⋄}]+)* )'
            lhsSpaceP← '^\h+' 
            rhsSpaceP← '\h+$'
            pats←lhsSpaceP quoteP formatP omegaNumP omega2P commentP rhsSpaceP
            lhsSpaceI quoteI formatI omegaNumI omega2I commentI rhsSpaceI←⍳≢pats
            dfn←pats ⎕R{CASE←⍵.PatternNum∘=
                CASE quoteI:    DQ2SQ ⍵∘⍙FLD 0
                CASE formatI:   ' ⎕FMT '
                CASE omegaNumI: '(⍵⊃⍨⎕IO+',')',⍨ omegas (⍵⍙FLD 0) getOmega ⍵∘⍙FLD 1
                CASE omega2I:   '(⍵⊃⍨⎕IO+',')',⍨ omegas ('⍵⍵')    getOmega omegaN+1
                CASE commentI:  ' '            ⍝⊣⎕←'Comment seen: "','"',⍨⍵ ⍙FLD 0
            }⍵
            caller←⊃1↓⎕RSI
            0::⎕SIGNAL/⎕DMX.(EM EN)  ⍝⊣⎕←↑⎕DMX.DM
            ⍎'(caller.',dfn,'omegas)'
        }
      ⍝EndSection ***** Main Loop Utilities
 ⍝EndSection ***** Utilities

 ⍝Section ********* Initializations
    0=≢format_omegas: {
         help←'⍝H'{l←≢⍺⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⍵
         ''⊣⎕ED 'help'
    }⎕NR ⊃⎕XSI
     format_omegas←⊆format_omegas
     format←⊃format_omegas
     omegas←1↓format_omegas
 
     omegaN←¯1
     result←⎕FMT''

  ⍝  Main Patterns
     dfnP←    (GenBalanced'{}'),'\h*'
     quoteP←  '(?<!\\)(?:"[^"]*")+'
     simpleP← '(\\.|[^{⋄])+'
     spacerP← '(?|\{(\h*)\}(\h*)|⋄(\h*))'
     miscP←   '.'
 ⍝EndSection ***** Initializations

 ⍝Section ********* Main
     pats←simpleP spacerP dfnP miscP
     simpleI spacerI dfnI miscI←⍳≢pats
     _←pats ⎕R{    
         CASE←⍵.PatternNum∘= ⋄ f0←⍵ ⍙FLD 0
         CASE simpleI:{
           _← ∆result Escape ⍵↓⍨-trail←+/∧\⌽⍵=' ' 
           ∆result⍣(0<trail)⊣trail⍴' ' 
         }f0
         CASE spacerI:∆result ∊⍵ ⍙FLD¨ 1 2
         CASE dfnI:{
           _←∆result DfnField ⍵↓⍨-trail←+/∧\⌽⍵=' '
           ∆result⍣(0<trail)⊣trail⍴' '  
         }f0
         CASE miscI:∆result ⍵ ⍙FLD 0
     }⊣⊆format
result
 ⍝EndSection ***** Main
}