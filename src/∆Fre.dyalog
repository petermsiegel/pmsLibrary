:namespace ∆FreLib 
  ∇ ⍙⍙RES← {⍙⍙L} ∆Fre ⍙⍙R 
  ⍝ ∆Fre a is  about the same performance as the C version, where a← ⎕A 
  ⍝ ∆Fre t is 20-25% slower than C version, where t← 'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'
    :If 900⌶0 ⋄ ⍙⍙L← 0 0 ⋄ :EndIf 
    ⍙⍙R← ,⊆⍙⍙R
    :TRAP 0
        :If ⊃⍙⍙L 
            ⍙⍙RES←  (⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.∆FExec ⍙⍙R
        :Else 
            ⍙⍙RES← {(⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.∆FExec ⍙⍙R} ⍙⍙R
        :Endif 
    :Else 
        ⎕SIGNAL ⊂⎕DMX.('EN' 'Message' 'EM',⍥⊂¨ EN Message ('∆Fre ',EM))
    :EndTrap
  ∇
    ##.∆Fre← ∆Fre 

    ⎕IO ⎕ML←0 1 
  ⍝ Run-time library routines ⎕SE.⍙F...
    libA← '{⍺←0⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'
    libB← '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'
    libD← '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'
    libM← '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'
    fmt←  ' ⎕FMT '
  ⍝ variables
    omega←0 
    _Opts← ⍠'EOL' 'LF' 
    esc lb rb← '`{}' 
    cr← ⊃crLit crVis← ⎕UCS 13 9229                                        ⍝ cr ␍
    escSep escEsc escLb escRb q qq spQ qSp← '`⋄' '``' '`{' '`}' '''' '''''' ' ''' ''' '

    cfPats← '\$\$' '\$' '%' '`⍵(\d*)' '⍹(\d*)' '(?:"[^"]*")+' '(?:''[^'']*'')+'
    markCF← '(?x) (?<P> (?<!`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 

    TFMatch← escSep escEsc escLb escRb q ⎕R cr esc lb rb qq _Opts 
    TF← { 0=≢⍵: '' ⋄ spQ, qSp,⍨ TFMatch ⍵ }
    OmegaNum← { 
      0=≢⍵: ⍕omega⊢←omega+1
      ok dig← ⎕VFI ⍵ 
      0∊ok: 'Logic Error: Invalid omega expression' ⎕SIGNAL 11
      ⍕omega⊢← dig 
    }
    QtMatch← q escEsc escSep ⎕R qq esc cr _Opts
    Qt2Apl← { q, q,⍨ QtMatch ⍵ }
    SF← { 0=≢⍵↓⍨ p←  +/∧\' '= ⍵: 1 p ⋄ 0 }
  ⍝ Doc: Returns [0: not doc, 1: horiz doc, 2: vert], code string w/o appended ↓%→, orig. doc string
    Doc←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '=⌽⍵ 
      ~ch∊'→↓%': 0 0 ⍵ '' 
        d← q, q,⍨ d/⍨ 1+q= d← ('▼▶'⊃⍨r← ch='→')@p⊣⍵
        1 r (p↑⍵) d 
    }
    CF← {  
        isSF len← SF ⍵                      ⍝ Space field? 
      isSF∧ 0=len: ''
      isSF: '(', '⍴'''')',⍨ ⍕len  
        isDoc dTyp c d← Doc ⍵                      ⍝ Doc CF?  True if doc∊1 2
        c← cfPats ⎕R {
            p← ⍵.PatternNum 
            p∊0 1 2: p⊃ libB fmt libA 
            p∊3 4:   '(⍵⊃⍨⎕IO+', ')',⍨ OmegaNum ⍵.(Lengths[1]↑ Offsets[1]↓ Block)
            p∊5 6:   Qt2Apl 1↓¯1↓ ⍵.Match  
        }_Opts⊢ c 
      isDoc: '({', d, (dTyp⊃ libA libM), c, '}⍵)'
        '({', c, '}⍵)'
    }
MarkCF← markCF ⎕R '\n\1\n' _Opts
∆FExec← {
    omega⊢← 0
    cr⊢← crLit crVis⊃⍨ 1=⊃⌽⍺                                    ⍝ cr ␍
    fields← ∊{ lb=⊃⍵: CF 1↓¯1↓⍵ ⋄ TF ⍵ }¨MarkCF ⊂fString← ⊃⍵
    code← ⍺{ ⊃⌽⍺: ⊢⎕←⍵ ⋄ ⍵} lb, libM, fields, '⍬', rb
  0≥⊃⍺: code, '⍵'                                                ⍝ Not a dfn. Emit code ready to execute
    quoted← '(⊂', ')',⍨ q, q,⍨ fString/⍨ 1+fString=q             ⍝ dfn: add quoted fmt string.
    lb, code, quoted, ',⍵', rb                                   ⍝ emit dfn string ready to convert to dfn itself
} 

:EndNamespace 
