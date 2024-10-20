Macros←{ ⍺←'' ⋄ _← ⍎'__NS__' ⎕NS ⍬⊣ __NS__← ⍬ 
⍝ Hide all the variables from user :mdef-e evaluations
⍺((⊃⎕RSI) __NS__.{   
⍝:Section options (⍺@CV) and caller (⍺⍺@Ns)
⍝ ⍺ is a single simple char. string (default: '')
⍝ options:  [noq/uiet | q/uiet]     [nos/imple | s/imple]
⍝   quiet:  exclude from output directives (except :mshow output)
⍝           Default: include output from all directives
⍝   simple: return output as a simple char string with carriage returns
⍝           separating lines. Default: return a vector of char vectors.
  caller← ⍺⍺
  ⍺← '' ⋄ Opt← (1∘∊⍷)∘(⎕C⍺)
    qOpt←  ( Opt 'q')∧ ~Opt 'noq'    ⍝ q/uiet.      Default 0 'noq'
    sOpt←  ( Opt 's')∧ ~Opt 'nos'    ⍝ [no]s/imple  Default 0 'nos'
    dOpt←  ( Opt 'd')∧ ~Opt 'nod'    ⍝ [no]d/ebug   Default 0 'nod'
⍝:EndSection 

⍝:Section Settable "parameters"
  ⍝ maxSubOpt: Maximum times to substitute macros per line. See Repeat
    maxSubOpt← 20 
  ⍝ "Index origin" for __COUNTER__ (1 or 0)
    counterIO←  0
⍝:EndSection

    ⎕IO ⎕ML← 0 1 ⋄ 

⍝:Section Miscellaneous Utilities
    disp←⊢    ⍝ Placeholder (⎕NC 3.3) for dfns::disp (⎕NC 3.2)
    Dfns_disp← {disp ⍵}{ 3.3=⎕NC ⊂'disp': ⍵⊣'disp' ⎕CY 'dfns'⋄ ⍵}   
    ⍝ Align: Aligns "comments" on RHS of a substituted line. 
    ⍝ Aligns at 40 chars, if space; else 80 100 ... 
    Align← 60 { 
      qOpt: ⍺ ⋄ ⍺⍺< ≢⍺: ⍺((⍺⍺+20)∇∇)⍵ ⋄ ⍵,⍨ ⍺⍺↑ ⍺ 
    }
  ⍝ CDoc: Return a string only if the "quiet" option is 0.
    CDoc←  (~qOpt)∘/    
    CNullLines← {⍵/⍨0≠≢∘TrimR¨⍵}⍣qOpt
    TrimLR←{ (+/∧\b)↓ ⍵↓⍨ -+/∧\⌽ b← ⍵=' ' }
    TrimR← { ⍵↓⍨ -+/∧\⌽⍵=' ' }
  ⍝ QTok: "xxx" =>   " 'xxx' ". No internal quote doubling added
    QTok← ' '''∘,,∘''' '   
  ⍝ ∆F: Match field ⍵ in ⎕R namespace ⍺. Happily returns '' if field is omitted/missing.
    ∆F← { l o b← ⍺.(Lengths Offsets Block) 
          ⍵≥≢l: '' ⋄ 0> l[⍵]: '' ⋄ l[⍵]↑ o[⍵]↓ b 
    }
  ⍝ ParmSplit: If ⍵ not null, split on semicolons (and remove blanks)
    ParmSplit←{ 0≠≢⍵: ' '~⍨¨ ';' (≠⊆⊢)⍵ ⋄ ⍵ }
⍝:EndSection Miscellaneous Utilities

⍝:Section Constants 
  ⍝ Error constants
    brErr← 'Macros DOMAIN ERROR: Too many right brackets "]"'
    CondErr← 'Macros DOMAIN ERROR: Invalid Conditional Expression: "'∘,,∘'"' 
    BadMacErr← 'Macros LOGIC ERROR: expected macro "'∘,,∘'" not defined!'
    DirErr← 'Macros DOMAIN ERROR: Invalid directive: "'∘,,∘'"'
    EvalErr← 'Macros DOMAIN ERROR: Could not evaluate macro RHS expression "'∘,,∘'"'
    InclErr← 'Macros DOMAIN ERROR: Unable to include file '∘, 
    QCTErr← 'Macros LOGIC ERROR in QCToken: expected ⍵ to start with '', ", or ⍝. String="'∘,,∘'"' 
  ⍝ Char Constants
    cr← ⎕UCS 13 
    sq dq lb rb cm esc ←'''"[]⍝`'
    dq2←dq,dq 
    lbP rbP scP←'\[' '\]' ';'
  ⍝ Pattern Constants
    qt1P←'(?:''[^'']*'')+' ⋄ qt2P←'(?:"[^"]*")+' ⋄ cmP←'(?:⍝.*$)'
    skipQP←  1↓∊ '|',¨qt1P qt2P
    skipQCP← 1↓∊ '|',¨qt1P qt2P cmP 
    let1P let2P← '[\pL∆⍙_]' '[\pL∆⍙_\d]'
    pfxAP pfxDP← '(?ix)' '(?ix)(^\h* ⍝? \h*)'
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
  ⍝ `abc12 => 'abc12'   `1.2E45 => '1.2E45'    `abc def 123 => 'abc' 'def' '123' 
  ⍝    If no var/num sequence matches, ` silently disappears.
    qtFauxP← ∆A '\` \h* ((?:(?: \⍺\⍵*\ßR | \d[\d\.E¯]* | \.\d+[\dE¯]* ) \h*)*)' 
  ⍝ Catenation of Symbols: 
  ⍝   a``b   => ab   (after any macro evaluations)
  ⍝   a``123 => a123 (ditto)
    catFauxP← '\h*\`{2}\h*' 
  ⍝ Continuation lines:  
  ⍝    line `` [spaces]$ 
  ⍝    line `` ⍝ comment$     (comments will be placed on sep line before code)
    continueP← '(\h*\`\h*)(⍝.*)?$'  
  ⍝ macroP: See ParseCode below.
    macroP←   ∆A '(\⍺\⍵*)','(?:\h*(', brktP,'))?'
  ⍝ Patterns for Macro-Defining and Displaying Directives:
  ⍝  
    def2P←    ∆D ':mdef ((?:-?[pem]{1,2})?) \h+ (\⍺\⍵*) \h* (?:\[ (.*?) \]) \h* (?:←\h*(.*) )? $'
    def1P←    ∆D ':mdef ((?:-?[pem]{1,2})?) \h+ (\⍺\⍵*)                     \h* (?:←\h*(.*) )? $'
    constP←   ∆D ':mconst                   \h+ (\⍺\⍵*)                     \h* (?:←\h*(.*) )? $'
    setP←     ∆D ':mset(?:var)?             \h+ (\⍺\⍵*)                     \h* (?:←\h*(.*) )? $'
    undefP←   ∆D ':mundef  \h+ (\⍺\⍵*) \h*$'
    showP←    ∆D ':mshow(-?m?)\b \h* (.*) $'
    inclP←    ∆D ':minclude\b    \h* (.*) $'
    onceP←    ∆D ':monce\b       \h*      $'
  ⍝ Patterns for Conditional Macros: :mif, :melseif, :melse, :mend/:mendif  
    ifP←     ∆D ':mif         \h+ ([^\h]+)   $'
    ifdefP←  ∆D ':mifdef      \h+ (\⍺\⍵*) \h*$'
    ifndefP← ∆D ':mifndef     \h+ (\⍺\⍵*) \h*$'
    elseifP← ∆D ':melseif     \h+ ([^\h]+)   $'
    elseP←   ∆D ':melse                   \h*$'
    endifP←  ∆D ':mend(?:if)?             \h*$'
  ⍝ pøp: hidden directive. 
    popP←    ∆D '^:mpop_\b .* $' 
  ⍝ Catchall for major syntax errors in macros only 
    errP←     ∆D ':m(def|set|undef|show|include|once|if|else|end|pop).*'
⍝:EndSection Constants

⍝:Section Include Macro Buffer Management. (See :minclude)
    includeBuf← ⍬
    onceStack← ⍬ 
    fiStack← ,⊂'[stdin]'
    liStack← ,0
    IncludeFi←{ 
        fi← TrimLR ⍵ 
        already← onceStack∊⍨ ⊂fi 
      already: 0⊣ includeBuf,← ⊂'⍝⍝⍝ Not including file "',fi,'". Already seen. ⍝⍝⍝'
        fiStack,← ⊂fi  ⋄ liStack,← 0
      22:: 22 ⎕SIGNAL⍨ InclErr fi
        ll← TrimR¨ ⊃⎕NGET fi 1
        ⍬⊣ includeBuf,← (⊂'⍝⍝⍝ Including file "', fi, '" ⍝⍝⍝'), ll, ⊂':mpop_'
    }
  ⍝ newStream← InclFlush inputStream@⍵: 
  ⍝    Prepend the lines of the included file to the input 
  ⍝    stream ¨⍵¨ (then clear the include buffer)
    InclFlush← { tt← includeBuf ⋄ includeBuf⊢← ⍬ ⋄ tt, ⍵ }
    InclPop←   { (fiStack liStack)↓⍨← - 1≠ ≢fiStack }

⍝:EndSection

⍝:Section Database (namespace) of macros
  db← ⎕NS⍬
  db.(keys←vals←⍬)
  ⍝ key← db.Set key value parm, where key is the macro name
  db.Set← db.{ ⍺←0
    ⍺: ##.caller SetMagic ⍵
      k v p parFlg←⍵ ⋄ i←keys⍳⊂k 
      pats← ##.ParmPat¨p 
    i<≢keys: k⊣ (i⊃vals)← v p pats 0 parFlg ⍬
      k⊣ keys vals,∘⊂← k (v p pats 0 parFlg ⍬)
  }
  db.SetMagic← db.{ k v p parFlg←⍵ ⋄ i←keys⍳⊂k 
      pats← ##.ParmPat¨p
    i<≢keys: k⊣ (i⊃vals)←  v p pats 1 parFlg ## 
      k⊣ keys vals,∘⊂← k (v p pats 1 parFlg ##)
  }
  ⍝ ...← [default] db.Get key 
  ⍝ Returns:   fnd (key val parms pats), where fnd=1 (if found)
  ⍝            fnd (key default ⍬ ⍬),    where fnd=0 (if not found)
  db.Get← db.{ ⍺←⊢ 
      i←keys⍳ ⊂⍵ 
    i=≢keys: 0 (⍵ ⍺ ⍬ ⍬ )⊣ (⍬≢⍺⍬){⍺: ⍬ ⋄ 11 ⎕SIGNAL⍨ ##.BadMacErr ⍵}⍵
    k (v p pats m parFlg ns)←  i⊃¨ keys vals 
    ~m: 1 (k (parFlg ##.CParens v) p pats) 
        1 (k (parFlg ##.CParens ⍕ns⍎v) p pats) 
  }
  ⍝ b← db.Del key
  ⍝ Deletes <key> and all its data, returning 1. If not found, returns 0.
  db.Del← db.{ k←⍵   
      0∊b ⊣ keys vals/⍨← ⊂b← (⍳≢keys)≠ keys⍳ ⊂k 
  }
  ⍝ ...← db.ShowMacros ['key1 key2 ...']. 
  ⍝ If the string of keys is empty (or has blanks), returns info for ALL keys.
  ⍝ Calls and returns the info from db.Show.
  ⍝ ...← db.Show [key1 key2 ... | keys]
  ⍝ If ⍵ is null, returns information for ALL existing keys.
  ⍝ Returns a formatted list of keys, parms, and values.
  db.ShowMacros← db.{ ⍺←0
    0≠≢mm← ⍺ Show ' '(≠⊆⊢)⍵: mm ⋄ ⊂'No macros defined' 
  }
  db.Show← db.{ ⍺←0
      title← 'macros'  'parms' 'value' 'magic?'
    (0=≢⍵)∧0≠≢keys: ⍺{
    ⍝ If ⍺=0, show only non-magic keys (unless user specifies keys on :mshow cmd)
      kk← ⍺{ ⍺=1: ⍵ ⋄ ⍵/⍨ (2↑¨⍵)≢¨⊂'__'}keys 
    0=≢kk: ⍬
      vv pp ppats mm parFlg ns ← ↓⍉↑vals[ keys⍳kk ]  
      title,[0] ⍉↑ kk pp (parFlg ##.CParens¨ vv) mm    
    }⍬ 
    (0=≢⍵): ⍬
      kk data← keys vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
      vv pp ppats mm parFlg ns ← ↓⍉↑ data 
      title,[0] ⍉↑ kk pp (parFlg ##.CParens¨ vv) mm    
  }
⍝:EndSection

⍝:Section Process Comments and (Single/Double) Quoted Strings
  ⍝ QCScan: 
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
        sq,sq,⍨ n/⍨ ~dq2⍷ n← n/⍨ 1+ sq= n← 1↓¯1↓ ⍵
  }
⍝:EndSection 

⍝:Section Process User Arguments
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
⍝:EndSection

⍝:Section Define Macros
  ⍝ flags: pFlag (add parens?), eFlag (should we execute the value once?),
  ⍝       mFlag (is it "magic," i.e. should we execute each time we see it?)
    DefMac← {
      (pFlag eFlag mFlag)(name val parms)← ⍺ ⍵  
      mFlag db.Set name (eFlag EvalM val) (ParmSplit parms) pFlag 
    }
⍝:EndSection

⍝:Section Conditional Stack (:mif, :elseIf, ..., :mend)
    condStk ← ⍬         
    condBegin condActive condSkip← 1 0 ¯1   
    CondEval← caller{ 
      0:: 11 ⎕SIGNAL⍨ CondErr ⍺ 
        b← ⍺⍺⍎'0≢⍥,', QCScan ⍵  
        (⊃⌽condStk)← condBegin condActive⊃⍨ b
        ' ⍝ => ', '(', (⍕b), ')'
    }
    CondDef← {  ⍝ Operator: ⍺⍺ is either ⊢ or ~
        fnd← ⊃ 0 db.Get ⍵ 
        (⊃⌽condStk)← condBegin condActive⊃⍨ ⍺⍺ fnd
        ' ⍝ => ', '(', ')',⍨ ⍵, fnd⊃' undefined' ' defined'
    }
    CondElse← { (⊃⌽condStk)←  condSkip condActive⊃⍨ condBegin= ⊃⌽condStk }
    CondEnd←  { ⊢condStk ↓⍨← ¯1 }
⍝:EndSection

⍝:Section Parse Macro Directives (:def, etc.)
    isDirctv← 0 
    pdPP← def2P def1P constP setP undefP showP inclP ifP ifdefP ifndefP elseifP elseP endifP popP onceP errP
          def2I def1I constI setI undefI showI inclI ifI ifdefI ifndefI elseifI elseI endifI popI onceI errI← ⍳≢pdPP
    ParseDirective← { isDirctv⊢← 0 ⋄ isDirctv,⊂ PD2 ⍵ } 
    PD2←  pdPP ⎕R { 
          Case← ∊∘⍵.PatternNum  
          F← ⍵∘∆F 
          isDirctv⊢← 1   
          m← '⍝ ',(' '⍴⍨0⌈l-2), m0← ⍵.Match↓⍨ l←≢F 1 
      ⍝ Major errors signalled no matter what
        Case errI:  11 ⎕SIGNAL⍨ DirErr 2↓m 
      ⍝ Hidden directive to manage file names...
        Case popI:    ''⊣ InclPop⍬
      ⍝ Conditional :mend executed no matter what
        Case endifI:  CDoc m⊣ CondEnd ⍬
      ⍝ Other conditionals executed only if NOT in condSkip mode
      condSkip= ⊃⌽condStk: '⍝-',m 
        Case ifI:     CDoc m Align m0 CondEval F 2 ⊣ condStk,⍨← condBegin 
        Case ifdefI:  CDoc m Align (⊢CondDef)  F 2 ⊣ condStk,⍨← condBegin 
        Case ifndefI: CDoc m Align (~CondDef)  F 2 ⊣ condStk,⍨← condBegin 
        Case elseifI: CDoc m Align m0  CondEval F 2 
        Case elseI:   CDoc m⊣     CondElse ⍬
      ⍝ Execute Macro Defs only if in condActive mode 
      condActive≠ ⊃⌽condStk: '⍝-',m 
        Case def1I:   CDoc m⊣ ('pem'∊⎕C F 2) DefMac (F 3) (F 4) ⍬
        Case def2I:   CDoc m⊣ ('pem'∊⎕C F 2) DefMac (F 3) (F 5) (F 4)
        Case constI:  CDoc m⊣ 1 1 0          DefMac (F 2) (F 3) ⍬
        Case setI:    CDoc m⊣ f2{ ⍎⍺,'←⍵' } 1 EvalM f3 ⊣ f2 f3← F¨2 3
        Case showI:   m, ∊(⊂cr,'⍝ '), Dfns_disp ('m'∊F 2) db.ShowMacros F 3
        Case undefI:  CDoc m⊣ db.Del F 2 
        Case inclI:   CDoc m⊣ IncludeFi F 2
        Case onceI:   CDoc m⊣ onceStack,← ¯1↑fiStack 
    }⍠('ResultText' 'Simple')('EOL' 'CR') 
⍝:EndSection 

⍝:Section Parse User Code Potentially Containing Macros 
  ⍝ Skip quotes and comments
    ⍝ PC_Last: Handle "faux" quote operator. (See qtFauxP definition)
    PC_Last← skipQCP qtFauxP ⎕R { 
      0=⍵.PatternNum: ⍵.Match 
      0=≢quotable← ⍵ ∆F 1: '' ⋄ ∊ QTok¨ ' ' (≠⊆⊢) quotable 
    }
    ⍝ ParseCode: Handle macros and "faux" catenation operator for obj names:
    ⍝    abc``123 => abc123 
    ParseCode← skipQCP macroP catFauxP  ⎕R { 
         skipI  macroI catI ← ⍳3 ⋄ C← ⍵.PatternNum∘= ⋄ F← ⍵∘∆F 
      C skipI: QCToken ⍵.Match 
      C catI: ''
    ⍝ C macroI...
        fnd (key val parms pats)← db.Get⍨ F 1 
        va← val, argStr← F 2
      ~fnd: va ⋄ 0=≢parms: va 
        args← key ScanArgs argStr 
        pats← skipQCP ,⍥⊆ pats
        repl← '\0' ,⍥⊆ args↑⍨≢parms
        pats ⎕R repl ⊣ val 
    }
    Repeat← { ⍺←0 ⋄ ⍵≡ txt← ⍵⍵ ⍵: txt ⋄ ⍺< ⍺⍺: (⍺+1) ∇ txt ⋄ txt }
  ⍝ EvalM: Evaluate code or, on failure, signal an error!
  ⍝ ∘ Both ⍕ and ⍎ below are executed in the caller env, 
  ⍝   with ⎕PP and ⎕FR temporarily altered so constants have high precision.
    EvalM← {  
     ~⍺: ⍵ 
        Rstr← caller.{ (⎕PP ⎕FR)⊢← ⍺ ⋄ ⍵ }
        _saved⊢← caller.{ s← ⎕PP ⎕FR ⋄ s⊣ (⎕PP ⎕FR)⊢← ⍵ } 34 1287 
        p← ParseLine  ⍵ 
     0:: 11 ⎕SIGNAL⍨ EvalErr ⍵⊣ ⎕←'Parsed: ',p⊣⎕←'Code:   ',⍵⊣ _saved Rstr⍬
        _saved Rstr caller.(⍕⍎)p 
    }
    _saved← 0 0
⍝:EndSection 

⍝:Section Parse Input Lines 
  ⍝ Continuation Lines?   aa ` [⍝...]
    ParseContinue← {
      line← contBuffer{0=≢⍺: TrimR ⍵ ⋄ ⍺, ' ', TrimLR ⍵} ⍵ 
      contBuffer⊢← '' 
      lc← skipQP continueP ⎕R {
        0=⍵.PatternNum: ⍵.Match 
        0=≢f2← ⍵ ∆F 2: cr,cr
          cr, '⍝ ', TrimLR 1↓f2    
      } ,⊂line  
      1= ≢lc: 0 (⊃lc) ⋄ contBuffer,← ⊃lc ⋄ 1 (⊃⌽lc) 
    } 
    contBuffer←''

    ParseLine← {   
        __LINE__+← 1               ⍝ Line number...
        hasC line← ParseContinue ⍵ ⍝⍝⍝ EVALUATE THIS!!! sometimes 2=≡line
    ⍝ hasC: line is either a comment line or a blank line.
      hasC: line
        isD line← ParseDirective line
      isD: line 
      condActive≠ ⊃⌽condStk: CDoc '⍝-⍝  ',line 
        out← PC_Last maxSubOpt Repeat ParseCode⊢ line 
      out≡line: '  ',line 
        ( '  ', out) Align ' ⍝ <= ',line 
    }
⍝:EndSection

⍝:Section Executive 
    Executive←{
      ⍬{
        0≠≢includeBuf: ⍺ ∇ InclFlush ⍵ 
        0=≢⍵: ⍺
          (⍺, ⊂ParseLine ⊃⍵) ∇ 1↓ ⍵ 
      } ⊆⍵
    }

    __COUNTER__← counterIO
    __LINE__← 0 
    _← db.SetMagic '__FILE__'     'QTok ⊃⌽fiStack'                   ⍬ 0
    _← db.SetMagic '__LINE__'     '__LINE__'                      ⍬ 0 
    _← db.SetMagic '__COUNTER__'  '((__COUNTER__+← 1)⊢ __COUNTER__)' ⍬ 0 

    _← (0 1 2+⊃⎕LC) ⎕STOP⍣dOpt ⊢'Macros'
    lineV← CNullLines Executive ⍵ 
    sOpt: 1↓∊cr,¨ lineV ⋄ lineV

⍝:EndSection 
})⍵
} 
