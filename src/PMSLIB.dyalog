:Namespace PMSLIB

⍝ PMSLIB Utilities
⍝H  ∆F:  Find a pcre field by name or field number.
⍝H  res ← ⍵ ∆F field
⍝H        ⍵: Value ⍵ within a ⎕R or ⎕S dfn right argument.
⍝H        field: Either a field number (0: the entire match) or name (e.g. 'mymatch') used in the pattern to ⎕R or ⎕S.
⍝H  Returns: the value of the specified field OR null string. 
⍝H           Returns null string if the field value (a) is null, (b) does not exist or (c) is inactive.
⍝H----------------------------------------------------------------------------------------------------

    ∆F←{N O B L←⍺.(Names Offsets Block Lengths)
        def←'' ⋄ isN←0≠⍬⍴0⍴⍵
        p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def
        B[O[p]+⍳L[p]]
    }
    ∆AND←{⍺⍺⊣⍵:⍵⍵⊣⍵ ⋄ 0     }   ⍝ Unlike dfns.and, allows array args
    ∆OR← {⍺⍺⊣⍵:1    ⋄ ⍵⍵ ⊣ ⍵}   ⍝ -ditto-
    
    ∇hd←∆HERE;⎕IO;⎕ML;cb;opt       
        hd←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
        opt←(⊃hd)[1+⍸'⍠'∊⍨⊃hd] ⋄ cb← '⍝ ' '⍝'⊃⍨'C'∊opt 
        hd/⍨←'⍝'≠⊃¨hd←1↓¨hd/⍨∧\cb∊⍨⊃¨hd←{⍵↓⍨+/∧\' '=⍵}¨1↓hd
        →0↓⍨'S'∊opt
        hd←¯1↓∊hd,¨⎕UCS 10  
    ∇

 ⍝H  ∆HERE: A Fast "here-document" selector for Dyalog APL, with simple options ⍠B, ⍠C; ⍠V, ⍠S.
 ⍝H  ∆HERE:    lines ← ∆HERE     ⍝ ⍠ options...
 ⍝H "Here document" Functions
 ⍝H   ∆HERE           ... [ [ ⍠ B | ⍠C] | [⍠V | ⍠S] ]? 
 ⍝H 
 ⍝H   Description:
 ⍝H     ∆HERE -- a "fast" here-document selector with simple options
 ⍝H     lines ← ∆HERE  [ ⍝ options] 
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
 ⍝H         myCode ← ∆HERE   ⍝ ⍠C  That selects option 0.  
 ⍝H     Under both options C and B,
 ⍝H       ∘ The comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
 ⍝H       ∘ Blank lines always end up as 0-length char vectors.
 ⍝H   Returns: 
 ⍝H       See ⍠V and ⍠S above
 ⍝H----------------------------------------------------------------------------------------------------


⍝ End PMSLIB Utilities
:EndNamespace