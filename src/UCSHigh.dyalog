 ⍝ Load via 2 ⎕FIX 'file://UCSHigh.dyalog'

 UCSScan←{ 
    
    ⍝ Single *: Ital, **: Bold, ***: BI
    ⍝ Starting text must immed precede a non-blank.
    ⍝ Ending   text must immed follow  a non-blank.
      pats← {'\*{',⍵,'}([^*\s].*?[^*\s])\*{',⍵,'}'}∘⍕¨3 2 1
      pats ⎕R {
          txt← ⍵.( Lengths[1]↑Offsets[1]↓Block )
          0=≢txt: ⍵.( Lengths[0]↑Offsets[0]↓Block ) ⍝ As is...
          choice← 'BI' 'B' 'I'  ⊃⍨ ⍵.PatternNum
          choice UCSHigh.UCSHigh txt 
     }⊢ ⍵
 }

:Namespace UCSHigh
 UCSHigh←{ 
      ⍝ UCSHigh: 
      ⍝ [font← 'B'] ∇ string 
      ⍝    font: [ 'B' | 'I' | 'BI' | 'IB' | '' ]
      ⍝    string: a char vector (or scalar)
      ⍝ ∘ Returns the vector with A-Za-z replaced by the Unicode 
      ⍝   bold (B) [the default], italic (I), or bold-italic (BI or IB) equivalent.
      ⍝ ∘ If <font> is '', returns <string> as is.
      ⍝ -----
      ⍝ Uses sans fonts, since they are roughly the same width as the std Dyalog font.
      ⍝
        ⎕IO←0 ⋄ ⍺← 'B'  
        0=≢⍺: ⍵ 
        sel← '𝗔𝘈𝘼𝘼'/⍨'B' 'I' 'BI' 'IB' ≡¨⊂⍺
        mask← ⍵∊ std← ⎕A,⎕C ⎕A
        alt← ⎕UCS (⍳52)+ ⎕UCS sel   
        { alt[ std⍳ ⍵ ] } @ ( ⍸mask ) ⊢⍵
    }
    :EndNamespace
 
