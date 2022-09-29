﻿ ⍝ "Here document" Functions
 ⍝   ∆HERE           ... [ [ ⍠B | ⍠C ] | [ ⍠V | ⍠S ] ]? 
 ⍝ 
 ⍝   Description:
 ⍝     ∆HERE -- a "fast" here-document selector with simple options
 ⍝     lines ← ∆HERE  [ ⍝ options] 
 ⍝     options: ⍠B ⍠C ⍠V ⍠S  (Blanks Comments Vectors String)
 ⍝     ∘ Note that the option is specified anywhere in a comment on the ∆HERE line!
 ⍝     ∘ Its form must be exactly '⍠C', not '⍠ C' or  "⍠x⊣x←'C'" etc.                                
 ⍝   Details:
 ⍝     ⍠B  (default) or  ⍠C 
 ⍝       +Option B: comment AND [B] blank lines constitute a here-doc   
 ⍝        Option C: [C] comment-only lines constitute a here-doc           
 ⍝     ⍠V  (default) or  ⍠S 
 ⍝       +Option V: return a [V] vector of character vectors
 ⍝        Option S: return a [S] string with LFs separating each line from the next 
 ⍝
 ⍝     Defaults are options B and V. 
 ⍝     To get option C, include ⍠C in a comment on the ∆HERE line, e.g.
 ⍝         myCode ← ∆HERE   ⍝ ⍠C  That selects option 0.  
 ⍝     Under both options C and B,
 ⍝       ∘ The comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
 ⍝       ∘ Blank lines always end up as 0-length char vectors.
 ⍝   Returns: 
 ⍝       See ⍠V and ⍠S above
    
 ⍝ hd: here doc, cb: comment + opt'l blank, op: options
 
∇hd←∆HERE;⎕IO;⎕ML;cb;opt       
 hd←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
 opt←(⊃hd)[1+⍸'⍠'∊⍨⊃hd] ⋄ cb← '⍝ ' '⍝'⊃⍨'C'∊opt 
 hd/⍨←'⍝'≠⊃¨hd←1↓¨hd/⍨∧\cb∊⍨⊃¨hd←{⍵↓⍨+/∧\' '=⍵}¨1↓hd
 →0↓⍨'S'∊opt
 hd←¯1↓∊hd,¨⎕UCS 10  
∇

∇__dummy__
 ⎕EX ⊃⎕SI
∇

 
