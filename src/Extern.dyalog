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

    ⎕IO ⎕ML←0 1 
  0=≢⍵: ⊢⎕ED '_'⊣_←'^ *⍝H ?(.*)' ⎕S ' \1'⊢⎕NR ⎕←⊃⎕XSI              ⍝ Display Help 
  90:: ⎕SIGNAL ⊂⎕DMX.( ('EN' EN) ('EM' 'Extern: Logic Error!') ('Message' Message) )
⍝ Define Variables
  ⍝ localizable system names (https://course.dyalog.com/Quad%20names/)
    localizable←  '⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO'   '⎕LX'    '⎕ML'   '⎕PATH'  
    localizable,← '⎕PP'  '⎕PW' '⎕RL'  '⎕RTL' '⎕SM' '⎕TRAP' '⎕USING' '⎕WSID' '⎕WX'  
  ⍝ Regex patterns 
    extP←  '(?ix) ^ \h* (?:⍝ \h*)? :extern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Extern nm nm
    intP←  '(?ix) ^ \h* (?:⍝ \h*)? :intern\b \h* ([^⍝\n]*) (.*\n)' ⍝ :Intern nm nm
    locP←  '(?x)  ^ \h* ; \h* ([^⍝\n]*) (.*\n)'                    ⍝ ;nm;nm  (APL's "intern")
    simpNmP←  '[\p{L}_∆⍙][\p{L}\p{N}_∆⍙]*'                         ⍝ simple user name
    ⍝ Build up skipP and tradNmP 
        qtP_t←     '(''[^'']*'')+'   
        comP_t←    '⍝.*'
        xNmP_t←    '[\p{L}_∆⍙#⍺⍵⎕][\p{L}\p{N}_∆⍙#⍺⍵⎕]*'            ⍝ user/sys/special          
        longNmP_t← '(?:',xNmP_t,'(\h*\.\h*',xNmP_t,')*)'           ⍝ complex name; spaces around '.' ok             
        balParP_t← '\((?:[^()''\n]+|''[^'']*''|(?R))*+\)'          ⍝ balanced parens - single line
        dfnBdyP_t← '\{(?:[^{}'']+|''[^'']*''|(?R))*+\}'            ⍝ dfn body - multiline ok
    skipP← '(?x) ',qtP_t, '|', comP_t, '|', dfnBdyP_t, '| \.\h*', balParP_t
    tradNmP← ':', simpNmP, '|', longNmP_t                           ⍝ Directive or complex name
    hdrP←  '(?x) ([^;⍝]+) ( (?:;[^⍝]*)? ) ( (?:⍝.*)? )'
  ⍝ :WITH processing 
  ⍝  ∘ Track...
  ⍝    :WITH, 
  ⍝    other directives with :END/:UNTIL stmts, and 
  ⍝    :ENDxxx/:UNTIL statements
  ⍝  ∘ For withP,  field 1 is the name in    :With  name[.name2...]  ⍝ Ref
  ⍝    but an empty string in                :With 'name[.name2...]' ⍝ Name string
    withP← '(?xi) :With\b\s*(',longNmP_t,'?)' ⋄ inWith← dirDepth← 0 
    dirP←  '(?xi) :(?|If|While|Repeat|For|Select|Trap|Hold|Disposable)' ⍝ :With omitted
    endP←  '(?xi) :(?:End\w*|Until)'                               ⍝ :End (with any suffix) or :Until (matching :While or :Repeat)
⍝ Define Basic Utilities
    FirstNm←    ⊢↑⍨⍳∘'.'⍤,                                         ⍝ In 'aa.bb.cc', 'aa' could be local
    CanBeLocal← ∊∘localizable                                      ⍝ (Auto-hashed)
    SkipNm←     { f←⊃⍵ ⋄ ~f∊ '⎕#:': 0 ⋄  f∊ '⎕': ~CanBeLocal ⊂⍵ ⋄ 1 }
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
      declaredInt~← declaredExt,← e (0 UWarnIf)  e∊ declaredInt
      keepOrig/ '    ⍝ :Extern ', f1, f2
    }
    UpdateInt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredExt~← declaredInt,← e (1 UWarnIf) e∊ declaredExt
    ⍺:keepOrig/ '    ⍝ :Intern ', f1, f2
      keepOrig/ '    ⍝ ; ', f1, f2 
    }
    ValidateArgs← {   
        ⍝ [A] ⍵ is name of tradfn/op
          myLns← ⊆⍵ 
          1=≢myLns: ( {0:: ¯1 ⋄ ⎕NC ⊂,⍵}⍵ ){       
            3.1 4.1∊⍨ ⍺: (⎕NR ⍵) (⌽nm↑⍨ '.'⍳⍨ nm←⌽⍵)               ⍝ Tradfn, Tradop
            err← 'Invalid object name' 'Unknown object' 'Object must be a tradfn/op' 
            11 ⎕SIGNAL⍨ err⊃⍨ ¯1 0⍳⍺
          } ⍵                                                      ⍝ ⍵: name of APL object
        ⍝ [B] ⍵ is ⎕NR of tradfn/op 
        ⍝ Returns the actual trad object name from the tradfn/op header, '' for dfn/op
        0:: 'Invalid object representation' ⎕SIGNAL 11
          myNm← ⊃{( ∪∊⊆⍨( 1⌷ key )[ (2⌷ key←⍉201⌶⍬)⍳ ⊂'MINI_FNAME' ]∊⍨∘∊200⌶ )'',⍨⍥⊂ ⊃⍵ } myLns
          ¯1≠ ⎕NC myNm: myLns myNm 
          'Invalid object representation' ⎕SIGNAL 11  
    }
