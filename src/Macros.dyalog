lnsOut← Macros lnsIn  

:With ⎕Ns⍬ ⋄  DEBUG←0 ⋄ :Trap 0/⍨ ~DEBUG
    ⎕IO ⎕ML←0 1
    nlC← ⎕UCS 13 

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
    Include←{ sysDir← './'
        fi← (sysDir/⍨ '<'=⊃⍵), fi← {'<"'∊⍨ ⊃⍵: 1↓¯1↓⍵ ⋄ ⍵}⍵
      0:: ⎕SIGNAL FileÊ fi ⋄ ⊃⎕NGET fi 1 
  }
  ⍝ Truthy: A "sort-of" true as in Python
  ⍝   Returns 1: For any array that is not of length 0  
  ⍝              that is not singleton (∊⍵) 0 or ⎕NULL
  ⍝   Returns 0: Otherwise 
    Truthy← { r←⍴s←∊⍵ ⋄ 1≠r:0≠r ⋄ s(~∊)0 ⎕NULL }

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
  ⍝ Macro (::DEF) dictionaries- declarations, fns, ops
    keysV← valsV← ⍬
    ⍝ I. Dictionary Support Fns 
      ⍝ Canon: Names starting with ⎕ are silently uppercase.
        Canon← { '⎕'=⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }
      ⍝ ToLinear: If a value is multiline, return its Serialise-d definition
        Encode←  ⎕SE.Dyalog.Array.(0∘Deserialise 1∘Serialise) 
        ToLinear← { 0∊ ⍴mx←⎕FMT ⍵: '' ⋄ 1=≢mx: ∊mx ⋄ Encode ⍵ }
    ⍝ II. (Major) Dictionary Routines
    ⍝ A. Set: k Set v   OR  Set k v
      Set← {  
          ⍺← ⊢
          k v←⍺ (⍵, ⍺/⍨0=≢⍵)
          vC← ⍺⍺ Eval v
          p←keysV⍳ ⊂kC← Canon k
        p≥ ≢keysV: keysV,← ⊂kC ⊣ valsV,← ⊂vC
        1: (p⊃ valsV)← vC  
      }
    ⍝ B. Eval: Eval v
    ⍝   ⍺=1: Ensure in linear char. form. Else ⍺=2: leave as is.
      Eval← {  ⍺←0  
          ⋄ Exec← { Ex← 85 privNs.⌶ ⋄ 0:: ⎕SIGNAL EvalÊ ⍵ ⋄ 85:: '' ⋄ 1 Ex ⍵ }
          e p q← 'epq'∊ ⎕C⍺⍺
          res← Parens⍣p⊣ QTs⍣q⊣ ToLinear⍣(p∨q∨⍺)⊣ raw← Exec⍣e⊣ ⍵
        0∊⍴raw: ''
        ⍺: ∊nlC, res  ⋄ res
      }
    ⍝ C. Undef:  Undef k
      Undef←{  
          (p← keysV⍳ ⊂kC← Canon ⍵)≥ ≢keysV: 0
          1⊣ keysV⊢← keysV/⍨ q ⊣ valsV⊢← valsV/⍨ q← p≠ ⍳≢keysV 
      }
    ⍝ D. Get:  Get k. If it does not exist, return k itself.
    ⍝ If ⍺, ensures result is a linearized char vector. Else returns in char (⍕) format.
      Get← { ⍺←0
        res← { (p← keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV: p⊃ valsV ⋄ ⍵ } ⍵
        ⍺: ToLinear res  ⋄ res 
      }
    ⍝ E. Exist: Exists k. Returns 1 if k is defined.
      Exists← {  (  keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV }
    ⍝ F. ShowAll: ShowAll ⍬ lists all keys and values.
      ShowAll← { ''⊣ keysV{ ⎕←1↓⍤1⊢⎕FMT(('> ',(8⌈≢_)↑ _←'"','"',⍨⍺),' → "') ⍵ '"' }¨0∘Get¨keysV }
 
  ⍝ Command parser (PCRE-based)
    ⍝ I. Support Fns
      ⋄ Cm←  '⍝ '∘, ⋄ Cm1← '⍝'∘,
      ⋄ Dir← '(?xi) ^ \h*  ::'∘,     ⍝ Preamble for directives...
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
      ⍝   Q, P (as above). E implicit in Eval, so ignored.
      evalP←   Dir'eval ([QEP]*)\h*(.*) $'   
      undefP←  Dir'undef \s+ (',nmP,') .* $'
      copyP←   Dir'copy((?:RAW|RA|R)?) \h+ ([^:]+:.*) $'
      includeP←Dir'include((?:RAW|RA|R)?) \h+ ("[^"]+"|<[^>]+>|[^ ]+) \h* $'
      ⍝ ifCondP: f1: if, elif, etc. f2: argument (left and right trimmed) 
      ifCondP← Dir'(?| ((?:el(?:se))?\h?if\h*(?:ndef|def|)) \h+ (.*?) \h* | (else)\b())$'
      endIfP←  Dir'end(?:if)? \h* () $'
      showP←   Dir'show(?:defs)? \h* $'
      unknDirP← Dir'.*$'
      pats←   nmP qtsP defP evalP undefP copyP includeP ifCondP endIfP showP cmP unknDirP   
              nmI qtsI defI evalI undefI copyI includeI ifCondI endIfI showI cmI unknDirI← ⍳≢pats
      lineNum←0

      continueP← '(?:\.{2,3}|…)\h*((?:⍝.*)?)\n'   ⍝ 2-3 dots OR ellipses Unicode char.
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
          C ifI:  Q Truthy privNs⍎Sub ⍵ ⋄ C ifDI:  Q Exists ⍵ ⋄ C ifNI: Q ~Exists ⍵
          ifNotYetTrue_skip≠ ⍺: ifPastTrueBlock_skip  
          C elifI: Q Truthy privNs⍎Sub ⍵ ⋄ C elifDI: Q Exists ⍵ ⋄ C elifNI: Q ~Exists ⍵
          C elI:   ifIsTrue_keep     
        } f2 
          skipG⊢←  2| ⊃⌽condG ⋄ (skipG⊃ '+-'), f0 
      }  

      Sub←  nmP qtsP cmP ⎕R { f0← ⍵.Match ⋄ ⍵.PatternNum= 0: 1 Get f0 ⋄ f0 }  

      privNs← ⎕NS⍬ 
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
            C nmI:  1 Get f0
            C defI: Cm f0⊣ f2 (f1 Set)  Sub f3 ⊣ f1 f2 f3← ∆F¨1 2 3 
            C evalI: Cm f0,  1 ((f1,'e') Eval) Sub f2 ⊣ f1 f2←    ∆F¨1 2 
            C undefI: Cm f0⊣ Undef ∆F 1 
            C copyI:  { f1 f2← ∆F¨1 2 ⋄ lns← Copy f2
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C includeI:  { f1 f2← ∆F¨1 2 ⋄ lns← Include f2 
              0=≢f1: Cm f0 ⊣ linesG,⍨← lns
              Cm f0, ∊nlC,¨ lns
            } ⍵
            C showI: Cm f0, ShowAll ⍬
            C unknDirI: ⎕SIGNAL UnknDirÊ f0
            ⎕SIGNAL logicÊ
        }⍠('UCP' 1)
          0=≢ ⍵: ⍺  
          curG← ⊃⍵ ⋄ linesG← 1↓⍵ 
        ~skipG: linesG ∇⍨ ⍺,⊂ Match curG  
         IfNotDirective curG:  linesG ∇⍨ ⍺,⊂ '⍝-',curG
         linesG ∇⍨ ⍺,⊂ Match curG 
      }

      (myLns myNm) nc← ParseArgs lnsIn
      lnsOut← (1↑myLns), ProcLns Continue 1↓myLns
:Else 
    ⎕SIGNAL ⊂⎕DMX.('EN' 'EM' 'Message',⍥⊆¨EN EM Message)
:EndTrap ⋄ :EndWith