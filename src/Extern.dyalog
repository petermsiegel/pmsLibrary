 Extern←{ 
⍝  Extern:
⍝    Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝    for all variables not explicitly external (non-local). Adds directives
⍝    :Extern and :Intern, as well as supporting local declarations (;nm1;nm2...) anywhere
⍝    in the program.

⍝    res← opts ∇ [ nm | codeStr ]
⍝         opts: [1 0 ¯1][1 0][int←10]
⍝         nm: simple or complex (qualified) name of tradfn/op
⍝         codeStr: vector of char vectors
⍝    res: Vector of char vectors OR pair of vectors of char vectors
⍝  
⍝   See ⍝H (HELP) Info below...
        
  0=≢⍵: ⊢⎕ED '_'⊣_←'^ *⍝H ?(.*)' ⎕S ' \1'⊢⎕NR ⎕←⊃⎕XSI              ⍝ Display Help 

    ⎕IO ⎕ML←0 1
  90:: ⎕SIGNAL ⊂⎕DMX.( ('EN' EN) ('EM' 'Extern: Logic Error!') ('Message' Message) )
  ∆ROpts← ('UCP' 1)('Mode' 'M')  ('NEOL' 1)('EOL' 'LF')
  ⍝ CanBeLocal: Matches localizable system names...
        _←  '⎕PATH' '⎕SM' '⎕TRAP' '⎕PP' '⎕FR' '⎕PW' '⎕USING' '⎕AVU' '⎕IO' '⎕RL'
        _,← '⎕WSID' '⎕LX' '⎕RTL' 'WX' '⎕DCT' '⎕CT' '⎕ML' '⎕DIV'    
    CanBeLocal← ∊∘_ 
  ⍝ Regex patterns 
    extP←  '(?ix) ^ \h* (?:⍝ \h*)? :extern\b \h* ([^⍝\n]*) (.*)'     ⍝ :Extern nm nm
    intP←  '(?ix) ^ \h* (?:⍝ \h*)? :intern\b \h* ([^⍝\n]*) (.*)'     ⍝ :Intern nm nm
    locP←  '(?ix) ^ \h* ; \h* ([^⍝\n]*) (.*)'                        ⍝ ;nm;nm  (APL's "intern")
    simpNmP←  '[\p{L}_∆⍙][\p{L}\p{N}_∆⍙]*'
  ⍝ Build up skipP and tokenP 
        qtP_t←   '(''[^'']*'')+' 
        comP_t←  '⍝.*'
        xNmP_t←      '[\p{L}_∆⍙#⍺⍵⎕][\p{L}\p{N}_∆⍙#⍺⍵⎕]*'                 
        longNmP_t←   xNmP_t,'(\h*\.\h*',xNmP_t,')*'                ⍝ aaa.bbb, but spaces around '.'
          _← '(?x) (?<P> \( ((?>  [^()''\n\r]+ | '                
        balParP_t← _, '(?: (?:''[^'']*'')+ | (?&P)* )+) ) \) )'    ⍝ balanced parens...
          _← '(?x) (?<B> \{ ((?>  [^{}'']+ | '                   
        dfnBdyP_t← _, '(?: (?:''[^'']*'')+ | (?&B)* )+) ) \} )'    ⍝ dfn body {...}
    skipP← qtP_t, '|', comP_t, '|', dfnBdyP_t, '|\.\h*', balParP_t
    tokenP← ':', simpNmP, '|', longNmP_t
    hdrP←  '(?x) ([^;⍝]+) ( (?:;[^⍝]*)? ) ( (?:⍝.*)? )'
  ⍝ Key Utilities
    FirstNm←  { ⍵↑⍨⍵⍳'.'},
    SkipNm← { f←⊃⍵ ⋄ ~f∊ '⎕#:': 0 ⋄  f∊ '⎕': ~CanBeLocal ⊂⍵ ⋄ 1 }
    Sort←   { ⍵[⍋⎕C⍣ foldCase ⊢⍵] } 
    FmtIntern← {  
      iNmsPerLn { ⊂'  ', ∊ ⍵,⍨¨ ⊂'; ' } {
        0=≢⍵: ⍬ ⋄ ⍺<≢⍵: (⍺⍺ ⍺↑⍵), ⍺ ∇ ⍺↓⍵ ⋄ ⍺⍺ ⍵
      } ⍵  
    } Sort
    Warn←{ ~⍺: ⍬ ⋄ ⍬⊣ ⎕←'Warning: ', ⍵}
    UpdateExt←{ f1 f2← ⍵ ⋄ e← '; '~⍨¨ ' '(≠⊆⊢) f1 
      _← (1∊ e∊ internNms) Warn '":EXTERN ',f1,'" overrides prior :INTERN declaration'
      internNms~← externNms,← e
      keepOrig/ '  ⍝ :Extern ', f1, f2
    }
    UpdateInt←{ ⍺←1 ⋄ f1 f2← ⍵ ⋄ e← '; '~⍨¨ ' '(≠⊆⊢) f1
        _← (1∊ e∊ externNms) Warn '":INTERN ',f1,'" overrides prior :EXTERN declaration'
        externNms~← internNms,← e
    ⍺:  keepOrig/ '  ⍝ :Intern ', f1, f2
        keepOrig/ '  ⍝ ; ', f1, f2 
    }

  ⍝ EXECUTIVE...
    ⍺←1 10
  ⍝ keepOrig:   Keep original declarations of externals and internals (locals)
  ⍝ iNmsPerLn:  # of internals to print on each line. (The default if ≤0 or omitted)
  ⍝ foldCase:   0 (sort UC before lc before ⎕SYS); else 1 (sort UC and lc together before ⎕SYS)
    defIPL←  10 
    returnType foldCase iNmsPerLn ← 3↑ ⍺
    keepOrig← returnType>0
    iNmsPerLn← iNmsPerLn 10 ⊃⍨ 0≥ iNmsPerLn

  ⍝ If ⍵ is a vec of (char) vecs, assume ⎕NR of tradfn/op; else assume it's a tradfn/op name
    ValidateArgs← {  
          lines← ⊆⍵ 
          1=≢lines: {
            nc← ⎕NC ⊂,⍵
           ¯1=  nc:         'Invalid object name'        ⎕SIGNAL 11
            0=  nc:         'Unknown object'             ⎕SIGNAL 11
            ~3.1 4.1∊⍨ nc:  'Object must be a tradfn/op' ⎕SIGNAL 11  
            (⎕NR ⍵) (⌽nm↑⍨'.'⍳⍨nm←⌽⍵)               ⍝ Tradfn, Tradop
          } ⍵
        ⍝ Returns the actual trad object name from the tradfn/op header, '' for dfn/op
          shortNm← ⊃{( ∪∊⊆⍨( 1⌷ key )[ (2⌷ key←⍉201⌶⍬)⍳ ⊂'MINI_FNAME' ]∊⍨∘∊200⌶ )'',⍨⍥⊂ ⊃⍵ } lines
          ¯1≠ ⎕NC shortNm: lines shortNm 
          'Object must represent a tradfn/op' ⎕SIGNAL 11  
    }
    fnBody me← ValidateArgs ⍵
 
  ⍝ Break header up into arg declarations, local declarations, comment
    hArg hLoc hCm← 3↑ hdrP ⎕R '\1\n\2\n\3'⊣ ⊂⊃fnBody
    hdrNms← simpNmP ⎕S '\0'⊣ hArg
    hdrOut← ⊂hArg,(' ⍝ '/⍨0≠≢hLoc), hLoc, hCm
    internNms←   ' '~⍨¨ ';' (≠⊆⊢) 1↓ hLoc 
    externNms←   ⍬
    explicitNms← ⍬
  
    patterns← extP intP locP skipP tokenP 
              extI intI locI skipI tokenI← ⍳≢patterns
    tail← patterns ⎕R {   
        Case← ⍵.PatternNum∘∊ 
        F←    ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
        m←    ⍵.Match
        Case extI:    UpdateExt F¨1 2                              ⍝ :EXTERN nm nm ...  [⍝ com]
        Case intI:    UpdateInt F¨1 2                              ⍝ :INTERN nm nm ...  [⍝ com]
        Case locI:  0 UpdateInt F¨1 2                              ⍝ ; nm; nm; ...      [⍝ com]
        Case  skipI:  m                                            ⍝ Skip comments, quotes, {...}, ns.(...)
      ⍝ Case tokenI:  ⍝ variable names (including system ⎕names and :directives)
      ⍝ Ignore :directives and system names that can't be localised...
        Case tokenI: {
          SkipNm ⍵:  ⍵         
          ⊢explicitNms,∘⊂← FirstNm ⍵ 
        } m 
        ∘∘∘ Unreachable ∘∘∘
    } ⍠∆ROpts⊣ 1↓ fnBody

    externNms←  ∪  externNms 
    internNms←  ∪( internNms ∪ explicitNms~ hdrNms~ ⊂me)  ⍝ ~externNms 
    internDecl← FmtIntern internNms
  ¯1=⊃⍺: Sort¨externNms internNms 
    hdrOut, internDecl, tail

⍝H 
⍝H Extern
⍝H ¯¯¯¯¯¯ 
⍝H Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝H for all variables not explicitly external (non-local). Adds directives
⍝H :Extern and :Intern, as well as supporting local declarations (;nm1;nm2...) anywhere
⍝H in the program.
⍝H 
⍝H res← opts ∇ [ nm | codeStr ]
⍝H 
⍝H      nm: Name of tradfn or tradop (may be a simple or a complex name:  
⍝H          simple: ThisFn,   complex:  #.myNs.MyFn, myNs.MyFn
⍝H      codeStr: lines of code of a tradfn or tradop
⍝H      opts: result type, fold case, locals per line
⍝H      opts[0]: What result is desired?
⍝H           1: Return the tradfn or tradop code with explicit locals (via ;nm1;nm2...)
⍝H              Show as comments:
⍝H              ∘ the original :Extern or :Intern directives 
⍝H              ∘ the original traditional local declarations (;nm1;nm2...)/ 
⍝H           0: Like opt[0]=1, but 
⍝H              ∘ remove original directives and declarations.
⍝H          ¯1: Simply list all the externals and internals as two character vectors of vectors, e.g.
⍝H              ┌─────────────┬───────────────────────────────────────────────────────────┐
⍝H              │┌───────┬───┐│┌─┬─┬─┬──────┬────┬────┬────┬──────┬──────┬─────┬───┬─────┐│
⍝H              ││Outside│⎕ML│││A│B│I│Inside│Tidy│Trad│glop│local3│local4│three│⎕IO│⎕TRAP││
⍝H              │└───────┴───┘│└─┴─┴─┴──────┴────┴────┴────┴──────┴──────┴─────┴───┴─────┘│
⍝H              └─────────────┴───────────────────────────────────────────────────────────┘
⍝H          Variables (for all 3 options) are sorted into order per opts[1] below. 
⍝H      opts[1]: fold case option (default 0)
⍝H              If 0 (default), sort variables in declaration in order:
⍝H                 Upper Case < Lower case < System Vars
⍝H              If 1, sort upper case and lower case vars together:
⍝H                 User Vars (fold case) < System Vars 
⍝H      opts[2]: How many locals per line in the resulting local declarations (;nm1;nm2).
⍝H              The default is 10 per line. Locals are sorted-- 
⍝H                 upper case names, lower case names, system names
⍝H              If opt[2] is ≤0, the default of 10 is assumed.
⍝H      res: 
⍝H        opt[0]∊1 0: the revised code of the presented tradfn or tradop, with:
⍝H        ∘ All simple variables without an :Extern assumed to be local. 
⍝H        ∘ Complex variables are assumed to be External
⍝H        ∘ Variables of the form name1.( name2 name3...) are treated as external,
⍝H          with names name2, etc. ignored.
⍝H        ∘ Dfn contents are ignored and do not impact localization.
⍝H  If <nm> or <codeStr> is not a tradfn or tradop, an error is signaled.
⍝H 
⍝H ----------------
⍝H  ○ Use 
⍝H      :Intern nm1 nm2 ... 
⍝H    to declare local variables.
⍝H    ∘ These are only needed for names not otherwise visible to the Extern function.
⍝H    ∘ Those that are visible will be declared as :Intern automatically.
⍝H  ○ Optionally, use smts of the form   
⍝H      ;nm1;nm2 
⍝H    anywhere in the program as a variant for :Intern statements.
⍝H  ○ Use 
⍝H      :Extern nm1 nm2 ... 
⍝H    to declare external (non-local) variables.
⍝H    ∘ This is needed to ensure an external (non-local)name (per above) is not 
⍝H      automatically localized.
⍝H
 }
