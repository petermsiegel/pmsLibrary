:namespace ∆FreLib 
  ∇ ⍙⍙RES← {⍙⍙L} ∆Fre ⍙⍙R  ; ⎕TRAP 
  ⍝ Performance of <∆Fre x> relative to C language version of ∆F
  ⍝    F-string                            This version vs C-version
  ⍝    ⎕A                                  ~1:1
  ⍝    'one`⋄two{ }{$$⍳2 2}{} one`⋄ two'    ~20-25% slower
    ⎕TRAP← 0 'C' '⎕SIGNAL ⊂⎕DMX.(''EM'' ''EN'' ''Message'' ,⍥⊂¨(''∆F '',EM) EN Message)'
    :If 900⌶0 
        ⍙⍙L← 0 0 0 
    :Elseif 0=≢ ⍙⍙L 
        ⍙⍙RES←1 0⍴'' ⋄ :Return 
    :Elseif 0= ⊃0⍴⍙⍙L 
        ⍙⍙L← 3↑ ⍙⍙L 
    :ElseIf 'help'≡⎕C ⍙⍙L 
        ∆FreLib.Help ⋄ ⍙⍙RES← 1 0⍴''⋄ :Return 
    :EndIf 
    :If ⊃⍙⍙L           ⍝ Generate Dfn from f-string ⊃⍙⍙R 
        ⍙⍙RES← (⊃⎕RSI)⍎ ⍙⍙L ∆FreLib.FSConvert ⊃⍙⍙R← ,⊆⍙⍙R
    :Else              ⍝ Generate and evaluate code from f-string ⊃⍙⍙R (⍙⍙R contains an ⍵)
        ⍙⍙RES← (⊃⎕RSI){⍺⍎ ⍙⍙L ∆FreLib.FSConvert ⊃⍙⍙R} ⍙⍙R← ,⊆⍙⍙R
    :Endif 
  ∇
    ##.∆F← ∆Fre 

⍝ Constants 
    ⎕IO ⎕ML←0 1 
  ⍝ Run-time library routines ⎕SE.⍙F...
    Above←   '{⍺←⍬⋄⎕ML←1⋄⊃⍪/(⌈2÷⍨w-m)⌽¨f↑⍤1⍨¨m←⌈/w←⊃∘⌽⍤⍴¨f←⎕FMT¨⍺⍵}'   ⍝ Above       (1- or 2-adic)
    Box←     '{⍺←0⋄⎕ML←1⋄⍺⎕SE.Dyalog.Utils.disp⊂⍣(1≥≡⍵),⍣(0=≡⍵)⊢⍵}'   ⍝ Box         (1- or 2-adic)
    Display← '0∘⎕SE.Dyalog.Utils.disp¯1∘↓'                            ⍝ Display All (1-adic)
    Merge←   '{⍺←⊢⋄⎕ML←1⋄⊃,/((⌈/≢¨)↑¨⊢)⎕FMT¨⍺⍵}'                      ⍝ Merge       (1- or 2-adic)
    Fmt←     ' ⎕FMT '                                                 ⍝ Format      (1- or 2-adic) 
  ⍝ Character values
    cr crVis← ⎕UCS 13 9229                                      ⍝ crVis: Choose 8629 ↵   9229  ␍
    esc lb rb← '`{}' 
    escDmd escEsc escLb escRb q qq spQ qSp← '`⋄' '``' '`{' '`}' '''' '''''' ' ''' ''' '
  ⍝ Patterns 
    cfpp← '\$\$' '\$' '%' '(?:`⍵|⍹)(\d*)' '(?:"[^"]*")+|(?:''[^'']*'')+'
    markCFp← '(?x) (?<P> (?<!`) \{ ((?>  [^{}"''`]+ | (?:`.)+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \} )' 
  ⍝ Errors 
    logicErr← 'Logic Error: Invalid omega expression' 911
  ⍝ Global variables.  May be changed via FSConvert (and routines it calls) at runtime
    omegaG←0 
    crG← cr                                                   ⍝ Value ignored. Set in FSConvert (q.v.)

⍝ Operators
    _Opts← ⍠'EOL' 'LF' 

⍝ Functions 
    TF← { 0= ≢⍵: '' ⋄ spQ, qSp,⍨ escDmd escEsc escLb escRb q ⎕R crG esc lb rb qq _Opts ⍵ }
    OmegaNum← { 
      0=≢⍵: ⍕omegaG⊢←omegaG+1
      0∊ ⊃r← ⎕VFI ⍵:  ⎕SIGNAL/ logicErr   
        ⍕omegaG⊢← ⊃⌽r  
    }
    Qt2Apl← { 
      QtMatch← q escEsc escDmd ⎕R qq esc crG _Opts
      q, q,⍨ QtMatch ⍵ 
    }
  ⍝ SFCheck: Checks if code field consists solely of 0 or more spaces (within the braces).
  ⍝    ∘ Returns (1 sfCod) if true.
  ⍝      sfCod is either '', if there are 0 spaces, or (nn⍴''), if nn spaces (n>0).
  ⍝    ∘ Returns 0 otherwise.
    SFCheck← { 
        sp← +/∧\' '= ⍵
      0≠ ≢sp↓ ⍵: 0 
      sp= 0: 1 '' 
        1, ⊂'(','⍴'''')',⍨ ⍕sp 
    }
  ⍝ DocCheck: Checks if code field contents (inside braces) has trailing ch ∊ '→%↓', ignoring blanks.
  ⍝   Returns cStr dFun dStr  
  ⍝     cStr: code string w/o appended ↓%→] (orig. code string if not a doc)   
  ⍝     dFun: '' (none), Above ('↓' or '%'), Merge ('→')
  ⍝     dStr: orig. doc string, but in quotes. '' if NOT a document string..]
    DocCheck←{  
        ch← ⍵⌷⍨ p← (≢⍵)-1+ +/∧\' '=⌽⍵ 
      ~ch∊'→↓%': ⍵ '' ''  
        dStr← q, q,⍨ dStr/⍨ 1+q= dStr← ('▼▶'⊃⍨ dTyp← ch='→')@p⊣⍵
        (p↑⍵) (dTyp⊃ Above Merge) dStr  
    }
    CF← {  
        isSF sfCod← SFCheck ⍵                           ⍝ Space field? 
      isSF: sfCod
        cStr dFun dStr ← DocCheck ⍵                     ⍝ Is CF Self-documenting?  
        cStr← cfpp ⎕R {
            p← ⍵.PatternNum 
            p∊0 1 2: p⊃ Box Fmt Above                  ⍝ $$ $ % 
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
    FSConvert← { 
        (dfn dbg box) fStr← ⍺ ⍵
        omegaG⊢← 0
        crG⊢← cr crVis⊃⍨ dbg                                      ⍝ cr ␍
        fmtAll← Merge Display⊃⍨ box 

        flds← OrderFlds ProcFlds ⊂fStr 
        code← (⎕∘←)⍣dbg⊣ lb, fmtAll, flds,  rb
      ~dfn: code, '⍵'                                                ⍝ Not a dfn. Emit code ready to execute
        quoted← '(⊂', ')',⍨ q, q,⍨ fStr/⍨ 1+ fStr= q           ⍝ dfn: add quoted fmt string.
        lb, code, quoted, ',⍵', rb                                   ⍝ emit dfn string ready to convert to dfn itself
    } 

    ∇ Help ;h 
      ⎕ED 'h' ⊣ h← '^ *⍝H(.*)' ⎕S '\1'⊣ ⎕SRC ⎕THIS  
    ∇

⍝H 
⍝H No help available (yet)
:EndNamespace 
