 :namespace ∆FreLib  
 
 ⍝ Same speed as C version (∆F a), where a← ⎕A 
 ⍝ 20-25% slower on (∆F t), where t← 'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'

∇ ⍙⍙RES← {⍙⍙L} ∆Fre ⍙⍙R 
    :If 900⌶0 ⋄ ⍙⍙L← 0 ⋄ :EndIf 
    :Select ⍙⍙L
    :Case 0 
        ⍙⍙RES← ⍙⍙L ((⊃⎕RSI){⍺⍺ ⍎ ⍺ ∆FreLib.∆FExec ⊃⍵}) ,⊆⍙⍙R
    :Case 1  
        ⍙⍙RES← (⊃⎕RSI) ⍎ ⍙⍙L ∆FreLib.∆FExec ⊃⊆⍙⍙R
    :Else
        ⍙⍙RES← (⍕⎕THIS.∆FreLib),'.∆Fre'
    :EndSelect
∇
##.∆F← ∆Fre 

∆FExec← {
  ⍝ Begin execution...
    omega⊢← 0
    fields← { '{'=⊃⍵: CF 1↓¯1↓⍵ ⋄ TF ⍵ }¨cfP ⎕R '\n\1\n'⍠opts⊢ ⊂⍵
    code← '{', (libM, ∊fields,'⍬'),'}'
~⍺: code, '⍵'                                                    ⍝ Not a dfn. Emit code ready to execute
    quoted← '(⊂',')',⍨ sq, sq,⍨ ⍵/⍨ 1+⍵=sq                       ⍝ dfn: add quoted fmt string.
    '{',code, quoted, ',⍵}'                                       ⍝ emit dfn string ready to convert to dfn itself
} 

  ⎕IO ⎕ML←0 1 
⍝ Run-time library routines ⎕SE.⍙F...
  libA←'{⍺←0⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'
  libB←'{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'
  libD←'0∘⎕SE.Dyalog.Utils.disp¯1∘↓'
  libM←'{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'
  fmt← ' ⎕FMT '

  opts← 'EOL' 'LF' 
  cr← ⎕UCS 13 
  esc sq sp← '`'' ' 
  esc2 sq2← 2⍴¨ esc sq 
  spSq sqSp← (sp, sq) (sq, sp) 

  cfP← '(?x) (?<P> (?<!\`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 
  TF← { 
    0=≢⍵: ''
    tfP← '`⋄' esc2 '`{' '`}' sq
    tfS← cr   esc   '{'  '}'  sq2
    spSq, sqSp,⍨ tfP ⎕R tfS  ⍠opts ⊣ ⍵ 
  }
  omega← 0 
  OmegaNum← { 
    0=≢⍵: ⍕omega⊢←omega+1
    ok dig← ⎕VFI ⍵ 
    0∊ok: 'Logic Error: Invalid omega expression' ⎕SIGNAL 11
    ⍕omega⊢← dig 
  }
  Qt2Apl← {
    f← sq esc2 '`⋄' ⎕R sq2 esc cr ⍠opts⊣ ⍵
    sq, f, sq 
  }
  SF← { 0=≢⍵↓⍨ p←  +/∧\' '= ⍵: 1 p ⋄ 0 0 }
⍝ Doc: Returns [0: not doc, 1: horiz doc, 2: vert], code string w/o appended ↓%→, orig. doc string
  Doc←{  
      ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '=⌽⍵ 
    ~ch∊'→↓%': 0 0 ⍵ '' 
      d← sq, sq,⍨ d/⍨ 1+sq= d← ('▼▶'⊃⍨r← ch='→')@p⊣⍵
      1 r (p↑⍵) d 
  }
  CF← {  
      isSF len← SF ⍵                      ⍝ Space field? 
    isSF∧ 0=len: ''
    isSF: '(',(⍕len),'⍴'''')' 
      isDoc dTyp c d← Doc ⍵                      ⍝ Doc CF?  True if doc∊1 2
      c← '\$\$' '\$' '%' '`⍵(\d*)'  '⍹(\d*)' '(?:"[^"]*")+' '(?:''[^'']*'')+' ⎕R {
          Fld← ⍵.{ Lengths[⍵]↑ Offsets[⍵]↓ Block }
          p← ⍵.PatternNum 
          p∊0 1 2: p⊃ libB fmt libA 
          p∊3 4:   '(⍵⊃⍨⎕IO+',(OmegaNum f1),')'⊣ f1← Fld 1
          p∊5 6:   Qt2Apl 1↓¯1↓ f0← Fld 0 
      }⍠opts⊢ c 
    isDoc: '({', (d, dTyp⊃ libA libM), c, '}⍵)'
      '({', c, '}⍵)'
  }

:EndNamespace 

