lnsOut← Macros lnsIn  

:With ⎕Ns⍬ 
    DEBUG←1
    ⎕IO ⎕ML←0 1
    nlC← ⎕UCS 13 
  ⍝ error messages 
    cpySyntxÊ← ⊂('EN' 11)('Message' '::COPY argument syntax— "::Copy ws: name1 ..."')
    endSyntxÊ←   ⊂('EN' 11)('Message' '::End directive doesn''t match anything')
    optionsÊ←  ⊂('EN' 11)('Message' 'Option(s) ⍺ are invalid or superfluous')
    logicÊ←    ⊂('EN' 11)('Message' 'Macros: Internal logic error!')
    missingE←  ⊂('EN' 11)('Message' 'Invalid argument (⍵): Invalid or missing function or op')
  ⍝ error fns
    CpyNFndÊ←  {⊂('EN' 11)('Message' ('::COPY Could not find fn(s)/op(s): ',⍵)) }
    UnknDirÊ←  {⊂('EN' 11)('Message' ('Invalid macro directive "','"',⍨ ⍵)) }
    FileÊ← {⊂('EN' 11)('Message' ('Invalid/Missing file: ''','''',⍨ ⍵)) }
    MacroÊ←   {⊂('EN' 11)('Message' ('Invalid macro name "','"',⍨ ⍵)) }
    EvalÊ←  {⊂('EN' 11)('Message' ('::DEFE failed evaluating expression "','"',⍨ ⍵)) }
 
    :Trap 0/⍨ ~DEBUG  
      TrimL← {⍵↓⍨ +/∧\ ⍵=' '}
      IfSkip_And_NotDir← { ⍺: '::'≢ 2↑ TrimL ⍵ ⋄ 0}
      Copy←{
        ~':'∊⍵: ⎕SIGNAL cpySyntxÊ
          dir names←':'(≠⊆⊢)⍵ ⋄ dir~← ' ' ⋄ names←' '(≠⊆⊢)names
        11:: ⎕SIGNAL CpyNFndÊ ⍵
          _←names (ns←⎕NS⍬).⎕CY dir ⋄ ⊃,/ns.(⎕NR¨⎕NL-3 4)
      }
      Include←{ sysDir← './'
          fi← (sysDir/⍨ '<'=⊃⍵), fi← {'<"'∊⍨ ⊃⍵: 1↓¯1↓⍵ ⋄ ⍵}⍵
        0:: ⎕SIGNAL FileÊ fi ⋄ ⊃⎕NGET fi 1 
      }
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
  
      keysV← ⍬
      valsV← ⍬
    ⍝ Canon: If ⍺=0, ignore invalid non-sys names...
      Canon← { '⎕'=⊃⍵: 1 ⎕C ⍵ ⋄ ⍵ }
      Set← {  
          ⍺← ⊢
          k v←⍺ (⍵, ⍺/⍨0=≢⍵)
          vC← ⍺⍺ Eval v
          p←keysV⍳ ⊂kC← Canon k
        p≥ ≢keysV: keysV,← ⊂kC ⊣ valsV,← ⊂vC
        1: (p⊃ valsV)← vC  
      }
      ToLinear← { 0∊ ⍴mx←⎕FMT ⍵: '' ⋄ 1=≢mx: ∊mx ⋄ ⎕SE.Dyalog.Array.Serialise ⍵}
      Eval← {  ⍺←0  
          ⋄ Parens← '('∘,,∘')'
          ⋄ QTs← {qt←'''' ⋄ (qt∘,,∘qt)⍵/⍨ 1+qt=⍵ }
          ⋄ Exec← {0:: ⎕SIGNAL EvalÊ ⍵ ⋄ privNs⍎⍵ }
          e p q← 'epq'∊ ⎕C⍺⍺
          0∊⍴res← Parens⍣p⊣ QTs⍣q⊣ ToLinear⍣e⊣ Exec⍣e⊣ ⍵: ''
          ⍺: ∊nlC, res ⋄ res
      }
      Undef←{  
          (p← keysV⍳ ⊂kC← Canon ⍵)≥ ≢keysV: 0
          1⊣ keysV⊢← keysV/⍨ q ⊣ valsV⊢← valsV/⍨ q← p≠ ⍳≢keysV 
      }
      Get← { ⍺←0
        res← { (p← keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV: p⊃ valsV ⋄ ⍵ } ⍵
        ⍺: ToLinear res  ⋄ res 
      }
      Exists← {  (  keysV⍳ ⊂kC← Canon ⍵ )< ≢keysV }
    ⍝ Truthy: A "sort-of" true as in Python
    ⍝   Returns 1: For any array that is not of length 0  
    ⍝              that is not singleton (∊⍵) 0 or ⎕NULL
    ⍝   Returns 0: Otherwise 
      Truthy← { r←⍴s←∊⍵ ⋄ 1≠r:0≠r ⋄ s(~∊)0 ⎕NULL }
      Show←   { ⍬⊣ keysV{ ⎕←((8⌈≢_)↑ _←'"','"',⍨⍺),' → "','"',⍨⍵ }¨valsV }

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
      unknDirP← Dir'.*$'
      pats←   nmP qtsP defP evalP undefP copyP includeP ifCondP endIfP cmP unknDirP   
              nmI qtsI defI evalI undefI copyI includeI ifCondI endIfI cmI unknDirI← ⍳≢pats
      lineNum←0

      continueP← '(?:\.{2,3}|…)\h*((?:⍝.*)?)\n'   ⍝ 2-3 dots OR ellipses Unicode char.
      continueG← ⍬
      Continue←qtsP cmP continueP '\n?$' ⎕R {  
          ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
          C 0 1: ∆F 0 ⋄ C 2: ' ' ⊣ continueG,← ⊂∆F 1
          (continueG⊢← ⍬)⊢ (∊' ',¨ continueG), ∆F 0
      }⍠('UCP' 1)('Mode' 'M')('EOL' 'LF')

      ifCondL← (,'if' 'elseif' 'elif' ∘., '' 'def' 'ndef'), ⊂'else'
      ifMapL← 0 1 2 3 4 5 3 4 5 6
      ifI ifDI ifNI elifI elifDI elifNI elI← 0 1 2 3 4 5 6
      IfCond← '⍝'∘,{   
           IF_TRIGGERED IF_READY IF_SKIP← 2 1 ¯1  ⍝ 0= IF_INACTIVE
           f0 (f1 f2)← ⍵ ⋄ p← ifCondL⍳ ⊂' '~⍨⎕C f1 ⋄ C← (p⊃ ifMapL)∘∊
        (≢ifCondL)= p : ⎕SIGNAL logicÊ
        condG,← (C ifI ifDI ifNI)/0
        (⊃⌽condG)← (⊃⌽condG){ Q← ⊃∘IF_READY IF_TRIGGERED
          C ifI:  Q Truthy privNs⍎Sub ⍵ ⋄ C ifDI:  Q Exists ⍵ ⋄ C ifNI: Q ~Exists ⍵
          IF_READY≠ ⍺: IF_SKIP  
          C elifI: Q Truthy privNs⍎Sub ⍵ ⋄ C elifDI: Q Exists ⍵ ⋄ C elifNI: Q ~Exists ⍵
          C elI:   IF_TRIGGERED     
        } f2 
          skipG⊢←  2| |⊃⌽condG
          (skipG⊃ '+-'), f0 
      }  

      Sub←  nmP qtsP cmP ⎕R { f0← ⍵.Match ⋄ ⍵.PatternNum= 0: 1 Get f0 ⋄ f0 }  

      privNs← ⎕NS⍬ 
      condG← ,0  ⋄ skipG←0 
      ProcLns← ⍬∘{
        Match← pats ⎕R { 
          ⍝ extern: linesG
            ∆F← ⍵.{Lengths[⍵]↑Offsets[⍵]↓Block} ⋄ C←  ⍵.PatternNum∘∊
            f0← ⍵.Match
            C endIfI:  '⍝+', f0 ⊣ skipG⊢← 2| |⊃⌽condG ⊣ condG↓⍨← ¯1 ⊣ ⎕SIGNAL⍣(1≥≢condG)⊢endSyntxÊ
            C ifCondI: IfCond f0 (∆F¨1 2)
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
            C unknDirI: ⎕SIGNAL UnknDirÊ f0
            ⎕SIGNAL logicÊ
        }⍠('UCP' 1)
          0=≢ ⍵: ⍺  
          curG← ⊃⍵ ⋄ linesG← 1↓⍵  
        skipG IfSkip_And_NotDir curG:  linesG ∇⍨ ⍺,⊂ '⍝-',curG
          linesG ∇⍨ ⍺,⊂ Match curG 
      }

      (myLns myNm) nc← ParseArgs lnsIn
      lnsOut← (1↑myLns), ProcLns Continue 1↓myLns
    :Else 
      ⎕SIGNAL ⊂⎕DMX.('EN' 'EM' 'Message',⍥⊆¨EN EM Message)
    :EndTrap
:EndWith