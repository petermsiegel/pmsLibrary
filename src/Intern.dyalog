 Intern←{ 
⍝  Intern: 
⍝  [1] [opts] ∇ [fnNm@CV | codeStr@CVV]    
⍝    Scan tradfns and tradopts and generate local variable declarations (;nm1;nm2...)
⍝    for all variables not explicitly external (non-local). Supports directives
⍝       [⍝]:EXTERN - declaring external (non-local) names
⍝       [⍝]:INTERN - declaring internal (local) names,
⍝    as well as supporting legacy local declarations
⍝       ; nm1; nm2...
⍝    which may appear anywhere in the program.
⍝    For options <opts> see HELP below.
⍝  [2] ∇⍨'help'
⍝    Displays HELP info
⍝ HELP: See ⍝H (HELP) info below.

    DEBUG ⎕IO ⎕ML←0 0 1 
  0/⍨ ~DEBUG:: ⎕SIGNAL ⊂⎕DMX.( ('EN' EN) ('EM',⍥⊂'Intern: ',EM)('Message' 'Logic Error!'))

⍝ Define Constants
  ⍝ error messages 
    missingE← ⊂('EN' 11)('Message' 'Invalid or missing tradfn/op. Use option ''help'' for help')
    badOptsE← ⊂('EN' 11)('Message' 'Invalid or superfluous option(s)')
  ⍝ mutable system names (https://course.dyalog.com/Quad%20names/)
    mutable←  '⎕AVU' '⎕CT' '⎕DCT' '⎕DIV' '⎕FR' '⎕IO'   '⎕LX'    '⎕ML'   '⎕PATH'  
    mutable,← '⎕PP'  '⎕PW' '⎕RL'  '⎕RTL' '⎕SM' '⎕TRAP' '⎕USING' '⎕WSID' '⎕WX'
  ⍝ miscellany
    weirdChs← '∆⍙_'                                                ⍝ See OrderWeird and user options
    NL← ⎕UCS 10
  ⍝ Regex subpatterns for nsP, skipP, tradNmP, and withP 
      balParP_t← '\((?:[^()''\n]+|''[^'']*''|(?R))*+\)'            ⍝ balanced parens - single line
      comP_t←    '⍝.*'
      dfnP_t← '\{(?:[^{}'']+|''[^'']*''|(?R))*+\}'                 ⍝ dfn body - multiline ok
      ⋄ xNmP_t←    '[\p{L}_∆⍙#⍺⍵⎕][\p{L}\p{N}_∆⍙#⍺⍵⎕]*'            ⍝ user/sys/special          
      longNmP_t← '(?:',xNmP_t,'(?:\h*\.\h*',xNmP_t,')*)'           ⍝ complex name; spaces around '.' ok             
      qtP_t←     '(''[^'']*'')+'   
      rolP_t←  '([^⍝\n]*) ((?:⍝.*)?\n)'                            ⍝ rol -> rest of line
      rosP_t← '([^⋄\n⍝]*) (?| () [⋄\n] | ( ⍝.* ) \n )'             ⍝ ros -> rest of stmt
  ⍝ Regex patterns (ext=external decl, int=internal decl, loc=local (internal) decl).
    dirP←  '(?ix) : (?: If|While|Repeat|For|Select|Trap|Hold|Disposable)' ⍝ Directives w/ :END, omitting :With
    endP←  '(?ix) : (?: End\w*|Until)'                             ⍝ :End[xxx] | :Until (matches :While | :Repeat)
    eosP←  '$|⋄'  
    extP← '(?ix) \h* (?:⍝ \h*)? :EXTERN\b \h*',rosP_t              ⍝ [⍝]:EXTERN nm nm
    hdrP← '(?x) ( [^;⍝]+ ) ( ;[^⍝]* | ) ( ⍝.* | )'                 ⍝ Parse hdr into 3 parts
    intP← '(?ix) \h* (?:⍝ \h*)? :INTERN\b \h*',rosP_t              ⍝ [⍝]:INTERN nm nm
    locP← '(?x)  ^ \h* ; \h* ',rolP_t                              ⍝ ;nm;nm  (APL's "intern")
    nsP←  '(?ix) '' ([^'']+) '' \h* ⎕NS (?!\h*⍨)'                  ⍝ '...' ⎕NS, but not '...' ⎕NS⍨
    simpNmP←  '[\p{L}_∆⍙][\p{L}\p{N}_∆⍙]*'                         ⍝ simple user name
    skipP← '(?x) ',qtP_t, '|', comP_t, '|', dfnP_t, '| \.\h*', balParP_t
    tradNmP← ':', simpNmP, '|', longNmP_t                          ⍝ Directive or complex name
    withP←  '(?ix) :WITH\b '                                       ⍝ :WITH processing, See: withFlg, dirDepth
  
⍝ Define Basic Utilities
    FirstNm←    ⊢↑⍨⍳∘'.'⍤,                                         ⍝ In 'aa.bb.cc', 'aa' could be local
    Help← { ⎕ED '_'⊣ _← ('^\h*⍝H(?|(?:\h|[0-',⍵,'])(.*)|()$)') ⎕S ' \1'⊢⎕NR ⊃⎕XSI }⍕  
  ⍝ Returns 1 for all simple names EXCEPT #, ##, or ⎕SE. Does not handle complex names.
  ⍝ When ignoring weird chars, we append at end AFTER a space so A comes before _A etc.
  ⍝ See weirdØ below
    OrderWeird← { ~weirdØ: ⍵ ⋄ ~1∊ weirdChs∊ ⍵: ⍵ ⋄  ⍵,⍨ ' ',⍨ ⍵~ weirdChs }¨ 
    Immutable←  (∊∘mutable){ ~'⎕#:'∊⍨ f← ⊃⍵: 0 ⋄  f∊ '⎕': ~⍺⍺ 1∘⎕C⊂⍵ ⋄ 1 }
  ⍝ Register mutable names unless within the scope of a :WITH statement.
    RegisterNm← { withFlg[1]: ⍬ ⋄ f← FirstNm ⍵ ⋄ Immutable f: ⍬ ⋄ ⍬ ⊣ nmReg,∘⊂← f }
    Sort←       { ⍵[ ⍋⎕C⍣ ⍺ ⊢ OrderWeird ⍵ ] }                           
    SplitNms←   { '⎕'∊⍨ ⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }¨ ' ;'∘((~∊⍨)⊆⊢)
    UWarnIf←    { 
        ~1∊ ⍵: ⍺ ⋄ l r← ⍺⍺⌽ ':EXTERN' ':INTERN' 
        ⍺⊣ ⎕←'Warning: "',l,(∊' ',¨⍵/ ⍺),'" conflicts with prior ',r,' declaration'
    }

⍝ Define Major Functions
⍝   FmtInt    - Grab as many local names as possible that fit in the (column) width specified
⍝   UpdateExt - Add name to external list, verifying it's not an explicit internal
⍝   UpdateInt - Add name to internal list, ditto
⍝   ParseOpts - Parse ⍺ and return options (...Ø)
⍝   ParseArgs - Parse ⍵ and return list of lines AND nameclass.
⍝   ParseFnHdr- Parse fn header, returning fn header names, local vars in header, comments
⍝   ScanTradFn- (The workhorse:) Parse user fn/op, looking for :EXTERN, :INTERN, etc.
    FmtInt← ⊃,/⍤{ fØ← ⍺
        pfx sep← '    ' '; ' 
        GrabLns← (0⌈ widthØ- ≢pfx)∘{ 
          Grab1←⍺∘{ 1≥ ≢⍵: ⍵ ⋄  ⍺> +/≢¨⍵: ⍵ ⋄ ⍺ ∇ ¯1↓⍵ } 
          ⍬ { 0=≢⍵:⍺ ⋄ (⍺, ⊂pfx, ∊ln) ∇ ⍵↓⍨ ≢ln← Grab1 ⍵ } sep,¨⍥⊆⍵
        }¨
      ⍝ Organize into (lower_and_other, upper_case, system_case) based on initial letter 
      ⍝ (by default ignoring initial ∆, ⍙, _)
        ForCases← ((⎕A,⎕Á) '⎕')∘{   
          fØ:   ⊂⍵ ⋄ (⊂⍵)/⍨¨ (u⍱s),⍥⊆ u s← ⍺∊¨⍨ ⊂⊃¨OrderWeird ⍵ 
        } 
        GrabLns ForCases fØ∘Sort ⍵
    } 
    UpdateExt←{ kØ (f1 f2)← ⍺ ⍵ ⋄ e← SplitNms  f1 
        declaredInt~← declaredExt,← e (0 UWarnIf) e∊ declaredInt
        (kØ≥1)/ '    ⍝ :Extern ', f1, f2, NL 
    }
    UpdateInt←{ (kØ isI)(f1 f2)← ⍺ ⍵ ⋄ e← SplitNms  f1
      1∊ b← Immutable¨ e: 11 ⎕SIGNAL⍨'These reserved names cannot be localized:',∊' ',¨e/⍨ b
        declaredExt~← declaredInt,← e (1 UWarnIf) e∊ declaredExt
      isI: (kØ≥1)/ '    ⍝ :Intern ', f1, f2, NL 
           (kØ≥2)/ '    ⍝ ; ',       f1, f2, NL
    }
⍝    opts:   resultØ  foldØ  weirdØ   widthØ  
⍝            2,1*,0,¯1  1,0*   1*,0     0*,>0
    ParseOpts←{
        def← 1 0 1 0 ⋄ defWid← ⍺  
      def<⍥≢⍵: ⎕SIGNAL badOptsE       
        (t/opts)← def/⍨ t←⎕NULL= opts← 1↓5↑⎕NULL, ⍵              ⍝ For omitted options, use defaults def
        opts[ wI/⍨ 0≥ opts[ wI ] ]← defWid ⊣ wI← 3               ⍝ If width≤0, default to ⍺/defWid
      0∊(¯1 0 1 2)(0 1)(0 1)∊⍨¨ 3↑opts: ⎕SIGNAL badOptsE
        opts
    }
    ParseArgs← { 
      0=≢⍵: ⎕SIGNAL missingE ⋄ 0/⍨ ~DEBUG::   ⎕SIGNAL missingE
        (myTxt myNm) nc← { ⍝ Case 1: ⍵ is a name; Case 2: ⍵ is a fn/op body
          1=≢⊆⍵: ((⎕NR ⍵ ) (⌽r↑⍨ '.'⍳⍨ r←⌽⍵)) (ns.⎕NC ⊂,⍵) ⊣ ns← ⊃⎕RSI  ⍝ Case 1
                 (⍵ myNm ) (ns.⎕NC ⊂,myNm←ns.⎕FX ⍵)        ⊣ ns← ⎕NS ⍬  ⍝ Case 2
        }⍵ 
        (⊃⌽myTxt),← NL    ⍝ Ensure last line ends in NL like all others.
      nc∊ 3.1 4.1: myTxt myNm ⋄ ∘∘err∘∘  
    }
    ParseFnHdr← { kØ pgm← ⍺ ⍵ ⋄ SplitAny← (~∊⍨)⊆⊢
      ⍝ hA: Arg names, hLoc: optl Local declarations, hC: optl Comment
      ⍝     Maximal Pattern:  {r}← {a} (l Opt r) w ; l1; l2 ⍝ comment
      hA hLoc hC←  hdrP ⎕R '\1\n\2\n\3\n'⊣ ⊂⊃ pgm  
      hNms← ' ←{}()' SplitAny hA
      hL2←  (kØ≥2)/ (' ⍝ '/⍨ 0≠ ≢hLoc), hLoc                    ⍝ Local vars on header line
      hC←   ('  '/⍨ (0=≢hL2)∧ 0≠ ≢hC), hC
      hOut← ⊂hA, hL2, hC     
      hOut hNms hLoc
    }
      scanPats← eosP extP intP locP nsP skipP withP dirP endP tradNmP     
                eosI extI intI locI nsI skipI withI dirI endI tradNmI← ⍳≢scanPats
    ScanTradFn← scanPats ⎕R {  
          Case← ⍵.PatternNum∘∊ ⋄ F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block}
          F0← ⍵.Match 
        withFlg[0]∧Case eosI: F0⊣ withFlg[]← 0 1
        Case eosI:    F0  ⍝ kØ isI
        Case extI:    resultØ   UpdateExt F¨1 2                  ⍝ :EXTERN nm nm ...  [⍝ com]
        Case intI:    resultØ 1 UpdateInt F¨1 2                  ⍝ :INTERN nm nm ...  [⍝ com]
        Case locI:    resultØ 0 UpdateInt F¨1 2                  ⍝ ; nm; nm; ...      [⍝ com]
        Case skipI:   F0                                         ⍝ Skip comments, quotes, {...}, ns.(...)
        Case tradNmI: F0⊣ RegisterNm F0
        Case dirI:    F0⊣ dirDepth+← withFlg[1] 
        Case endI:    F0⊣ withFlg[1]← 0< dirDepth⊢← 0⌈ dirDepth- withFlg[1] 
        Case nsI:     F0⊣ RegisterNm F 1
        Case withI:   F0⊣ withFlg[0]← ~withFlg[1]⊣ dirDepth+← withFlg[1]
        ∘∘∘ Unreachable ∘∘∘
    }⍠ ('UCP' 1)('Mode' 'M')('NEOL' 1)('EOL' 'LF')               ⍝ Mode M needed for dfnP_t and eosP
 
⍝ ===============================================================================
⍝ === Begin Executive ===========================================================
⍝ ===============================================================================
⍝ ∘ Help? (Intern⍨'help')
  'help'≡⍥⎕C⍵: _← Help 0
⍝ ∘ Parse and Validate ⍵-Args---
    myTxt myNm← ParseArgs ⍵
⍝ ∘ Parse ⍺-Options, passing length of longest line (but not >⎕PW) to ParseOpts 
    ⍺← ⍬  
    resultØ foldØ weirdØ widthØ ← (⎕PW⌊ ⌈/≢¨myTxt) ParseOpts ⍺  
⍝ ∘ Parse Fn/Op Header---
    fnHdr hdrNms hLoc← resultØ ParseFnHdr myTxt         
⍝ ∘ Init Database of declared internal, external names, and names found in body of fn/op 
    declaredInt←   SplitNms 1↓ hLoc
    declaredExt←   ⍬
    nmReg←      ⍬
⍝ ∘ Init :With-related State Vars
    withFlg← 2⍴ dirDepth← 0 
    fnBody← ScanTradFn 1↓ myTxt
⍝ ∘ Prepare and return result
    declaredExt← ∪ declaredExt 
    nmReg/⍨←  ~Immutable¨ nmReg                                  ⍝ Ignore names that are by def immutable                  
    totalInt← ∪declaredInt∪ nmReg~ declaredExt∪ hdrNms~ ⊂myNm 
  ¯1=resultØ: foldØ∘Sort¨ declaredExt totalInt                        ⍝ Return (externals internals)
    fnHdr, (foldØ FmtInt totalInt), fnBody

⍝ ===============================================================================
⍝ === END PROGRAM ===============================================================
⍝ ===============================================================================

⍝H
⍝H          ┌─────────────────────────────────┐
⍝H Intern:  │ result← opts ∇ [ nm | codeStr ] │
⍝H          └─────────────────────────────────┘
⍝H
⍝H OVERVIEW
⍝H ¯¯¯¯¯¯¯¯
⍝H   Scans a tradfn/tradopt to generate local variable declarations (;nm1;nm2...)
⍝H   for all names not made explicitly external (non-local) using a :EXTERN directive. 
⍝H   Supports new (pseudo-)directives :EXTERN and :INTERN at the start of comments or 
⍝H   a program line.
⍝H   :∘ :Extern statements declare variables that are not internal (not local):
⍝H      :EXTERN myExtern1 MyExternFn ⎕PW   OR    ⍝ :EXTERN myExtern1 MyExternFn ⎕PW
⍝H   ∘ Normally, all other variables within the scope of the tradfn will be  
⍝H     considered local so THEY NEED NOT BE DECLARED, but you may explicitly 
⍝H     declare variables as local via the :INTERN statement:
⍝H      :INTERN internal1; ⎕IO            OR     ⍝ :INTERN internal1; ⎕IO
⍝H   ∘ As a nod to legacy, we allow internal statements in an APL local variable
⍝H     style (beginning a line ANYWHERE in the code outside a comment):
⍝H      ; internal1; ⎕IO       
⍝H   ∘ An :INTERN (or ;...) declaration would be required for internal items used within
⍝H     quotes-- see myNs below-- or used within dfn bodies, if they are treated as globals
⍝H     (externals), as for "count" here.
⍝H      :INTERN myNs              :INTERN count
⍝H      'myNs' ⎕NS ...            {count∘← ⍵}10  ⍝ Contrived but legal example
⍝H      NOTE: See EXPERIMENTAL FEATURE below, which automatically handles
⍝H            internal 'myNs' above.
⍝H     An :INTERN declaration would not be needed for myNs in the following case:
⍝H      myNs← ⎕NS ...  ⍝ myNs registered automatially as internal.
⍝H
⍝H DETAILS
⍝H ¯¯¯¯¯¯¯
⍝H   ∘ By default, all top-level names will automatically be made local to a
⍝H     presented tradfn/op. A top-level name is defined simply as:
⍝H         ∘ the first simple name within a complex name ('like' in like.this.one)
⍝H         ∘ an unquoted argument to :With, e.g. :With local_name
⍝H         ∘ a name outside an included dfn and outside the scope of a :With statement.
⍝H         ∘ a declared local via a legacy APL statment: ; like; this; one
⍝H   ∘ "Local" declarations (like the ones above) are equivalent to :INTERN, and kept
⍝H   only for compatibility/legacy reasons.
⍝H     * Intern handles these constructions properly, with the variables
⍝H          myNs, name, myNs2 
⍝H       all automatically internal!
⍝H
⍝H       ⍝ Expects local myNs created earlier, e.g. via myNs←⎕NS⍬ or 'myNs' ⎕NS⍬
⍝H         myNs.(alpha beta gamma)← *1 2 3 
⍝H         name← { all sorts of invisible names }
⍝H
⍝H       ⍝ :With...
⍝H       ⍝ Expects local myNs2 created earlier, e.g. via myNs2←⎕NS⍬ or 'myNs2' ⎕NS⍬
⍝H         :With myNs2               ⍝ automatically :INTERN (local)
⍝H             ignore_me←1           ⍝ treated as myNs2.ignore_me and ignored.
⍝H         :EndWith 
⍝H 
⍝H       ⍝ Equivalent to :With statement above!
⍝H         myNs2.ignore_me←1. 
⍝H
⍝H     * Does NOT** check for whether a name is set before use in order to determine locality.
⍝H       If it appears in code outside dfn and other limiting scope, it's by default :INTERN.
⍝H               ** (unlike dfns, which are "smarter")
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
⍝H         ┌──────────────┬──────────┬───────────────────┬──────────────────────────────────┐
⍝H   opts: │ result type  │fold case │ignore weird chars │ max width of locals declaration  │
⍝H         │              │          │  (when sorting)   │                                  │
⍝H         │ 2, 1*, 0, ¯1 │  1, 0*   │      1*, 0        │    ((≢longest_line) ⌊ ⎕PW) **    │
⍝H         └──────────────┴──────────┴───────────────────┴──────────────────────────────────┘
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
⍝H             2: Show as comments
⍝H                 ∘ both the original :EXTERN and :INTERN directives; and
⍝H                 ∘ the original traditional (legacy) local declarations (;nm1;nm2...)/ 
⍝H      >>>    1: (DEFAULT) Show as comments: 
⍝H                 ∘ both the original :EXTERN and :INTERN directives; however, 
⍝H                Remove (don't show): 
⍝H                 ∘ the original traditional (legacy) local declarations.
⍝H             0: Remove (don't show): 
⍝H                ∘ both the original :EXTERN and :INTERN directives; however, 
⍝H                ∘ the original traditional (legacy) local declarations.
⍝H          ¯1: Simply list all the externals and internals as two character vectors of vectors, e.g.
⍝H              ┌─────────────┬───────────────────────────────────────────────────────────┐
⍝H              │┌───────┬───┐│┌─┬─┬─┬──────┬────┬────┬────┬──────┬──────┬─────┬───┬─────┐│
⍝H              ││Outside│⎕ML│││A│B│I│Inside│Tidy│Trad│glop│local3│local4│three│⎕IO│⎕TRAP││
⍝H              │└───────┴───┘│└─┴─┴─┴──────┴────┴────┴────┴──────┴──────┴─────┴───┴─────┘│
⍝H              └─────────────┴───────────────────────────────────────────────────────────┘
⍝H              Externals and internals are each sorted in unicode (⍋⍵) order.
⍝H      opts[1]: fold upper and lower case in output (legacy) locals declarations...
⍝H      >>>   ∘ If 0 (default), sort and display variables in order:
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
⍝H      >>>   ∘ If 1 (default), sorts/classifies names containing with ∆, ⍙ or _ 
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
⍝H      >>>     The default (if omitted or specified as 0) is:
⍝H                  the width of the longest line in the fn/op passed or ⎕PW, whichever is smaller
⍝H              Generated local names are by default output this way:  
⍝H                  lower case names + newline + upper case names + newline + system names
⍝H              If opt[3] is ≤0, the default is assumed.
⍝H  
⍝H   result
⍝H   ¯¯¯¯¯¯
⍝H     If opt[0]∊2 1 0: result is the revised code of the presented tradfn or tradop, 
⍝H     with:
⍝H        ∘ All simple variables without an :EXTERN are assumed to be internal(local). 
⍝H            (name1 name2)←3      ==> name1, name2 are internal.
⍝H        ∘ The first name in a complex variable name is assumed to be internal (local).
⍝H             test.alpha.beta←3   ==>  test is internal.
⍝H        ∘ Dfn contents are ignored completely and names only seen inside them are
⍝H          neither external nor internal.
⍝H     If the input <nm> or <codeStr> is not a tradfn or tradop, an error is signaled.
⍝H 
⍝H   Within your local fn/op
⍝H   ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
⍝H   ○ Use 
⍝H       [⍝ ]:INTERN nm1 nm2 ... 
⍝H     to declare local variables.
⍝H     ∘ These are only needed for names not otherwise visible to the Intern function.
⍝H     ∘ Those that are visible will be declared as :INTERN automatically.
⍝H   ○ Optionally, use stmts of the form   
⍝H       ;nm1;nm2 
⍝H      anywhere in the program (not preceded by a comment lamp '⍝') 
⍝H      as a variant for :INTERN statements.
⍝H   ○ Use 
⍝H       [⍝ ]:EXTERN nm1 nm2 ... 
⍝H       to declare external (non-local) variables.
⍝H     ∘ This is needed to ensure an external (non-local)name (per above) is not 
⍝H       automatically localized.
⍝H   Handles :WITH constructs, i.e. ignoring (not localizing) any name within the scope
⍝H     of a :WITH statement.  
⍝H     ∘ May require :EXTERN statements for class 9 variable names which are local
⍝H      to the function but not visibly initialized...
⍝H
⍝H   Warns if names are declared as both :EXTERN and :INTERN.
⍝H   
⍝H   EXPERIMENTAL FEATURE:
⍝H   ∘ Intern will recognize a simple quoted string in this context: 
⍝H      -    to the left of ⎕NS,                    e.g.    'name1.name2' ⎕NS ...
⍝H      and generate an appropriate :INTERN for the FIRST name in that fstring.
⍝H   Bugs: Does not notice ⎕SHADOW variables, but will assume names not declared as :EXTERN
⍝H         are internal by default.
⍝H        ⎕SHADOW 'myNs' 'localPW'      ⍝ Redundant declaration of locals.
⍝H        myNs← ⎕NS⍬ ⋄ localPW← ⎕PW     ⍝ myNs, localPW are local by default!!!
 }
