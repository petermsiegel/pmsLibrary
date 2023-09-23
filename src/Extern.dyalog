 Extern←{ 
⍝  Extern: 
⍝  [1] [opts] ∇ [fnNm@CV | codeStr@CVV]    
⍝    Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝    for all variables not explicitly external (non-local). Supports directives
⍝    [⍝]:Extern and [⍝]:Intern, as well as supporting local declarations (;nm1;nm2...) anywhere
⍝    in the program.
⍝  [2] ∇⍨'help'
⍝    See ⍝H (HELP) Info below...
    DEBUG ⎕IO ⎕ML←1 0 1 
  0/⍨ ~DEBUG:: ⎕SIGNAL ⊂⎕DMX.( ('EN' EN) ('EM',⍥⊂'Extern: ',EM)('Message' 'Logic Error!'))

⍝ Define Variables
  ⍝ error messages 
    missingE← ⊂('EN' 11)('Message' 'Invalid or missing tradfn/op. Use option ''help'' for help')
  ⍝ localizable system names (https://course.dyalog.com/Quad%20names/)
    localizable←  '⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO'   '⎕LX'    '⎕ML'   '⎕PATH'  
    localizable,← '⎕PP'  '⎕PW' '⎕RL'  '⎕RTL' '⎕SM' '⎕TRAP' '⎕USING' '⎕WSID' '⎕WX'
  ⍝ Characters to ignore (for sorting/grouping only) with ignoreWeird option (weirdSpecialO←1)
    weird← '∆⍙_'
  ⍝ Regex patterns 
    extP←  '(?ix) ^ \h* (?:⍝ \h*)? :extern\b \h* ([^⍝\n]*) (.*\n?)' ⍝ [⍝]:Extern nm nm
    intP←  '(?ix) ^ \h* (?:⍝ \h*)? :intern\b \h* ([^⍝\n]*) (.*\n?)' ⍝ [⍝]:Intern nm nm
    locP←  '(?x)  ^ \h* ; \h* ([^⍝\n]*) (.*\n)'                    ⍝    ;nm;nm  (APL's "intern")
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
    CanBeLocal← ∊∘localizable                                      ⍝ (Auto-hashed)
    FirstNm←    ⊢↑⍨⍳∘'.'⍤,                                         ⍝ In 'aa.bb.cc', 'aa' could be local
    Help←       { (⎕ED '_')⊢ _← '^ *⍝H ?(.*)' ⎕S ' \1'⊢⎕NR ⊃⎕XSI }   
    SkipNm←     { ~'⎕#:'∊⍨ f← ⊃⍵: 0 ⋄  f∊ '⎕': ~CanBeLocal ⊂⍵ ⋄ 1 }
  ⍝ When ignoring weird chars, we append at end AFTER a space so A comes before _A etc.
  ⍝ See weirdSpecialO below
    OrderWeird← { ~weirdSpecialO: ⍵ ⋄ ~1∊weird∊⍵: ⍵ ⋄ (⍵~ weird),' ', ⍵ }¨ 
    Sort←       { ⍵[ ⍋⎕C⍣ foldCaseO ⊢ OrderWeird ⍵ ] }                           
    SplitNms←   { '⎕'∊⍨ ⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }¨ ' ;'∘((~∊⍨)⊆⊢)
    UWarnIf←    { 
        ~1∊ ⍵: ⍺ ⋄ l r← ⍺⍺⌽':Extern' ':Intern' 
        ⍺⊣ ⎕←'Warning: "',l,(∊' ',¨⍵/ ⍺),'" conflicts with prior ',r,' declaration'
    }

⍝ Define Major Functions
⍝   FmtInt    - Grab as many local names as possible that fit in the (column) width specified
⍝   UpdateExt - Add name to external list, verifying it's not an explicit internal
⍝   UpdateInt - Add name to internal list, ditto
⍝   ParseOpts - Parse ⍺ and return options (...O)
⍝   ParseArgs - Parse ⍵ and return list of lines AND nameclass.
⍝   ParseFnHdr- Parse fn header, returning fn header names, local vars in header, comments
⍝   ScanTradFn- (The workhorse:) Parse user fn/op, looking for :EXTERN, :INTERN, etc.
    FmtInt← ⊃,/⍤{
        pfx sep← '    ' '; ' 
        GrabLns← (0⌈ widthO- ≢pfx)∘{ 
          Grab1←⍺∘{ 1≥ ≢⍵: ⍵ ⋄  ⍺> +/≢¨⍵: ⍵ ⋄ ⍺ ∇ ¯1↓⍵ } 
          ⍬ { 0=≢⍵:⍺ ⋄ (⍺, ⊂pfx, ∊ln) ∇ ⍵↓⍨ ≢ln← Grab1 ⍵ } sep,¨⍥⊆⍵
        }¨
      ⍝ Organize into (lower_and_other, upper_case, system_case) based on initial letter 
      ⍝ (by default ignoring initial ∆, ⍙, _)
        cases← (⎕A,⎕Á) '⎕' 
        ForCases← {   
          foldCaseO:   ⊂⍵ ⋄ (⊂⍵)/⍨¨ (u⍱s),⍥⊆ u s← cases∊¨⍨ ⊂⊃¨OrderWeird ⍵ 
        } 
        GrabLns ForCases Sort ⍵
    } 
    UpdateExt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredInt~← declaredExt,← e (0 UWarnIf) e∊ declaredInt
      (keepOrigO≥1)/ '    ⍝ :Extern ', f1, f2
    }
    UpdateInt←{ f1 f2← ⍵ ⋄ e← SplitNms  f1
      declaredExt~← declaredInt,← e (1 UWarnIf) e∊ declaredExt
    ⍺:(keepOrigO≥1)/ '    ⍝ :Intern ', f1, f2
      (keepOrigO≥2)/ '    ⍝ ; ', f1, f2 
    }
⍝          ┌──────────────┬──────────┬───────────────────┬──────────────────────────────────┐
⍝    opts: │  keepOrigO   │foldCaseO │   weirdSpecialO    │              widthO              │
⍝          │ result type  │fold case │ignore weird chars │ max width of locals declaration  │
⍝          │              │          │  (when sorting)   │                                  │
⍝          │ 2*, 1, 0, ¯1 │  1, 0*   │      1*, 0        │       ≢(longest line)**          │
⍝          └──────────────┴──────────┴───────────────────┴──────────────────────────────────┘
⍝             *=default                                  **=default or if 0
    ParseOpts←{
      def← 2 0 1 0 ⋄ defWid← ⍺         
      (t/opts)← def/⍨ t←⎕NULL= opts← 1↓5↑⎕NULL, ⍵                ⍝ For omitted options, use defaults def
      opts[ wI/⍨ 0≥ opts[ wI ] ]← defWid ⊣ wI← 3                 ⍝ If width≤0, default to defWid
      opts
    }
    ParseArgs← { 
      0=≢⍵: ⎕SIGNAL missingE ⋄ 0::   ⎕SIGNAL missingE
        args nc← {
          1=≢⊆⍵: ((⎕NR ⍵ ) (⌽r↑⍨ '.'⍳⍨ r←⌽⍵)) (ns.⎕NC ⊂,⍵) ⊣ ns← ⊃⎕RSI  ⍝ ⍵ is a name
                 (⍵ myNm ) (ns.⎕NC ⊂,myNm←ns.⎕FX ⍵)        ⊣ ns← ⎕NS ⍬  ⍝ ⍵ is a fn/op body
        }⍵ 
      nc∊ 3.1 4.1: args ⋄ ∘∘err∘∘  
    }
    ParseFnHdr←{ kpOrigLoc pgm← ⍺ ⍵ ⋄ splitAny← (~∊⍨)⊆⊢
      ⍝ hA: Arg names, hLoc: optl Local declarations, hC: optl Comment
      ⍝     Maximal Pattern:  {r}← {a} (l Opt r) w ; l1; l2 ⍝ comment
      hA hLoc hC← 3↑ hdrP ⎕R '\1\n\2\n\3'⊣ ⊂⊃ pgm
      hNms← ' ←{}()' splitAny hA
      hL2← (kpOrigLoc≥2)/ ('  ⍝ '/⍨0≠ ≢hLoc), hLoc           ⍝ Local vars on header line
      hOut← ⊂hA, hL2, hC       
      hOut hNms hLoc
    }
    scanPats← extP intP locP skipP withP dirP endP tradNmP   
              extI intI locI skipI withI dirI endI tradNmI← ⍳≢scanPats
    ScanTradFn← scanPats ⎕R {   
        Case← ⍵.PatternNum∘∊ ⋄ F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
        Case extI:    UpdateExt F¨1 2                            ⍝ :EXTERN nm nm ...  [⍝ com]
        Case intI:  1 UpdateInt F¨1 2                            ⍝ :INTERN nm nm ...  [⍝ com]
        Case locI:  0 UpdateInt F¨1 2                            ⍝ ; nm; nm; ...      [⍝ com]
        Case  skipI:  F 0                                        ⍝ Skip comments, quotes, {...}, ns.(...)
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

⍝ ===============================================================================
⍝ ===============================================================================
⍝ Begin Executive...
⍝ ∘ Help? (Extern⍨'help')
  'help'≡⍥⎕C⍵: _← Help⍬
⍝ ∘ Parse and Validate ⍵-Args---
    myTxt myNm← ParseArgs ⍵
⍝ ∘ Parse ⍺-Options, passing length of longest line to ParseOpts 
    ⍺← ⍬  
    keepOrigO foldCaseO weirdSpecialO widthO ← (⌈/≢¨myTxt) ParseOpts ⍺  
⍝ ∘ Parse Fn/Op Header---
    hdrOut hdrNms hLoc← keepOrigO ParseFnHdr myTxt         
⍝ ∘ Init Database of declared internal, external names, and names found in body of fn/op 
    declaredInt←   SplitNms 1↓ hLoc
    declaredExt←   ⍬
    foundNms←      ⍬
⍝ ∘ Init :With-related State Vars
    inWith← dirDepth← 0 
⍝ ∘ Scan function sans header
    tail← ScanTradFn 1↓ myTxt
⍝ ∘ Prepare and return result
    declaredExt← ∪ declaredExt 
    totalInt←    ∪ declaredInt∪ foundNms~ declaredExt∪ hdrNms~ ⊂myNm 
  ¯1=⊃⍺: Sort¨ declaredExt totalInt                              ⍝ Return (externals internals)
    hdrOut, (FmtInt totalInt), tail

⍝H 
⍝H          ┌─────────────────────────────────┐
⍝H Extern:  │ result← opts ∇ [ nm | codeStr ] │
⍝H          └─────────────────────────────────┘
⍝H
⍝H OVERVIEW
⍝H ¯¯¯¯¯¯¯¯
⍝H   Scans a tradfn/tradopt to generate local variable declarations (;nm1;nm2...)
⍝H   for all names not explicitly external (non-local), based on an :Extern directive. 
⍝H   Supports new (pseudo-)directives :Extern and :Intern within comments or 
⍝H   at the start of a line.
⍝H   :∘ Extern statements declare variables that are not internal (local):
⍝H      :Extern myExtern1 MyExternFn ⎕PW   OR    ⍝ :Extern myExtern1 MyExternFn ⎕PW
⍝H   ∘ Normally, all other variables will be considered local, but you may explicitly
⍝H     declare variables as local via the :Intern statement:
⍝H      :Intern internal1; ⎕IO            OR     ⍝ :Intern internal1; ⎕IO
⍝H   ∘ As a legacy "style," we allow internal statements in an APL local variable
⍝H     format (beginning a line ANYWHERE in the code outside a comment):
⍝H      ; internal1; ⎕IO       
⍝H   ∘ An :INTERN (or ;...) declaration would be required for items declared within
⍝H     called functions, local or external dfns, or within quotes:
⍝H      :Intern myNs              :Intern count
⍝H      'myNs' ⎕NS ...            {count∘← ⍵}10  ⍝ Contrived but legal example
⍝H
⍝H DETAILS
⍝H ¯¯¯¯¯¯¯
⍝H   ∘ By default, all top-level names will automatically be made local to a
⍝H     presented tradfn/op. A top-level name is defined simply as:
⍝H         ∘ the first simple name within a complex name ('like' in like.this.one)
⍝H         ∘ an unquoted argument to :With, e.g. :With local_name
⍝H         ∘ a name outside an included dfn and outside the scope of a :With statement.
⍝H         ∘ a declared local via a legacy APL statment: ; like; this; one
⍝H   ∘ "Local" declarations (like the ones above) are equivalent to :Intern, and kept
⍝H   only for compatibility/legacy reasons.
⍝H     * Extern handles these constructions properly, with the variables
⍝H          myNs, name, myNs2 
⍝H       all automatically internal!
⍝H
⍝H       ⍝ Assumes myNs created earlier, e.g. via myNs←⎕NS⍬ or 'myNs' ⎕NS⍬
⍝H         myNs.(alpha beta gamma)← *1 2 3 
⍝H         name← { all sorts of invisible names }
⍝H
⍝H       ⍝ :With...
⍝H       ⍝ Assumes myNs2 created earlier, e.g. via myNs2←⎕NS⍬ or 'myNs2' ⎕NS⍬
⍝H         :With myNs2               ⍝ automatically :INTERN (local)
⍝H             ignore_me←1           ⍝ treated as myNs2.ignore_me and ignored.
⍝H         :EndWith 
⍝H 
⍝H       ⍝ Equivalent to :With statement above!
⍝H         myNs2.ignore_me←1. 
⍝H
⍝H     * Does NOT check for whether a name is set before use to determine locality
⍝H       (unlike dfns, which are "smarter").
⍝H
⍝H SYNTAX
⍝H ¯¯¯¯¯¯
⍝H ┌─────────────────────────────────┐
⍝H │ result← opts ∇ [ nm | codeStr ] │
⍝H └─────────────────────────────────┘
⍝H
⍝H   nm | codeStr:
⍝H      nm: (char vector) simple or complex (qualified) name of tradfn/op (traditional only).
⍝H      codeStr: (vector of char vectors) lines of proper tradfn/op (ditto).
⍝H         ┌─────────────┬──────────┬───────────────────┬──────────────────────────────────┐
⍝H   opts: │ result type │fold case │ignore weird chars │ max width of locals declaration  │
⍝H         │             │          │  (when sorting)   │                                  │
⍝H         │ 2*, 1 0, ¯1 │  1, 0*   │      1*, 0        │       ≢(longest line)**          │
⍝H         └─────────────┴──────────┴───────────────────┴──────────────────────────────────┘
⍝H            *=default                                         **=default or if 0
⍝H ----------------------------------------------------------------------------
⍝H 
⍝H   ⍺ is 'help'
⍝H   ¯¯¯¯¯¯¯¯¯¯¯
⍝H   If ⍺≡'help' (actually ⍺≡⍥⎕C'help', i.e. with case ignored)
⍝H      ∇⍨ 'help'  OR  'help'∇ ⍬
⍝H   displays this basic "help" information. ⍵ is ignored in this case.
⍝H 
⍝H   Options for ⍺
⍝H   ¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H            ┌───────────┬─────────┬───────────────────┬─────────────────────────────────┐
⍝H      opts: │result type│fold case│ignore weird chars │ max width of locals declaration │
⍝H            └───────────┴─────────┴───────────────────┴─────────────────────────────────┘
⍝H      opts[0]: What result is desired?
⍝H           2, 1, 0: Return the tradfn or tradop code...
⍝H             2: (Default) Show as comments
⍝H                 ∘ both the original :Extern and :Intern directives; and
⍝H                 ∘ the original traditional (legacy) local declarations (;nm1;nm2...)/ 
⍝H             1: Show as comments: 
⍝H                 ∘ both the original :Extern and :Intern directives; however, 
⍝H                Remove (don't show): 
⍝H                 ∘ the original traditional (legacy) local declarations.
⍝H             0: Remove (don't show): 
⍝H                ∘ both the original :Extern and :Intern directives; however, 
⍝H                ∘ the original traditional (legacy) local declarations.
⍝H          ¯1: Simply list all the externals and internals as two character vectors of vectors, e.g.
⍝H              ┌─────────────┬───────────────────────────────────────────────────────────┐
⍝H              │┌───────┬───┐│┌─┬─┬─┬──────┬────┬────┬────┬──────┬──────┬─────┬───┬─────┐│
⍝H              ││Outside│⎕ML│││A│B│I│Inside│Tidy│Trad│glop│local3│local4│three│⎕IO│⎕TRAP││
⍝H              │└───────┴───┘│└─┴─┴─┴──────┴────┴────┴────┴──────┴──────┴─────┴───┴─────┘│
⍝H              └─────────────┴───────────────────────────────────────────────────────────┘
⍝H              Externals and internals are each sorted in unicode (⍋⍵) order.
⍝H      opts[1]: fold upper and lower case in output (legacy) locals declarations...
⍝H            ∘ If 0 (default), sort and display variables in order:
⍝H                 Lower case locals (internals), e.g. dog, ⍙dog, etc.
⍝H                 Upper Case locals (internals), e.g. Cat, ∆Cat, etc.
⍝H                 System Var locals (internals), i.e. starting with ⎕ (⎕IO, etc.)
⍝H              e.g.
⍝H                 ; aI; aTEST; base; cntV; f; ix; lt0         ⍝ lc
⍝H                 ; mapV; outV; place; _test                  ⍝ opt[3]=1: _test sorted as 'test'
⍝H                 ; ∆ALPHA; _ALPHA; ⍙ALPHA; ALPHA             ⍝ uc        ∆ALPHA sorted as 'ALPHA'
⍝H                 ; ATEST; ⍙B; _C; ∆D; MONKEY; _TEST
⍝H                 ; ⎕IO; ⎕ML                                  ⍝ sys names
⍝H            ∘ If 1, sort everything in as single list (with case ignored):
⍝H              e.g.
⍝H                 ; aI; ∆ALPHA; _ALPHA; ⍙ALPHA; ALPHA         ⍝ a's and A's together
⍝H                 ; aTEST; ATEST; ⍙B; base; _C; cntV
⍝H                 ; ∆D; f; ix; lt0; mapV; MONKEY
⍝H                 ; outV; place; _TEST; _test; ⎕IO            ⍝ sys names (⎕...) at end
⍝H                 ; ⎕ML
⍝H      opts[2]: Ignore "weird" chars "∆⍙_" in output (legacy) local "declarations"... 
⍝H            ∘ If 1 (default), sorts/classifies names containing with ∆, ⍙ or _ 
⍝H              as if these special characters were ignored (actually, as in a 2ndary sort field). 
⍝H              * For an example, see opts[1] above. 
⍝H                 ∘ '∆Cats_dogs' is actually sorted as if 'Catsdogs ∆Cats_dogs'
⍝H                 ∘ 'Cats∆_dogs' is actually sorted as if 'Catsdogs Cats∆_dogs'
⍝H            ∘ If 0, we sort/classify ∆, ⍙, and _ as lower-case letters and
⍝H              sort them in their natural order.
⍝H              e.g.
⍝H                 ; _ALPHA; _C; _TEST; _test; aI
⍝H                 ; ALPHA; aTEST; ATEST; base; cntV
⍝H                 ; f; ix; lt0; mapV; MONKEY; outV
⍝H                 ; place; ∆ALPHA; ∆D; ⍙ALPHA; ⍙B
⍝H                 ; ⎕IO; ⎕ML
⍝H      opts[3]: Max width of each resulting local declarations line (;nm1;nm2).
⍝H              The default (if omitted or specified as 0) is:
⍝H                  the width of the longest line in the fn/op passed.
⍝H              Generated local names are by default output this way:  
⍝H                  lower case names + newline + upper case names + newline + system names
⍝H              If opt[3] is ≤0, the default is assumed.
⍝H  
⍝H   result
⍝H   ¯¯¯¯¯¯
⍝H     If opt[0]∊2 1 0: result is the revised code of the presented tradfn or tradop, 
⍝H     with:
⍝H        ∘ All simple variables without an :Extern assumed to be local. 
⍝H        ∘ Complex variables assumed to be External
⍝H        ∘ Variables of the form name1.[name2...]( name2 name3...) treated as External,
⍝H          with names name2, etc. ignored. Name name1 will be Internal by default.
⍝H        ∘ Dfn contents are ignored completely and do not impact localization.
⍝H     If the input <nm> or <codeStr> is not a tradfn or tradop, an error is signaled.
⍝H 
⍝H   Within your local fn/op
⍝H   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H   ○ Use 
⍝H       [⍝ ]:Intern nm1 nm2 ... 
⍝H     to declare local variables.
⍝H     ∘ These are only needed for names not otherwise visible to the Extern function.
⍝H     ∘ Those that are visible will be declared as :Intern automatically.
⍝H    ○ Optionally, use stmts of the form   
⍝H       ;nm1;nm2 
⍝H      anywhere in the program (not preceded by a comment lamp '⍝') 
⍝H      as a variant for :Intern statements.
⍝H    ○ Use 
⍝H       [⍝ ]:Extern nm1 nm2 ... 
⍝H       to declare external (non-local) variables.
⍝H     ∘ This is needed to ensure an external (non-local)name (per above) is not 
⍝H       automatically localized.
⍝H    Handles :WITH constructs, i.e. ignoring (not localizing) any name within the scope
⍝H     of a :WITH statement.  
⍝H    ∘ May require :EXTERN statements for class 9 variable names which are local
⍝H      to the function but not visibly initialized...
⍝H
⍝H    Warns if names are declared as both :EXTERN and :INTERN.
⍝H   
⍝H    Bugs: Does not notice ⎕SHADOW variables, but will assume names not declared as :Extern
⍝H    are internal by default.
⍝H        ⎕SHADOW 'myNs' 'localPW'      ⍝ Redundant. myNs and localPW are local by default.
⍝H        myNs← ⎕NS⍬ ⋄ localPW← ⎕PW 
 }
