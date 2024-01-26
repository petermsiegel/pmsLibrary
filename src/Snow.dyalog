 {tid}←Snow delayMs
 ;r;c;snow;star;tree;moon;Put;sky;flakes;window;mask;ULine;had
 ;⎕IO

 ⍝ delayMs:  50=flurry, 125=mild storm,  250=squall
 :If 0=delayMs ⋄ delayMs←1000÷8 ⋄ :EndIf

 ⎕IO←1
 :If 0=⎕TID
     tid←Snow&delayMs ⋄ :Return
 :EndIf

 r←30 ⋄ c←⎕PW-5 ⋄ snow←∊,\'❆❊❄' ⋄ star←∊,\'٭✰☆' ⋄ tree←∊,\'🌲🌲🌲🌲🌴🌳' ⋄ moon←'☾☽☾☽🌙🌛🌜🌙🌛🌜🌕🌝'
 star←∊,\'☆★✦✪✩✧✮✭✬✫✯⁑⁂✰✴✳✲✱✥✤✣✢✼✻✺✹✸✷✶✵❇❃❂❁❀✿✾✽≛⋆❅❆❄❋❊❉❈⍣✫✬⭐❂🌟❈⁑ᕯ＊⚝💫⯨⯩⯪⯫𓇻'

⍝ open background editor as fn (for colours)
 ⎕ED&'window' ⋄ ⎕NQ ⎕SE'GotFocus' ⍝ go back to session
 ⍞←'⎕TKILL',⎕TID,'⍝ Press Enter to stop'

 Put←{(⍺,' ')[l⌊?c⍴⍵×l←1+≢⍺]} ⍝ ⍵-spread-out random ⍺ chars
 ULine←{⊃⎕FMT'_'(⎕UCS 8)⍵}¨   ⍝ combine chars with underline
 :Repeat ⍝ set vars
     sky←moon[?≢moon]@(⊂?c,⍨r-1)⊢(↑star∘Put¨40⍴⍨r-1)⍪(tree Put 5)
     flakes←r c⍴'' ⋄ had←c⍴0

     :Repeat
         flakes((snow Put 30)⍪¯1↓⌽⍨)←1⌊¯2+?r⍴7

         mask←(sky(~∊)tree)∧(' '≠flakes)
         window←ULine@{had}@r⊢(mask/⍥,flakes)@{mask}sky
         had∨←(' '≠⊢⌿flakes)∧(tree(~∊⍨)⊢⌿sky)

         ⎕DL delayMs÷1000
     :Until ~' '∊⊢⌿window
 :EndRepeat
