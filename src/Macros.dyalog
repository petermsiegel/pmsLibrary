Macros←{ ⍺← 1 ⋄ keepComments← ⍺  
⍝:Section Settable "options"
  ⍝ maxSubOpt: Maximum times to substitute macros per line. See Repeat
    maxSubOpt← 10 
⍝:EndSection

    ⎕IO ⎕ML← 0 1 ⋄ caller← ⊃⎕RSI 

⍝:Section Miscellaneous Utilities
    _← 'disp' (dfns←⎕NS⍬).⎕CY 'dfns'
    ⍝ Align: Aligns "comments" on RHS of a substituted line. 
    ⍝ Aligns at 60 chars, if space; else 80 100 ... 
    Align← 60 { ~keepComments: ⍺ ⋄ ⍺⍺< ≢⍺: ⍺((⍺⍺+20)∇∇)⍵ ⋄ ⍵,⍨ ⍺⍺↑ ⍺ }
    Doc← { ~keepComments: '' ⋄ ⍵}
    TrimLR←{ (+/∧\b)↓ ⍵↓⍨ -+/∧\⌽ b← ⍵=' ' }
    TrimR← {⍵↓⍨ -+/∧\⌽⍵=' ' }
    Qt← ' '''∘,,∘''' '
    ∆F← { l o b← ⍺.(Lengths Offsets Block) 
          ⍵≥≢l: '' ⋄ l[⍵]<0: '' ⋄ l[⍵]↑ o[⍵]↓ b 
    }
⍝:EndSection Miscellaneous Utilities

⍝:Section Constants 
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
    sq dq lb rb cm esc ←'''"[]⍝`'
    dq2←dq,dq 
    lbP rbP scP←'\[' '\]' ';'
  ⍝ Pattern Constants
    qt1P←'(?:''[^'']*'')+' ⋄ qt2P←'(?:"[^"]*")+' ⋄ cmP←'(?:⍝.*$)'
    skipQP←  1↓∊ '|',¨qt1P qt2P
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
  ⍝ `abc12 => 'abc12'   `1.2E45 => '1.2E45'. 
  ⍝    If no var/num matches, ` silently disappears.
    qtFauxP← ∆A '\` \h* ((?: \⍺\⍵*\ßR | \d[\d\.E¯]* | \.\d+[\dE¯]* )?)' 
  ⍝ Catenation of Symbols: 
  ⍝   a``b   => ab   (after any macro evaluations)
  ⍝   a``123 => a123 (ditto)
    catFauxP← '\h*\`{2}\h*' 
  ⍝ Continuation lines:  
  ⍝    line `` [spaces]$ 
  ⍝    line `` ⍝ comment$     (comments will be placed on sep line before code)
    continueP← '(\s*\`\s*)(⍝.*)?$'  
  ⍝ macroP: See ParseCode below.
    macroP←   ∆A '(\⍺\⍵*)','(?:\h*(', brktP,'))?'
  ⍝ Patterns for Macro-Defining and Displaying Directives:
    ⍝   :mdef, :mdef-p (add parens), :mundef :mshow
    def2P←    ∆D ':mdef ((?:\h*-[pem]{1,2})?) \h+ (\⍺\⍵*) \s* (?:\[ (.*?) \]) \s* (?:← \s*)? (.*) $'
    def1P←    ∆D ':mdef ((?:\h*-[pem]{1,2})?) \h+ (\⍺\⍵*)                     \s* (?:← \s*)? (.*) $'
    undefP←   ∆D ':mundef  \s+ (\⍺\⍵*) \s*$'
    showP←    ∆D ':mshow\b (.*) $'
    inclP←    ∆D ':minclude\b (.*) $'
    onceP←    ∆D ':monce\b (.*) $'
  ⍝ Patterns for Conditional Macros: :mif, :melseif, :melse, :mend/:mendif  
    ifP←     ∆D ':mif\b \s*([^\s]+)$'
    ifdefP←  ∆D ':mifdef\b\s*(\⍺\⍵*) \s*$'
    ifndefP← ∆D ':mifndef\b\s*(\⍺\⍵*) \s*$'
    elseifP← ∆D ':melseif\b \s*([^\s]+)$'
    elseP←   ∆D ':melse \s*$'
    endifP←  ∆D ':mend(?:if)? \s*$'
  ⍝ pøp: hidden directive. 
    popP←    ∆D '^:mpop_\b .* $' 
  ⍝ Catchall for major syntax errors in macros only 
    errP←     ∆D ':m(defp?|undef|show|include|if|else|end|pop_).*'
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
        k v p parens←⍵ ⋄ i←keys⍳⊂k 
        pats← ##.ParmPat¨p 
      i<≢keys: k⊣ (i⊃vals)← v p pats 0 parens ⍬
        k⊣ keys vals,∘⊂← k (v p pats 0 parens ⍬)
    }
    db.SetMagic← db.{ k v p parens←⍵ ⋄ i←keys⍳⊂k 
        pats← ##.ParmPat¨p
      i<≢keys: k⊣ (i⊃vals)←  p pats 1 parens ## 
        k⊣ keys vals,∘⊂← k (v p pats 1 parens ##)
    }
  ⍝ ...← [default] db.Get key 
  ⍝ Returns:   fnd (key val parms pats), where fnd=1 (if found)
  ⍝            fnd (key default ⍬ ⍬),    where fnd=0 (if not found)
    db.Get← db.{ ⍺←⊢ 
        i←keys⍳ ⊂⍵ 
      i=≢keys: 0 (⍵ ⍺ ⍬ ⍬ )⊣ (⍬≢⍺⍬){⍺: ⍬ ⋄ 11 ⎕SIGNAL⍨ ##.BadMacErr ⍵}⍵
      k (v p pats m parens ns)←  i⊃¨ keys vals 
      ~m: 1 (k (parens ##.CParens v) p pats) 
          1 (k (parens ##.CParens ⍕ns⍎v) p pats) 
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
    db.ShowMacros← db.{ 0≠≢mm← Show ' '(≠⊆⊢)⍵: mm ⋄ ⊂'No macros defined' }
    db.Show← db.{
        title← 'keys' 'magic?' 'parms' 'value'
      (0=≢⍵)∧0≠≢keys: {
        vv pp ppats mm parens ns ← ↓⍉↑vals  
        title,[0] ⍉↑ keys mm pp (parens ##.CParens¨ vv)    
      }⍬ 
      (0=≢⍵): ⍬
        kk data← keys vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
        vv pp ppats mm parens ns ← ↓⍉↑ data 
        title,[0] ⍉↑ kk mm  pp (parens ##.CParens¨ vv)  
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

⍝:Section Conditional Stack (:mif, :elseIf, ..., :mend)
    condStk ← ⍬         
    condBegin condActive condSkip← 1 0 ¯1   
    CondEval← caller{ 
      0:: 11 ⎕SIGNAL⍨ BadCondErr ⍺ 
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
    pdPP← def2P def1P undefP showP inclP ifP ifdefP ifndefP elseifP elseP endifP popP onceP errP
          def2I def1I undefI showI inclI ifI ifdefI ifndefI elseifI elseI endifI popI onceI errI← ⍳≢pdPP
    ParseDirective← { isDirctv⊢← 0 ⋄ isDirctv,⊂ PD2 ⍵ } 
    PD2← pdPP ⎕R { 
          Case← ∊∘⍵.PatternNum  
          F← ⍵∘∆F 
          isDirctv⊢← 1
          m← '⍝ ',(' '⍴⍨0⌈l-2), m0← ⍵.Match↓⍨ l←≢F 1 
      ⍝ Major errors signalled no matter what
        Case errI:  11 ⎕SIGNAL⍨ DirErr 2↓m 
      ⍝ Hidden directive to manage file names...
        Case popI:   ''⊣ InclPop⍬
      ⍝ Conditional :mend executed no matter what
        Case endifI: Doc m⊣ CondEnd ⍬
      ⍝ Other conditionals executed only if NOT in condSkip mode
      condSkip= ⊃⌽condStk: '⍝-',m 
        Case ifI:     Doc m Align m0 CondEval F 2 ⊣ condStk,⍨← condBegin 
        Case ifdefI:  Doc m Align (⊢CondDef)  F 2 ⊣ condStk,⍨← condBegin 
        Case ifndefI: Doc m Align (~CondDef)  F 2 ⊣ condStk,⍨← condBegin 
        Case elseifI: Doc m Align m0  CondEval F 2 
        Case elseI:   Doc m⊣     CondElse ⍬
      ⍝ Execute Macro Defs only if in condActive mode 
      condActive≠ ⊃⌽condStk: '⍝-',m 
        Case def1I: {
          pFlag eFlag mFlag← 'pem'∊⎕C F 2 ⋄ name← F 3 
          value← eFlag EvalM F 4
          Doc m⊣ mFlag db.Set name value ⍬ pFlag 
        }⍬
        Case def2I:  { 
            pFlag eFlag mFlag← 'pem'∊⎕C F 2 ⋄ name← F 3   
            value← eFlag EvalM F 5 
            parms← ' '~⍨¨ ';' (≠⊆⊢) F 4
          0=≢parms: Doc m⊣ mFlag db.Set name value ⍬ pFlag 
            Doc m⊣ mFlag db.Set name value parms pFlag  
        }⍬
        Case showI:  m, ∊(⊂cr,'⍝ '), dfns.disp db.ShowMacros F 2
        Case undefI: Doc m⊣ db.Del F 2 
        Case inclI:  Doc m⊣ IncludeFi F 2
        Case onceI:  Doc m⊣ onceStack,← ¯1↑fiStack 
    }⍠('ResultText' 'Simple')('EOL' 'CR') 
⍝:EndSection 

⍝:Section Parse User Code Potentially Containing Macros 
  ⍝ Skip quotes and comments
    ⍝ PC_Last: Handle "faux" quote operator. (See qtFauxP definition)
    PC_Last← skipQCP qtFauxP ⎕R { 
      0=⍵.PatternNum: ⍵.Match 
      0=≢quotable← ⍵ ∆F 1: '' ⋄ Qt quotable
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
  ⍝ EvalM: Evaluate code or, on failure, return as is!
    EvalM← { 0:: 11 ⎕SIGNAL⍨ EvalErr ⍵ ⋄ ~⍺: ⍵ ⋄ ⍕caller⍎ParseCode ⍵ }
⍝:EndSection 

⍝:Section Parse Input Lines 
  ⍝ Continuation Lines?   aa ` [⍝...]
    ParseContinue← {
      line← contBuffer{0=≢⍺: TrimR ⍵ ⋄ ⍺, ' ', TrimLR ⍵} ⍵ 
      contBuffer⊢← '' 
      lc← skipQP continueP ⎕R {
          0=⍵.PatternNum: ⍵.Match 
          0=≢f2← ⍵ ∆F 2: cr,' ' ⋄ cr, '⍝ ', TrimLR 1↓f2 
      } ,⊂line  
      1= ≢lc: 0 lc ⋄ contBuffer,← ⊃lc ⋄ 1 (⊃⌽lc) 
    } 
    contBuffer←''

    ParseLine← {   
        __LINE__+← 1               ⍝ Line number...
        hasC line← ParseContinue ⍵
    ⍝ hasC: line is either a comment line or a blank line.
      hasC: line          
        isD line← ParseDirective line
      isD: line 
      condActive≠ ⊃⌽condStk: Doc '⍝-⍝  ',line 
        out← PC_Last maxSubOpt Repeat ParseCode⊢ line 
      out≡line: '  ',line 
        (∊ '  ',out) Align ∊' ⍝ <= ',line 
    }
⍝:EndSection
⍝:Section Executive 
    Executive←{ ⍺←⍬  
        0≠≢includeBuf: ⍺ ∇ InclFlush ⍵ 
        0=≢⍵:  1↓∊ cr,¨⍺
          (⍺, ⊂ParseLine ⊃⍵) ∇ 1↓ ⍵ 
    }

    __LINE__← 0 
    _← db.SetMagic '__FILE__' 'Qt ⊃⌽fiStack' ⍬ 0
    _← db.SetMagic '__LINE__' '__LINE__' ⍬ 0 

    {⍵/⍨0≠≢¨⍵} cr (≠⊆⊢) Executive ⊆⍵ 
⍝:EndSection 
 } 
