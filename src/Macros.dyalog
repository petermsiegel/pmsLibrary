Macros←{
    ⎕IO ⎕ML← 0 1
    caller← ⊃⎕RSI 
    _← 'disp' (dfns←⎕NS⍬).⎕CY 'dfns'
  ⍝ Error constants
    brErr← 'Parse: Too many right brackets "]"'
  ⍝ Char Constants
    sq dq lb rb ←'''"[]'
    cr← ⎕UCS 13 
    dq2←dq,dq
    lbP←'\['
    rbP←'\]'
    scP←';'
  ⍝ Patterns
    qt1P←'(?:''[^'']*'')+'
    qt2P←'(?:"[^"]*")+'
    comP←'(?:⍝.*$)'
    skipP← 1↓∊ '|',¨qt1P qt2P comP 
    let1P let2P← '[\pL∆⍙_]' '[\pL∆⍙_\d]'
    pfxAP← '(?ix)'
    pfxDP← '(?ix)  (^\s* ⍝? \s*) '
    bLftP bRgtP← '(?<![\pL∆⍙_])' '(?![\pL∆⍙_\d])'
    ParmPat← (bLftP,'\Q')∘, ,∘('\E',bRgtP)        ⍝ Pattern to match word ⍵ exactly
    EscPat← { ⍵/⍨1+'\'=⍵ }
    CParens← { ⍺: '(',⍵,')' ⋄ ⍵}
  ⍝ \⍺  - 1st let of APL var name (non-digit)
  ⍝ \⍵  - subseq. let of APL var name
  ⍝ \ßL - \b for APL simple names (left side)
  ⍝ \ßR - \b for APL simple names (right side)
    ∆D← (EscPat¨'^' '\⍺' '\⍵' '\ßL' '\ßR')  ⎕R (EscPat¨ pfxDP let1P let2P bLftP bRgtP)
    ∆A← (EscPat¨'^' '\⍺' '\⍵' '\ßL' '\ßR')  ⎕R (EscPat¨ pfxAP let1P let2P bLftP bRgtP)
    brktP←  '(?<B> \[ ((?> [^]["'']+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&B)* )+)  \] )' 
    parenP← '(?<P> \( ((?> [^)("'']+ | (?:"[^")*")+ | (?:''[^'']*'')+ | (?&P)* )+)  \) )' 
    macroP← ∆A '(\⍺\⍵*)','(?:\h*(', brktP,'))?'
  ⍝ Macro directives:
  ⍝   :def (:define) :defp (:definep) :undef :showm
    def2P←    ∆D ':def(?:ine)?(p)? \s+ (\⍺\⍵*) \s* (?:\[ (.*?) \]) \s* (?:← \s*)? (.*) $'
    def1P←    ∆D ':def(?:ine)?(p)? \s+ (\⍺\⍵*)                     \s* (?:← \s*)? (.*) $'
    undefP←   ∆D ':undef  \s+ (\⍺\⍵*) \s*$'
    showP←    ∆D ':showm?\b (.*) $'
  ⍝ Conditionals 
    mifP←     ∆D ':mif\b \s*([^\s]+)$'
    melseifP← ∆D ':mel(?:se)?if\b \s*([^\s]+)$'
    melseP←   ∆D ':melse \s*$'
    mendifP←  ∆D ':mend(?:if)? \s*$'
  ⍝ Catchall for major syntax errors 
    errP←     ∆D ':(def(ine)p?|undef|showm?|mif|mel|mend).*'

    Tbl← ⎕NS⍬
    Tbl.(keys←vals←parms←pats←⍬)
    Tbl.Set1← Tbl.{
        k v p←⍵ ⋄ i←keys⍳⊂k 
      i<≢keys: k⊣ (i⊃vals)←v⊣ (i⊃parms)←p ⊣ (i⊃pats)←##.ParmPat¨p 
        k⊣ keys vals parms pats,∘⊂← k v p (##.ParmPat¨p)
    }
    Tbl.Get1← Tbl.{ ⍺←⊢ 
        i←keys⍳ ⊂⍵ 
      i<≢keys: 1(keys vals parms pats⊃⍨¨i) 
      0≡⍺0: 11 ⎕SIGNAL⍨ 'Key "',⍵,'" is not in dictionary'
        0 (⍵ ⍺ ⍬ ⍬)
    }
    Tbl.Del← Tbl.{
        k←⍵   
        keys vals parms pats /⍨← ⊂b← (⍳≢keys)≠ keys⍳⊂k 
        0∊b   
    }
    Tbl.Show← Tbl.{
      (0=≢⍵)∧0≠≢keys: ⍉↑ keys parms vals
      (0=≢⍵): ⍬
        ⍉↑ keys parms vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
    }
    Tbl.ShowMacros← Tbl.{ 
      0≠≢mm← Show ' '(≠⊆⊢)⍵: mm ⋄ ⊂'No macros defined'
    }

    ProcQts← {
      pqPP← qt1P qt2P comP                       ⍝ ' " ;
            qt1I qt2I comI← ⍳≢pqPP
      pqPP ⎕R { C←∊∘⍵.PatternNum ⋄ m←⍵.Match
          C qt1I: m
          C qt2I: sq,sq,⍨(dq2(~⍷)n)/n←1↓¯1↓m/⍨1+m=sq
          C comI: m 
      } ⍵
    }
    GetArgs←{
        gaPP←qt1P qt2P lbP rbP scP                ⍝ ' " [ ] ;
             qt1I qt2I lbI rbI scI←⍳≢ gaPP

        (lb≠⊃⍵)∨(rb≠⊃⌽⍵): 11 ⎕SIGNAL⍨ 'Macro args apparently don''t start and end with brackets'
        brPos←1   ⍝ We've seen lb 

        txt← gaPP ⎕R{ C←∊∘⍵.PatternNum ⋄ m←⍵.Match
          C qt1I: m
          C qt2I: sq,sq,⍨(dq2(~⍷)n)/n←1↓¯1↓m/⍨1+m=sq
          C lbI:  m⊣ brPos+←1 
          C rbI:  m⊣ brErr ⎕SIGNAL 11/⍨ 1≥ brPos⊢← brPos-1 
          C scI:  cr m⊃⍨ brPos>1               ⍝ Splitting on "bare" semicolons
        }1↓ ¯1↓ ⍵
        cr (≠⊆⊢)txt 
    }
  ⍝ Managing the Conditional Stack used for :mif ... :mend
    cStack ← ⍬         
    cStart cActive cSkip← 1 0 ¯1   
    CondEval← caller∘{ 
      0:: 'Macros: Invalid conditional' ⎕SIGNAL 11 
        (⊃cStack)← cStart cActive⊃⍨  b← ⍺⍎'0≢⍥,', ProcQts ⍵  
        ' => ', '(', (⍕b), ')'
    }
    CondElse← { (⊃cStack)←  cSkip cActive⊃⍨ cStart= ⊃cStack }
    CondEnd←  { ⊢cStack ↓⍨← 1 }
  ⍝ Parse Macro Directives (:def, etc.)
    isDirctv← 0 
    pdPP← def2P def1P undefP showP mifP melseifP melseP mendifP errP
          def2I def1I undefI showI mifI melseifI melseI mendifI errI← ⍳≢pdPP
    ParseDirective← { 
      isDirctv⊢← 0 
      isDirctv, ⊂PD2 ⍵
    } 
    PD2← pdPP ⎕R { 
          Case← ∊∘⍵.PatternNum  
          F← ⍵.{ 0>lw← Lengths[⍵]: '' ⋄ lw↑ Offsets[⍵]↓ Block }
          isDirctv⊢← 1
          m← '⍝ ',(' '⍴⍨0⌈l-2), ⍵.Match↓⍨ l←≢F 1 

      ⍝ Major errors signalled no matter what
        Case errI:  11 ⎕SIGNAL⍨ 'Invalid directive: "', (2↓m),'"' 

      ⍝ Conditional :mend executed no matter what
        Case mendifI: m⊣ CondEnd ⍬
      
      ⍝ Other conditionals executed only if NOT in cSkip mode
      cSkip= ⊃cStack: '⍝-',m 
        Case mifI:     m, CondEval F 2 ⊢ cStack,← cStart 
        Case melseifI: m, CondEval F 2 
        Case melseI:   m⊣ CondElse ⍬
      
      ⍝ Execute Macro Defs only if in cActive mode 
      cActive≠ ⊃cStack: '⍝-',m 
        Case def1I: m⊣ Tbl.Set1 (F 3)((1=≢F 2)CParens F 4)(⍬) 
        Case def2I:  { 
            f3 f4 f5← F¨3 4 5 ⋄ f5← (1=≢F 2)CParens f5
            f4Parms← ' '~⍨¨ ';' (≠⊆⊢) f4
          0=≢f4Parms: m⊣ Tbl.Set1 f3 f5 ⍬
            m⊣ Tbl.Set1 f3 f5 f4Parms 
        }⍬
        Case showI: m, ∊(⊂cr,'⍝ '),dfns.disp Tbl.ShowMacros ⎕←F 2 
        Case undefI: m⊣ Tbl.Del F 2 
    }
  ⍝ Parse (user) code with macros
    ParseCode← macroP ⎕R { 
        F← ⍵.{ ⍵≥≢ll←Lengths: '' ⋄ 0>ll[⍵]: '' ⋄ ll[⍵]↑ Offsets[⍵]↓ Block }
        fnd (key val parms pats)← Tbl.Get1⍨ F 1 
        va← val, argStr← F 2
      ~fnd: va ⋄ 0=≢parms: va ⋄ 
        args← GetArgs argStr 
        pats← skipP ,⍥⊆ pats
        repl← '\0' ,⍥⊆ args↑⍨≢parms
        pats ⎕R repl ⊣ val 
    }
  ⍝ Parse lines-- logic per directive or not
    ParseLine← { 
      line← ⍵↓⍨ -+/∧\⌽⍵=' '
        isD line← ParseDirective line
      isD: line ⋄ 
      cActive= ⊃cStack: '⍝ ',line,cr,'  ',ParseCode ProcQts line
         '⍝-⍝  ',line 
    }
    1↓∊ cr∘,∘ParseLine¨⊆⍵
 }
