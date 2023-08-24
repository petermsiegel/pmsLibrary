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
  ⍝ localizable system names (https://course.dyalog.com/Quad%20names/)
    localizable←  '⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO'   '⎕LX'    '⎕ML'   '⎕PATH'  
    localizable,← '⎕PP'  '⎕PW' '⎕RL'  '⎕RTL' '⎕SM' '⎕TRAP' '⎕USING' '⎕WSID' '⎕WX'  
  ⍝ Regex patterns 
    extP←  '(?ix) ^ \h* (?:⍝ \h*)? :extern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Extern nm nm
    intP←  '(?ix) ^ \h* (?:⍝ \h*)? :intern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Intern nm nm
    locP←  '(?x)  ^ \h* ; \h* ([^⍝\n]*) (.*\n)'                    ⍝ ;nm;nm  (APL's "intern")
    simpNmP←  '[\p{L}_∆⍙][\p{L}\p{N}_∆⍙]*'                         ⍝ simple user name
    ⍝ Build up skipP and bodyNmP 
        qtP_t←     '(''[^'']*'')+'   
        comP_t←    '⍝.*'
        xNmP_t←    '[\p{L}_∆⍙#⍺⍵⎕][\p{L}\p{N}_∆⍙#⍺⍵⎕]*'            ⍝ user/sys/special          
        longNmP_t← xNmP_t,'(\h*\.\h*',xNmP_t,')*'                  ⍝ complex name; spaces around '.' ok             
        balParP_t← '\((?:[^()''\n]+|''[^'']*''|(?R))*+\)'          ⍝ balanced parens - single line
        dfnBdyP_t← '\{(?:[^{}'']+|''[^'']*''|(?R))*+\}'            ⍝ dfn body - multiline ok
    skipP← '(?x) ',qtP_t, '|', comP_t, '|', dfnBdyP_t, '| \.\h*', balParP_t
    bodyNmP← ':', simpNmP, '|', longNmP_t                           ⍝ Directive or complex name
    hdrP←  '(?x) ([^;⍝]+) ( (?:;[^⍝]*)? ) ( (?:⍝.*)? )'
  ⍝ Basic Utilities
    FirstNm←    { ⍵↑⍨⍵⍳'.' },                                      ⍝ a.b.c? a could be local
    CanBeLocal← ∊∘localizable                                      ⍝ Auto-hashed
    SkipNm←     { f←⊃⍵ ⋄ ~f∊ '⎕#:': 0 ⋄  f∊ '⎕': ~CanBeLocal ⊂⍵ ⋄ 1 }
    Sort←       { ⍵[ ⍋⎕C⍣ foldCase ⊢⍵ ] }                          ⍝ Sys Vars to upper case...
    SplitNms←   { '⎕'∊⍨ ⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }¨ ' ;'∘((~∊⍨)⊆⊢)
    UWarnIf←    { 
        ~1∊ ⍵: ⍺ ⋄ l r← ⍺⍺⌽':Extern' ':Intern' 
        ⍺⊣ ⎕←'Warning: "',l,(∊' ',¨⍵/ ⍺),'" conflicts with prior ',r,' declaration'
    }
 ⍝ Major Functions
    FmtInt← {  
      intPL { ⊂'    ', ∊ ⍵,⍨¨ ⊂'; ' } { 0=≢⍵: ⍬ ⋄ ⍺<≢⍵: (⍺⍺ ⍺↑⍵), ⍺ ∇ ⍺↓⍵ ⋄ ⍺⍺ ⍵ } ⍵  
    } Sort
    UpdateExt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredInt~← declaredExt,← e (0 UWarnIf)  e∊ declaredInt
      keepOrig/ '    ⍝ :Extern ', f1, f2
    }
    UpdateInt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredExt~← declaredInt,← e (1 UWarnIf) e∊ declaredExt
    ⍺:keepOrig/ '    ⍝ :Intern ', f1, f2
      keepOrig/ '    ⍝ ; ', f1, f2 
    }
  ⍝ If ⍵ is a vec of (char) vecs, it's an ⎕NR of tradfn/op; else a tradfn/op name
    ValidateArgs← {  
          lines← ⊆⍵ 
          1=≢lines: ( {0:: ¯1 ⋄ ⎕NC ⊂,⍵}⍵ ){       
            3.1 4.1∊⍨ ⍺: (⎕NR ⍵) (⌽nm↑⍨ '.'⍳⍨ nm←⌽⍵)               ⍝ Tradfn, Tradop
            err← 'Invalid object name' 'Unknown object' 'Object must be a tradfn/op' 
            11 ⎕SIGNAL⍨ err⊃⍨ ¯1 0⍳⍺
          } ⍵                                                      ⍝ ⍵: name of APL object
        ⍝                                                          ⍝ ⍵: ⎕NR of tradfn/op 
        ⍝ Returns the actual trad object name from the tradfn/op header, '' for dfn/op
        0:: 'Invalid object representation' ⎕SIGNAL 11
          shortNm← ⊃{( ∪∊⊆⍨( 1⌷ key )[ (2⌷ key←⍉201⌶⍬)⍳ ⊂'MINI_FNAME' ]∊⍨∘∊200⌶ )'',⍨⍥⊂ ⊃⍵ } lines
          ¯1≠ ⎕NC shortNm: lines shortNm 
          'Invalid object representation' ⎕SIGNAL 11  
    }
 
