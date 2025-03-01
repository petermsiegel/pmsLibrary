:namespace ∆FreLib 
  ∇ ⍙⍙RES← {⍙⍙L} ∆Fre ⍙⍙R  ; ⎕TRAP 
  ⍝ Performance of <∆Fre x> relative to C language version of ∆F
  ⍝    F-string                            This version vs C-version
  ⍝    ⎕A                                  ~1:1
  ⍝    'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'    ~20-25% slower
    ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 ⋄ ⍙⍙L← 0 0 0 
    :Elseif 0=≢ ⍙⍙L ⋄  ⍙⍙RES←1 0⍴'' ⋄ :Return 
    :EndIf 
    ⍙⍙R← ,⊆⍙⍙R
    :If ⊃⍙⍙L←3↑ ⍙⍙L    ⍝ Generate Dfn
        ⍙⍙RES←  (⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.∆FExec ⍙⍙R
    :Else              ⍝ Generate-evaluate code from f-string ⍙⍙L
        ⍙⍙RES← {(⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.∆FExec ⍙⍙R} ⍙⍙R
    :Endif 
  ∇
    ##.∆F← ∆Fre 

    ⎕IO ⎕ML←0 1 
  ⍝ Run-time library routines ⎕SE.⍙F...
    libA← '{⍺←0⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'   ⍝ Above
    libB← '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'    ⍝ Box
    libD← '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                             ⍝ Display All
    libM← '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                      ⍝ Merge
    fmt←  ' ⎕FMT '
  ⍝ variables.    xxxG variables are "global", i.e. may be changed in ∆FExec at runtime
    omegaG←0 
    crG← ⊃crLit crVis← ⎕UCS 13 9229                                 ⍝ cr     8629 ↵   9229  ␍

    _Opts← ⍠'EOL' 'LF' 
    esc lb rb← '`{}' 
    escSep escEsc escLb escRb q qq spQ qSp← '`⋄' '``' '`{' '`}' '''' '''''' ' ''' ''' '

    cfPats← '\$\$' '\$' '%' '(?:`⍵|⍹)(\d*)' '(?:"[^"]*")+|(?:''[^'']*'')+'
    markCF← '(?x) (?<P> (?<!`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 

    TF← {     
      TFMatch← escSep escEsc escLb escRb q ⎕R crG esc lb rb qq _Opts 
      0=≢⍵: '' ⋄ spQ, qSp,⍨ TFMatch ⍵ 
    }
    OmegaNum← { 
      0=≢⍵: ⍕omegaG⊢←omegaG+1
      ok dig← ⎕VFI ⍵ 
      0∊ok: 'Logic Error: Invalid omega expression' ⎕SIGNAL 911    ⍝ cfPats should never allow
      ⍕omegaG⊢← dig 
    }
    Qt2Apl← { 
      QtMatch← q escEsc escSep ⎕R qq esc crG _Opts
      q, q,⍨ QtMatch ⍵ 
    }
    SFCheck← { 0=≢⍵↓⍨ p←  +/∧\' '= ⍵: 1 p ⋄ 0 }
  ⍝ DocCheck: Returns 
  ⍝     isDoc:[bool], docType:[0: vert, 1: horiz doc], c:[code string w/o appended ↓%→], d:[orig. doc string, but in quotes]
    DocCheck←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '=⌽⍵ 
      ~ch∊'→↓%': 0 0 ⍵ '' 
        d← q, q,⍨ d/⍨ 1+q= d← ('▼▶'⊃⍨r← ch='→')@p⊣⍵
        1 r (p↑⍵) d 
    }
    CF← {  
        isSF len← SFCheck ⍵                             ⍝ Space field? 
      isSF∧ 0=len: ''
      isSF: '(', '⍴'''')',⍨ ⍕len  
        isDoc dTyp c d← DocCheck ⍵                      ⍝ Is CF Self-documenting?  
        c← cfPats ⎕R {
            p← ⍵.PatternNum 
            p∊0 1 2: p⊃ libB fmt libA                   ⍝ $$ $ % 
            p=3:     '(⍵⊃⍨⎕IO+', ')',⍨ OmegaNum ⍵.(Lengths[1]↑ Offsets[1]↓ Block)
            p=4:     Qt2Apl 1↓¯1↓ ⍵.Match               ⍝ "..." or '...' 
        }_Opts⊢ c 
      isDoc: '({', d, (dTyp⊃ libA libM), c, '}⍵)'
        '({', c, '}⍵)'
    }
    ProcFields← { lb=⊃⍵: CF 1↓¯1↓⍵ ⋄ TF ⍵ }¨
    MarkCF← markCF ⎕R '\n\1\n' _Opts
    ∆FExec← {
        omegaG⊢← 0
        crG⊢← crLit crVis⊃⍨ 1= 1⊃ ⍺                                  ⍝ cr ␍
        fmtAll← libM libD⊃⍨ 1= 2⊃ ⍺ 

        fields← ∊ProcFields MarkCF ⊂fString← ⊃⍵ 
        code← ⍺{ 1⊃⍺: ⊢⎕←⍵ ⋄ ⍵} lb, fmtAll, fields, '⍬', rb
      0≥ 0⊃ ⍺: code, '⍵'                                             ⍝ Not a dfn. Emit code ready to execute
        quoted← '(⊂', ')',⍨ q, q,⍨ fString/⍨ 1+ fString= q           ⍝ dfn: add quoted fmt string.
        lb, code, quoted, ',⍵', rb                                   ⍝ emit dfn string ready to convert to dfn itself
    } 

:EndNamespace 
