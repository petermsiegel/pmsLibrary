 ⍝ "Here document" Functions
 ⍝    ∆HERE        <-- Use this one!
 ⍝    ⍙HERE        <-- Modestly more efficient.
 ⍝    ∆HEREX       <-- Obsolescent. Perform extra fns in user code
 ⍝ 
 ⍝ ∆HERE -- a "fast" here-document selector with simple options
 ⍝   lines ← ∆HERE ⍝      Option 1 (default)
 ⍝   lines ← ∆HERE ⍝ ⍠0   Option 0 Note that the option must be specified in a comment!
 ⍝ Details:
 ⍝   Grabs contiguous [0] comment-only lines (hp←'⍝') or [1] comment AND blank lines  (hp←'⍝ ').
 ⍝   Default is option 2. To get option 1, include ⍠0 in a comment on the ∆HERE line, e.g.
 ⍝       myCode ← ∆HERE   ⍝ ⍠0  That selects option 0.  
 ⍝   If the comment begins with ⍝⍝, it is ignored. Otherwise, the comment symbol is removed.
 ⍝   Blank lines always end up as 0-length char vectors.
 ⍝   Returns the resulting lines as a vector of character vectors.
 ⍝   
 ∇h←∆HERE;⎕IO;⎕ML;hp       
 h←(1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
 hp← '⍝ ' '⍝'⊃⍨1∊'⍠0'⍷⊃h    ⍝ Does ⍠0 appear on the ∆HERE line (in a comment)
 h←h/⍨'⍝'≠⊃¨h←1↓¨h/⍨∧\hp∊⍨⊃¨h←{⍵↓⍨+/∧\' '=⍵}¨1↓h
∇

⍝ ⍙HERE-- same as ∆HERE without option ⍝ ⍠0 available (⍠1, option 1 only).
⍝ Savings is minimal, e.g. 8%.
⍝ If blank lines are ignored, ∆HERE ⍝ ⍠0 may be faster...
 ∇h←⍙HERE;⎕IO;⎕ML       
 h←h/⍨'⍝'≠⊃¨h←1↓¨h/⍨∧\'⍝ '∊⍨⊃¨h←{⍵↓⍨+/∧\' '=⍵}¨h←(1+1⊃2↑(50100⌶)2)↓{0<≢⍵:⍵ ⋄ ↓(0⊃⎕RSI).(180⌶)1⊃⎕SI}⎕NR⊃1 0⌷⎕STACK⊣⎕IO ⎕ML←0 1
∇

⍝ ∆HEREX
⍝ As much as this was fun to write, I don't use all the options here.
⍝ It's here more for its entertaining way of passing options ;-)
⍝
⍝ ∆HEREX-- see full documentation at ∆HERE.doc
⍝ ∆HERE-- like ∆HEREX, but fixed with options MULTI, NOBLANKS, NODEBUG (oMulti oBlanks oDebug←1 0 0) 
⍝ 1. hereDoc lines are those lines immediately after the ∆HEREX that match /^ *⍝/,
⍝ contiguously until the first line NOT matching /^ *⍝/
⍝ 2. Those matching /^ *⍝[^⍝]/ are then discarded as "Here comments."
⍝ 3. If the 'BL[anks]' option is specified (see below),
⍝     lines matching /^ *$/ are treated as if prefixed with '⍝' (resulting in blank "here" lines).
∇h ←∆HEREX
 ;kw;here;opt;oString;lineEnd;oDebug;oMulti;oBlanks;⎕IO;⎕ML

 ⎕IO ⎕ML oMulti oBlanks oDebug←0 1 1 0 0
 lineEnd←⎕UCS 13    ⍝  CR character. If used in Dyalog, behaves like CR + LF.

 here←1⊃2↑(50100⌶)2    ⍝ 2↑⎕LC = 2↑(50100⌶)2
 :If 0=here ⋄ '∆HEREX: Not called from within a trad''l fn/op'⎕SIGNAL 11 ⋄ :EndIf

 :If 0=≢h ←⎕NR⊃1 0⌷⎕STACK                     ⍝ ~5% faster than equiv. (0⊃⎕RSI).⎕NR 1⊃⎕SI
 :AndIf 0=≢h ←↓(0⊃⎕RSI).(180⌶)1⊃⎕SI           ⍝ A Class member? 180⌶ returns its ⎕CR.
     11 ⎕SIGNAL⍨'∆HEREX: locked or invalid fn/op: ',1⊃⎕XSI
 :EndIf
 
⍝ Get the options from the ∆HEREX statement line- after ⍠ and up to ⍝ or end of line
:If '⍠'∊oString←here⊃h 
    oString←'⍝[^⍠]*⍠([^⍝]*)'⎕S'\1'⊣oString
    :For opt :In {⍵⊆⍨' '≠⍵}1(819⌶)⊣∊oString
       :Select 2↑opt
          ⋄ :Case 'BL' ⋄ oBlanks←1                  ⍝ Blank lines treated as comments (blank HERE lines in output)
          ⋄ :Case 'SI' ⋄ oMulti←0                   ⍝ output a SIngle (string) with embedded LFs or CRs
          ⋄ :Case 'MU' ⋄ oMulti←1                   ⍝ output MUltiple (strings) w/o LFs or CRs
          ⋄ :Case 'LF' ⋄ lineEnd oMulti←(⎕UCS 10)0  ⍝ Use LF in output strings; implies SIngle
          ⋄ :Case 'CR' ⋄ lineEnd oMulti←(⎕UCS 13)0  ⍝ Use CR in output strings; implies SIngle
          ⋄ :CaseList 'DE' 'DB' ⋄ oDebug←1          ⍝ Use DEBUG mode: which is verbose....
       :EndSelect
    :EndFor
 :EndIf
 :If oDebug
     ⎕←('DEBUG: here line:[',(⍕here),']: "'),(here⊃h ),'"'
     ⎕←'DEBUG: option str: "',oString,'"'
     ⎕←'DEBUG: oBlanks=',oBlanks,',oMulti=',oMulti
     ⎕←'DEBUG: lineEnd=',∊'LF' 'CR' '?'⊃⍨10 13⍳⎕UCS lineEnd
 :EndIf

⍝ Build the ∆HEREX document as follows:
⍝ A. Gather all lines after <here>
 h ←⊆h ↓⍨1+here
⍝ A1. If oBlanks=1, treat blank lines as (empty) comment lines
 h ←'^\h*$'⎕R'⍝ '⍣oBlanks⊣h 
⍝ D. Among these, keep only ones without an original /^\h*⍝⍝/ prefix.
⍝ |              C. Gather contiguous comment (only) lines (see A1.) and drop comment symbol
⍝ ∨              ∨                 B. Drop leading blanks on each line (before comment symbol)
 h ←h /⍨'⍝'≠⊃¨h ←1↓¨h /⍨∧\'⍝'=⊃¨h ←{⍵↓⍨+/∧\' '=⍵}¨h 
 :If ~oMulti
     h ←¯1↓∊h ,¨lineEnd
 :EndIf
 ∇
 
