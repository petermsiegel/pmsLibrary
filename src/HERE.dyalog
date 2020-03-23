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
 ⍝     Grabs contiguous ... 
 ⍝        Option 0: comment-only lines:               (⍝ ⍠0)
 ⍝        Option 1: comment AND blank lines:  default (⍝ ⍠1)
 ⍝     Default is option 1. To get option 1, include ⍠0 in a comment on the ∆HERE line, e.g.
 ⍝         myCode ← ∆HERE   ⍝ ⍠0  That selects option 0.  
 ⍝     Under both options,
 ⍝       ∘ The comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
 ⍝       ∘ Blank lines always end up as 0-length char vectors.
 ⍝   Returns: 
 ⍝      the resulting lines as a vector of character vectors.
    
 ∇h←∆HERE;⎕IO;⎕ML;hp       
 h←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
 hp← '⍝ ' '⍝'⊃⍨1∊'⍠0'⍷⊃h   
 h←h/⍨'⍝'≠⊃¨h←1↓¨h/⍨∧\hp∊⍨⊃¨h←{⍵↓⍨+/∧\' '=⍵}¨1↓h
∇

 
