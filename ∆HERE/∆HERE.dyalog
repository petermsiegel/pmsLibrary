﻿ hd←∆HERE;opt
 ;kw;here;optString;lineEnd;oDebug;oMulti;oSpaces;⎕IO;⎕ML
⍝ ∆HERE-- see documentation below
 ⎕IO ⎕ML←0 1
 oMulti oSpaces oDebug←1 0 0
 lineEnd←⎕UCS 13    ⍝  CR character. If used in Dyalog, behaves like CR + LF.

 here←1⊃2↑⎕LC
 :If 0=here ⋄ '∆HERE: Not called from within a fn/op'⎕SIGNAL 11 ⋄ :EndIf

 :If 0=≢hd←⎕NR⊃1 0⌷⎕STACK                     ⍝ ~5% faster than equiv. (0⊃⎕RSI).⎕NR 1⊃⎕SI
 :AndIf 0=≢hd←↓(0⊃⎕RSI).(180⌶)1⊃⎕SI           ⍝ A Class member? 180⌶ returns its ⎕CR.
     11 ⎕SIGNAL⍨'∆HERE: locked or invalid fn/op: ',1⊃⎕XSI
 :EndIf

⍝ Get the options from the ∆HERE statement line.
 optString←1(819⌶)⊣∊'⍝[^⍠]*⍠(.*)$'⎕S'\1'⊣here⊃hd
 :For opt :In {⍵⊆⍨' '≠⍵}optString
     :Select 2↑opt
          ⋄ :Case 'SP' ⋄ oSpaces←1
          ⋄ :Case 'SI' ⋄ oMulti←0
          ⋄ :Case 'MU' ⋄ oMulti←1
          ⋄ :Case 'LF' ⋄ lineEnd oMulti←(⎕UCS 10)0
          ⋄ :Case 'CR' ⋄ lineEnd oMulti←(⎕UCS 13)0
          ⋄ :CaseList 'DE' 'DB' ⋄ oDebug←1
     :EndSelect
 :EndFor

 :If oDebug
     ⎕←('DEBUG: here line:[',(⍕here),']: "'),(here⊃hd),'"'
     ⎕←'DEBUG: option str: "',optString,'"'
     ⎕←'DEBUG: oSpaces=',oSpaces,',oMulti=',oMulti,',lineEnd=',(⎕UCS lineEnd)
 :EndIf

⍝ Get the ∆HERE document as follows:
⍝   A: Gather all lines in caller following ∆HERE call in ⎕NR format.
⍝      A1. If oSpaces=1, convert empty lines to the form '⍝ '.
⍝   B: Drop leading blanks from each.
⍝   C: Gather contig. lines beginning (now) with '⍝'.
⍝      C1. Keeping in mind A1 above, stop when a line not beginning with '⍝' is reached.
⍝   D. Select, from these, all those w/ '⍝ ' prefix, remove prefix, and return.
⍝      Other selected lines are treated as comments and ignored. (e.g. '⍝⍝ Comment').

 hd←⊆hd↓⍨1+here
 :If oSpaces
     hd←'^\h*$'⎕R'⍝ '⊣hd   ⍝ Convert blank lines to comment lines with single blank...
 :EndIf
 hd←1↓¨hd/⍨' '=⊃¨hd←1↓¨hd/⍨∧\'⍝'=⊃¨hd←{⍵↓⍨+/∧\' '=⍵}¨hd
 :If ~oMulti
     hd←¯1↓∊hd,¨lineEnd
 :EndIf

⍝ --------------------------------------------------------------------------------------------------
⍝ ∆HERE:   hereDoc ← ∆HERE [⍝ <anytext>  ⍠ keywords]
⍝       keywords:
⍝           SPaces | NOSPaces   Do uncommented blank lines end the ∆HERE doc?
⍝           MUltiple | SIngle   Do we return a vector of vectors or a single char vector?
⍝           LF | CR             Sets SIngle
⍝           DEbug, DBG          Show debug info.
⍝       Returns an APL "Here Document" entered as a series of comments following the ∆HERE function.
⍝       The ∆HERE document ends when a non-comment line is seen, one not of the form '^\h*⍝'
⍝              NoSpaces: including a blank line;
⍝              SPACES: excluding blank lines '^\h*$', which are treated as '⍝ '.
⍝       ∘ Comment lines of the form '^\h*⍝ ' are kept;
⍝       ∘ Comment lines of the form '^\h*⍝[^⍝] are ignored, but don't end the ∆HERE document.
⍝
⍝ Returns:
⍝       [MULTIPLE* option] a vector of character vectors of ∆HERE-doc lines following the ∆HERE call.
⍝       [SINGLE option] a single vector string with CR (default) or NL (option) <<separating>> lines.
⍝       For each line returned, the prefix '^\h*⍝ ' is removed (leading blanks, comment symbol, one blank).
⍝       ------------
⍝       * MULTIPLE is the default.
⍝ Options:
⍝      ∆HERE is a niladic function. Options are within a comment on the same function line as the ∆HERE.
⍝      Option keywords on the ∆HERE function line are of this Regex form:
⍝           ⍝[^⍠]*⍠ keywords
⍝      e.g. this example treats empty lines after the ∆HERE as blank comment lines,
⍝           and returns multiple lines using the carriage return.
⍝           h←∆HERE    ⍝ SP CR
⍝
⍝∘ Keyword Options, Associated Variables, and Actions
⍝  Keyword    Abbrev Def  Options←val  Description
⍝  SPACES     SP          oSpaces←1    Treat empty lines as comment lines '⍝ ',
⍝                                      so only text lines end a ∆HERE doc
⍝  NOSPACES   NOSP   Y    oSpace←0     Treat empty lines as if APL code, ending a ∆HERE sequence.
⍝  MULTIPLE   MU     Y    oMulti←1     If multiple lines, return as vec of vec strings
⍝  SINGLE     SI          oMulti←0     If multiple lines, return as single vector with CR as line separator
⍝  LF         LF          lineEnd←⎕UCS 10   (linefeed). Sets SINGLE, i.e. oMulti←0
⍝  CR         CR     Y    lineEnd←⎕UCS 13   (carriage return).  Sets SINGLE, i.e. oMulti←0.
⍝  DEBUG      DEB    N    oDebug←1     Start debug (verbose) mode
⍝            DBG         oDebug←1      Alternative to DEB/UG
⍝  anything else          **ignore**
⍝
⍝ The default keywords are:  ⍝ ⍠ MULTI  NOSPACES   -- Create vector of vector and end the ∆HERE doc at first non-comment
⍝ A common alternative is:   ⍝ ⍠ CR SP             -- Create a char string with lines separated by CR carriage return.
⍝
⍝ If SINGLE is specified, CR is the default line separator.
⍝ The default options are:       oMulti←1 ⋄ oSpaces←0 ⋄ lineEnd←⎕UCS 13
⍝
⍝  Here document example
⍝      myHtml←∆HERE     ⍝ Tolerate blank lines ⍠ SP
⍝      ⍝ <!DOCTYPE HTML>
⍝      ⍝ <html>
⍝      ⍝⍝ Next line is blank.    <-- This line is ignored because of '⍝⍝'.
⍝                                <-- Blank line would end the HERE doc without 'SPACES' option.
⍝      ⍝ <head>
⍝      ⍝ <meta name="viewport" content="width=device-width, initial-scale=1">
⍝                                <-- Ditto
⍝      <style>
⍝      etc.
⍝ BUGS:   The calling function must be an unlocked fn or op.
