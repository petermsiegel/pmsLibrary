Macros←{ 
⍝ Hide all the variables from user :mdef-e and -m evaluations
⍺←⍬     
⍺ (⎕NS ⍬).{  
    ⎕IO ⎕ML← 0 1  
⍝ :Section Master Error Handler...
    Sig← ⎕SIGNAL/{ ⍺←11 ⋄ msg← ⍵  
      0= ⎕NC 'lineStk': msg 11      ⍝ Done, if we aren't yet on a line...
        context← (⊃⌽fileStk), (lb,rb,⍨ ⍕__LINE__),' ',__TEXT__
        (msg, cr, context) 11 
    } 
⍝ :EndSection Master Error Handler

⍝:Section Options (⍺)
⍝ ⍺ is either null, or one or more options of the form ('option_name' value.)
⍝ options:  
⍝  ('quiet' [0|1]) ('simple' [0|1]) ('debug' [0|1]) 
⍝  ('warn' [1|0])  ('caller' (⊃⎕RSI))
⍝   quiet:  exclude from output directives (except :mshow output)
⍝           Default 0: include output from all directives
⍝  simple:  return output as a simple char string with carriage returns
⍝           separating lines. (Assumed option if keyword "simple" is omitted).
⍝           Default 0: return a vector of char vectors.
⍝   debug:  if 1, stops the function at the Executive (q.v.) for debugging.
⍝           Provides additional debugging information.
⍝           Default 0: no debugging.
⍝    warn:  if 1 (default), warn if a macro is redefined (even slightly).
⍝           Default 0: redefined macros accepted without warnings.  
⍝  caller:  the caller namespace; 
⍝           Default: ⊃⎕RSI (actual namespace of calling function).
    defaults←('simple' 0)('quiet' 0)('debug' 0)('warn' 1)('caller' (⊃⎕RSI))
  ⍝           ↑ Assumed option if scalar.
  ⍝ The following vars will be set in namespace ¨o¨.
  ⍝    quiet, simple, debug, warn, and caller. 
    o← defaults { 
        w← ⍺∘{ 1=≢⍵: (⊃⊃⍺) ⍵ ⋄ ⍵}¨ ⊂⍣(¯2= ≡⍵)⊢⍵ 
      0∊ 2= ≢¨aw← ⍺,w: Sig 'Macros: Invalid option format' 
      1∊ x← ~⊃∊/ ⊃¨¨w ⍺:  Sig 'Macros: Unknown option(s): ', ∊⊃¨x/ ⍵
        ns←⎕NS ⍬ ⋄ ns⊣ {ns⍎ (⊃⍵), '←⊃⌽⍵'}¨ aw 
    } ⍺
⍝:EndSection Options 

⍝:Section Settable Parameters
  ⍝ maxSubOpt: 
  ⍝   Maximum times to substitute potentially "runaway" macros per line before error. 
  ⍝   See Repeat
    maxSubOpt← 20 
  ⍝ "Index origin" for __COUNTER__ (1 or 0)
    counterOrigin←  0
  ⍝ How much to indent user text lines...
    lMarg←2 
⍝:EndSection Settable Parameters

⍝:Section Constants 
  ⍝ Error constants (dfns and char)
    BadDefErr← 'Macros DOMAIN ERROR: Invalid definition: '∘,,∘'[]'
    brErr←     'Macros DOMAIN ERROR: Too many right brackets "]"'
    CondErr←   'Macros DOMAIN ERROR: Invalid Conditional Expression: "'∘,,∘'"' 
    BadMacErr← 'Macros LOGIC ERROR: expected macro "'∘,,∘'" not defined!'
    DirErr←    'Macros DOMAIN ERROR: Invalid directive: "'∘,,∘'"'
    EvalErr←   'Macros DOMAIN ERROR evaluating macro RHS expression "'∘,,∘'"'
    InclErr←   'Macros DOMAIN ERROR: Unable to include file '∘, 
    QCTErr←    'Macros LOGIC ERROR: ¨QCToken¨ requires ⍵ to start with '', ", or ⍝. String="'∘,,∘'"' 
    
  ⍝ Char Constants
    cr← ⎕UCS 13 
    sp sq dq lb rb cm esc sc← ' ''"[]⍝`;'   ⍝ Our "escape" is ` 
    dq2← dq,dq 
  ⍝ Regex Constants and Fns
    lbP rbP←  '\',¨ lb rb 
    scP← sc   
    qt1P←'(?:''[^'']*'')+' ⋄ qt2P←'(?:"[^"]*")+' ⋄ cmP←'(?:⍝.*$)'
    skipQP←  1↓ ∊'|',¨qt1P qt2P
    skipQCP← 1↓ ∊'|',¨qt1P qt2P cmP 
    let1P let2P← '[#⎕\pL∆⍙_]' '[#⎕\pL∆⍙_\d]'
    pfxAP pfxDP← '(?ix)' '(?ix)(^\h* ⍝? \h*)'
    bLftP bRgtP← ('(?<![#⎕\pL∆⍙_])') '(?![#⎕\pL∆⍙_\d])'
    brktP←  '(?<B> \[ ((?> [^]["'']+ | (?:"[^"]*")+ | (?:''[^'']*'')+ | (?&B)* )+) \] )' 
  ⍝ Pattern Dfns 
  ⍝ ParmPat: Pattern to match parameter word ⍵ exactly
    ParmPat← (bLftP,'\Q')∘, ,∘('\E',bRgtP)        
    EscPat← { ⍵/⍨ 1+'\'=⍵ }
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
  ⍝ macroP: See ParseMacros below.
    macroP←   ∆A '(\⍺\⍵*)','(?:\h*(', brktP,'))?'
  ⍝ Patterns for Macro-Defining and Displaying Directives:
  ⍝  
    def2P←    ∆D ':mdef ((?:-?[pem]{1,2})?) \h+ (\⍺\⍵*) \h* (?:\[ (.*?) \]) \h* (?:←\h*(.*) )? $'
    def1P←    ∆D ':mdef ((?:-?[pem]{1,2})?) \h+ (\⍺\⍵*)                     \h* (?:←\h*(.*) )? $'
    constP←   ∆D ':mconst                   \h+ (\⍺\⍵*)                     \h* (?:←\h*(.*) )? $'
    setP←     ∆D ':mset(?:v(?:ar)?)?        \h+ (\⍺\⍵*(?:\.\⍺\⍵*)*)         \h* (?:←\h*(.*) )? $'
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
  ⍝ pop: hidden directive. 
    eofTokP←     ∆D '^:meof_\b .* $' 
  ⍝ Catchall for major syntax errors in macro directives only 
    errP←     ∆D ':m(def|const|set|undef|show|include|once|if|else|end|pop).*'
⍝:EndSection Constants

⍝:Section Miscellaneous Utilities   
  ⍝ AlignCm: Aligns "comments" on RHS of a substituted line. 
  ⍝ Aligns at ⍺⍺ chars, if space; else ⍺⍺+20, ⍺⍺+40, ...
    AlignCm← 60 { 
      o.quiet: ⍺ ⋄ ⍺⍺< ≢⍺: ⍺((⍺⍺+20)∇∇)⍵ ⋄ ⍵,⍨ ⍺⍺↑ ⍺ 
    }
  ⍝ CBracket:  'xxx' => '[xxx]', ⍬ => ⍬.
    CBracket← { 0=≢⍵: ⍬ ⋄ lb, rb,⍨ 1↓ ∊sc,¨⍵~¨sp }
  ⍝ CDoc: Return the string ⍵ only if the "quiet" option is off.
    CDoc←  (~o.quiet)∘/ 
  ⍝ CNullLines: Remove null (empty) lines from ⍵ if "quiet" option.   
    CNullLines← {⍵/⍨0≠≢∘TrimR¨⍵}⍣o.quiet
  ⍝ DebugMode: Turned on if ⍵=1. Else turned off.
    DebugMode←{ 
      ~⍵: ⍬ ⎕STOP ⊃⎕XSI ⋄ next← 1+⊃⍺ 
      ⎕←'Debug Mode Active. Start Dyalog Tracing? '
      'n'∊ ⎕C⍞↓⍨ ≢⍞←'Yes or no? [Yes] ': 0⊣⎕←'Tracing is skipped...'
      ⎕← 'Tracing starting...'
      next ⎕STOP ⊃⎕XSI
    }
  ⍝ disp: placeholder (⎕NC 3.3) for dfns::disp (⎕NC 3.2)
    disp←⊢    
    Dfns_disp← {disp ⍵}{ 3.3=⎕NC ⊂'disp': ⍵⊣'disp' ⎕CY 'dfns'⋄ ⍵}   
  ⍝ IsInt: 1 if ⍵ has ¯ or digits
    IsInt← ∧/∊∘('¯',⎕D)
  ⍝ Obj2Str:  str← lMarg∘Obj2Str obj 
  ⍝   lMarg:   left margin for each "line". 
  ⍝   obj:     arbitrary ⎕FMT-ready object 
  ⍝   Returns: string vector with internal lefthand blanks & carriage returns.
    Obj2Str← lMarg∘{
      1↓ ,cr, m↑[1]⍨ -⍺+ ⊃⌽⍴m← ⎕FMT ⍵
    }
  ⍝ ParmSplit: 
  ⍝   If ⍵ is not null or blank, split on semicolons, removing ALL blanks
  ⍝   Else return ⍬ 
    ParmSplit←{ 
      pStr← ⍵~' ' ⋄ 0= ≢pStr: ⍬ ⋄ ';' (≠⊆⊢) pStr
    }
  ⍝ QTok: Convert token (with no internal quotes) to string: "xxx" =>   " 'xxx' "
  ⍝       No internal quote doubling added...
    QTok← (sp,sq)∘,,∘(sq,sp) 
  ⍝ QNTok: Like QTok, but leaves numeric constants outside quotes
    QNTok← { IsInt ⊃⍵: SpTok ⍵ ⋄ QTok ⍵ }
  ⍝  
    SpTok← sp∘, ,∘sp
  ⍝ Trim blanks...
    TrimLR←{ (+/∧\b)↓ ⍵↓⍨ -+/∧\⌽ b← ⍵=' ' }
    TrimR← { ⍵↓⍨ -+/∧\⌽⍵=' ' }  
    Where← { (⊃⌽fileStk), (lb,rb,⍨ ⍕⊃⌽lineStk),' ',__TEXT__ }
  ⍝ ∆F: Match field ⍵ in ⎕R namespace ⍺. 
  ⍝     Happily returns '', if field is omitted/missing.
    ∆F← { l o b← ⍺.(Lengths Offsets Block) 
          ⍵≥≢l: '' ⋄ 0> l[⍵]: '' ⋄ l[⍵]↑ o[⍵]↓ b 
    }
⍝:EndSection Miscellaneous Utilities

⍝:Section Include Macro Buffer Management. (See :minclude)
    fileBuf← ⍬
    onceStk← ⍬ 
    fileStk← ,⊂''
    lineStk← ,0
    IncludeFile←{ 
        fi← TrimLR ⍵ 
        already← onceStk∊⍨ ⊂fi 
      already: 0⊣ fileBuf,← (⊂'⍝⍝⍝ *** Macros: Already included file "',fi,'" and :mOnce specified. *** ⍝⍝⍝') 
        fileStk,← ⊂fi  ⋄ lineStk,← 0
      22:: 22 Sig InclErr fi 
        ll← TrimR¨ ⊃⎕NGET fi 1
        1⊣ fileBuf,←  (⊂'⍝⍝⍝ *** Macros: Including file "', fi, '". *** ⍝⍝⍝'), ll, ⊂':meof_'
    }
  ⍝ newStream← FlushFileBuf inputStream@⍵: 
  ⍝    Prepend the lines of the included file to the input 
  ⍝    stream ¨⍵¨ (then clear the include buffer)
    FlushFileBuf← { tt← fileBuf ⋄ fileBuf⊢← ⍬ ⋄ tt, ⍵ }
  ⍝ EofSeen: We saw an ':meof_' token in the input stream (we put it there!)
    EofSeen←   { (fileStk lineStk)↓⍨← - 1≠ ≢fileStk }
⍝:EndSection

⍝:Section Database (namespace) of macros
  db← ⎕NS⍬
  db.(keys←vals←⍬)
⍝ key← db.Set k:key v:value p:parmV addParens, where key is the macro name
  db.Set← db.{ ⍺←0 ⋄ 
    ⍺:  SetMagic ⍵
      m← 0  
      k vIn p addParens← ⍵ ⋄ k← 1∘⎕C⍣('⎕'=⊃k)⊢ k 
      i←keys⍳ ⊂k
      v← addParens ##.CParens vIn 
      pats← ##.ParmPat¨p 
      newV← v p pats m addParens 
    i<≢keys: k⊣ {
        oldV← i⊃vals 
      oldV ≡ newV: ⍬              
    ⍝ A Macro has been redefined...
        (i⊃vals)← newV            ⍝ Keep new def.
      ~##.o.warn: ⍬               ⍝ The "warn" option is off: return happily.
    ⍝ A Macro has been redefined and the "warn" option is off: warn user.
        oldP newP← ##.CBracket¨ 1⊃¨oldV newV
        difF← ≢/ oldF newF← oldV[3 4],⍥⊂ newV[3 4] 
        oF nF← { difF: '; flags: ', ⍵ ⋄ '' }¨ oldF newF  
        ⎕← ##.Where ⍬
        ⎕←'>>> Warning: Value for macro "',k,'" has changed' 
        ⎕←'>>> Old: ', k, oldP, '←', oldV[0], oF
        ⎕←'>>> New: ', k, newP, '←', newV[0], nF
        ⍬
    } ⍬
    k⊣ keys vals,∘⊂← k ⍺
  }
⍝ SetMagic: ⍵: k:key, v:value, p:parmV, addParens)
  db.SetMagic← db.{ 
      m← 1 
      k vIn p addParens← ⍵ ⋄ k← 1∘⎕C⍣('⎕'=⊃k)⊢ k 
      i←keys⍳ ⊂k 
      v← addParens ##.CParens vIn 
      pats← ##.ParmPat¨p 
    i<≢keys: k⊣ (i⊃vals)←  v p pats m addParens  
      k⊣ keys vals,∘⊂← k  (v p pats m addParens)
  }
  ⍝ ...← [default] db.Get key 
  ⍝ Returns:   fnd (key val parmV pats), where fnd=1 (if found)
  ⍝            fnd (key default ⍬ ⍬),    where fnd=0 (if not found)
  db.Get← db.{ ⍺←⊢ 
       i←keys⍳ ⊂k← 1∘⎕C⍣('⎕'=⊃⍵)⊢ ⍵ 
    i=≢keys: 0 (⍵ ⍺ ⍬ ⍬ )⊣ (⍬≢⍺⍬)##.{⍺: ⍬ ⋄ Sig BadMacErr ⍵ }k 
       k (v p pats magic addParens)←  i⊃¨ keys vals 
  0:: ##.{ Sig EvalErr ⍵ }v 
    magic: 1 (k (addParens ##.CParens ⍕##⍎v) p pats) 
           1 (k (addParens ##.CParens     v) p pats) 
  }
  ⍝ b← db.Del key
  ⍝ Deletes <key> and all its data, returning 1. If not found, returns 0.
  db.Del← db.{ 
      k← 1∘⎕C⍣('⎕'=⊃⍵)⊢ ⍵ 
      0∊b ⊣ keys vals/⍨← ⊂b← (⍳≢keys)≠ keys⍳ ⊂k 
  }
  ⍝ ...← db.ShowMacros ['key1 key2 ...']. 
  ⍝ If the string of keys is empty (or has blanks), returns info for ALL keys.
  ⍝ Calls and returns the info from db.Show.
  ⍝ ...← db.Show [key1 key2 ... | keys]
  ⍝ If ⍵ is null, returns information for ALL existing keys.
  ⍝ Returns a formatted list of keys, parmV, and values.
  db.ShowMacros← db.{ ⍺←0
    Show← {
      title← 'macros'  'parms' 'value' 'magic?'
    (0=≢⍵)∧0≠≢keys: ⍺{
    ⍝ If ⍺=0, show only non-magic keys (unless user specifies keys on :mshow cmd)
      kk← ⍺{ ⍺=1: ⍵ ⋄ ⍵/⍨ (2↑¨⍵)≢¨⊂'__'}keys 
      kk← { 1∘⎕C⍣('⎕'=⊃⍵)⊢ ⍵ }¨ kk 
    0=≢kk: ⍬
      vv pp ppats mmagic addParens← ↓⍉↑vals[ keys⍳kk ]  
      title,[0] ⍉↑ kk pp (addParens ##.CParens¨ vv) mmagic    
    }⍬ 
    (0=≢⍵): ⍬
      kk data← keys vals⌷⍨¨ ⊂⊂ii/⍨ (≢keys)> ii← keys⍳ ∪⍵ 
      vv pp ppats mm addParens← ↓⍉↑ data 
      title,[0] ⍉↑ kk pp (addParens ##.CParens¨ vv) mm  
    } 
    0≠≢mm← ⍺ Show ' '(≠⊆⊢)⍵: mm ⋄ ⊂'No macros defined' 
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
      ~sq dq cm∊⍨ ⊃⍵: Sig QCTErr ⍵ 
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

      (lb≠⊃⍵)∨(rb≠⊃⌽⍵): ⊂⍵⊣ Sig 'Parameter brackets [...] required for macro "',⍺,'"'    ⍝ No args!
      brPos←1   ⍝ We've seen a lb 
      ⊢txt← gaPP ⎕R{ C←∊∘⍵.PatternNum ⋄ m←⍵.Match
        C qt1I: m
        C qt2I: sq,sq,⍨ n/⍨ ~dq2⍷ n←n/⍨ 1+ sq= n←1↓ ¯1↓m
        C lbI:  m⊣ brPos+←1 
        C rbI:  m⊣ brErr Err⍨ 11/⍨ 1≥ brPos⊢← brPos-1 
        C scI:  cr m⊃⍨ brPos>1         ⍝ Splitting on "bare" semicolons
      }⊆1↓ ¯1↓ ⍵ 
  }
⍝:EndSection

⍝:Section Define Macros
     DefMac← { 
    ⍝ ⍺⍺=1, if macro of the form   mac[parms] or mac[].
    ⍝       If of the form  mac[ ], an error is signaled.
      hasParm← ⍺⍺   
      (eval magic parenFlag)(name val parmStr)← ⍺ ⍵ 
      parmV← ParmSplit parmStr 
      hasParm∧ 0= ≢parmV: Sig BadDefErr name 
    ~o.debug∧eval: {
      flat← 1↓ ∊cr, ⎕FMT eval CCodeEval val
      magic db.Set name flat parmV parenFlag
    }⍬         
      ⎕←'Debug: ', Where⍬
      ⎕←' >>> Evaluating "',val,'"'
      flat← 1↓ ∊cr, ⎕FMT eval CCodeEval val  
      ⎕←'==> ',flat
      magic db.Set name flat parmV parenFlag 
    }
⍝:EndSection

⍝:Section Conditional Stack (:mif, :elseIf, ..., :mend)
    condStk ← ⍬         
    condBegin condActive condSkip← 1 0 ¯1   
    CondEval← o.caller{ 
      0:: Sig CondErr ⍺ 
        b← ⍺⍺⍎'0≢⍥,', QCScan Parse ⍵
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
    pdPP← def2P def1P constP setP undefP showP inclP ifP ifdefP elifP elifdefP elseP endifP eofTokP onceP errP
          def2I def1I constI setI undefI showI inclI ifI ifdefI elifI elifdefI elseI endifI eofTokI onceI errI← ⍳≢pdPP
    ParseDirective← { isDirctv⊢← 0 ⋄ isDirctv,⊂ PD2 ⍵ } 
    PD2←  pdPP ⎕R { 
          Case← ∊⍨∘⍵.PatternNum  
          F← ⍵∘∆F 
          isDirctv⊢← 1   
          m← '⍝ ',(' '⍴⍨0⌈l-2), m0← ⍵.Match↓⍨ l←≢F 1 
      ⍝ Major errors signalled no matter what
        Case errI:  Sig DirErr 2↓m 
      ⍝ Hidden directive to manage :include file names...
        Case eofTokI: ''⊣ EofSeen⍬
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
        Case def1I:   CDoc m⊣ ('emp'∊⎕C F 2) (0DefMac) (F 3) (F 4) ⍬  
        Case def2I:   CDoc m⊣ ('emp'∊⎕C F 2) (1DefMac) (F 3) (F 5) (F 4)
      ⍝ mconst- alias for mdef-e  
        Case constI:  CDoc m⊣ 1 0 0 (0DefMac) (F 2) (F 3) ⍬ 
        Case setI:    CDoc m⊣ SetCallerVar/ F¨2 3
        Case showI:   m, ∊(⊂cr,'⍝ '), Dfns_disp ('m'∊F 2) db.ShowMacros F 3
        Case undefI:  CDoc m⊣ db.Del F 2 
        Case inclI:   CDoc ('⍝- '/⍨0=ok), m↓⍨ 2× ~ok← IncludeFile F 2
        Case onceI:   CDoc m⊣ onceStk,← ¯1↑fileStk 
    }⍠('ResultText' 'Simple')('EOL' 'CR') 
⍝:EndSection 

⍝:Section Parse User Code Potentially Containing Macros 
  ⍝ Skip quotes and comments
    ⍝ ParseMacros: Handle macros and "faux" catenation operator for obj names:
    ⍝    abc``123 => abc123 
    ParseMacros← skipQCP macroP ⎕R { 
        C← ⍵.PatternNum∘= ⋄ F← ⍵∘∆F 
      C 0: QCToken ⍵.Match 
    ⍝ C macroI...
        fnd (key val parmV pats)← db.Get⍨ F 1 
        argStr← F 2
      ~fnd: val, argStr 
        noP← 0=≢parmV ⋄ noA← 0=≢argStr   
      noP∧ noA: val, argStr  
      noP:  val, lb, rb,⍨ ParseMacros 1↓¯1↓ argStr 
        args← key ScanArgs argStr 
        pats← skipQCP ,⍥⊆ pats
        repl← '\0' ,⍥⊆ args↑⍨≢parmV
        pats ⎕R repl ⊣ val 
    }
    ParseCodeCatF← skipQCP catFauxP ⎕R {
      0= ⍵.PatternNum: ⍵.Match ⋄ ''
    }
    ⍝ ParseCodeQtF: Handle "faux" quote operator. (See qtFauxP definition)
    ParseCodeQtF← skipQCP qtFauxP ⎕R { 
      0=⍵.PatternNum: ⍵.Match 
      0=≢quotable← ⍵ ∆F 1: '' 
        ∊ QNTok¨ ' ' (≠⊆⊢) quotable 
    }
    Parse← { ParseCodeQtF ParseCodeCatF maxSubOpt Repeat ParseMacros⊢⍵}
    Repeat← { ⍺← 0 ⍵ ⋄ i orig← ⍺ 
      ⍵≡ txt← ⍵⍵ ⍵: txt 
      i< ⍺⍺: (i+1)orig ∇ txt 
          ⎕← 'Macros Warning: Runaway macro substitution stopped at',⍺⍺,'iterations on line ',⍕⊃⌽lineStk
          ⎕← '>>> Orig:   "',orig,'"'
          ⎕← '>>> Result: "',txt,'"'
          ⎕← '>>> Keeping original line!'
          orig
    }
  ⍝ CCodeEval: (If ⍺=1), Evaluate code or, on failure, signal an error!
  ⍝ ∘ Both ⍕ and ⍎ below are executed in the o.caller env, 
  ⍝   with ⎕PP and ⎕FR temporarily altered so constants have high precision.
    CCodeEval← o.caller{  
     ~⍺: ⍵  
        Rstr← ⍺⍺.{ (⎕PP ⎕FR)⊢← ⍺ ⋄ ⍵ }
        _saved⊢← ⍺⍺.{ s← ⎕PP ⎕FR ⋄ s⊣ (⎕PP ⎕FR)⊢← ⍵ } 34 1287 
         p← Parse ⍵   
     0:: Sig EvalErr ⍵⊣ _saved Rstr⍬ 
        _saved Rstr ⍺⍺.(⍕⍎)p 
    }
    _saved← 0 0
  ⍝ SetCallerVar: ⍺ SetCallerVar ⍵. 
  ⍝ Sets name ⍺ in caller namespace to the evaluated value ⍵.
    SetCallerVar← o.caller{ ⍺⍺⍎⍺,'←⍎⍵'}∘{1 CCodeEval ⍵ }
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
        (⊃⌽lineStk)+← ⍺               ⍝ Line number (in the style of cpp)...
        hasC line← ParseContinue ⍵ ⍝⍝⍝ EVALUATE THIS!!! sometimes 2=≡line
        __TEXT__⊢← line 
    ⍝ hasC: line is either a comment line or a blank line.
      hasC: line
        isD line← ParseDirective line
      isD: line 
      condActive≠ ⊃⌽condStk: CDoc '⍝-',line 
        out← Parse line               
      out≡line: Obj2Str line 
        ( Obj2Str out) AlignCm ' ⍝ <= ',line 
    }
⍝:EndSection

⍝:Section Executive 
    Executive←{
      ⍬{
        0≠≢fileBuf: ⍺ ∇ FlushFileBuf ⍵ 
        0=≢⍵: ⍺
          (⍺, ⊂ParseLine ⊃⍵) ∇ 1↓ ⍵ 
      } ⊆⍵
    }

    __COUNTER__← counterOrigin
    __TEXT__← ⊢0 
    _← db.SetMagic '__FILE__'     '(QTok ⊃⌽fileStk)'                  ⍬ 0
    _← db.SetMagic '__LINE__'     '(⊃⌽lineStk)'                      ⍬ 0 
    _← db.SetMagic '__COUNTER__'  '(__COUNTER__+← 1)⊢ __COUNTER__'   ⍬ 0 
    _← ⎕LC DebugMode o.debug 
  ⍝ Executive...
    lineV← CNullLines Executive ⍵ 
    o.simple: 1↓∊(⊂cr,⍨ o.debug/ '␍'),¨ lineV ⋄ lineV

⍝:EndSection 
}⍵
} 
