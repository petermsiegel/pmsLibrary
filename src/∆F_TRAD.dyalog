out←∆F_TRAD in

in←,in
out← ⍬
field←''


SkipLB← {⍵↓⍨+/∧\' '=⍵}
SkipTB← {⍵↓⍨-+/∧\' '=⌽⍵}

GetQStr←   {
  q← ⊃⍵  ⋄ sq dq←'''"'
  ~q∊sq dq: 'Whoops! Quote (" or '') must start in col 1'
  SetSQ←  { sq,sq,⍨, ⍵/⍨1+⍵=sq }

  len← +/ (⊢∧(∧⍀∨⍀=⊢))(⊢∨≠\)q∘=⍵ 
  q≠1↑⍵↓⍨len-1: 'Whoops: No ending quote!'
  q=dq:  (SetSQ s/⍨ ~(dq,dq)⍷ s← (len-2)↑ 1↓ ⍵) (len↓⍵)
  len (↑,⍥⊆↓) ⍵ 
}
esc←'`'

sq dq colon lb rb fmtCh←'''":{}$'
sp←' '

skipCh←  ∪⎕AV~⎕A,(⎕C⎕A),⎕D

TEXT CODE SPACE←0 1 2
braceLvl←0
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
        :Case lb
          braceLvl←1
          out,←⊂field
          field←''
          in← SkipLB in 
          :IF colon=⊃in 
              in↓⍨← 1
              mode←SPACE
          :ELSE  
              mode←CODE
          :ENDIF     
            :Continue
        :EndSelect
        field,←ch

    :Case CODE
        :Select ch
        :Case lb
            braceLvl+←1
            field,←ch
            in← SkipLB in 
        :Case rb
            braceLvl-←1
            :If braceLvl≤0
                out,←⊂'({','}⍵)',⍨field
                field←''
                mode←TEXT
                :Continue
            :Else
                field,←ch
            :EndIf
        :CaseList dq sq 
            _ls ← sp/⍨ ~skipCh∊⍨ ⊃field  
            str in ← GetQStr ch,in ⋄ in← SkipLB in 
            _rs← sp/⍨ ~skipCh∊⍨ ⊃in
            field,← _ls, str, _rs  
        :Case sp 
            in← SkipLB in 
            :IF  ~skipCh∊⍨ ⊃in ⋄ :ANDIF ~skipCh∊⍨ ⊃field
                 field,← ch
            :Endif 
        :Case colon
             in← SkipLB in 
             field,← ch
        :Case fmtCh
             in← SkipLB in 
             field← SkipTB field
             _ls _rs← (sp/⍨ ~skipCh∊⍨ ⊃field) (sp/⍨ ~skipCh∊⍨ ⊃in) 
             field,←_ls,'⎕FMT',_rs 
        :Else
            in← SkipLB in
            field,←ch
        :EndSelect

    :Case SPACE
        field,←'<SP>'
        :Select ch
        :Case rb
            braceLvl-←1
            :If braceLvl≤0
                out,←⊂field
                field←''
                mode←TEXT
                :Continue
            :Else
                field,←ch
            :EndIf
        :Else
            field,←ch
        :EndSelect

    :ENDSELECT ⍝ mode
:EndWhile

out,←⊂field
out←out/⍨0≠≢¨out
⍝ ⊃{⊃,/⍺⍵↑⍨¨⌈⍥≢/⍺⍵}⍥⎕FMT/⍎
out←out
