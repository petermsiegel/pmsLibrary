Macros←{ 
⍝ Hide all the variables from user :mdef-e evaluations
⍺←'' ⋄__NS__← ⍬ 
⍺ ((⊃⎕RSI) (⍎'__NS__' ⎕NS ⍬).{   
⍝:Section options (⍺@CV) and caller (⍺⍺@Ns)
⍝ ⍺ is a single simple char. string (default: '')
⍝ options:  [noq/uiet | q/uiet]     [nos/imple | s/imple]
⍝   quiet:  exclude from output directives (except :mshow output)
⍝           Default: include output from all directives
⍝   simple: return output as a simple char string with carriage returns
⍝           separating lines. Default: return a vector of char vectors.
    ⎕IO ⎕ML← 0 1 
    caller← ⍺⍺
    ⍺← '' ⋄ Opt← ⍺ { M← 1∘∊⍷∘(⎕C ⍺⍺) ⋄ ⍺: ~M 'no',⍵ ⋄ (M ⍵)∧ 1 ∇ ⍵ }  
  ⍝ [no]q/uiet.  Default 0, 'noq'    ⍝ [no]s/imple  Default 0, 'nos'
  ⍝ [no]d/ebug   Default 0, 'nod'    ⍝ [no]w/arn    Default 1, 'w'
    qOpt sOpt dOpt wOpt← 0 0 0 1 Opt¨ 'qsdw'         
⍝:EndSection 

⍝:Section Settable "parameters"
  ⍝ maxSubOpt: 
  ⍝   Maximum times to substitute "runaway" macros per line before error. 
  ⍝   See Repeat
    maxSubOpt← 20 
  ⍝ "Index origin" for __COUNTER__ (1 or 0)
    counterOrigin←  0
⍝:EndSection 

⍝:Section Miscellaneous Utilities
    disp←⊢    ⍝ Placeholder (⎕NC 3.3) for dfns::disp (⎕NC 3.2)
    Dfns_disp← {disp ⍵}{ 3.3=⎕NC ⊂'disp': ⍵⊣'disp' ⎕CY 'dfns'⋄ ⍵}   
  ⍝ AlignCm: Aligns "comments" on RHS of a substituted line. 
  ⍝ Aligns at ⍺⍺ chars, if space; else ⍺⍺+20, ⍺⍺+40, ...
    AlignCm← 60 { 
      qOpt: ⍺ ⋄ ⍺⍺< ≢⍺: ⍺((⍺⍺+20)∇∇)⍵ ⋄ ⍵,⍨ ⍺⍺↑ ⍺ 
    }
  ⍝ CDoc: Return the string ⍵ only if the "quiet" option is off.
    CDoc←  (~qOpt)∘/ 
  ⍝ CNullLines: Remove null (empty) lines from ⍵ if "quiet" option.   
    CNullLines← {⍵/⍨0≠≢∘TrimR¨⍵}⍣qOpt
  ⍝ Trim blanks...
    TrimLR←{ (+/∧\b)↓ ⍵↓⍨ -+/∧\⌽ b← ⍵=' ' }
    TrimR← { ⍵↓⍨ -+/∧\⌽⍵=' ' }
  ⍝ CBracket:  'xxx' => '[xxx]', ⍬ => ⍬.
    CBracket← { 0=≢⍵: ⍬ ⋄ lb, rb,⍨ 1↓ ∊sc,¨⍵~¨sp }
  ⍝ QTok: Convert token (with no internal quotes) to string: "xxx" =>   " 'xxx' "
  ⍝       No internal quote doubling added...
    SpTok← ' '∘, ,∘' '
    QTok← ' '''∘,,∘''' '   
    QTok2← { numStart∊⍨ ⊃⍵: SpTok ⍵ ⋄ QTok ⍵ }
  ⍝ ∆F: Match field ⍵ in ⎕R namespace ⍺. Happily returns '' if field is omitted/missing.
    ∆F← { l o b← ⍺.(Lengths Offsets Block) 
          ⍵≥≢l: '' ⋄ 0> l[⍵]: '' ⋄ l[⍵]↑ o[⍵]↓ b 
    }
  ⍝ ParmSplit: 
  ⍝   If ⍵ is not null or blank, split on semicolons (and remove blanks)
  ⍝   Else return ⍬ 
    ParmSplit←{ pStr← ⍵~' ' ⋄ 0= ≢pStr: ⍬ ⋄ ';' (≠⊆⊢) pStr}
⍝:EndSection Miscellaneous Utilities

⍝:Section Constants 
  ⍝ Error constants
    BadDefErr← 'Macros: Invalid definition: '∘,,∘'[]'
    brErr←     'Macros DOMAIN ERROR: Too many right brackets "]"'
    CondErr←   'Macros DOMAIN ERROR: Invalid Conditional Expression: "'∘,,∘'"' 
    BadMacErr← 'Macros LOGIC ERROR: expected macro "'∘,,∘'" not defined!'
    DirErr←    'Macros DOMAIN ERROR: Invalid directive: "'∘,,∘'"'
    EvalErr←   'Macros DOMAIN ERROR: Could not evaluate macro RHS expression "'∘,,∘'"'
    InclErr←   'Macros DOMAIN ERROR: Unable to include file '∘, 
    QCTErr←    'Macros LOGIC ERROR in QCToken: expected ⍵ to start with '', ", or ⍝. String="'∘,,∘'"' 
  ⍝ Char Constants
    cr← ⎕UCS 13 
    sp sq dq lb rb cm esc sc ←' ''"[]⍝`;'
    dq2←dq,dq 
    numStart← '¯',⎕D 
  ⍝ Pattern Constants
    lbP rbP←  '\',¨ lb rb 
    scP← sc   
    qt1P←'(?:''[^'']*'')+' ⋄ qt2P←'(?:"[^"]*")+' ⋄ cmP←'(?:⍝.*$)'
    skipQP←  1↓∊ '|',¨qt1P qt2P
    skipQCP← 1↓∊ '|',¨qt1P qt2P cmP 
    let1P let2P← '[\pL∆⍙_]' '[\pL∆⍙_\d]'
    pfxAP pfxDP← '(?ix)' '(?ix)(^\h* ⍝? \h*)'
    bLftP bRgtP← ('(?<![\pL∆⍙_])') '(?![\pL∆⍙_\d])'
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
    ifP←      ∆D ':mif            \h+ ([^\h]+)   $'
    ⍝ mifdef, mifndef
    ifdefP←   ∆D ':mif(n?)def     \h+ (\⍺\⍵*) \h*$'
    elifP←    ∆D ':melseif        \h+ ([^\h]+)   $'
    elifdefP← ∆D ':melseif(n?)def \h+ ([^\h]+)   $'
    elseP←    ∆D ':melse\b                    \h*$'
    endifP←   ∆D ':mend(?:if)?\b              \h*$'
  ⍝ pøp: hidden directive. 
    popP←     ∆D '^:mpop_\b .* $' 
  ⍝ Catchall for major syntax errors in macro directives only 
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
⍝ key← db.Set k:key v:value p:parms parenFlg, where key is the macro name
  db.Set← db.{ ⍺←0 ⋄ 
    ⍺: ##.caller SetMagic ⍵
      m ns← 0 ⍬ 
      k v p parenFlg← ⍵ ⋄ i←keys⍳⊂k 
      v← parenFlg CParens v 
      pats← ##.ParmPat¨p 
    i<≢keys: {
        oldV← i⊃vals 
        newV← v p pats m parenFlg ns  
      oldV≡newV: ⍵
        (i⊃vals)← newV 
      ~##.wOpt: ⍵
        oldP newP← ##.CBracket¨ 1⊃¨oldV newV
        difF← ≢/ oldF newF← oldV[3 4 5],⍥⊂ newV[3 4 5] 
          ∆Fl← difF∘{ ⍺: '; flags: ', ⍵ ⋄ '' } 
        ⎕←'Warning: Value for macro "',⍵,'" has changed'  f`
        ⎕←'>>> Old: ', ⍵, oldP, '←', oldV[0], ∆Fl oldF 
        ⎕←'>>> New: ', ⍵, newP, '←', newV[0], ∆Fl newF 
        ⍵
    }k
      k⊣ keys vals,∘⊂← k ( v p pats 0 0 )
  }
⍝ SetMagic: ⍵: k:key, v:value, p:parms, parenFlg)
  db.SetMagic← db.{ 
      m ns← 1 ##
      k v p parenFlg← ⍵ 
      i←keys⍳ ⊂k 
      v← parenFlg CParens v 
      pats← ##.ParmPat¨p 
    ⍝ (i⊃vals)← 
    ⍝  v:value, p:parms, pats:pats for parms, m:magic=1, parenFlg, execute namespace
    i<≢keys: k⊣ (i⊃vals)←  v p pats m parenFlg ns  
      k⊣ keys vals,∘⊂← k  (v p pats m parenFlg ns)
  }
  ⍝ ...← [default] db.Get key 
  ⍝ Returns:   fnd (key val parms pats), where fnd=1 (if found)
  ⍝            fnd (key default ⍬ ⍬),    where fnd=0 (if not found)
  db.Get← db.{ ⍺←⊢ 
       i←keys⍳ ⊂⍵ 
    i=≢keys: 0 (⍵ ⍺ ⍬ ⍬ )⊣ (⍬≢⍺⍬){⍺: ⍬ ⋄ 11 ⎕SIGNAL⍨ ##.BadMacErr ⍵}⍵
       k (v p pats m parenFlg ns)←  i⊃¨ keys vals 
    m: 1 (k (parenFlg ##.CParens ⍕ns⍎v) p pats) 
       1 (k (parenFlg ##.CParens v) p pats) 
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
      vv pp ppats mm parenFlg ns ← ↓⍉↑vals[ keys⍳kk ]  
      title,[0] ⍉↑ kk pp (parenFlg ##.CParens¨ vv) mm    
    }⍬ 
    (0=≢⍵): ⍬
      kk data← keys vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
      vv pp ppats mm parenFlg ns ← ↓⍉↑ data 
      title,[0] ⍉↑ kk pp (parenFlg ##.CParens¨ vv) mm    
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
      (eFlag mFlag)(name val parms parmFlag)← ⍺ ⍵ 
      parmV← ParmSplit parms  
      parmFlag∧ 0=≢parmV: 11 ⎕SIGNAL⍨ BadDefErr name 
    ⍝              name  value                          parameters parmFlag
      mFlag db.Set name (eFlag CEval val) parmV parmFlag 
    }
⍝:EndSection

⍝:Section Conditional Stack (:mif, :elseIf, ..., :mend)
    condStk ← ⍬         
    condBegin condActive condSkip← 1 0 ¯1   
    CondEval← caller{ 
      0:: 11 ⎕SIGNAL⍨ CondErr ⍺ 
        b← ⍺⍺⍎'0≢⍥,', QCScan ParseCode ⍵
        (⊃⌽condStk)← condBegin condActive⊃⍨ b
        ' ⍝ => ', '(', (⍕b), ')'
    }
    CondDef← {  ⍝ Operator: ⍺⍺ is either 1 or 0
        fnd← ⊃ 0 db.Get ⍵ ⋄ Sel← ⍺⍺∘{ ⍺: ⍵ ⋄ ~⍵}
        (⊃⌽condStk)← condBegin condActive⊃⍨ Sel fnd
        ' ⍝ => ', '(', ')',⍨ ⍵, fnd⊃' undefined' ' defined'
    }
    CondElse← { (⊃⌽condStk)←  condSkip condActive⊃⍨ condBegin= ⊃⌽condStk }
    CondEnd←  { ⊢condStk ↓⍨← ¯1 }
⍝:EndSection

⍝:Section Parse Macro Directives (:def, etc.)
    isDirctv← 0 
    pdPP← def2P def1P constP setP undefP showP inclP ifP ifdefP elifP elifdefP elseP endifP popP onceP errP
          def2I def1I constI setI undefI showI inclI ifI ifdefI elifI elifdefI elseI endifI popI onceI errI← ⍳≢pdPP
    ParseDirective← { isDirctv⊢← 0 ⋄ isDirctv,⊂ PD2 ⍵ } 
    PD2←  pdPP ⎕R { 
          Case← ∊⍨∘⍵.PatternNum  
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
        Case ifI:     CDoc m AlignCm m0 CondEval F 2 ⊣ condStk,⍨← condBegin 
        Case elifI:   CDoc m AlignCm m0 CondEval F 2 
        Case ifdefI, elifdefI:  {
                      CDoc m AlignCm (1≠≢F 2)CondDef F 3 ⊣ condStk,⍨← condBegin
        } ⍬
        Case elseI:   CDoc m⊣ CondElse ⍬
      ⍝ Execute Macro Defs only if in condActive mode 
      condActive≠ ⊃⌽condStk: '⍝-',m 
        Case def1I:   CDoc m⊣ ('pem'∊⎕C F 2) DefMac (F 3) (F 4) ⍬     0
        Case def2I:   CDoc m⊣ ('pem'∊⎕C F 2) DefMac (F 3) (F 5) (F 4) 1
        Case constI:  CDoc m⊣ 1 1 0          DefMac (F 2) (F 3) ⍬     0
        Case setI:    CDoc m⊣ f2 SetLocal 1 CEval f3 ⊣ f2 f3← F¨2     3
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
      0=≢quotable← ⍵ ∆F 1: '' 
        ∊ QTok2¨ ' ' (≠⊆⊢) quotable 
    }
    ⍝ ParseCode: Handle macros and "faux" catenation operator for obj names:
    ⍝    abc``123 => abc123 
    ParseCode← skipQCP macroP catFauxP  ⎕R { 
         skipI  macroI catI ← ⍳3 ⋄ C← ⍵.PatternNum∘= ⋄ F← ⍵∘∆F 
      C skipI: QCToken ⍵.Match 
      C catI: ''
    ⍝ C macroI...
        fnd (key val parms pats)← db.Get⍨ F 1 
        argStr← F 2
      ~fnd: val, argStr 
        noP← 0=≢parms ⋄ noA← 0=≢argStr   
      noP∧ noA: val, argStr  
      noP:  val, lb, rb,⍨ ParseCode 1↓¯1↓ argStr 
        args← key ScanArgs argStr 
        pats← skipQCP ,⍥⊆ pats
        repl← '\0' ,⍥⊆ args↑⍨≢parms
        pats ⎕R repl ⊣ val 
    }
    Repeat← { ⍺← 0 ⍵ ⋄ i orig← ⍺ 
      ⍵≡ txt← ⍵⍵ ⍵: txt 
      i< ⍺⍺: (i+1)orig ∇ txt 
          ⎕← 'Macros Warning: Substitution suppressed for line:'
          ⎕← ' "',orig,'"'
          ⎕← '>>> Runaway macro substitution detected at',⍺⍺,'iterations.'
          ⎕← '>>> Txt was: "',txt,'"'
          orig
    }
  ⍝ CEval: (If ⍺=1), Evaluate code or, on failure, signal an error!
  ⍝ ∘ Both ⍕ and ⍎ below are executed in the caller env, 
  ⍝   with ⎕PP and ⎕FR temporarily altered so constants have high precision.
    CEval← {  
     ~⍺: ⍵  
        Rstr← caller.{ (⎕PP ⎕FR)⊢← ⍺ ⋄ ⍵ }
        _saved⊢← caller.{ s← ⎕PP ⎕FR ⋄ s⊣ (⎕PP ⎕FR)⊢← ⍵ } 34 1287 
         p← ParseCode ⍵   
     0:: 11 ⎕SIGNAL⍨ EvalErr ⍵⊣ ⎕←'Parsed: ',p⊣⎕←'Code:   ',⍵⊣ _saved Rstr⍬
        _saved Rstr caller.(⍕⍎)p 
    }
    _saved← 0 0
  ⍝ SetLocal: ⍺ SetLocal val. Sets name in ⍺ to value <val>.
    SetLocal← { ⍎⍺,'←⍵' }
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

    ParseLine← { ⍺←1  
        __LINE__+← ⍺               ⍝ Line number...
        hasC line← ParseContinue ⍵ ⍝⍝⍝ EVALUATE THIS!!! sometimes 2=≡line
    ⍝ hasC: line is either a comment line or a blank line.
      hasC: line
        isD line← ParseDirective line
      isD: line 
      condActive≠ ⊃⌽condStk: CDoc '⍝-',line 
        out← PC_Last maxSubOpt Repeat ParseCode⊢ line 
      out≡line: '  ',line 
        ( '  ', out) AlignCm ' ⍝ <= ',line 
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

    __COUNTER__← counterOrigin
    __LINE__← 0 
    _← db.SetMagic '__FILE__'     'QTok ⊃⌽fiStack'                    ⍬ 0
    _← db.SetMagic '__LINE__'     '__LINE__'                         ⍬ 0 
    _← db.SetMagic '__COUNTER__'  '(__COUNTER__+← 1)⊢ __COUNTER__'   ⍬ 1 

    _← (dOpt/ 1 2+⊃⎕LC) ⎕STOP ⊃⎕XSI
    lineV← CNullLines Executive ⍵ 
    sOpt: 1↓∊(⊂cr,⍨ dOpt/'␍'),¨ lineV ⋄ lineV

⍝:EndSection 
})⍵
} 
