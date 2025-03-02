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
    :If ⊃⍙⍙L←3↑ ⍙⍙L    ⍝ Generate Dfn from f-string ⊃⍙⍙R 
        ⍙⍙RES←  (⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.FSXlt ⊃⍙⍙R
    :Else              ⍝ Generate-evaluate code from f-string ⊃⍙⍙R
        ⍙⍙RES← {(⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.FSXlt ⊃⍙⍙R} ⍙⍙R
    :Endif 
  ∇
    ##.∆F← ∆Fre 

    ⎕IO ⎕ML←0 1 
  ⍝ Run-time library routines ⎕SE.⍙F...
    codA← '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'   ⍝ Above
    codB← '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'   ⍝ Box
    codD← '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                            ⍝ Display All
    codM← '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                      ⍝ Merge
    codF←  ' ⎕FMT '                                                ⍝ Format 
  ⍝ Global variables.  May be changed via FSXlt at runtime
    omegaG←0 
    crG← ⊃crLit crVis← ⎕UCS 13 9229                                 ⍝ cr     8629 ↵   9229  ␍

    esc lb rb← '`{}' 
    escDmd escEsc escLb escRb q qq spQ qSp← '`⋄' '``' '`{' '`}' '''' '''''' ' ''' ''' '

    cfpp← '\$\$' '\$' '%' '(?:`⍵|⍹)(\d*)' '(?:"[^"]*")+|(?:''[^'']*'')+'
    markCFp← '(?x) (?<P> (?<!`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 

    _Opts← ⍠'EOL' 'LF' 
    TF← { 0= ≢⍵: '' ⋄ spQ, qSp,⍨ escDmd escEsc escLb escRb q ⎕R crG esc lb rb qq _Opts ⍵ }
    OmegaNum← { 
      0=≢⍵: ⍕omegaG⊢←omegaG+1
      0∊ ⊃r← ⎕VFI ⍵: 'Logic Error: Invalid omega expression' ⎕SIGNAL 911    
        ⍕omegaG⊢← ⊃⌽r  
    }
    Qt2Apl← { 
      QtMatch← q escEsc escDmd ⎕R qq esc crG _Opts
      q, q,⍨ QtMatch ⍵ 
    }
    SFCheck← { 0=≢⍵↓⍨ p←  +/∧\' '= ⍵: 1 p ⋄ 0 }
  ⍝ DocCheck: Returns dStr dType cStr  
  ⍝     cStr: code string w/o appended ↓%→] (orig. code string if not a doc)   
  ⍝     dFun: '' (none), codA ('↓' or '%'), codM ('→')
  ⍝     dStr: orig. doc string, but in quotes. '' if none.]
    DocCheck←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '=⌽⍵ 
      ~ch∊'→↓%': ⍵ '' ''  
        dStr← q, q,⍨ dStr/⍨ 1+q= dStr← ('▼▶'⊃⍨ dTyp← ch='→')@p⊣⍵
        (p↑⍵) (dTyp⊃ codA codM) dStr  
    }
    CF← {  
        isSF len← SFCheck ⍵                             ⍝ Space field? 
      isSF∧ 0=len: ''
      isSF: '(', '⍴'''')',⍨ ⍕len  
        cStr dFun dStr ← DocCheck ⍵                  ⍝ Is CF Self-documenting?  
        cStr← cfpp ⎕R {
            p← ⍵.PatternNum 
            p∊0 1 2: p⊃ codB codF codA                  ⍝ $$ $ % 
            p=3:     '(⍵⊃⍨⎕IO+', ')',⍨ OmegaNum ⍵.(Lengths[1]↑ Offsets[1]↓ Block) ⍝ `⍵[nnn] and ⍹[nnn]
            p=4:     Qt2Apl 1↓¯1↓ ⍵.Match               ⍝ "..." or '...' 
        }⊢ cStr ⍝ _Opts⊢ cStr 
        '({', dStr, dFun, cStr, '}⍵)'
    }
  ⍝ ∘ User flds are effectively executed L-to-R and displayed in L-to-R order 
  ⍝   by reversing their order, evaluating R-to-L, then reversing again.
  ⍝ ∘ "Older" style (execute fields R-to-L, display L-to-R): Order← ∊'⍬',⍨⊢
    OrderFlds←   '⌽'∘,⍤ ∊'⍬'∘,⍤ ⌽
    ProcFlds← { lb=⊃⍵: CF 1↓¯1↓⍵ ⋄ TF ⍵ }¨ markCFp ⎕R '\n\1\n' _Opts
    FSXlt← { (dfn dbg box) fStr← ⍺ ⍵
        omegaG⊢← 0
        crG⊢← crLit crVis⊃⍨ dbg                                      ⍝ cr ␍
        fmtAll← codM codD⊃⍨ box 

        flds← OrderFlds ProcFlds ⊂fStr 
        code← { dbg: ⊢⎕←⍵ ⋄ ⍵ } lb, fmtAll, flds,  rb
      ~dfn: code, '⍵'                                                ⍝ Not a dfn. Emit code ready to execute
        quoted← '(⊂', ')',⍨ q, q,⍨ fString/⍨ 1+ fString= q           ⍝ dfn: add quoted fmt string.
        lb, code, quoted, ',⍵', rb                                   ⍝ emit dfn string ready to convert to dfn itself
    } 

:EndNamespace 
