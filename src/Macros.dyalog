Macros←{ ⍺← 1  
    ⎕IO ⎕ML← 0 1
    caller← ⊃⎕RSI 
    includeLines←⍬
    maxMacSub← 10   ⍝ Maximum times to substitute macros per line. See Repeat
    _← 'disp' (dfns←⎕NS⍬).⎕CY 'dfns'
  ⍝ Error constants
    brErr← 'Parse: Too many right brackets "]"'
    BadCondErr← 'Macros: Invalid Conditional Expression: "'∘,,∘'"' 
    BadMacErr← 'Macros: expected macro "'∘,,∘'" not defined!'
    DirErr← 'Invalid directive: "'∘,,∘'"'
    EvalErr← 'Macros: Could not evaluate macro RHS expression "'∘,,∘'"'
    InclErr← 'Macros :minclude error: Unable to include file '∘, 
    QCTErr← 'QCToken expected ⍵ to start with '', ", or ⍝. String="'∘,,∘'"' 
  ⍝ Char Constants
    cr← ⎕UCS 13 
    sq dq lb rb cm ←'''"[]⍝'
    dq2←dq,dq 
    lbP rbP scP←'\[' '\]' ';'
  ⍝ Pattern Constants
    qt1P←'(?:''[^'']*'')+' ⋄ qt2P←'(?:"[^"]*")+' ⋄ cmP←'(?:⍝.*$)'
    skipQCP← 1↓∊ '|',¨qt1P qt2P cmP 
    let1P let2P← '[\pL∆⍙_]' '[\pL∆⍙_\d]'
    pfxAP pfxDP← '(?ix)' '(?ix)(^\s* ⍝? \s*)'
    bLftP bRgtP← '(?<![\pL∆⍙_])' '(?![\pL∆⍙_\d])'
    brktP←  '(?<B> \[ ((?> [^]["'']+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&B)* )+) \] )' 
  ⍝ Pattern Dfns 
  ⍝ ParmPat: Pattern to match parameter word ⍵ exactly
    ParmPat← (bLftP,'\Q')∘, ,∘('\E',bRgtP)        
    EscPat← { ⍵/⍨1+'\'=⍵ }
    CParens← { ⍺: '(',⍵,')' ⋄ ⍵}
  ⍝ Helper Fns ∆D, ∆A create pseudo PCRE escapes: \⍺, \⍵, \ßL, \ßR
    ⍝   \⍺  - 1st let of APL var name (non-digit)
    ⍝   \⍵  - subseq. let of APL var name
    ⍝   \ßL - \b for APL simple names (left side)
    ⍝   \ßR - \b for APL simple names (right side)
    ∆A← (EscPat¨'^' '\⍺' '\⍵' '\ßL' '\ßR')  ⎕R (EscPat¨ pfxAP let1P let2P bLftP bRgtP)
    ∆D← (EscPat¨'^' '\⍺' '\⍵' '\ßL' '\ßR')  ⎕R (EscPat¨ pfxDP let1P let2P bLftP bRgtP)
  ⍝ `abc => 'abc'
    qtFauxP← ∆A '\`\⍺\⍵*\ßR' 
  ⍝   a``b => ab (after any macro evaluations)
    catFauxP← '\h*`{2}\h*'         
  ⍝ macroP: See ParseCode below.
    macroP←   ∆A '(\⍺\⍵*)','(?:\h*(', brktP,'))?'
  ⍝ Patterns for Macro-Defining and Displaying Directives:
    ⍝   :mdef, :mdefp (add parens), :mundef :mshow
    def2P←    ∆D ':mdef([pe]{0,2}) \s+ (\⍺\⍵*) \s* (?:\[ (.*?) \]) \s* (?:← \s*)? (.*) $'
    def1P←    ∆D ':mdef([pe]{0,2}) \s+ (\⍺\⍵*)                     \s* (?:← \s*)? (.*) $'
    undefP←   ∆D ':mundef  \s+ (\⍺\⍵*) \s*$'
    showP←    ∆D ':mshow\b (.*) $'
    inclP←    ∆D ':minclude\b (.*) $'
  ⍝ Patterns for Conditional Macros: :mif, :melseif, :melse, :mend/:mendif  
    mifP←     ∆D ':mif\b \s*([^\s]+)$'
    melseifP← ∆D ':melseif\b \s*([^\s]+)$'
    melseP←   ∆D ':melse \s*$'
    mendifP←  ∆D ':mend(?:if)? \s*$'
  ⍝ Catchall for major syntax errors in macros only 
    errP←     ∆D ':m(defp?|undef|show|include|if|else|end).*'
  ⍝ Handle :minclude directive to include files...
    IncludeFile←{  
      fnm← TrimLR ⍵
    22:: 22 ⎕SIGNAL⍨ InclErr fnm
      ll← ⊃⎕NGET fnm 1
      ⍬⊣ includeLines,← (⊂'⍝⍝⍝ Including file ', fnm, ' ⍝⍝⍝'), ll
    }
    TrimLR←{ (+/∧\b)↓ ⍵↓⍨ -+/∧\⌽ b← ⍵=' ' }
  ⍝ Database (namespace) of macros
    db← ⎕NS⍬
    db.(keys←vals←parms←pats←⍬)
  ⍝ key← db.Set1 key value parm, where key is the macro name
    db.Set1← db.{
        k v p←⍵ ⋄ i←keys⍳⊂k 
      i<≢keys: k⊣ (i⊃vals)←v⊣ (i⊃parms)←p ⊣ (i⊃pats)←##.ParmPat¨p 
        k⊣ keys vals parms pats,∘⊂← k v p (##.ParmPat¨p)
    }
  ⍝ ...← [default] db.Get1 key 
  ⍝ Returns:   fnd (key val parms pats), where fnd=1 (if found)
  ⍝            fnd (key default ⍬ ⍬),    where fnd=0 (if not found)
    db.Get1← db.{ ⍺←⊢ 
        i←keys⍳ ⊂⍵ 
      i<≢keys: 1(keys vals parms pats⊃⍨¨i) 
      0≡⍺0: 11 ⎕SIGNAL⍨ BadMacErr ⍵ ⋄ 0 (⍵ ⍺ ⍬ ⍬)
    }
  ⍝ b← db.Del key
  ⍝ Deletes <key> and all its data, returning 1. If not found, returns 0.
    db.Del← db.{ k←⍵   
        0∊b ⊣ keys vals parms pats /⍨← ⊂b← (⍳≢keys)≠ keys⍳ ⊂k 
    }
  ⍝ ...← db.ShowMacros ['key1 key2 ...']. 
  ⍝ If the string of keys is empty (or has blanks), returns info for ALL keys.
  ⍝ Calls and returns the info from db.Show.
  ⍝ ...← db.Show [key1 key2 ... | keys]
  ⍝ If ⍵ is null, returns information for ALL existing keys.
  ⍝ Returns a formatted list of keys, parms, and values.
    db.ShowMacros← db.{ 0≠≢mm← Show ' '(≠⊆⊢)⍵: mm ⋄ ⊂'No macros defined' }
    db.Show← db.{
      (0=≢⍵)∧0≠≢keys: ⍉↑ keys parms vals
      (0=≢⍵): ⍬
        ⍉↑ keys parms vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
    }
  ⍝ QCScan: 
  ⍝   Process comments and quoted strings and hide from macro processing.
  ⍝ Scans a string for comments or quoted strings and processes them...
  ⍝   ∘ Convert double-quote sequences into single-quote sequences, 
  ⍝   ∘ Leave single-quote sequences as is,
  ⍝   ∘ Skip (⍺=1) or remove (⍺=0) comments.
    QCScan← { ⍺←1 ⋄ skipCm← ⍺                     ⍝ 1=Skip; 0= remove                     ⍝ ' " ;
      skipQCP ⎕R { skipCm QCToken ⍵.Match } ⍵
    }
  ⍝ QCToken is the workhorse for QCScan.
  ⍝ QCToken expects ⍵ to be a comment or quoted string.
  ⍝ No scan is done before or after.
    QCToken←{ ⍺←1 
       ~sq dq cm∊⍨ ⊃⍵: 11⎕SIGNAL⍨ QCTErr ⍵ 
       sq=⊃⍵: ⍵ ⋄ '⍝'=⊃⍵: ⍺⊃ '' ⍵ 
          sq,sq,⍨ n/⍨ ~dq2⍷ n← n/⍨ 1+ sq= n← 1↓¯1↓ m
    }
  ⍝ ScanArgs-- process user arguments and match up with macro parameters.
  ⍝   Only valid with a complete argument expression [...]
    ScanArgs←{ 
        gaPP←qt1P qt2P lbP rbP scP                ⍝ ' " [ ] ;
             qt1I qt2I lbI rbI scI←⍳≢ gaPP

        (lb≠⊃⍵)∨(rb≠⊃⌽⍵): ⊂⍵⊣ ⎕←'Macros Warning: Parameter brackets assumed for macro "',⍺,'[...]".'       ⍝ No args!
        brPos←1   ⍝ We've seen a lb 
        ⊢txt← gaPP ⎕R{ C←∊∘⍵.PatternNum ⋄ m←⍵.Match
          C qt1I: m
          C qt2I: sq,sq,⍨ n/⍨ ~dq2⍷ n←n/⍨ 1+ sq= n←1↓ ¯1↓m
          C lbI:  m⊣ brPos+←1 
          C rbI:  m⊣ brErr ⎕SIGNAL 11/⍨ 1≥ brPos⊢← brPos-1 
          C scI:  cr m⊃⍨ brPos>1         ⍝ Splitting on "bare" semicolons
        }⊆1↓ ¯1↓ ⍵ 
    }
  ⍝ Managing the Conditional Stack used for :mif ... :mend
    condStk ← ⍬         
    condBegin condActive condSkip← 1 0 ¯1   
    CondEval← caller{ 
      0:: 11 ⎕SIGNAL⍨ BadCondErr ⍺ 
        b← ⍺⍺⍎'0≢⍥,', QCScan ⍵  
        (⊃⌽condStk)← condBegin condActive⊃⍨ b
        ' => ', '(', (⍕b), ')'
    }
    CondElse← { (⊃⌽condStk)←  condSkip condActive⊃⍨ condBegin= ⊃⌽condStk }
    CondEnd←  { ⊢condStk ↓⍨← ¯1 }
  ⍝ Parse Macro Directives (:def, etc.)
    isDirctv← 0 
    pdPP← def2P def1P undefP showP inclP mifP melseifP melseP mendifP errP
          def2I def1I undefI showI inclI mifI melseifI melseI mendifI errI← ⍳≢pdPP
    ParseDirective← { isDirctv⊢← 0 ⋄ isDirctv,⊂ PD2 ⍵ } 
    PD2← pdPP ⎕R { 
          Case← ∊∘⍵.PatternNum  
          F← ⍵.{ 0>lw← Lengths[⍵]: '' ⋄ lw↑ Offsets[⍵]↓ Block }
          isDirctv⊢← 1
          m← '⍝ ',(' '⍴⍨0⌈l-2), m0← ⍵.Match↓⍨ l←≢F 1 
      ⍝ Major errors signalled no matter what
        Case errI:  11 ⎕SIGNAL⍨ DirErr 2↓m 
      ⍝ Conditional :mend executed no matter what
        Case mendifI: m⊣ CondEnd ⍬
      ⍝ Other conditionals executed only if NOT in condSkip mode
      condSkip= ⊃⌽condStk: '⍝-',m 
        Case mifI:     m, m0 CondEval F 2 ⊢ condStk,⍨← condBegin 
        Case melseifI: m, m0 CondEval F 2 
        Case melseI:   m⊣    CondElse ⍬
      ⍝ Execute Macro Defs only if in condActive mode 
      condActive≠ ⊃⌽condStk: '⍝-',m 
        Case def1I: {
          pFlag eFlag← 'pe'∊⎕C F 2 ⋄ name← F 3 
          value← pFlag CParens eFlag EvalM F 4
          m⊣ db.Set1 name value ⍬
        }⍬
        Case def2I:  { 
            pFlag eFlag← 'pe'∊⎕C F 2 ⋄ name← F 3   
            value← pFlag CParens eFlag EvalM F 5 
            parms← ' '~⍨¨ ';' (≠⊆⊢) F 4
          0=≢parms: m⊣ db.Set1 name value ⍬
            m⊣ db.Set1 name value parms 
        }⍬
        Case showI: m, ∊(⊂cr,'⍝ '),dfns.disp db.ShowMacros F 2
        Case undefI: m⊣ db.Del F 2 
        Case inclI:  m⊣ IncludeFile F 2 
    }
  ⍝ ParseCode: Parse (user) code with macros
  ⍝ Skip quotes and comments
    ⍝ PC_II: Handle "faux" quote operator: `xxx => 'xxx'
    PC_II← skipQCP qtFauxP ⎕R { 0=⍵.PatternNum: ⍵.Match ⋄ sq, (1↓⍵.Match),sq }
    ParseCode← PC_II skipQCP macroP catFauxP ⎕R { 
         skipI macroI joinI← 0 1 2 ⋄ C← ⍵.PatternNum∘=
      C skipI: QCToken ⍵.Match 
      C joinI: ''
    ⍝ C macroI...
        F← ⍵.{ ⍵≥≢ll←Lengths: '' ⋄ 0>ll[⍵]: '' ⋄ ll[⍵]↑ Offsets[⍵]↓ Block }
        fnd (key val parms pats)← db.Get1⍨ F 1 
        va← val, argStr← F 2
      ~fnd: va ⋄ 0=≢parms: va 
        args← key ScanArgs argStr 
        pats← skipQCP ,⍥⊆ pats
        repl← '\0' ,⍥⊆ args↑⍨≢parms
        pats ⎕R repl ⊣ val 
    }
    Repeat← { ⍺←0 ⋄ ⍵≡ txt← ⍵⍵ ⍵: txt ⋄ ⍺< ⍺⍺: (⍺+1) ∇ txt ⋄ txt }
  ⍝ EvalM: Evaluate code or, on failure, return as is!
    EvalM← { 0:: 11 ⎕SIGNAL⍨ EvalErr ⍵ ⋄ ~⍺: ⍵ ⋄ ⍕caller⍎ParseCode ⍵ }

  ⍝ Parse lines-- logic per directive or not
    ParseLine← { 
      line← ⍵↓⍨ -+/∧\⌽⍵=' '
        isD line← ParseDirective line
      isD: line ⋄ 
      condActive≠ ⊃⌽condStk: '⍝-⍝  ',line 
        out←  maxMacSub Repeat ParseCode⊢ line 
      out≡line: '  ',line 
          PadRHS← 60 { ⍺⍺<≢⍺: ⍺, ⍵ ⋄ ⍵,⍨ ⍺⍺↑ ⍺}  
        ('  ',out) PadRHS ' ⍝ <= ',line 
    }
    ParseAll←{ ⍺←⍬ 
       0≠≢includeLines: ⍺ ∇ tt, ⍵⊣ includeLines⊢← ⍬⊣  tt← includeLines 
       0=≢⍵:  1↓∊ cr,¨⍺
        (⍺, ⊂ParseLine ⊃⍵) ∇ 1↓ ⍵ 
    }
    ParseAll ⊆⍵ 
 }
