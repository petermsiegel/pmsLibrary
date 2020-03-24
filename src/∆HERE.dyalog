 ⍝ "Here document" Functions
 ⍝   ∆HERE         
 ⍝ 
 ⍝   Description:
 ⍝     ∆HERE -- a "fast" here-document selector with simple options
 ⍝     lines ← ∆HERE ⍝      Option 1 (default)
 ⍝     lines ← ∆HERE ⍝ ⍠0   Option 0 
 ⍝     ∘ Note that the option is specified anywhere in a comment on the ∆HERE line!
 ⍝     ∘ Its form must be exactly '⍠0', not '⍠ 0' or  '⍠x⊣x←0' etc.                                
 ⍝   Details:
 ⍝      ⍠0  or  ⍠1 (default)
 ⍝        Option 0: comment-only lines:           
 ⍝        Option 1: comment AND blank lines   
 ⍝      ⍠2  or  ⍠3 (default)
 ⍝        Option 2: return a vector of character vectors
 ⍝        Option 3: return a string with LFs separating each line from the next 
 ⍝     Default is option 1. To get option 1, include ⍠0 in a comment on the ∆HERE line, e.g.
 ⍝         myCode ← ∆HERE   ⍝ ⍠0  That selects option 0.  
 ⍝     Under both options,
 ⍝       ∘ The comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
 ⍝       ∘ Blank lines always end up as 0-length char vectors.
 ⍝   Returns: 
 ⍝       See ⍠2 and ⍠3 above
    
∇h←∆HERE;⎕IO;⎕ML;f;hp;o       
 h←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1  
 h←h/⍨'⍝'≠⊃¨h←1↓¨h/⍨∧\ (⊃¨h←{⍵↓⍨+/∧\' '=⍵}¨1↓h)∊⍨ '⍝ ' '⍝'⊃⍨'0'∊o←f[1+⍸'⍠'∊⍨f←⊃h]
 :IF '3'∊o ⋄ h←¯1↓∊h,¨⎕UCS 10  ⋄ :Endif
∇
∇_dummy_
 ⎕EX '_dummy_'
∇

 
