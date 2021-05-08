∆JOIN←{ ⎕IO←0
::COMPRESS ON    ⍝ Removes comments, extra blanks, empty lines.
:::⍝ Documentation  Treat these lines as comments, up to and including '⍝ EndDocumentation'
   To ⎕FIX me:    2 ∆FIX 'MyDyalogLibrary/pmsLibrary/src/∆JOIN.dyalog'
   Join two objects, ⍺ and ⍵, converting to strings, and padding as necessary.
   Syntax:  ⍺ ⍺⍺:NS ∇ ⍵⍵:NS|CV ⍵
   ⍺:  left obj,
   ⍵:  right obj; both converted to string matrices
   ⍺⍺: 0-   put ⍺ to left of ⍵   (not centered)
       0.1- put ⍺ to left of ⍵   (centered)      (0.1 or any float ⍺⍺, 0<⍺⍺ and ⍺⍺<2)
       1-   put ⍺ above ⍵        (not centered)
       1.1- put ⍺ above ⍵        (centered)      (1.1 or any float ⍺⍺, 1<⍺⍺ and ⍺⍺<2)
   ⍵⍵: 1-   place a "rule" (line) of appropriate type (horiz '—' or vert '|') between ⍺ and ⍵
       str- place one "rule" for each char of <str> to right or below ⍺, per ⍺⍺.
   Example:
       m←4 3⍴⍳6  ⋄  n←2 3⍴⍳6
       m (0 ∆JOIN 1) n          m (0.2 ∆JOIN 1) n
     0 1 2│0 1 2              0 1 2│
     3 4 5│3 4 5              3 4 5│0 1 2
     0 1 2│                   0 1 2│3 4 5
     3 4 5│                   3 4 5│
 ⍝ EndDocumentation

         dir rule←⍺⍺ ⍵⍵
         ruleChars← (⌊dir){ww←∊⍵⍵ ⋄ 0≠1↑0⍴ww: ww ⋄ ww/(⍺⍺⊃⍵)  }rule⊣'│—'
         ctr← dir≠⌊dir
         horz← 0=⌊dir
         nhorz←~horz
 "Macro definitions are for demonstration purposes. Performance advantages are modest, given minimal reuse."C 
  ::DEFL Cat←       ,[ horz]
  ::DEFL Rot←       ⌽[nhorz]
  ::DEFL Extend←    maxLen↑[nhorz]    "Take←↑[nhorz]"C
  ::DEFL TakeAlt←   ↑[ horz]
  ::DEF  hasRule←   0<(≢ruleChars)∘⊣  "Silly: made a fn, when this would do: hasRule← 0<≢ruleChars"C
  ::DEF  NotNum←    0=80|⎕DR
  ::DEF  NotSimple← 1<|∘≡
  ::DEF  AddRule←ruleChars∘{0=≢⍺: ⍵ ⋄ 1=≢⍺: ⍵ Cat ⍬⍴⍺ ⋄ (1↓⍺) ∇ ⍵ Cat ⍬⍴⍺}  ⍝ See note above re: "rule"
  ::DEF  NumPad←{nhorz:⍵  ⋄  (hasRule∨NotSimple∨NotNum)⍺:  ⍵ ⋄  (-1+1⌷⍴⍵) TakeAlt ⍵}
  ::DEF  Center←maxLen{~ctr: ⍵ ⋄ (-⌊0.5×|⍺⍺-⍺)Rot ⍵ }

         a←AddRule ⎕FMT  ⍺
         b←NumPad ∘⎕FMT⍨ ⍵
         aLen bLen←(nhorz)⌷∘⍴¨a b
         maxLen←⌈/aLen bLen
         a2←aLen Center Extend a
         b2←bLen Center Extend b
         a2 Cat b2
}