⍝ EXECUTIVE...
  ⍝ Options---
    defIntPL← 10 
    ⍺←1 0 defIntPL
  ⍝ [0] → keepOrig:   1*  Pass thru original declarations of externals and internals as comments
  ⍝                   0   Omit original declarations
  ⍝ [1] → foldCase:   1   Sort order: {Fold Upper and lower case} > sys vars (⎕IO...)
  ⍝                   0*  Sort order: Upper case > Lower case > sys vars (⎕IO...)
  ⍝ [2] → intPL:      # of internals to print on each line. 
  ⍝                   defIntPL* by default or if ⍺[2]≤0
    keepOrig foldCase intPL ← 3↑ ⍺
    keepOrig← keepOrig>0
    intPL←    intPL defIntPL ⊃⍨ 0≥ intPL
  ⍝ Args---
    fnBody fnNm← ValidateArgs ⍵
  ⍝ Fn/Op Header---
  ⍝    hA: arg names, hL: optl local declarations, hC: optl comment
        hA hL hC← 3↑ hdrP ⎕R '\1\n\2\n\3'⊣ ⊂⊃fnBody
        hdrNms← ' ←{}'((~∊⍨)⊆⊢) hA
      ¯1∊⎕NC hdrNms: 'Invalid names in fn/op header' ⎕SIGNAL 11
        hL2← keepOrig/ ('  ⍝ '/⍨0≠ ≢hL), hL                        ⍝ Local vars on header line
    hdrOut← ⊂hA, hL2, hC                

  ⍝ Database---  of declared internal, external names, and names in body of fn/op 
    declaredInt←   SplitNms 1↓ hL
    declaredExt←   ⍬
    bodyNms←       ⍬
  ⍝ Scan fn body
    scanPats← extP intP locP skipP bodyNmP 
              extI intI locI skipI bodyNmI← ⍳≢scanPats
    ScanTradFn← scanPats ⎕R {   
        Case← ⍵.PatternNum∘∊ ⋄ F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
        Case extI:    UpdateExt F¨1 2                              ⍝ :EXTERN nm nm ...  [⍝ com]
        Case intI:  1 UpdateInt F¨1 2                              ⍝ :INTERN nm nm ...  [⍝ com]
        Case locI:  0 UpdateInt F¨1 2                              ⍝ ; nm; nm; ...      [⍝ com]
        Case  skipI:  F 0                                          ⍝ Skip comments, quotes, {...}, ns.(...)
      ⍝ (fn/op) boy names: variable names, including system ⎕names and :directives
        Case bodyNmI:  { SkipNm ⍵: ⍵ ⋄ ⊢bodyNms,∘⊂← FirstNm ⍵ } F 0
        ∘∘∘ Unreachable ∘∘∘
    } ⍠∆ROpts
    tail← ScanTradFn 1↓ fnBody
  ⍝ Result---
    declaredExt← ∪ declaredExt 
    totalInt← ∪ declaredInt∪ bodyNms~  declaredExt∪ hdrNms~ ⊂fnNm 
  ¯1=⊃⍺: Sort¨ declaredExt totalInt                                ⍝ Return (externals internals)
    hdrOut, (FmtInt totalInt), tail

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
