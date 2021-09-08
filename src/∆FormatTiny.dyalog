 result←∆F format_ømegas

⍝ A basic APL-aware formatting function

 ;braceI;braceP;fields;format;GenBalanced;miscI;miscP;omegaN;pats
 ;simpleI;simpleP;spacerI;spacerP;ømegas;∆result;⍙FLD;__gbCtr
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
         _p←'(?x) (?<N> '                                            ⍝ Pattern <bal1>: N←'bal1' and L R←'{}'
         _p,←'L'                                                     ⍝ ∘ Match "{", then atomically 1 or more of:
         _p,←'       (?> (?: \\.)+     | [^LR\\"]+ '                 ⍝     ∘ (\.)+ | [^{}\\''"]+ OR
         _p,←'         | (?: "[^"]*")+ '                             ⍝     ∘ QT anything QT  OR
         _p,←'         | (?&N)*'                                     ⍝     ∘ bal1 {...} recursively 0 or more times
         _p,←'       )+'                                             ⍝     ∘ Else submatch done. Finally,
         _p,←'R   )'                                                 ⍝ ∘ Match "}"
      ⍝ Repl. 'N' with Gen1 (1st call), 'L' with \{, 'R' with \}.
         ∊N@('N'∘=)⊣∊L@('L'∘=)⊣∊R@('R'∘=)⊣_p
     }
     ∆result←{
         r←⎕FMT ⍵
         h←(≢result)⌈≢r
         result∘←(h↑result),[1]h↑r
         ''
     }
 :EndSection ***** Utilities

 :Section ********* Initializations
     :If 0=≢format_ømegas
         'Help info'
         :Return
     :EndIf
     format_ømegas←⊆format_ømegas
     format←⊃format_ømegas
     ømegas←1↓format_ømegas

     omegaN←0
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
         NL←⎕UCS 13
         Escape←{
             '(?<!\\)\\n' '\\([{}⋄])'⎕R'\r' '\1'⊣⍵
         }
         DQ2SQ←{
             DQ2←'""' ⋄ SQ←''''
             str←1↓¯1↓⍵
             str←(~DQ2⍷str)/str
             SQ,SQ,⍨str  ⍝ (1+str∊SQ)/str
         }
         DfnArg←{
             omegaNumP←'⍵(\d{1,2})' ⋄ omega2P←'⍵⍵'
             formatP←'(?<!\\)\$'
             pats←quoteP formatP omegaNumP omega2P
             quoteI formatI omegaNumI omega2I←⍳≢pats
             dfn←pats ⎕R{CASE←⍵.PatternNum∘=
                 CASE quoteI:DQ2SQ ⍵∘⍙FLD 0
                 CASE formatI:' ⎕FMT '
                 CASE omegaNumI:'(⍵⊃⍨⎕IO+',')',⍨⍵∘⍙FLD 1
                 CASE omega2I:(omegaN+←1)⊢'(⍵⊃⍨⎕IO+',')',⍨⍕omegaN
             }⍵
             Calr←⊃1↓⎕RSI
             0::⎕SIGNAL/⎕DMX.(EM EN)⊣⎕←↑⎕DMX.DM
             ⍎'(Calr.',dfn,'ømegas)'
         }
         CASE←⍵.PatternNum∘= ⋄ f0←⍵ ⍙FLD 0
         CASE simpleI:∆result Escape f0
         CASE spacerI:∆result ⍵ ⍙FLD 1
         CASE braceI:∆result DfnArg f0
         CASE miscI:∆result ⍵ ⍙FLD 0
     }⊣⊆format

 :EndSection ***** Main