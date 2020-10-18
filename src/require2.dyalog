 require2←{⍺←⊃⎕RSI
     ⍝ require [flags] [objects]
     ⍝

     DEBUG←1
     CALLER←⍺ ⋄ defSfx←'⍙⍙.require'
     ⎕IO←0
     Err←⎕SIGNAL∘11

     NL←⎕UCS 10

⍝ ------ UTILITIES
⍝ ∆F:  Find a pcre field by name or field number
     ∆F←{⎕IO←0
         N O B L←⍺.(Names Offsets Block Lengths)
         def←'' ⋄ isN←0≠⍬⍴0⍴⍵
         p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
         B[O[p]+⍳L[p]]
     }

     DLB←{⍵↓⍨+/∧\⍵=' '}                                   ⍝ Delete leading blanks
  ⍝ ========= MAIN



     ScanOptions←{  ⍝ Process options -fff, returning unaffected tokens...
         0=≢⍵:⍺ ⋄ opt←0⊃⍵ ⋄ tokens←1↓⍵ ⋄ done←0
         '-'≠1↑opt:(⍺,⊂opt)∇ tokens
         tokens←tokens{
             case←(1↑1↓opt)∘≡∘, ⋄ with←⊣
             case'f':⍺⊣force∘←1
             case'r':⍺ with caller libSfx∘←#''             ⍝ -root,          also sets -lib ""
             case'R':⍺ with caller libSfx∘←# defSfx        ⍝ -Root,          also sets -lib '⍙⍙.require'
             case's':⍺ with caller libSfx∘←⎕SE''           ⍝ -session        also sets -lib ""
             case'S':⍺ with caller libSfx∘←⎕SE defSfx      ⍝ -Session        also sets -lib '⍙⍙.require'
             case'd':⍺ with DEBUG∘←1                       ⍝ -debug
             case'-':⍺ with done∘←1                        ⍝ --              done with options
             case'c':(1↓⍺) with caller∘←⊃⍺                 ⍝ -caller caller
             case'l':(1↓⍺) with libSfx∘←⊃⍺                 ⍝ -lib    prefix

             Err'Invalid option: ',opt
         }opt
         done:⍺,tokens
         ⍺ ∇ tokens
     }∘,

     ScanTokens←{
         UnDQ←{s/⍨~DQ2⍷s←1↓¯1↓⍵} ⋄ DQ2←2⍴'"'               ⍝ Convert DQ strings to SQ strings
         ⍝     DQ           SQ              WorD    SPaces
         pList←'("[^"]*")+' '(''[^'']*'')+' '[^ ]+' ' +'
         eDQ eSQ eWD eSP←⍳≢pList
         ResolveTokens←{
             f0←⍵ ∆F 0 ⋄ case←⍵.PatternNum∘∊
             case eWD:f0 ⋄ case eDQ:UnDQ f0 ⋄ case eSQ:1↓¯1↓f0 ⋄ case eSP:NL
             Err'Logic Error'
         }
         pList ⎕R ResolveTokens⊣⊆DLB ⍵
     }

     debug force caller libSfx←0 0 CALLER'⍙⍙.require'
     tokens←⍬ ScanOptions ScanTokens ⍵

     _←{
         ⍵:⎕←'force'force'  caller'caller'  libSfx'libSfx
         ''
     }DEBUG
     tokens
 }
