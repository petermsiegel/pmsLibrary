 Extern←{ 
⍝  Extern: 
⍝  [1] [opts] ∇ [fnNm@CV | codeStr@CVV]    
⍝    Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝    for all variables not explicitly external (non-local). Adds directives
⍝    :Extern and :Intern, as well as supporting local declarations (;nm1;nm2...) anywhere
⍝    in the program.
⍝  [2] ∇⍨'help'
⍝    See ⍝H (HELP) Info below...

    ⎕IO ⎕ML←0 1 
  0:: ⎕SIGNAL ⊂⎕DMX.( ('EN' EN) ('EM',⍥⊂'Extern: ',EM)('Message' 'Logic Error!'))
⍝ Define Variables
  ⍝ error messages 
    missingE← ⊂('EN' 11)('Message' 'Invalid or missing tradfn/op. Use option ''help'' for help')
  ⍝ localizable system names (https://course.dyalog.com/Quad%20names/)
    localizable←  '⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO'   '⎕LX'    '⎕ML'   '⎕PATH'  
    localizable,← '⎕PP'  '⎕PW' '⎕RL'  '⎕RTL' '⎕SM' '⎕TRAP' '⎕USING' '⎕WSID' '⎕WX'  
  ⍝ Regex patterns 
    extP←  '(?ix) ^ \h* (?:⍝ \h*)? :extern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Extern nm nm
    intP←  '(?ix) ^ \h* (?:⍝ \h*)? :intern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Intern nm nm
    locP←  '(?x)  ^ \h* ; \h* ([^⍝\n]*) (.*\n)'                    ⍝ ;nm;nm  (APL's "intern")
    simpNmP←  '[\p{L}_∆⍙][\p{L}\p{N}_∆⍙]*'                         ⍝ simple user name
    ⍝ Build up skipP, tradNmP, and (further below) withP 
        qtP_t←     '(''[^'']*'')+'   
        comP_t←    '⍝.*'
        xNmP_t←    '[\p{L}_∆⍙#⍺⍵⎕][\p{L}\p{N}_∆⍙#⍺⍵⎕]*'            ⍝ user/sys/special          
        longNmP_t← '(?:',xNmP_t,'(\h*\.\h*',xNmP_t,')*)'           ⍝ complex name; spaces around '.' ok             
        balParP_t← '\((?:[^()''\n]+|''[^'']*''|(?R))*+\)'          ⍝ balanced parens - single line
        dfnBdyP_t← '\{(?:[^{}'']+|''[^'']*''|(?R))*+\}'            ⍝ dfn body - multiline ok
    skipP← '(?x) ',qtP_t, '|', comP_t, '|', dfnBdyP_t, '| \.\h*', balParP_t
    tradNmP← ':', simpNmP, '|', longNmP_t                          ⍝ Directive or complex name
    hdrP←  '(?x) ([^;⍝]+) ( (?:;[^⍝]*)? ) ( (?:⍝.*)? )'
  ⍝ :WITH processing: withP (:With), dirP (:If, etc.), endP (:End and :Until) 
    withP← '(?xi) :With\b\s*(',longNmP_t,'?)'                      ⍝ See: inWith, dirDepth
    dirP←  '(?xi) :(?: If|While|Repeat|For|Select|Trap|Hold|Disposable)' ⍝ :With omitted
    endP←  '(?xi) :(?: End\w*|Until)'                              ⍝ :End (with any suffix) or :Until (matching :While or :Repeat)
⍝ Define Basic Utilities
    FirstNm←    ⊢↑⍨⍳∘'.'⍤,                                         ⍝ In 'aa.bb.cc', 'aa' could be local
    CanBeLocal← ∊∘localizable                                      ⍝ (Auto-hashed)
    SkipNm←     { ~'⎕#:'∊⍨ f← ⊃⍵: 0 ⋄  f∊ '⎕': ~CanBeLocal ⊂⍵ ⋄ 1 }
    Sort←       { ⍵[ ⍋⎕C⍣ foldCase ⊢⍵ ] }                          ⍝ Sys Vars to upper case...
    SplitNms←   { '⎕'∊⍨ ⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }¨ ' ;'∘((~∊⍨)⊆⊢)
    UWarnIf←    { 
        ~1∊ ⍵: ⍺ ⋄ l r← ⍺⍺⌽':Extern' ':Intern' 
        ⍺⊣ ⎕←'Warning: "',l,(∊' ',¨⍵/ ⍺),'" conflicts with prior ',r,' declaration'
    }
⍝ Define Major Functions
    FmtInt← {  
      intPL { ⊂'    ', ∊ ⍵,⍨¨ ⊂'; ' } { 0=≢⍵: ⍬ ⋄ ⍺<≢⍵: (⍺⍺ ⍺↑⍵), ⍺ ∇ ⍺↓⍵ ⋄ ⍺⍺ ⍵ } ⍵  
    } Sort
    UpdateExt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredInt~← declaredExt,← e (0 UWarnIf) e∊ declaredInt
      keepOrig/ '    ⍝ :Extern ', f1, f2
    }
    UpdateInt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredExt~← declaredInt,← e (1 UWarnIf) e∊ declaredExt
    ⍺:keepOrig/ '    ⍝ :Intern ', f1, f2
      keepOrig/ '    ⍝ ; ', f1, f2 
    }
    ValidateArgs← { 
      0::  ⎕SIGNAL missingE
        args nc← {
          1=≢⊆⍵: ((⎕NR ⍵ ) (⌽r↑⍨ '.'⍳⍨ r←⌽⍵)) (ns.⎕NC ⊂,⍵) ⊣ ns← ⊃⎕RSI  ⍝ ⍵ is a name
                 (⍵ myNm ) (ns.⎕NC ⊂,myNm←ns.⎕FX ⍵)        ⊣ ns← ⎕NS ⍬  ⍝ ⍵ is a fn/op body
        }⍵ 
      nc∊ 3.1 4.1: args ⋄ ∘∘err∘∘  
    }
⍝ Begin Executive...
⍝ ∘ Parse ⍺-Options---
    defIntPL← 10 
    ⍺←1 0 defIntPL
  ⍝ ∘ Help? (Extern⍨'help')
    'help'≡⍺: _← (⎕ED '_')⊢ _← '^ *⍝H ?(.*)' ⎕S ' \1'⊢⎕NR ⊃⎕XSI     ⍝ Display Help 
    0=≢⍵:     ⎕SIGNAL missingE
  ⍝ [0] → keepOrig:   1*  Pass thru original declarations of externals and internals as comments
  ⍝                   0   Omit original declarations
  ⍝ [1] → foldCase:   1   Sort order: {Fold Upper and lower case} > sys vars (⎕IO...)
  ⍝                   0*  Sort order: Upper case > Lower case > sys vars (⎕IO...)
  ⍝ [2] → intPL:      # of internals to print on each line. 
  ⍝                   defIntPL* by default or if ⍺[2]≤0
    keepOrig foldCase intPL← 3↑ ⍺
    keepOrig← keepOrig>0
    intPL←    intPL defIntPL⊃⍨ 0≥ intPL
⍝ ∘ Validate/Parse ⍵-Args---
    myTxt myNm← ValidateArgs ⍵
⍝ ∘ Parse Fn/Op Header---
  ⍝   hA: Arg names, hL: optl Local declarations, hC: optl Comment
      hA hL hC← 3↑ hdrP ⎕R '\1\n\2\n\3'⊣ ⊂⊃myTxt
    hdrNms← ' ←{}()' ((~∊⍨)⊆⊢) hA
    hL2← keepOrig/ ('  ⍝ '/⍨0≠ ≢hL), hL                          ⍝ Local vars on header line
    hdrOut← ⊂hA, hL2, hC                
⍝ ∘ Init Database of declared internal, external names, and names found in body of fn/op 
    declaredInt←   SplitNms 1↓ hL
    declaredExt←   ⍬
    foundNms←      ⍬
⍝ ∘ Init :With-related State Vars
    inWith← dirDepth← 0 
⍝ ∘ Prepare to Scan trad fn/op
    scanPats← extP intP locP skipP withP dirP endP tradNmP   
              extI intI locI skipI withI dirI endI tradNmI← ⍳≢scanPats
    ScanTradFn← scanPats ⎕R {   
        Case← ⍵.PatternNum∘∊ ⋄ F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
        Case extI:    UpdateExt F¨1 2                              ⍝ :EXTERN nm nm ...  [⍝ com]
        Case intI:  1 UpdateInt F¨1 2                              ⍝ :INTERN nm nm ...  [⍝ com]
        Case locI:  0 UpdateInt F¨1 2                              ⍝ ; nm; nm; ...      [⍝ com]
        Case  skipI:  F 0                                          ⍝ Skip comments, quotes, {...}, ns.(...)
      ⍝ (fn/op) names: variable names, including system ⎕names and :directives
      ⍝  ∘ Ignore (skip) names within :With statements
        Case tradNmI:  { inWith: ⍵ ⋄ SkipNm ⍵: ⍵ ⋄  ⊢foundNms,∘⊂← FirstNm ⍵ } F 0
      ⍝ Track directives only within the scope of :With
        Case dirI:   F 0⊣ dirDepth+← inWith 
      ⍝ :With name1[.name2...] ... :End[with]
      ⍝ ∘  Register <name1> as a body name, iff this is not a :With embedded in another :With
        Case withI:  F 0⊣  inWith∘← 1 ⊣ {inWith∨ 0=≢⍵: ⍬ ⋄ ⊢foundNms,∘⊂← FirstNm ⍵} F 1
      ⍝ Track ':END...' only if we're within the scope of 1 or more :WITH statements.
        Case endI:   F 0⊣  inWith∘← 0< dirDepth← 0⌈ dirDepth - inWith
        ∘∘∘ Unreachable ∘∘∘
    }⍠ ('UCP' 1)('Mode' 'M')('NEOL' 1)('EOL' 'LF')
⍝ ∘ Scan function sans header
    tail← ScanTradFn 1↓ myTxt
⍝ ∘ Prepare and return result
    declaredExt← ∪ declaredExt 
    totalInt←    ∪ declaredInt∪ foundNms~ declaredExt∪ hdrNms~ ⊂myNm 
  ¯1=⊃⍺: Sort¨ declaredExt totalInt                                ⍝ Return (externals internals)
    hdrOut, (FmtInt totalInt), tail

⍝H 
⍝H Extern
⍝H ¯¯¯¯¯¯ 
⍝H   Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝H   for all names not explicitly external (non-local). Adds directives
⍝H   :Extern and :Intern, as well as supporting local declarations (;nm1;nm2...) anywhere
⍝H   in the program.  
⍝H   ∘ Handles name.(other names etc.) and embedded dfns correctly.
⍝H   ∘ Does NOT check how names are USED. 
⍝H   ∘ Ignores variables that appear only within :WITH clauses.
⍝H
⍝H   res← opts ∇ [ nm | codeStr ]
⍝H
⍝H   nm | codeStr:
⍝H      nm: (char vector) simple or complex (qualified) name of tradfn/op
⍝H      codeStr: (vector of char vectors) lines of proper tradfn/op
⍝H   opts: result type, fold case, locals per line (see ⍝H comments below)
⍝H   res: (Based on result type)
⍝H      (vector of char vectors) lines of tradfn/op  OR 
⍝H      (pair of vectors of char vectors) list of externals, list of internals
⍝H 
⍝H   For help:  
⍝H      ∇⍨ 'help'        (OR  'help'∇ ⍬)
⍝H 
⍝H res← opts ∇ [ nm | codeStr ]
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
⍝H  Handles :WITH constructs, i.e. treating any name within the scope
⍝H     of a :WITH statement as defaulting to :EXTERN automatically (unless declared otherwise). 
⍝H   ∘ May require :EXTERN statements for class 9 variable names which are local
⍝H     to the function but not visible initialized...
⍝H  Warns if names are declared both as :EXTERN and :INTERN.
⍝H  Bugs: Does not notice ⎕SHADOW variables, but will assume names not declared as :Extern
⍝H        are internal by default.
 }
