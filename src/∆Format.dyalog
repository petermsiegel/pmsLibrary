result←∆F format_omegas
⍝H ∆F: A basic APL-aware formatting function (file: ∆Format.dyalog).
⍝H     [⎕←] ∆F 'formatting_string' ⍵0 ⍵1 ⍵2 ...
⍝H Special symbols:
⍝H     {code}        APL Code Field. Accesses arguments ⍵0 (1st vector after formatting string), ⍵1, ⍵2, through ⍵N.
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
⍝H     Outside {code} sequence...
⍝H     ⋄             Field separator. Any trailing blanks will separate the prior field from the next.
⍝H     { }           Field separator. Any internal blanks will separate the prior field from the next.
⍝H     \n            Returns a newline (actually an \r presented to APL ⎕FMT)
⍝H     \⋄            A simple ⋄ character.
⍝H     \{            A simple { character.
⍝H     \}            A simple } character.
⍝H    

 ;braceI;braceP;fields;format;getOmega;GenBalanced;help;miscI;miscP;omegaN;pats
 ;Escape;DQ2SQ;DfnArg;simpleI;simpleP;spacerI;spacerP;omegas;∆result;⍙FLD;__gbCtr
 ;⎕IO;⎕TRAP

 ⎕TRAP←0 'C' '⎕SIGNAL/⎕DMX.(EM EN)'
 ⎕IO←0

 :Section ********* Utilities
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
       ok num ← ⎕VFI ⍵
       0∊ok: ⎕SIGNAL/('Index error: ',⍵,' out of range')3
       omegaN∘←num
       ⍵
      }
      :Section ********* Main Loop Utilities     
        Escape←{
              '(?<!\\)\\n' '\\([{}⋄])'⎕R'\r' '\1'⊣⍵
          }
        DQ2SQ←{
            DQ2←'""' ⋄ SQ←''''
            SQ,SQ,⍨(~DQ2⍷str)/str←1↓¯1↓⍵ 
        }
        DfnArg←{
            omegaNumP← '⍵(\d{1,2})' 
            omega2P←   '⍵⍵'
            formatP←   '(?<!\\)\$'
            commentP←  '(?x) (?:⍝ (?| (?:"[^"]*")+ | [^⋄}]+)* )'
            pats←quoteP formatP omegaNumP omega2P commentP
            quoteI formatI omegaNumI omega2I commentI←⍳≢pats
            dfn←pats ⎕R{CASE←⍵.PatternNum∘=
                CASE quoteI:    DQ2SQ ⍵∘⍙FLD 0
                CASE formatI:   ' ⎕FMT '
                CASE omegaNumI: '(⍵⊃⍨⎕IO+',')',⍨ getOmega ⍵∘⍙FLD 1
                CASE omega2I:   '(⍵⊃⍨⎕IO+',')',⍨⍕omegaN ⊣omegaN+←1
                CASE commentI:  ' '            ⍝⊣⎕←'Comment seen: "','"',⍨⍵ ⍙FLD 0
            }⍵
            caller←⊃1↓⎕RSI
            0::⎕SIGNAL/⎕DMX.(EM EN)⊣⎕←↑⎕DMX.DM
            ⍎'(caller.',dfn,'omegas)'
        }
      :EndSection ***** Main Loop Utilities
 :EndSection ***** Utilities

 :Section ********* Initializations
     :If 0=≢format_omegas
         help←'⍝H'{l←≢⍺⋄ l↓¨((⊂⍺)≡¨l↑¨⍵)/⍵}⎕NR ⊃⎕XSI
         ⎕ED 'help'
         :Return
     :EndIf
     format_omegas←⊆format_omegas
     format←⊃format_omegas
     omegas←1↓format_omegas
 
     omegaN←¯1
     result←⎕FMT''

      ⍝  Main Patterns
     braceP←GenBalanced'{}'
     quoteP←'(?<!\\)(?:"[^"]*")+'
     simpleP←'(\\.|[^{⋄])+'
     spacerP←'(?|\{(\h*)\}|⋄(\h*))'
     miscP←'.'
 :EndSection ***** Initializations

 :Section ********* Main
     pats←simpleP spacerP braceP miscP
     simpleI spacerI braceI miscI←⍳≢pats
     {}pats ⎕R{
         CASE←⍵.PatternNum∘= ⋄ f0←⍵ ⍙FLD 0
         CASE simpleI:∆result Escape f0
         CASE spacerI:∆result ⍵ ⍙FLD 1
         CASE braceI:∆result DfnArg f0
         CASE miscI:∆result ⍵ ⍙FLD 0
     }⊣⊆format

 :EndSection ***** Main