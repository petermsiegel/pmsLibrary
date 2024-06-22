 hd←∆HERE;⎕IO;⎕ML;cb;opt
 hd←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
 opt←(⊃hd)[1+⍸'⍠'∊⍨⊃hd] ⋄ cb←'⍝ ' '⍝'⊃⍨'C'∊opt
 hd/⍨←'⍝'≠⊃¨hd←1↓¨hd/⍨∧\cb∊⍨⊃¨hd←{⍵↓⍨+/∧\' '=⍵}¨1↓hd
 →0↓⍨'S'∊opt
 hd←¯1↓∊hd,¨⎕UCS 10

   ⍝H "Here document" Functions
   ⍝H   ∆HERE           ⍝ ... [ [ ⍠B | ⍠C ] | [ ⍠V | ⍠S ] ]?
   ⍝H
   ⍝H   Description:
   ⍝H     ∆HERE -- a "fast" here-document selector with simple options
   ⍝H     lines ← ∆HERE  [   ⍝H options]
   ⍝H     options: ⍠B ⍠C ⍠V ⍠S  (Blanks Comments Vectors String)
   ⍝H     ∘ Note that the option is specified anywhere in a comment on the ∆HERE line!
   ⍝H     ∘ Its form must be exactly '⍠C', not '⍠ C' or  "⍠x⊣x←'C'" etc.
   ⍝H   Details:
   ⍝H     ⍠B  (default) or  ⍠C
   ⍝H       +Option B: comment AND [B] blank lines constitute a here-doc
   ⍝H        Option C: [C] comment-only lines constitute a here-doc
   ⍝H     ⍠V  (default) or  ⍠S
   ⍝H       +Option V: return a [V] vector of character vectors
   ⍝H        Option S: return a [S] string with LFs separating each line from the next
   ⍝H
   ⍝H     Defaults are options B and V.
   ⍝H     To get option C, include ⍠C in a comment on the ∆HERE line, e.g.
   ⍝H         myCode ← ∆HERE     ⍝H ⍠C  That selects option 0.
   ⍝H     Under both options C and B,
   ⍝H       ∘ The comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
   ⍝H       ∘ Blank lines always end up as 0-length char vectors.
   ⍝H   Returns:
   ⍝H       See ⍠V and ⍠S above

   ⍝H hd: here doc, cb: comment + opt'l blank, op: options