⍝ Begin Executive...
⍝ ∘ Parse Options---
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
⍝ ∘ Validate/Parse Args---
    myTxt myNm← ValidateArgs ⍵
⍝ ∘ Parse Fn/Op Header---
  ⍝    hA: arg names, hL: optl local declarations, hC: optl comment
      hA hL hC← 3↑ hdrP ⎕R '\1\n\2\n\3'⊣ ⊂⊃myTxt
    hdrNms← ' ←{}()'((~∊⍨)⊆⊢) hA
  ¯1∊⎕NC hdrNms: 'Invalid names in fn/op header' ⎕SIGNAL 11
      hL2← keepOrig/ ('  ⍝ '/⍨0≠ ≢hL), hL                          ⍝ Local vars on header line
    hdrOut← ⊂hA, hL2, hC                
⍝ ∘ Declare Database---  of declared internal, external names, and names found in body of fn/op 
    declaredInt←   SplitNms 1↓ hL
    declaredExt←   ⍬
    foundNms←      ⍬
⍝ ∘ Prepare to Scan trad fn/op
    scanPats← extP intP locP skipP withP dirP tradNmP endP  
              extI intI locI skipI withI dirI tradNmI endI← ⍳≢scanPats
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
        Case endI:   F 0⊣  inWith∘← 0< dirDepth⊣ dirDepth-← inWith
        ∘∘∘ Unreachable ∘∘∘
    }⍠ ('UCP' 1)('Mode' 'M')('NEOL' 1)('EOL' 'LF')
⍝ ∘ Scan function sans header
    tail← ScanTradFn 1↓ myTxt
⍝ ∘ Prepare and return result
    declaredExt← ∪ declaredExt 
    totalInt← ∪ declaredInt∪ foundNms~ declaredExt∪ hdrNms~ ⊂myNm 
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
⍝H  EXPERIMENTAL: Handle :WITH constructs, i.e. treating any name within the scope
⍝H     of a :WITH statement as defaulting to :EXTERN automatically (unless declared otherwise). 
⍝H   ∘ May require :EXTERN statements for class 9 variable names which are local
⍝H     to the function but not visible initialized...
⍝H XNote: Extern is not aware of ":With" constructs; that is, names within the scope of
⍝H X   a ":With" will be incorrectly assumed to be local. This in general WON'T CAUSE
⍝H X   ANY ISSUES, because Dyalog will evaluate the associated "global" variables  
⍝H X   with respect to the explicit ":With" variable  and the extra local declarations 
⍝H X   will have no effect. 
⍝H X ∘ If you find this aesthetically displeasing, you can declare the affected variables 
⍝H X   as external.
⍝H X ∘ Local variables within the scope of the ":With" will automatically 
⍝H X   be localized as expected. (See Dyalog rules for the :With directive).
 }
