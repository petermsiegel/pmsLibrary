lnsOut← {opts} Macros lnsIn  

⍝ Use :With to avoid all those annoying variable declarations...
:With ⎕NS⍬ ⋄  DEBUG←0 ⋄ :Trap 0/⍨ ~DEBUG
  ⎕IO ⎕ML←0 1
  nlC← ⎕UCS 13 
  :IF ~900⌶1 ⋄ :ANDIF opts≡⍥⎕C 'help'
        ⎕ED '_'⊣ _← ('^\h*⍝H ?(.*)') ⎕S ' \1'⊢⎕NR ⊃⎕XSI ⋄ :RETURN 
  :ENDIF 

⍝ error messages 
  cpyNoWsÊ←  ⊂('EN' 11)('Message' '::COPY argument syntax— "::Copy ws: name1 ..."')
  endSyntxÊ← ⊂('EN' 11)('Message' '::End directive doesn''t match anything')
  optionsÊ←  ⊂('EN' 11)('Message' 'Option(s) ⍺ are invalid or superfluous')
  logicÊ←    ⊂('EN' 11)('Message' 'Macros: Internal logic error!')
  missingE←  ⊂('EN' 11)('Message' 'Invalid argument (⍵): Invalid or missing function or op')

⍝ error fns
  CpyNFndÊ←  {⊂('EN' 11)('Message' ('::COPY Could not find fn(s)/op(s): ',⍵)) }
  UnknDirÊ←  {⊂('EN' 11)('Message' ('Invalid macro directive "','"',⍨ ⍵)) }
  FileÊ← {⊂('EN' 11)('Message' ('Invalid/Missing file: ''','''',⍨ ⍵)) }
  MacroÊ←   {⊂('EN' 11)('Message' ('Invalid macro name "','"',⍨ ⍵)) }
  EvalÊ←  {⊂('EN' 11)('Message' ('::DEFE failed evaluating expression "','"',⍨ ⍵)) }
 
⍝ Small Support Functions
  QTs← {qt←'''' ⋄ (qt∘,,∘qt)⍵/⍨ 1+qt=⍵ }
  Parens← '('∘,,∘')'
  ⍝ Exec runs all ::DEFE (and ::EVAL) stmts in a sandbox available to later such stmts.
  ⍝ If ⍺=1, require an explicit result!
  sandboxNs← ⎕NS⍬
  Exec← (sandboxNs){ ⍺←0 ⋄ 0:: ⎕SIGNAL EvalÊ ⍵ ⋄ 85:: '' ⋄ 1 (85⍺⍺.⌶) ⍵,⍨ ⍺/'⊢' }
  IfNotDirective← { '::'≢ 2↑TrimL ⍵ }
  TrimL← {⍵↓⍨ +/∧\ ⍵=' '}
  ⍝ Copy in as text from_ws: obj1 [obj2...]
  ⍝ copy objects obj1 [obj2...] from APL workspace from_ws
  ⍝ Signals cpyNoWsÊ if no ws named or CpyNFndÊ if any object is not copied.
  Copy←{
      ~':'∊⍵: ⎕SIGNAL cpyNoWsÊ
        dir names←':'(≠⊆⊢)⍵ ⋄ dir~← ' ' ⋄ names←' '(≠⊆⊢)names
      11:: ⎕SIGNAL CpyNFndÊ ⍵
        _←names (ns←⎕NS⍬).⎕CY dir ⋄ ⊃,/ns.(⎕NR¨⎕NL-3 4)
  }
  ⍝ Include  [<file_from_sys_path> | "file_from_user_dir" | file_from_user_dir_no_spaces]
  ⍝ Copy in the text from a file either 
  ⍝    in the system path, or
  ⍝    in the user directory
  ⍝ On error, signals fileÊ
  Include←{ 
        DYALOG← 2 ⎕NQ'.' 'GetEnvironment' 'DYALOG'
        sysDir←  DYALOG, '/SALT/spice'
        fi← (sysDir/⍨ '<'=⊃⍵), fi← {'<"'∊⍨ ⊃⍵: 1↓¯1↓⍵ ⋄ ⍵}⍵
      0:: ⎕SIGNAL FileÊ fi ⋄ ⊃⎕NGET fi 1 
  }
  ⍝ Truthy: A "sort-of" true as in Python
  ⍝   Returns 1: For any array that is not of length 0  
  ⍝              and that is not singleton (∊⍵) 0 or ⎕NULL
  ⍝   Returns 0: Otherwise 
  Truthy← { r←⍴s←∊⍵ ⋄ 1≠r: 0≠r ⋄ s(~∊)0 ⎕NULL }
⍝ Major functions
  ⍝ Parse the arguments to Macros from ⍵.
  ParseArgs← {  
      ⍝  Returns: (lines name) rc:
      ⍝         rc is 0, if error, else the nameclass of <name>.
      ⍝ 
      0=≢⍵:        (⍬ ⍬) 0
      0/⍨ ~DEBUG:: (⍬ ⍬) 0
      (myLns myNm) nc← { 
          VV2Fn← { ns← ⎕NS ⍬ ⋄ (⍵ myNm ) (ns.⎕NC ⊂,myNm←ns.⎕FX ⍵)  }
          ⍝ Case 1: ⍵ is a name 
          1=≢⊆⍵: {      
            ⍝ Case 1a: ⍵ is a filename prefixed by 'file://'
              p≡⍥⎕C ⍵↑⍨ nP← ≢p←'file://': VV2Fn ⊃⎕NGET (nP↓ ⍵) 1
            ⍝ Case 1b: ⍵ is a function name (simple or prefixed)
                ((⎕NR ⍵ ) (⌽r↑⍨ '.'⍳⍨ r←⌽⍵)) (ns.⎕NC ⊂,⍵) ⊣ ns← ⊃⎕RSI
          } ⍵  
          ⍝ Case 2: ⍵ is a fn/op body (vector of char vectors, i.e. multi-line)
            VV2Fn ⍵ 
      }⍵ 
      0=≢myLns: (⍬ ⍬) 0   
      3 4(~∊⍨) ⌊nc:  ⎕SIGNAL missingE  
        (myLns myNm) nc 
  }
  :Section defs dictionary
  ⍝ defs...: Macro (::DEF) dictionaries- declarations, fns, ops
    keysV← valsV← ⍬
    ⍝ I. Dictionary Support Fns 
      ⍝ Canon: Names starting with ⎕ are stored in uppercase.
      Canon← { '⎕'=⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }
      ⍝ ToLinear: If a value is multiline, return a canonical linear definition
      AsCode←  ⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise) 
      ToLinear← { 0∊ ⍴mx←⎕FMT ⍵: '' ⋄ 1=≢mx: ∊mx ⋄ AsCode ⍵ }
    ⍝ II. (Major) Dictionary Routines
    ⍝ A. DictSet: k (opts DictSet) v   OR  (opts DictSet) k v
    ⍝    Define kC, as k normalized. 
    ⍝    If v is '', then v← kC. vC is v formatted/evaluated per opts.
    ⍝    opts: See DictEval ([0] Execute, [1] Add Parens, [2] Add Quotes)
    ⍝    Returns vC.
        ⍝ sysV←  '⎕PATH' '⎕SM' '⎕TRAP' '⎕PP' '⎕FR' '⎕PW'
        ⍝ sysV,← '⎕USING' '⎕AVU' '⎕IO' '⎕RL' '⎕CT'
        ⍝ sysV,← 'WSID' '⎕LX' '⎕RTL' '⎕WX' '⎕DCT' '⎕ML' '⎕DIV'
        ⍝ IsSysV← ∊∘sysV
        ⍝ DictSet← {  
        ⍝     Mirror2Sandbox← {  
        ⍝       kC2← IsSysV {'⎕'≠⊃⍵: ⍵ ⋄ ⍺⍺ ⊂⍵: ⍵ ⋄ '⍙',1↓⍵ } ⍺
        ⍝       sandboxNs⍎kC2,'←⍵'
        ⍝     }
        ⍺← ⊢ ⋄ k v←⍺ ⍵ 
        kC← Canon k ⋄ vC← (⍺⍺ DictEval) v kC⊃⍨ 0=≢v  
        p←keysV⍳ ⊂kC  ⍝ ⋄  _← kC Mirror2Sandbox vC
      p≥ ≢keysV: valsV ,∘⊂← vC ⊣ keysV,∘⊂← kC  
      1:        (p⊃ valsV)← vC  
    }
    ⍝ B. DictEval: DictEval v
    ⍝   ⍺=1: Require an explicit result, if ⍺⍺[0]=1. 
    ⍝   ⍺=0: Do not require an explicit result. 
    ⍝        Start (non-null) result on a new line.
    ⍝   ⍺⍺:  [0] Execute (e), [1] Add parens (p), [2] Add quotes (q)
    DictEval← { ⍺←1 ⋄ e p q← 'epq'∊ ⎕C ⍺⍺
        res← Parens⍣p⊣ QTs⍣q⊣ ToLinear⍣(p∨q∨~⍺)⊣ raw← ⍺∘Exec⍣e⊣ ⍵
      0∊⍴raw: '' ⋄ res,⍨ nlC/⍨ ~⍺
    }
    ⍝ C. DictUndef:  DictUndef k
    DictUndef←{  
        (p← keysV⍳ ⊂kC← Canon ⍵)≥ ≢keysV: 0
        1⊣ keysV⊢← keysV/⍨ q ⊣ valsV⊢← valsV/⍨ q← p≠ ⍳≢keysV 
    }
    ⍝ D. DictGet:  DictGet k. If it does not exist, return k itself.
    ⍝ If ⍺, ensures result is a linearized char vector. Else returns in char (⍕) format.
    DictGet← { ⍺←0 ⋄ p← keysV⍳ ⊂kC← Canon ⍵ 
      val← { p< ≢keysV: p⊃ valsV ⋄ ⍵ } kC
      ⍺: ToLinear val  ⋄ val 
    }
    ⍝ E. Exist: DictExists k. Returns 1 if k is defined.
    DictExists← {  ( keysV⍳ ⊂Canon ⍵ )< ≢keysV }
    ⍝ F. DictShow: DictShow ⍬ lists all keys and values.
    DictShow← { 
      kk← { 0=≢⍵: keysV ⋄ ' ' (≠⊆⊢) ⍵ }⍵ ⋄ vv← 0∘DictGet¨kk
      ''⊣ kk{ ⎕←1↓⍤1⊢⎕FMT(('> ',(12⌈≢_)↑ _←'"','"',⍨⍺),'→') ⍵ }¨vv
    }
  :EndSection ⍝ defs dictionary

  :Section Command Parser
  ⍝ Command parser (PCRE-based)
    ⍝ I. Support Fns
      ⋄ Cm←  '⍝ '∘,                  ⍝ Comment prefix in ⎕R output.
      ⋄ Dir← '(?xi) ^ \h*  ::'∘,     ⍝ Preamble for directives in Regex patterns.
    ⍝ Regex Patterns
      nmP1_t←  '[\pL_∆⍙][\w_∆⍙]*'
      nmP←     '(?<!\.)⎕?',nmP1_t,'(?:\.',nmP1_t,')?(?!\.)' 
      qtsP←    '(''[^'']*'')+' 
      cmP←     '⍝.*$'   ⍝ Order after directives, since they may appear as comments
      ⍝ ::DEF
      ⍝   ::DEF name← val  OR  ::DEF name val
      ⍝   ::DEF name      is equiv to     ::DEF name← name      (defines the name as itself)
      ⍝   ::DEF name←     is equiv to     ::DEFE name← ⎕UCS 32  (the first blank after the ← is ignored)
      ⍝ ::DEF[QEP]
      ⍝   E: Evaluate the expression in a private namespace
      ⍝   Q: Add quotes to the expression (after evaluating)
      ⍝   P: Add parens around the final expression (after evaluating)
      defP←    Dir'def ([QEP]*) \h+ (',nmP,') (?: \h* ← \h? | \h+)?+ (.*) $' 
      ⍝ ::EVAL[QEP] expr
      ⍝   Evaluates <expr> in a private namespace and includes the result in the output.
      ⍝   Side effects in the private namespace will be available to later expressions.
      ⍝   Q, P (as above). E is obligatory, so added automatically.
      evalP←   Dir'eval ([QEP]*)\h*(.*) $'   
      undefP←  Dir'undef \s+ (',nmP,') .* $'
      copyP←   Dir'copy((?:RAW|R)?) \h+ ([^:]+:.*) $'
      includeP←Dir'include((?:RAW|R)?) \h+ ("[^"]+"|<[^>]+>|[^ ]+) \h* $'
      ⍝ ifCondP: f1: if, elif, etc. f2: argument (left and right trimmed) 
      ifCondP← Dir'(?| ((?:el(?:se))?\h?if\h*(?:ndef|def|)) \h+ (.*?) \h* | (else)\b())$'
      endIfP←  Dir'end(?:if)? \h* () $'
      showP←   Dir'show(?:defs)? \h* (.*) $'
      unknDirP← Dir'.*$'
      pats←   nmP qtsP defP evalP undefP copyP includeP ifCondP endIfP showP cmP unknDirP   
              nmI qtsI defI evalI undefI copyI includeI ifCondI endIfI showI cmI unknDirI← ⍳≢pats

      continueP← '\h*(?:\.{2,3}|…)\h*((?:⍝.*)?)\n'   ⍝ 2-3 dots OR ellipses Unicode char.
      continueG← ⍬
      Continue←qtsP cmP continueP '\n?$' ⎕R {  
          ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
          C 0 1: ∆F 0 ⋄ C 2: ' ' ⊣ continueG,← ⊂∆F 1
          (continueG⊢← ⍬)⊢ (∊' ',¨ continueG), ∆F 0
      }⍠('UCP' 1)('Mode' 'M')('EOL' 'LF')

      ifCondL← (,'if'    'elseif' 'elif' ∘., '' 'def' 'ndef'), ⊂'else'
      ifMapL←    0 1 2    3 4 5   3 4 5                           6
      ifI ifDI ifNI elifI elifDI elifNI elI← 0 1 2 3 4 5 6
      ifIsTrue_keep ifNotYetTrue_skip ifPastTrueBlock_skip ifNotActive_keep← 2 1 ¯1 0
      IfCond← '⍝'∘,{     
           f0 (f1 f2)← ⍵ ⋄ p← ifCondL⍳ ⊂' '~⍨⎕C f1 ⋄ C← (p⊃ ifMapL)∘∊
        (≢ifCondL)= p : ⎕SIGNAL logicÊ
        condG,← (C ifI ifDI ifNI)/0
        (⊃⌽condG)← (⊃⌽condG){ Q← ⊃∘ifNotYetTrue_skip ifIsTrue_keep
          C ifI:  Q Truthy Exec NmSub ⍵ ⋄ C ifDI:  Q DictExists ⍵ ⋄ C ifNI: Q ~DictExists ⍵
          ifNotYetTrue_skip≠ ⍺: ifPastTrueBlock_skip  
          C elifI: Q Truthy Exec NmSub ⍵ ⋄ C elifDI: Q DictExists ⍵ ⋄ C elifNI: Q ~DictExists ⍵
          C elI:   ifIsTrue_keep     
        } f2 
          f0,⍨ '+-'⊃⍨ skipG ⊣ skipG⊢←  2| ⊃⌽condG 
      }  
      NmSub←  nmP qtsP cmP ⎕R { 
        f0← ⍵.Match ⋄ ⍵.PatternNum= 0: 1 DictGet f0 ⋄ f0 
      }  

      condG← ,ifNotActive_keep ⋄ skipG←0 
      ProcLns← ⍬∘{
        Match← pats ⎕R { 
          ⍝ extern: linesG
            ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
            f0← ⍵.Match
            C endIfI:  '⍝+', f0 ⊣ skipG⊢← 2| ⊃⌽condG ⊣ condG↓⍨← ¯1 ⊣ ⎕SIGNAL⍣(1≥≢condG)⊢endSyntxÊ
            C ifCondI: IfCond f0 (∆F¨1 2)
          skipG: '⍝-',f0
            C qtsI cmI: f0 
            C nmI:  1 DictGet f0
            C defI: Cm f0⊣ f2 ((f1) DictSet)  NmSub f3 ⊣ f1 f2 f3← ∆F¨1 2 3 
            C evalI: Cm f0,  0 ((f1,'e') DictEval) NmSub f2 ⊣ f1 f2←    ∆F¨1 2 
            C undefI: Cm f0⊣ DictUndef ∆F 1 
            C copyI:  { f1 f2← ∆F¨1 2 ⋄ lns← Copy f2
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C includeI:  { f1 f2← ∆F¨1 2 ⋄ lns← Include f2 
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C showI: Cm f0, DictShow ∆F 1
            C unknDirI: ⎕SIGNAL UnknDirÊ f0
          ⎕SIGNAL logicÊ
        }⍠('UCP' 1)
          0=≢ ⍵: ⍺  
            curG← ⊃⍵ ⋄ linesG← 1↓⍵ 
          ~skipG: linesG ∇⍨ ⍺,⊂ Match curG  
          IfNotDirective curG:  linesG ∇⍨ ⍺,⊂ '⍝-',curG
            linesG ∇⍨ ⍺,⊂ Match curG 
      }
  :EndSection Command Parser

      (myLns myNm) nc← ParseArgs lnsIn
      lnsOut← (1↑myLns), ProcLns Continue 1↓myLns
:Else 
    ⎕SIGNAL ⊂⎕DMX.('EN' 'EM' 'Message',⍥⊆¨EN EM Message)
:EndTrap ⋄ :EndWith

⍝H Macros - 
⍝H    A C-preprocessor-like macro processor for Dyalog functions and operators.
⍝H Syntax:
⍝H    fn_lines← [opts] Macros [ fn_lines | fn_name | file://file_name ]
⍝H      opts: 'help' (if specified, the right arg is ignored)
⍝H      fn_lines           2 or more lines of a fn/op to preprocess
⍝H      fn_name            the name of an APL fn/op (including any ns spec)
⍝H      file://file_name  the name of a file containing one or more APL objects.
⍝H
⍝H Directives (case is ignored on directive names; "␢" represents an optional space.
⍝H    ::DEF[PQE] name← val     Defines name as having the value <val>, possibly transformed:
⍝H                             E-- after executing in a private namespace.
⍝H                             P-- adding parens on the outside.
⍝H                             Q-- after adding quotes on the outside, doubling internal quotes.
⍝H                             If val is omitted, name has the value of null
⍝H    ::DEF[PQE] name [val]    If val is omitted, it is name by default
⍝H    ::UNDEF name
⍝H    ::IF expression          If expression is "truthy," the block is executed 
⍝H                             (truthy: true if more than 1 elem or, if 1 elem, neither 0 nor ⎕NULL)
⍝H                             IF/ELSEIF/ENDIF sequences may be nested.
⍝H    ::IF[␢DEF|␢NDEF] name    If name is (is not) defined, the block is executed.
⍝H                             ::IF, ::IFDEF, ::IF DEF, etc. are allowed. 
⍝H                             Note: "␢" stands in for an opt'l space character.
⍝H    ::ELSE␢IF[␢DEF|␢NDEF]... As for ::IF above.  ::ELSEIF, ::ELSE IF, etc. are allowed.
⍝H    ::ELIF[␢DEF|␢NDEF]...    Same as ELSEIF
⍝H    ::ELSE                   The block is executed if no IF or ELSEIF has executed.
⍝H    ::END[IF]                Marks the end of an IF sequence.
⍝H    name used in user code   A defined name found in user code is replaced by its value 
⍝H                             as defined (via DEF or its variants).
⍝H                             Names beginning with ⎕ are treated and matched as if upper case.
⍝H                             Names must be simple, containing no dots (namespace elements).
⍝H    ::EVAL code              Evaluates the code in a private NS (shared across calls).
⍝H                             Displays the result simply in the output if a single line.
⍝H                             Displays a code version in the output, if not a single line.
⍝H    ::COPY ws: obj1 ...      Copies obj1 etc. from workspace ws as code in text form,
⍝H                             after scanning for Macros directives.
⍝H    ::COPY[R|RAW]            Like Copy, but does not evaluate via Macros.
⍝H    ::INCLUDE [<fi> | "fi"]  Copies in everything in the file specified into the output stream,
⍝H                             after scanning for Macros directives.
⍝H                             <fi> looks in the "system" directory, "fi" in the user dir.
⍝H    ::INCLUDE[R|RAW]         Like ::INCLUDE, but does not evaliate via Macros.
⍝H    ::SHOW                   Lists in the session (not output stream) values of defined names.
⍝H    … Continuation lines     Macros allows any line (user code or directive) to be continued.
⍝H    ...  OR                  Continuations are indicated via ellpsis (... .. or …)
⍝H    ..   OR                  at the end of a line before any comments.
⍝H    …                        Any ellipsis (plus newline) is replaced by a single space.
⍝H                             '…' is ⎕UCS 8230.