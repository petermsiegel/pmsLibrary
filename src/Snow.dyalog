{tid}←Snow delayMs
  ;r;c;snow;star;tree;moon;Put;sky;flakes;window;mask;minDelayMs; ULine;had;wobble
  ;⎕IO;⎕TRAP

⍝ A tweak of Adam B's version

  ⎕IO←1 ⋄ ⎕TRAP←1000 'C' '→Done'
  :If 0=⎕TID ⋄ tid←Snow&delayMs ⋄ :Return ⋄ :EndIf

⍝ delayMs:  50=flurry, 125=mild storm,  250=squall
  :If 0=delayMs ⋄ delayMs← 125 ⋄ :EndIf 
   minDelayMs← 10                    ⍝ Under ~10 ms and the screen doesn't update well...

  r←30 ⋄ c←⎕PW-5 
  snow←∊,\'❆❊❄' 
  tree←∊,\'🌲🌲🌲🌲🌴🌳' 
  moon←'☾☽☾☽🌙🌛🌜🌙🌛🌜🌕🌝'
  star←∊,\'☆★✦✪✩✧✮✭✬✫✯⁑⁂✰✴✳✲✱✥✤✣✢✼✻✺✹✸✷✶✵❇❃❂❁❀✿✾✽≛⋆❅❆❄❋❊❉❈⍣✫✬⭐❂🌟❈⁑ᕯ＊⚝💫⯨⯩⯪⯫𓇻'

⍝ open background editor as fn (for colours)
  ⎕ED&'window'             
  ⍞←'⎕TKILL',⎕TID,'⍝ Press Enter to stop (or issue an Interrupt)'

  Put←{(⍺,' ')[l⌊?c⍴⍵×l←1+≢⍺]}         ⍝ ⍵-spread-out random chars ⍺
  ULine←{⊃⎕FMT'_'(⎕UCS 8)⍵}¨           ⍝ combine chars with underline
  :Repeat ⍝ set vars
      sky←moon[?≢moon]@(⊂?c,⍨r-1)⊢(↑star∘Put¨40⍴⍨r-1)⍪(tree Put 5)
      flakes←r c⍴'' ⋄ had←c⍴0
      :Repeat
          wobble← ¯10  ⍝ Orig: ¯2
          flakes((snow Put r)⍪¯1↓⌽⍨)←1⌊wobble+?r⍴ 7
          mask←(sky(~∊)tree)∧(' '≠flakes)
          window←ULine@{had}@r⊢(mask/⍥,flakes)@{mask}sky
          had∨←(' '≠⊢⌿flakes)∧(tree(~∊⍨)⊢⌿sky)
          ⎕DL 1000÷⍨ minDelayMs⌈delayMs   
      :Until ~' '∊⊢⌿window
  :EndRepeat

  Done: 
    ⎕←(⎕UCS 13),'Done...'
