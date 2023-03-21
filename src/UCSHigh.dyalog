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
    sel← '𝗔𝘈𝘼𝘼'/⍨'B' 'I' 'BI' 'IB' 
    mask← ⍵∊ std← ⎕A,⎕C ⎕A
    alt← ⎕UCS (⍳52)+ ⎕UCS sel   
    { alt[ std⍳ mask/ ⍵ ] } @ ( ⍸mask ) ⊢⍵
 }
