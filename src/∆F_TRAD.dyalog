 out←∆F_TRAD in
 in←,in
 out←field←⍬

 esc←'`'

 TEXT CODE SPACE←0 1 2
 codeLvl←0
 mode←TEXT

 :While 0≠≢in
     ch←⊃in ⋄ in←1↓in
     :Select mode
     :Case TEXT
         :Select ch
         :Case esc
             nxt←⊃in ⋄ in←1↓in
             :If nxt∊'{}',esc
                 ch←nxt
             :ElseIf nxt∊'⋄'
                 ch←⎕UCS 13
             :Else
                 field,←ch
                 ch←nxt
             :EndIf
         :Case '{'
             mode←CODE
             codeLvl←1
             out,←⊂field
             field←⍬
             :Continue
         :EndSelect
         field,←ch

     :Case CODE
         :Select ch
         :Case '{'
             codeLvl+←1
             field,←ch
         :Case '}'
             codeLvl-←1
             :If codeLvl≤0
                 out,←⊂field
                 field←⍬
                 mode←TEXT
                 :Continue
             :Else
                 field,←ch
             :EndIf
         :Else
             field,←ch
         :EndSelect
     :EndSelect
 :EndWhile
 out,←⊂field
 out←out/⍨0≠≢¨out
