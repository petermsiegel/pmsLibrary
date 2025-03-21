﻿ r←{vals}DollarSign str;pats;Sub;SubFn;strings;nulls;marker ⍝ $ string enhancement ${1} for indexing into left arg, ${expr}, and \JSON escapes
 ;⎕IO;⎕ML
 ⎕IO ⎕ML←1 1
 :If 900⌶⍬
     vals←⊢
 :EndIf
 :Trap 0
     str←'\$\{([^}'']*(''[^'']*''))*[^}'']*\}' '\\u....|\\.'⎕R{⍵.PatternNum:⎕JSON⍠'Dialect' 'JSON5'⊢'"',⍵.Match,'"' ⋄ ⍵.Match}str
     pats←'\$\{[\d ]+\}' '\$\{([^}'']*(''[^'']*''))*[^}'']*\}'⍝ \w ${12} ${expr}
     nulls←1+⌈/0,'\x{0}+'⎕S 1⊢str
     marker←nulls⍴⎕UCS 0
     strings←⍬⊃⍤⍴⍣(1≥|≡str)(nulls↓¨⊢⊂⍨marker∘⍷)¨⊆pats ⎕R marker⊢str
     Sub←{
         ⍵.i←{×⍵.⎕NC'i':1+⍵.i ⋄ ⎕IO}⍵
         3=≢⍵.Match:⍵.i⊃⍵⍵
         levels←+/∧\⎕RSI=⎕THIS
         Content←levels(⊃⍬⍴levels↓⎕RSI,⎕THIS).(86⌶)1↓⍵.Match ⍝ in calling env
         i←~⍵.PatternNum
         i∧3=⎕NC'⍺⍺':⎕SIGNAL⊂('EN' 2)('Message' 'Indexing requires a left argument')
         ⍕((1/⍺⍺)⊃⍨⊂)⍣(~⍵.PatternNum)⊢⍺⍺ Content ⍵⍵
     }
     SubFn←vals Sub strings
     r←pats ⎕R SubFn str
 :Else
     ⎕SIGNAL ⎕DMX.{⊂'EM' 'EN' 'Message',⍥⊂¨('$ ',EM) EN Message}⍬
 :EndTrap
