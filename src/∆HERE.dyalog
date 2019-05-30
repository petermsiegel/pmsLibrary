 hd←∆HERE
⍝ ∆HERE-- see full documentation at ∆HERE.doc
⍝ 1. hereDoc lines are those lines immediately after the ∆HERE that match /^ *⍝/,
⍝ contiguously until the first line NOT matching /^ *⍝/
⍝ 2. Those matching /^ *⍝[^ ]/ are then discarded as "hereDoc comments."
⍝ 3. If the 'BL[anks]' option is specified (see below),
⍝     lines matching /^ *$/ are treated as prefixed with '⍝'.
 ;kw;here;opt;oString;lineEnd;oDebug;oMulti;oBlanks;⎕IO;⎕ML

 ⎕IO ⎕ML oMulti oBlanks oDebug←0 1 1 0 0
 lineEnd←⎕UCS 13    ⍝  CR character. If used in Dyalog, behaves like CR + LF.

 here←1⊃2↑(50100⌶)2    ⍝ 2↑⎕LC = 2↑(50100⌶)2
 :If 0=here ⋄ '∆HERE: Not called from within a trad''l fn/op'⎕SIGNAL 11 ⋄ :EndIf

 :If 0=≢hd←⎕NR⊃1 0⌷⎕STACK                     ⍝ ~5% faster than equiv. (0⊃⎕RSI).⎕NR 1⊃⎕SI
 :AndIf 0=≢hd←↓(0⊃⎕RSI).(180⌶)1⊃⎕SI           ⍝ A Class member? 180⌶ returns its ⎕CR.
     11 ⎕SIGNAL⍨'∆HERE: locked or invalid fn/op: ',1⊃⎕XSI
 :EndIf

⍝ Get the options from the ∆HERE statement line- after ⍠ and up to ⍝ or end of line
 oString←'⍝[^⍠]*⍠([^⍝]*)'⎕S'\1'⊣here⊃hd
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

 :If oDebug
     ⎕←('DEBUG: here line:[',(⍕here),']: "'),(here⊃hd),'"'
     ⎕←'DEBUG: option str: "',oString,'"'
     ⎕←'DEBUG: oBlanks=',oBlanks,',oMulti=',oMulti
     ⎕←'DEBUG: lineEnd=',∊'LF' 'CR' '?'⊃⍨10 13⍳⎕UCS lineEnd
 :EndIf

⍝ Build the ∆HERE document as follows:
⍝ A. Gather all lines after <here>
 hd←⊆hd↓⍨1+here
⍝ A1. If oBlanks=1, treat blank lines as (empty) comment lines
 hd←'^\h*$'⎕R'⍝ '⍣oBlanks⊣hd
⍝  D. Among these, keep only this w/ original '⍝ ' prefix and remove a single blank.
⍝  |             C. Gather contiguous commented lines (see A1.) and drop comment symbol
⍝  ∨             ∨                 B. Drop leading blanks on each line (before comment symbol)
 hd←1↓¨hd/⍨' '=⊃¨hd←1↓¨hd/⍨∧\'⍝'=⊃¨hd←{⍵↓⍨+/∧\' '=⍵}¨hd
 :If ~oMulti
     hd←¯1↓∊hd,¨lineEnd
 :EndIf
